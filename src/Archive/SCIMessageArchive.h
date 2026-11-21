#import <Foundation/Foundation.h>

// Device-local text snapshots, not a server-side unsend bypass.
@interface SCIMessageArchive : NSObject
+ (instancetype)sharedArchive;
- (void)observeMessage:(id)message text:(NSString *)text;
- (void)retainDeletedMessage:(id)message;
- (void)markDeletedMessageID:(id)messageID;
- (NSArray<NSDictionary *> *)deletedMessages;
- (void)removeEntry:(NSString *)entryID;
- (void)clear;
@end
