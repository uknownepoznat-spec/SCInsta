#import "../../Utils.h"
#import "../../InstagramHeaders.h"

// Hook for Direct Message deletion - iOS 26 compatible
%hook IGDirectThreadViewController
- (void)deleteMessage:(id)message {
    if ([SCIUtils getBoolPref:@"keep_deleted_message"]) {
        NSLog(@"[PekiWare] Blocking message deletion from ThreadViewController");
        return;
    }
    %orig;
}

- (void)deleteMessages:(NSArray *)messages {
    if ([SCIUtils getBoolPref:@"keep_deleted_message"]) {
        NSLog(@"[PekiWare] Blocking multiple message deletion from ThreadViewController");
        return;
    }
    %orig;
}

- (void)deleteMessageWithConfirmation:(id)message {
    if ([SCIUtils getBoolPref:@"keep_deleted_message"]) {
        NSLog(@"[PekiWare] Blocking message deletion with confirmation");
        return;
    }
    %orig;
}

%end

// Hook for Direct Message thread deletion
%hook IGDirectThread
- (void)deleteMessage:(id)message {
    if ([SCIUtils getBoolPref:@"keep_deleted_message"]) {
        NSLog(@"[PekiWare] Blocking thread message deletion");
        return;
    }
    %orig;
}

- (void)removeMessage:(id)message {
    if ([SCIUtils getBoolPref:@"keep_deleted_message"]) {
        NSLog(@"[PekiWare] Blocking thread message removal");
        return;
    }
    %orig;
}

%end

// Hook for Direct Message item removal from inbox
%hook IGDirectInboxViewController
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([SCIUtils getBoolPref:@"keep_deleted_message"] && editingStyle == UITableViewCellEditingStyleDelete) {
        NSLog(@"[PekiWare] Blocking message deletion from inbox");
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
        NSLog(@"[PekiWare] Blocking visual message deletion");
        return;
    }
    %orig;
}

- (void)deleteCurrentMessage {
    if ([SCIUtils getBoolPref:@"keep_deleted_message"]) {
        NSLog(@"[PekiWare] Blocking current visual message deletion");
        return;
    }
    %orig;
}

%end

// Hook for message manager
%hook IGDirectMessageManager
- (void)deleteMessage:(id)message fromThread:(id)thread {
    if ([SCIUtils getBoolPref:@"keep_deleted_message"]) {
        NSLog(@"[PekiWare] Blocking message deletion from manager");
        return;
    }
    %orig;
}

%end

// Hook for any message removal operations
%hook IGDirectMessage
- (void)markAsDeleted {
    if ([SCIUtils getBoolPref:@"keep_deleted_message"]) {
        NSLog(@"[PekiWare] Blocking message mark as deleted");
        return;
    }
    %orig;
}

- (void)setIsDeleted:(BOOL)deleted {
    if ([SCIUtils getBoolPref:@"keep_deleted_message"] && deleted) {
        NSLog(@"[PekiWare] Blocking message set as deleted");
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
