#import "SCIMessageArchive.h"
#import "../Utils.h"

static NSString *SCIArchiveString(id value) {
    if ([value isKindOfClass:[NSString class]]) return value;
    if ([value isKindOfClass:[NSNumber class]]) return [value stringValue];
    return nil;
}

static NSString *SCIArchiveField(id object, NSArray<NSString *> *keys) {
    for (NSString *key in keys) {
        NSString *value = SCIArchiveString([SCIUtils mediaValueForObject:object key:key]);
        if (value.length) return value;
    }
    return nil;
}

@interface SCIMessageArchive ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *entries;
@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, strong) dispatch_queue_t queue;
@end

@implementation SCIMessageArchive

+ (instancetype)sharedArchive {
    static SCIMessageArchive *archive;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ archive = [self new]; });
    return archive;
}

- (instancetype)init {
    if ((self = [super init])) {
        _queue = dispatch_queue_create("com.pekiscripter.message-archive", DISPATCH_QUEUE_SERIAL);
        NSURL *base = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject;
        NSURL *folder = [base URLByAppendingPathComponent:@"PekiScripter" isDirectory:YES];
        [[NSFileManager defaultManager] createDirectoryAtURL:folder withIntermediateDirectories:YES
            attributes:@{NSFileProtectionKey: NSFileProtectionCompleteUntilFirstUserAuthentication} error:nil];
        [folder setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
        _fileURL = [folder URLByAppendingPathComponent:@"message-snapshots.plist"];
        NSDictionary *saved = [NSDictionary dictionaryWithContentsOfURL:_fileURL];
        _entries = [NSMutableDictionary new];
        for (NSString *key in saved) {
            id entry = saved[key];
            if ([key isKindOfClass:[NSString class]] && [entry isKindOfClass:[NSDictionary class]]
                && [entry[@"text"] isKindOfClass:[NSString class]]
                && [entry[@"capturedAt"] isKindOfClass:[NSDate class]]
                && [entry[@"entryID"] isKindOfClass:[NSString class]]
                && [entry[@"messageID"] isKindOfClass:[NSString class]]
                && [entry[@"sender"] isKindOfClass:[NSString class]]
                && [entry[@"threadID"] isKindOfClass:[NSString class]]
                && [entry[@"deleted"] isKindOfClass:[NSNumber class]]) {
                _entries[key] = entry;
            }
        }
    }
    return self;
}

- (void)persist {
    // Bound retained private data and disk usage. Never upload message contents.
    if (self.entries.count > 500) {
        NSArray *oldest = [self.entries keysSortedByValueUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
            return [a[@"capturedAt"] compare:b[@"capturedAt"]];
        }];
        NSUInteger count = self.entries.count - 500;
        [self.entries removeObjectsForKeys:[oldest subarrayWithRange:NSMakeRange(0, count)]];
    }
    NSError *error = nil;
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:self.entries
        format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
    if (data && ![data writeToURL:self.fileURL
        options:NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUntilFirstUserAuthentication error:&error]) {
        NSLog(@"[Peki Scripter] Could not persist local message archive: %@", error.domain);
    }
}

