#import "../../Utils.h"
#import "../../InstagramHeaders.h"

// Global storage for deleted messages
static NSMutableArray *_deletedMessages;
static NSMutableArray *_deletedMessageIds;

// Initialize storage
__attribute__((constructor))
static void initDeletedMessagesStorage() {
    _deletedMessages = [[NSMutableArray alloc] init];
    _deletedMessageIds = [[NSMutableArray alloc] init];
    NSLog(@"[PekiWare] KeepDeletedMessages initialized - storage ready");
}

// Test log on app launch
__attribute__((constructor))
static void testKeepDeletedMessages() {
    BOOL isEnabled = [SCIUtils getBoolPref:@"keep_deleted_message"];
    NSLog(@"[PekiWare] KeepDeletedMessages setting: %@", isEnabled ? @"ENABLED" : @"DISABLED");
}

// Hook for visual message deletion - REAL CLASS
%hook IGDirectVisualMessageViewerController
- (void)deleteMessage:(id)message {
    if ([SCIUtils getBoolPref:@"keep_deleted_message"]) {
        NSLog(@"[PekiWare] Saving visual message before deletion");
        
        // Save message before deletion
        @try {
            if (message && ![_deletedMessageIds containsObject:[message valueForKey:@"messageId"]]) {
                [_deletedMessages addObject:message];
                [_deletedMessageIds addObject:[message valueForKey:@"messageId"]];
                NSLog(@"[PekiWare] Saved visual message: %@", [message valueForKey:@"text"] ?: @"[Media/Other]");
            }
        } @catch (NSException *exception) {
            NSLog(@"[PekiWare] Error saving visual message: %@", exception.reason);
        }
        
        // Don't call %orig - prevent deletion
        return;
    }
    %orig;
}

- (void)deleteCurrentMessage {
    if ([SCIUtils getBoolPref:@"keep_deleted_message"]) {
        NSLog(@"[PekiWare] Saving current visual message before deletion");
        
        // Get current message and save it
        @try {
            id currentMessage = [self valueForKey:@"currentMessage"];
            if (currentMessage && ![_deletedMessageIds containsObject:[currentMessage valueForKey:@"messageId"]]) {
                [_deletedMessages addObject:currentMessage];
                [_deletedMessageIds addObject:[currentMessage valueForKey:@"messageId"]];
                NSLog(@"[PekiWare] Saved current visual message: %@", [currentMessage valueForKey:@"text"] ?: @"[Media/Other]");
            }
        } @catch (NSException *exception) {
            NSLog(@"[PekiWare] Error saving current visual message: %@", exception.reason);
        }
        
        // Don't call %orig - prevent deletion
        return;
    }
    %orig;
}

%end

// Hook for composer deletion
%hook IGDirectComposer
- (void)deleteMessage:(id)message {
    if ([SCIUtils getBoolPref:@"keep_deleted_message"]) {
        NSLog(@"[PekiWare] Saving message from composer before deletion");
        
        // Save message before deletion
        @try {
            if (message && ![_deletedMessageIds containsObject:[message valueForKey:@"messageId"]]) {
                [_deletedMessages addObject:message];
                [_deletedMessageIds addObject:[message valueForKey:@"messageId"]];
                NSLog(@"[PekiWare] Saved message from composer: %@", [message valueForKey:@"text"] ?: @"[Media/Other]");
            }
        } @catch (NSException *exception) {
            NSLog(@"[PekiWare] Error saving message from composer: %@", exception.reason);
        }
        
        // Don't call %orig - prevent deletion
        return;
    }
    %orig;
}

%end

// Hook for notes composer deletion
%hook IGDirectNotesComposerViewController
- (void)deleteMessage:(id)message {
    if ([SCIUtils getBoolPref:@"keep_deleted_message"]) {
        NSLog(@"[PekiWare] Saving message from notes composer before deletion");
        
        // Save message before deletion
        @try {
            if (message && ![_deletedMessageIds containsObject:[message valueForKey:@"messageId"]]) {
                [_deletedMessages addObject:message];
                [_deletedMessageIds addObject:[message valueForKey:@"messageId"]];
                NSLog(@"[PekiWare] Saved message from notes composer: %@", [message valueForKey:@"text"] ?: @"[Media/Other]");
            }
        } @catch (NSException *exception) {
            NSLog(@"[PekiWare] Error saving message from notes composer: %@", exception.reason);
        }
        
        // Don't call %orig - prevent deletion
        return;
    }
    %orig;
}

%end

// Legacy hooks for older Instagram versions
%hook IGDirectRealtimeIrisThreadDelta
+ (id)removeItemWithMessageId:(id)arg1 {
    if ([SCIUtils getBoolPref:@"keep_deleted_message"]) {
        NSLog(@"[PekiWare] Blocking message removal via IrisThreadDelta");
        arg1 = NULL;
    }
    return %orig(arg1);
}
%end

%hook IGDirectMessageUpdate
+ (id)removeMessageWithMessageId:(id)arg1{
    if ([SCIUtils getBoolPref:@"keep_deleted_message"]) {
        NSLog(@"[PekiWare] Blocking message removal via MessageUpdate");
        arg1 = NULL;
    }
    return %orig(arg1);
}
%end
