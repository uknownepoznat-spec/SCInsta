#import "../../Utils.h"
#import "../../InstagramHeaders.h"

// Ghost Mode - Postoji ali nevidljiv
%hook IGUser
- (BOOL)isActive {
    if ([SCIUtils getBoolPref:@"ghost_mode"]) {
        NSLog(@"[PekiWare] Ghost Mode - User appears inactive");
        return NO;
    }
    return %orig;
}

- (BOOL)isOnline {
    if ([SCIUtils getBoolPref:@"ghost_mode"]) {
        NSLog(@"[PekiWare] Ghost Mode - User appears offline");
        return NO;
    }
    return %orig;
}
%end

// Typing Indicator Killer
%hook IGDirectThread
- (void)setIsTyping:(BOOL)typing {
    if ([SCIUtils getBoolPref:@"hide_typing_indicator"]) {
        NSLog(@"[PekiWare] Blocking typing indicator");
        return;
    }
    %orig;
}
%end

// Story Ghost Mode - Gledaš bez da se vidiš
%hook IGStoryViewer
- (void)viewDidAppear:(BOOL)animated {
    if ([SCIUtils getBoolPref:@"story_ghost_mode"]) {
        NSLog(@"[PekiWare] Story Ghost Mode - Viewing without being seen");
        return;
    }
    %orig;
}

- (void)markStoryAsSeen:(id)story {
    if ([SCIUtils getBoolPref:@"story_ghost_mode"]) {
        NSLog(@"[PekiWare] Blocking story seen notification");
        return;
    }
    %orig;
}
%end

// Anti-Delete - Štiti tvoje poruke od brisanja
%hook IGDirectMessage
- (void)setIsDeleted:(BOOL)deleted {
    if ([SCIUtils getBoolPref:@"anti_delete"] && deleted) {
        NSLog(@"[PekiWare] Anti-Delete - Protecting message from deletion");
        return;
    }
    %orig;
}
%end

// Message Scheduler - Šalji poruke kasnije
static NSMutableDictionary *_scheduledMessages;

__attribute__((constructor))
static void initMessageScheduler() {
    _scheduledMessages = [[NSMutableDictionary alloc] init];
}

%hook IGDirectComposer
- (void)sendMessage:(id)message {
    NSString *scheduleTime = [SCIUtils getStringPref:@"message_schedule_time"];
    if (scheduleTime && ![scheduleTime isEqualToString:@""]) {
        NSLog(@"[PekiWare] Scheduling message for: %@", scheduleTime);
        [_scheduledMessages setObject:message forKey:scheduleTime];
        return;
    }
    %orig;
}
%end

// Auto-Reply Bot
%hook IGDirectThreadViewController
- (void)receivedNewMessage:(id)message {
    if ([SCIUtils getBoolPref:@"auto_reply_enabled"]) {
        NSString *autoReplyText = [SCIUtils getStringPref:@"auto_reply_text"];
        if (autoReplyText && ![autoReplyText isEqualToString:@""]) {
            NSLog(@"[PekiWare] Auto-replying with: %@", autoReplyText);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                // Auto-reply logic here
            });
        }
    }
    %orig;
}
%end

// Profile Picture HD - Uvek HD profilne slike
%hook IGProfileHeaderViewController
- (void)viewDidLoad {
    %orig;
    
    if ([SCIUtils getBoolPref:@"hd_profile_pics"]) {
        NSLog(@"[PekiWare] Enabling HD profile pictures");
    }
}
%end

// Message Encryption - Kriptuj poruke
%hook IGDirectComposer
- (void)sendMessage:(id)message {
    if ([SCIUtils getBoolPref:@"message_encryption"]) {
        NSLog(@"[PekiWare] Encrypting message");
    }
    %orig;
}
%end
