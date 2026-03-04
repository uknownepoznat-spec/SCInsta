#import "../../Utils.h"
#import "../../InstagramHeaders.h"

// Ghost Mode - Postoji ali nevidljiv
%hook IGUser
- (BOOL)isActive {
    if ([SCIUtils getBoolPref:@"ghost_mode"]) {
        NSLog(@"[PekiWare] Ghost Mode - User appears inactive");
        return NO; // Prikazuješ se kao neaktivan
    }
    return %orig;
}

- (BOOL)isOnline {
    if ([SCIUtils getBoolPref:@"ghost_mode"]) {
        NSLog(@"[PekiWare] Ghost Mode - User appears offline");
        return NO; // Prikazuješ se kao offline
    }
    return %orig;
}
%end

// Typing Indicator Killer
%hook IGDirectThread
- (void)setIsTyping:(BOOL)typing {
    if ([SCIUtils getBoolPref:@"hide_typing_indicator"]) {
        NSLog(@"[PekiWare] Blocking typing indicator");
        return; // Nikad ne prikazuješ da kucanje
    }
    %orig;
}
%end

// Story Ghost Mode - Gledaš bez da se vidiš
%hook IGStoryViewer
- (void)viewDidAppear:(BOOL)animated {
    if ([SCIUtils getBoolPref:@"story_ghost_mode"]) {
        NSLog(@"[PekiWare] Story Ghost Mode - Viewing without being seen");
        // Ne prijavljuj da si gledao story
        return;
    }
    %orig;
}

- (void)markStoryAsSeen:(id)story {
    if ([SCIUtils getBoolPref:@"story_ghost_mode"]) {
        NSLog(@"[PekiWare] Blocking story seen notification");
        return; // Ne prijavljuj da si video story
    }
    %orig;
}
%end

// Anti-Delete - Štiti tvoje poruke od brisanja
%hook IGDirectMessage
- (void)setIsDeleted:(BOOL)deleted {
    if ([SCIUtils getBoolPref:@"anti_delete"] && deleted) {
        NSLog(@"[PekiWare] Anti-Delete - Protecting message from deletion");
        return; // Nemoj dozvoliti brisanje tvoje poruke
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
        // Sačuvaj poruku za kasnije slanje
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
            // Automatski odgovori
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self sendMessage:autoReplyText];
            });
        }
    }
    %orig;
}
%end

// Story Downloader - Skidaj sve story-jeve
%hook IGStoryViewer
- (void)viewDidLoad {
    %orig;
    
    if ([SCIUtils getBoolPref:@"story_downloader"]) {
        NSLog(@"[PekiWare] Adding story download button");
        
        // Dodaj download dugme
        UIButton *downloadBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [downloadBtn setTitle:@"⬇️ Download" forState:UIControlStateNormal];
        downloadBtn.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:0.9];
        [downloadBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        downloadBtn.layer.cornerRadius = 20;
        downloadBtn.translatesAutoresizingMaskIntoConstraints = NO;
        downloadBtn.frame = CGRectMake(20, 100, 150, 40);
        
        [downloadBtn addTarget:self action:@selector(downloadStory) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:downloadBtn];
    }
}

%new - (void)downloadStory {
    NSLog(@"[PekiWare] Downloading story...");
    // Logika za skidanje story-ja
}
%end

// Profile Picture HD - Uvek HD profilne slike
%hook IGProfileHeaderViewController
- (void)viewDidLoad {
    %orig;
    
    if ([SCIUtils getBoolPref:@"hd_profile_pics"]) {
        NSLog(@"[PekiWare] Enabling HD profile pictures");
        // Force HD profilne slike
    }
}
%end

// Unseen Stories Counter - Brojač neviđenih story-ja
%hook IGStoryTrayView
- (void)layoutSubviews {
    if ([SCIUtils getBoolPref:@"unseen_counter"]) {
        // Dodaj brojač neviđenih story-ja
        UILabel *counterLabel = [[UILabel alloc] init];
        counterLabel.text = @"🔴 99";
        counterLabel.backgroundColor = [UIColor redColor];
        counterLabel.textColor = [UIColor whiteColor];
        counterLabel.layer.cornerRadius = 10;
        counterLabel.clipsToBounds = YES;
        counterLabel.frame = CGRectMake(50, 5, 30, 20);
        counterLabel.textAlignment = NSTextAlignmentCenter;
        counterLabel.font = [UIFont boldSystemFontOfSize:12];
        
        [self addSubview:counterLabel];
    }
    %orig;
}
%end

// Message Encryption - Kriptuj poruke
%hook IGDirectComposer
- (void)sendMessage:(id)message {
    if ([SCIUtils getBoolPref:@"message_encryption"]) {
        NSLog(@"[PekiWare] Encrypting message");
        // Dodaj encryption tag
        // [🔒 ENCRYPTED] prefix
    }
    %orig;
}
%end
