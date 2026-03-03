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

// Hook for Direct Message deletion - iOS 26 compatible
%hook IGDirectThreadViewController
- (void)deleteMessage:(id)message {
    if ([SCIUtils getBoolPref:@"keep_deleted_message"]) {
        NSLog(@"[PekiWare] Saving message before deletion from ThreadViewController");
        
        // Save message before deletion
        @try {
            if (message && ![_deletedMessageIds containsObject:[message valueForKey:@"messageId"]]) {
                [_deletedMessages addObject:message];
                [_deletedMessageIds addObject:[message valueForKey:@"messageId"]];
                NSLog(@"[PekiWare] Saved message: %@", [message valueForKey:@"text"] ?: @"[Media/Other]");
            }
        } @catch (NSException *exception) {
            NSLog(@"[PekiWare] Error saving message: %@", exception.reason);
        }
        
        // Don't call %orig - prevent deletion
        return;
    }
    %orig;
}

- (void)deleteMessages:(NSArray *)messages {
    if ([SCIUtils getBoolPref:@"keep_deleted_message"]) {
        NSLog(@"[PekiWare] Saving multiple messages before deletion from ThreadViewController");
        
        // Save all messages before deletion
        @try {
            for (id message in messages) {
                if (message && ![_deletedMessageIds containsObject:[message valueForKey:@"messageId"]]) {
                    [_deletedMessages addObject:message];
                    [_deletedMessageIds addObject:[message valueForKey:@"messageId"]];
                    NSLog(@"[PekiWare] Saved message: %@", [message valueForKey:@"text"] ?: @"[Media/Other]");
                }
            }
        } @catch (NSException *exception) {
            NSLog(@"[PekiWare] Error saving messages: %@", exception.reason);
        }
        
        // Don't call %orig - prevent deletion
        return;
    }
    %orig;
}

- (void)deleteMessageWithConfirmation:(id)message {
    if ([SCIUtils getBoolPref:@"keep_deleted_message"]) {
        NSLog(@"[PekiWare] Saving message before deletion with confirmation");
        
        // Save message before deletion
        @try {
            if (message && ![_deletedMessageIds containsObject:[message valueForKey:@"messageId"]]) {
                [_deletedMessages addObject:message];
                [_deletedMessageIds addObject:[message valueForKey:@"messageId"]];
                NSLog(@"[PekiWare] Saved message: %@", [message valueForKey:@"text"] ?: @"[Media/Other]");
            }
        } @catch (NSException *exception) {
            NSLog(@"[PekiWare] Error saving message: %@", exception.reason);
        }
        
        // Don't call %orig - prevent deletion
        return;
    }
    %orig;
}

%end

// Hook for Direct Message thread deletion
%hook IGDirectThread
- (void)deleteMessage:(id)message {
    if ([SCIUtils getBoolPref:@"keep_deleted_message"]) {
        NSLog(@"[PekiWare] Saving thread message before deletion");
        
        // Save message before deletion
        @try {
            if (message && ![_deletedMessageIds containsObject:[message valueForKey:@"messageId"]]) {
                [_deletedMessages addObject:message];
                [_deletedMessageIds addObject:[message valueForKey:@"messageId"]];
                NSLog(@"[PekiWare] Saved thread message: %@", [message valueForKey:@"text"] ?: @"[Media/Other]");
            }
        } @catch (NSException *exception) {
            NSLog(@"[PekiWare] Error saving thread message: %@", exception.reason);
        }
        
        // Don't call %orig - prevent deletion
        return;
    }
    %orig;
}