- (void)captureMessage:(id)message text:(NSString *)knownText deleted:(BOOL)deleted {
    if (![SCIUtils getBoolPref:@"keep_deleted_message"] || !message) return;
    NSMutableDictionary *threadState = [NSThread currentThread].threadDictionary;
    if ([threadState[@"SCIArchiveCapturing"] boolValue]) return;
    threadState[@"SCIArchiveCapturing"] = @YES;
    @try {
        NSString *text = knownText ?: SCIArchiveField(message, @[@"text", @"messageText", @"body"]);
        if (!text.length) return; // Text only; do not claim to back up expiring attachments.
        NSString *messageID = SCIArchiveField(message, @[@"messageId", @"messageID", @"itemId", @"itemID", @"clientContext"]);
        if (!messageID.length && !deleted) return;
        NSString *threadID = SCIArchiveField(message, @[@"threadId", @"threadID"]) ?: @"Unknown conversation";
        NSString *sender = SCIArchiveField(message, @[@"senderId", @"senderID", @"userId"]) ?: @"Unknown sender";
        // No guessed account identity: explicitly label the archive as device-local.
        NSString *entryID = messageID.length
            ? [NSString stringWithFormat:@"%@/%@", threadID, messageID] : NSUUID.UUID.UUIDString;
        NSDictionary *snapshot = @{
            @"entryID": entryID, @"messageID": messageID ?: entryID,
            @"threadID": threadID, @"sender": sender,
            @"text": [text substringToIndex:MIN(text.length, 16000)],
            @"capturedAt": [NSDate date], @"deleted": @(deleted)
        };
        dispatch_async(self.queue, ^{
            NSString *storageKey = entryID;
            // A message can acquire its thread ID after its text is first read.
            for (NSString *key in self.entries) {
                if ([self.entries[key][@"messageID"] isEqual:snapshot[@"messageID"]]) {
                    storageKey = key;
                    break;
                }
            }
            NSDictionary *previous = self.entries[storageKey];
            // Later tombstones/redaction placeholders must not replace retained text.
            if ([previous[@"deleted"] boolValue]) return;
            if (previous && [previous[@"text"] isEqual:snapshot[@"text"]]
                && [previous[@"threadID"] isEqual:snapshot[@"threadID"]]
                && [previous[@"sender"] isEqual:snapshot[@"sender"]] && !deleted) return;
            NSMutableDictionary *updated = [snapshot mutableCopy];
            updated[@"entryID"] = storageKey;
            self.entries[storageKey] = updated;
            [self persist];
        });
    } @finally {
        [threadState removeObjectForKey:@"SCIArchiveCapturing"];
    }
}

- (void)observeMessage:(id)message text:(NSString *)text {
    [self captureMessage:message text:text deleted:NO];
}

- (void)retainDeletedMessage:(id)message {
    if ([message isKindOfClass:[NSString class]] || [message isKindOfClass:[NSNumber class]]) {
        [self markDeletedMessageID:message];
        return;
    }
    [self captureMessage:message text:nil deleted:YES];
    NSString *messageID = SCIArchiveField(message, @[@"messageId", @"messageID", @"itemId", @"itemID", @"clientContext"]);
    if (messageID.length) [self markDeletedMessageID:messageID];
}

- (void)markDeletedMessageID:(id)value {
    if (![SCIUtils getBoolPref:@"keep_deleted_message"]) return;
    NSString *messageID = SCIArchiveString(value);
    if (!messageID.length) return;
    dispatch_async(self.queue, ^{
        BOOL changed = NO;
        for (NSString *key in self.entries.allKeys) {
            NSDictionary *entry = self.entries[key];
            if ([entry[@"messageID"] isEqual:messageID] && ![entry[@"deleted"] boolValue]) {
                NSMutableDictionary *updated = [entry mutableCopy];
                updated[@"deleted"] = @YES;
                self.entries[key] = updated;
                changed = YES;
            }
        }
        if (changed) [self persist];
    });
}

- (NSArray<NSDictionary *> *)deletedMessages {
    __block NSArray *result;
    dispatch_sync(self.queue, ^{
        NSPredicate *deleted = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *entry, NSDictionary *bindings) {
            return [entry[@"deleted"] boolValue];
        }];
        result = [[self.entries.allValues filteredArrayUsingPredicate:deleted]
            sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
                return [b[@"capturedAt"] compare:a[@"capturedAt"]];
            }];
    });
    return result;
}

- (void)removeEntry:(NSString *)entryID {
    dispatch_async(self.queue, ^{
        [self.entries removeObjectForKey:entryID];
        [self persist];
    });
}

- (void)clear {
    dispatch_async(self.queue, ^{
        [self.entries removeAllObjects];
        [self persist];
    });
}
@end