- (void)removeMessage:(id)message {
    if ([SCIUtils getBoolPref:@"keep_deleted_message"]) {
        NSLog(@"[PekiWare] Saving thread message before removal");
        
        // Save message before removal
        @try {
            if (message && ![_deletedMessageIds containsObject:[message valueForKey:@"messageId"]]) {
                [_deletedMessages addObject:message];
                [_deletedMessageIds addObject:[message valueForKey:@"messageId"]];
                NSLog(@"[PekiWare] Saved thread message for removal: %@", [message valueForKey:@"text"] ?: @"[Media/Other]");
            }
        } @catch (NSException *exception) {
            NSLog(@"[PekiWare] Error saving thread message: %@", exception.reason);
        }
        
        // Don't call %orig - prevent removal
        return;
    }
    %orig;
}

%end

// Hook for Direct Message item removal from inbox
%hook IGDirectInboxViewController
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([SCIUtils getBoolPref:@"keep_deleted_message"] && editingStyle == UITableViewCellEditingStyleDelete) {
        NSLog(@"[PekiWare] Preventing message deletion from inbox");
        // Don't call %orig - prevent deletion
        return;
    }
    %orig;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    %orig;
    
    // Check if this is a delete action
    if ([SCIUtils getBoolPref:@"keep_deleted_message"]) {
        // Additional check for swipe-to-delete
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // Prevent any deletion that might occur after selection
        });
    }
}

%end

// Hook for visual message deletion
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

// Hook for message manager
%hook IGDirectMessageManager
- (void)deleteMessage:(id)message fromThread:(id)thread {
    if ([SCIUtils getBoolPref:@"keep_deleted_message"]) {
        NSLog(@"[PekiWare] Saving message before deletion from manager");
        
        // Save message before deletion
        @try {
            if (message && ![_deletedMessageIds containsObject:[message valueForKey:@"messageId"]]) {
                [_deletedMessages addObject:message];
                [_deletedMessageIds addObject:[message valueForKey:@"messageId"]];
                NSLog(@"[PekiWare] Saved message from manager: %@", [message valueForKey:@"text"] ?: @"[Media/Other]");
            }
        } @catch (NSException *exception) {
            NSLog(@"[PekiWare] Error saving message from manager: %@", exception.reason);
        }
        
        // Don't call %orig - prevent deletion
        return;
    }
    %orig;
}

%end

// Hook for any message removal operations - REMOVED due to forward declaration issue
// %hook IGDirectMessage
// - (void)markAsDeleted {
//     if ([SCIUtils getBoolPref:@"keep_deleted_message"]) {
//         NSLog(@"[PekiWare] Preventing message mark as deleted");
//         
//         // Save message before marking as deleted
//         @try {
//             if (![_deletedMessageIds containsObject:[self valueForKey:@"messageId"]]) {
//                 [_deletedMessages addObject:self];
//                 [_deletedMessageIds addObject:[self valueForKey:@"messageId"]];
//                 NSLog(@"[PekiWare] Saved message from markAsDeleted: %@", [self valueForKey:@"text"] ?: @"[Media/Other]");
//             }
//         } @catch (NSException *exception) {
//             NSLog(@"[PekiWare] Error saving message from markAsDeleted: %@", exception.reason);
//         }
//         
//         // Don't call %orig - prevent marking as deleted
//         return;
//     }
//     %orig;
// }

// - (void)setIsDeleted:(BOOL)deleted {
//     if ([SCIUtils getBoolPref:@"keep_deleted_message"] && deleted) {
//         NSLog(@"[PekiWare] Preventing message set as deleted");
//         
//         // Save message before setting as deleted
//         @try {
//             if (![_deletedMessageIds containsObject:[self valueForKey:@"messageId"]]) {
//                 [_deletedMessages addObject:self];
//                 [_deletedMessageIds addObject:[self valueForKey:@"messageId"]];
//                 NSLog(@"[PekiWare] Saved message from setIsDeleted: %@", [self valueForKey:@"text"] ?: @"[Media/Other]");
//             }
//         } @catch (NSException *exception) {
//             NSLog(@"[PekiWare] Error saving message from setIsDeleted: %@", exception.reason);
//         }
//         
//         // Don't call %orig - prevent setting as deleted
//         return;
//     }
//     %orig;
// }

// %end

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
