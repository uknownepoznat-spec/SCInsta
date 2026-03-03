#import <substrate.h>
#import <objc/message.h>
#import "InstagramHeaders.h"
#import "Tweak.h"
#import "Utils.h"
#import "Settings/SCISettingsViewController.h"

// Ensure compiler knows IGProfileViewController is a UIViewController
@interface IGProfileViewController : UIViewController
- (void)sci_addPekiLocalVerificationBadgeIfNeeded;
- (BOOL)sci_isViewingOwnProfile;
- (void)sci_updateCustomFollowerCountIfNeeded;
- (void)findAndUpdateFollowerLabels:(NSInteger)count;
- (void)searchAndUpdateLabelsInView:(UIView *)view targetCount:(NSInteger)count;
- (NSString *)formatFollowerCount:(NSInteger)count;
@end

///////////////////////////////////////////////////////////

// Screenshot handlers

#define VOID_HANDLESCREENSHOT(orig) [SCIUtils getBoolPref:@"remove_screenshot_alert"] ? nil : orig;
#define NONVOID_HANDLESCREENSHOT(orig) return VOID_HANDLESCREENSHOT(orig)

///////////////////////////////////////////////////////////

// * Tweak version *
NSString *SCIVersionString = @"v1.0.0";

// Variables that work across features
BOOL seenButtonEnabled = false;
BOOL dmVisualMsgsViewedButtonEnabled = false;

// Tweak first-time setup
%hook IGInstagramAppDelegate
- (_Bool)application:(UIApplication *)application willFinishLaunchingWithOptions:(id)arg2 {
    // Default PekiWare config
    NSDictionary *sciDefaults = @{
        @"hide_ads": @(YES),
        @"copy_description": @(YES),
        @"detailed_color_picker": @(YES),
        @"remove_screenshot_alert": @(YES),
        @"call_confirm": @(YES),
        @"keep_deleted_message": @(YES),
        @"dw_feed_posts": @(YES),
        @"dw_reels": @(YES),
        @"dw_story": @(YES),
        @"save_profile": @(YES),
        @"dw_finger_count": @(3),
        @"dw_finger_duration": @(0.5),
        @"reels_tap_control": @"default",
        @"nav_icon_ordering": @"default",
        @"swipe_nav_tabs": @"default",
        @"enable_notes_customization": @(YES),
        @"custom_note_themes": @(YES),
        @"peki_local_verification": @(NO),
        @"peki_custom_follower_count": @(0),
        @"peki_enable_custom_followers": @(NO)
    };
    [[NSUserDefaults standardUserDefaults] registerDefaults:sciDefaults];
    
    // Override instagram defaults
    if ([SCIUtils getBoolPref:@"liquid_glass_buttons"]) {
        [[NSUserDefaults standardUserDefaults] setValue:@(YES) forKey:@"instagram.override.project.lucent.navigation"];
    }
    else {
        [[NSUserDefaults standardUserDefaults] setValue:@(NO) forKey:@"instagram.override.project.lucent.navigation"];
    }

    return %orig;
}
- (_Bool)application:(UIApplication *)application didFinishLaunchingWithOptions:(id)arg2 {
    %orig;

    // Open settings for first-time users
    double openDelay = [SCIUtils getBoolPref:@"tweak_settings_app_launch"] ? 0.0 : 5.0;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(openDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (
            ![[[NSUserDefaults standardUserDefaults] objectForKey:@"SCInstaFirstRun"] isEqualToString:SCIVersionString]
            || [SCIUtils getBoolPref:@"tweak_settings_app_launch"]
        ) {
            NSLog(@"[PekiWare] First run, initializing");

            // Display settings modal on screen
            NSLog(@"[PekiWare] Displaying PekiWare first-time settings modal");
            UIViewController *rootController = [[self window] rootViewController];
            SCISettingsViewController *settingsViewController = [SCISettingsViewController new];
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];

            [rootController presentViewController:navigationController animated:YES completion:nil];
        }
    });

    NSLog(@"[PekiWare] Cleaning cache...");
    [SCIUtils cleanCache];

    if ([SCIUtils getBoolPref:@"flex_app_launch"]) {
        [[objc_getClass("FLEXManager") sharedManager] showExplorer];
    }

    return true;
}

- (void)applicationDidBecomeActive:(id)arg1 {
    %orig;
    
    if ([SCIUtils getBoolPref:@"flex_app_start"]) {
        [[objc_getClass("FLEXManager") sharedManager] showExplorer];
    }
}
%end

// Disable sending modded insta bug reports
%hook IGWindow
- (void)showDebugMenu {
    return;
}
%end

%hook IGBugReportUploader
- (id)initWithNetworker:(id)arg1
         pandoGraphQLService:(id)arg2
             analyticsLogger:(id)arg3
                userDefaults:(id)arg4
         launcherSetProvider:(id)arg5
shouldPersistLastBugReportId:(id)arg6
{
    return nil;
}
%end

// Disable anti-screenshot feature on visual messages
%hook IGStoryViewerContainerView
- (void)setShouldBlockScreenshot:(BOOL)arg1 viewModel:(id)arg2 { VOID_HANDLESCREENSHOT(%orig); }
%end

// Disable screenshot logging/detection
%hook IGDirectVisualMessageViewerSession
- (id)visualMessageViewerController:(id)arg1 didDetectScreenshotForVisualMessage:(id)arg2 atIndex:(NSInteger)arg3 { NONVOID_HANDLESCREENSHOT(%orig); }
%end

%hook IGDirectVisualMessageReplayService
- (id)visualMessageViewerController:(id)arg1 didDetectScreenshotForVisualMessage:(id)arg2 atIndex:(NSInteger)arg3 { NONVOID_HANDLESCREENSHOT(%orig); }
%end

%hook IGDirectVisualMessageReportService
- (id)visualMessageViewerController:(id)arg1 didDetectScreenshotForVisualMessage:(id)arg2 atIndex:(NSInteger)arg3 { NONVOID_HANDLESCREENSHOT(%orig); }
%end

%hook IGDirectVisualMessageScreenshotSafetyLogger
- (id)initWithUserSession:(id)arg1 entryPoint:(NSInteger)arg2 {
    if ([SCIUtils getBoolPref:@"remove_screenshot_alert"]) {
        NSLog(@"[PekiWare] Disable visual message screenshot safety logger");
        return nil;
    }

    return %orig;
}
%end

%hook IGScreenshotObserver
- (id)initForController:(id)arg1 { NONVOID_HANDLESCREENSHOT(%orig); }
%end

%hook IGScreenshotObserverDelegate
- (void)screenshotObserverDidSeeScreenshotTaken:(id)arg1 { VOID_HANDLESCREENSHOT(%orig); }
- (void)screenshotObserverDidSeeActiveScreenCapture:(id)arg1 event:(NSInteger)arg2 { VOID_HANDLESCREENSHOT(%orig); }
%end

%hook IGDirectMediaViewerViewController
- (void)screenshotObserverDidSeeScreenshotTaken:(id)arg1 { VOID_HANDLESCREENSHOT(%orig); }
- (void)screenshotObserverDidSeeActiveScreenCapture:(id)arg1 event:(NSInteger)arg2 { VOID_HANDLESCREENSHOT(%orig); }
%end

%hook IGStoryViewerViewController
- (void)screenshotObserverDidSeeScreenshotTaken:(id)arg1 { VOID_HANDLESCREENSHOT(%orig); }
- (void)screenshotObserverDidSeeActiveScreenCapture:(id)arg1 event:(NSInteger)arg2 { VOID_HANDLESCREENSHOT(%orig); }
%end

%hook IGSundialFeedViewController
- (void)screenshotObserverDidSeeScreenshotTaken:(id)arg1 { VOID_HANDLESCREENSHOT(%orig); }
- (void)screenshotObserverDidSeeActiveScreenCapture:(id)arg1 event:(NSInteger)arg2 { VOID_HANDLESCREENSHOT(%orig); }
%end

%hook IGDirectVisualMessageViewerController
- (void)screenshotObserverDidSeeScreenshotTaken:(id)arg1 { VOID_HANDLESCREENSHOT(%orig); }
- (void)screenshotObserverDidSeeActiveScreenCapture:(id)arg1 event:(NSInteger)arg2 { VOID_HANDLESCREENSHOT(%orig); }
%end

/////////////////////////////////////////////////////////////////////////////

// Hide items

// Direct suggested chats (in search bar)
%hook IGDirectInboxSearchListAdapterDataSource
- (id)objectsForListAdapter:(id)arg1 {
    NSArray *originalObjs = %orig();
    NSMutableArray *filteredObjs = [NSMutableArray arrayWithCapacity:[originalObjs count]];

    for (id obj in originalObjs) {
        BOOL shouldHide = NO;

        // Section header 
        if ([obj isKindOfClass:%c(IGLabelItemViewModel)]) {

            // Broadcast channels
            if ([[obj valueForKey:@"uniqueIdentifier"] isEqualToString:@"channels"]) {
                if ([SCIUtils getBoolPref:@"no_suggested_chats"]) {
                    NSLog(@"[PekiWare] Hiding suggested chats (header)");

                    shouldHide = YES;
                }
            }

            // Ask Meta AI
            else if ([[obj valueForKey:@"labelTitle"] isEqualToString:@"Ask Meta AI"]) {
                if ([SCIUtils getBoolPref:@"hide_meta_ai"]) {
                    NSLog(@"[PekiWare] Hiding meta ai suggested chats (header)");

                    shouldHide = YES;
                }
            }

            // AI
            else if ([[obj valueForKey:@"labelTitle"] isEqualToString:@"AI"]) {
                if ([SCIUtils getBoolPref:@"hide_meta_ai"]) {
                    NSLog(@"[PekiWare] Hiding ai suggested chats (header)");

                    shouldHide = YES;
                }
            }
            
        }

        // AI agents section
        else if (
            [obj isKindOfClass:%c(IGDirectInboxSearchAIAgentsPillsSectionViewModel)]
         || [obj isKindOfClass:%c(IGDirectInboxSearchAIAgentsSuggestedPromptViewModel)]
         || [obj isKindOfClass:%c(IGDirectInboxSearchAIAgentsSuggestedPromptLoggingViewModel)]
        ) {

            if ([SCIUtils getBoolPref:@"hide_meta_ai"]) {
                    NSLog(@"[PekiWare] Hiding suggested chats (ai agents)");

                shouldHide = YES;
            }

        }

        // Recipients list
        else if ([obj isKindOfClass:%c(IGDirectRecipientCellViewModel)]) {

            // Broadcast channels
            if ([[obj recipient] isBroadcastChannel]) {
                if ([SCIUtils getBoolPref:@"no_suggested_chats"]) {
                    NSLog(@"[PekiWare] Hiding suggested chats (broadcast channels recipient)");

                    shouldHide = YES;
                }
            }
            
            // Meta AI (special section types)
            else if (([obj sectionType] == 20) || [obj sectionType] == 18) {
                if ([SCIUtils getBoolPref:@"hide_meta_ai"]) {
                    NSLog(@"[PekiWare] Hiding meta ai suggested chats (meta ai recipient)");

                    shouldHide = YES;
                }
            }

            // Meta AI (catch-all)
            else if ([[[obj recipient] threadName] isEqualToString:@"Meta AI"]) {
                if ([SCIUtils getBoolPref:@"hide_meta_ai"]) {
                    NSLog(@"[PekiWare] Hiding meta ai suggested chats (meta ai recipient)");

                    shouldHide = YES;
                }
            }
        }

        // Populate new objs array
        if (!shouldHide) {
            [filteredObjs addObject:obj];
        }

    }

    return [filteredObjs copy];
}
%end

// Direct suggested chats (thread creation view)
%hook IGDirectThreadCreationViewController
- (id)objectsForListAdapter:(id)arg1 {
    NSArray *originalObjs = %orig();
    NSMutableArray *filteredObjs = [NSMutableArray arrayWithCapacity:[originalObjs count]];

    for (id obj in originalObjs) {
        BOOL shouldHide = NO;

        // Meta AI suggested user in direct new message view
        if ([SCIUtils getBoolPref:@"hide_meta_ai"]) {
            
            if ([obj isKindOfClass:%c(IGDirectCreateChatCellViewModel)]) {

                // "AI Chats"
                if ([[obj valueForKey:@"title"] isEqualToString:@"AI chats"]) {
                    NSLog(@"[PekiWare] Hiding meta ai: direct thread creation ai chats section");

                    shouldHide = YES;
                }

            }

            else if ([obj isKindOfClass:%c(IGDirectRecipientCellViewModel)]) {

                // Meta AI suggested user
                if ([[[obj recipient] threadName] isEqualToString:@"Meta AI"]) {
                    NSLog(@"[PekiWare] Hiding meta ai: direct thread creation ai suggestion");

                    shouldHide = YES;
                }

            }
            
        }

        // Invite friends to insta contacts upsell
        if ([SCIUtils getBoolPref:@"no_suggested_users"]) {
            if ([obj isKindOfClass:%c(IGContactInvitesSearchUpsellViewModel)]) {
                NSLog(@"[PekiWare] Hiding suggested users: invite contacts upsell");

                shouldHide = YES;
            }
        }

        // Populate new objs array
        if (!shouldHide) {
            [filteredObjs addObject:obj];
        }
    }

    return [filteredObjs copy];
}
%end

// Direct suggested chats (inbox view)
%hook IGDirectInboxListAdapterDataSource
- (id)objectsForListAdapter:(id)arg1 {
    NSArray *originalObjs = %orig();
    NSMutableArray *filteredObjs = [NSMutableArray arrayWithCapacity:[originalObjs count]];

    for (id obj in originalObjs) {
        BOOL shouldHide = NO;

        // Section header
        if ([obj isKindOfClass:%c(IGDirectInboxHeaderCellViewModel)]) {
            
            // "Suggestions" header
            if ([[obj title] isEqualToString:@"Suggestions"]) {
                if ([SCIUtils getBoolPref:@"hide_meta_ai"]) {
                    NSLog(@"[PekiWare] Hiding suggested chats (header: messages tab)");

                    shouldHide = YES;
                }
            }

            // "Accounts to follow/message" header
            else if ([[obj title] hasPrefix:@"Accounts to"]) {
                if ([SCIUtils getBoolPref:@"no_suggested_users"]) {
                    NSLog(@"[PekiWare] Hiding suggested users: (header: inbox view)");

                    shouldHide = YES;
                }
            }

        }

        // Suggested recipients
        else if ([obj isKindOfClass:%c(IGDirectInboxSuggestedThreadCellViewModel)]) {
            if ([SCIUtils getBoolPref:@"hide_meta_ai"]) {
                NSLog(@"[PekiWare] Hiding suggested chats (recipients: channels tab)");

                shouldHide = YES;
            }
        }

        // "Accounts to follow" recipients
        else if ([obj isKindOfClass:%c(IGDiscoverPeopleItemConfiguration)] || [obj isKindOfClass:%c(IGDiscoverPeopleConnectionItemConfiguration)]) {
            if ([SCIUtils getBoolPref:@"no_suggested_users"]) {
                NSLog(@"[PekiWare] Hiding suggested chats: (recipients: inbox view)");

                shouldHide = YES;
            }
        }

        // Populate new objs array
        if (!shouldHide) {
            [filteredObjs addObject:obj];
        }

    }

    return [filteredObjs copy];
}
%end

// Explore page results
%hook IGSearchListKitDataSource
- (id)objectsForListAdapter:(id)arg1 {
    NSArray *originalObjs = %orig();
    NSMutableArray *filteredObjs = [NSMutableArray arrayWithCapacity:[originalObjs count]];

    for (id obj in originalObjs) {
        BOOL shouldHide = NO;

        // Meta AI
        if ([SCIUtils getBoolPref:@"hide_meta_ai"]) {

            // Section header 
            if ([obj isKindOfClass:%c(IGLabelItemViewModel)]) {

                // "Ask Meta AI" search results header
                if ([[obj valueForKey:@"labelTitle"] isEqualToString:@"Ask Meta AI"]) {
                    shouldHide = YES;
                }

            }

            // Empty search bar upsell view
            else if ([obj isKindOfClass:%c(IGSearchNullStateUpsellViewModel)]) {
                shouldHide = YES;
            }

            // Meta AI search suggestions
            else if ([obj isKindOfClass:%c(IGSearchResultNestedGroupViewModel)]) {
                shouldHide = YES;
            }

            // Meta AI suggested search results
            else if ([obj isKindOfClass:%c(IGSearchResultViewModel)]) {

                // itemType 6 is meta ai suggestions
                if ([obj itemType] == 6) {
                    if ([SCIUtils getBoolPref:@"hide_meta_ai"]) {
                        shouldHide = YES;
                    }
                    
                }

                // Meta AI user account in search results
                else if ([[[obj title] string] isEqualToString:@"meta.ai"]) {
                    if ([SCIUtils getBoolPref:@"hide_meta_ai"]) {
                        shouldHide = YES;
                    }
                }

            }
            
        }

        // No suggested users
        if ([SCIUtils getBoolPref:@"no_suggested_users"]) {

            // Section header 
            if ([obj isKindOfClass:%c(IGLabelItemViewModel)]) {

                // "Suggested for you" search results header
                if ([[obj valueForKey:@"labelTitle"] isEqualToString:@"Suggested for you"]) {
                    shouldHide = YES;
                }

            }

            // Instagram users
            else if ([obj isKindOfClass:%c(IGDiscoverPeopleItemConfiguration)]) {
                shouldHide = YES;
            }

            // See all suggested users
            else if ([obj isKindOfClass:%c(IGSeeAllItemConfiguration)] && ((IGSeeAllItemConfiguration *)obj).destination == 4) {
                shouldHide = YES;
            }

        }

        // Populate new objs array
        if (!shouldHide) {
            [filteredObjs addObject:obj];
        }

    }

    return [filteredObjs copy];
}
%end

// Story tray
%hook IGMainStoryTrayDataSource
- (id)allItemsForTrayUsingCachedValue:(BOOL)cached {
    NSArray *originalObjs = %orig(cached);
    NSMutableArray *filteredObjs = [NSMutableArray arrayWithCapacity:[originalObjs count]];

    for (IGStoryTrayViewModel *obj in originalObjs) {
        BOOL shouldHide = NO;

        if ([SCIUtils getBoolPref:@"no_suggested_users"]) {
            // This hides as many recommended models as possible, without hiding genuine models
            // Most recommended models share a 32 digit id, unlike normal accounts
            if ([obj isKindOfClass:%c(IGStoryTrayViewModel)] && [obj.pk length] == 32) {
                NSLog(@"[PekiWare] Hiding suggested users: story tray");

                shouldHide = YES;
            }
        }

        if ([SCIUtils getBoolPref:@"hide_ads"]) {
            // "New!" account id is 3538572169
            if ([obj isKindOfClass:%c(IGStoryTrayViewModel)] && (obj.isUnseenNux == YES || [obj.pk isEqualToString:@"3538572169"])) {
                NSLog(@"[PekiWare] Removing ads: story tray");

                shouldHide = YES;
            }
        }

        // Populate new objs array
        if (!shouldHide) {
            [filteredObjs addObject:obj];
        }
    }

    return [filteredObjs copy];
}
%end

/////////////////////////////////////////////////////////////////////////////

// Confirm buttons

/*
* Long press alerts can be triggered continuously by holding down on the button
*
* Instead, you call the "_didTap" method from the "_didLongPress" method
* Then, in the "_didTap" method, you make sure the confirm alert is only shown once
*/

static BOOL showingFeedItemUFIConfirm = NO;
static BOOL showingVerticalUFIConfirm = NO;

%hook IGFeedItemUFICell
- (void)UFIButtonBarDidTapOnLike:(id)arg1 {
    if ([SCIUtils getBoolPref:@"like_confirm"]) {
        NSLog(@"[PekiWare] Confirm post like triggered");

        [SCIUtils showConfirmation:^(void) { %orig; }];
    }
    else {
        return %orig;
    }  
}

- (void)UFIButtonBarDidTapOnRepost:(id)arg1 {
    if (showingFeedItemUFIConfirm) return;

    if ([SCIUtils getBoolPref:@"repost_confirm"]) {
        NSLog(@"[PekiWare] Confirm repost triggered");

        showingFeedItemUFIConfirm = YES;

        [SCIUtils showConfirmation:^(void) { %orig; showingFeedItemUFIConfirm = NO; }
                     cancelHandler:^(void) { showingFeedItemUFIConfirm = NO; }];
    }
    else {
        return %orig;
    }
}

- (void)UFIButtonBarDidLongPressOnRepost:(id)arg1 {
    if ([SCIUtils getBoolPref:@"repost_confirm"]) {
        NSLog(@"[PekiWare] Confirm repost triggered (long press hack)");

        [self UFIButtonBarDidTapOnRepost:nil];
    }
    else {
        return %orig;
    }
}
- (void)UFIButtonBarDidLongPressOnRepost:(id)arg1 withGestureRecognizer:(id)arg2 {
    if ([SCIUtils getBoolPref:@"repost_confirm"]) {
        NSLog(@"[PekiWare] Confirm repost triggered (long press hack)");

        [self UFIButtonBarDidTapOnRepost:nil];
    }
    else {
        return %orig;
    }
}
%end

%hook IGSundialViewerVerticalUFI
- (void)_didTapLikeButton:(id)arg1 {
    if (showingVerticalUFIConfirm) return;

    if ([SCIUtils getBoolPref:@"like_confirm_reels"]) {
        NSLog(@"[PekiWare] Confirm reels like triggered");

        showingVerticalUFIConfirm = YES;

        [SCIUtils showConfirmation:^(void) { %orig; showingVerticalUFIConfirm = NO; }
                     cancelHandler:^(void) { showingVerticalUFIConfirm = NO; }];
    }
    else {
        return %orig;
    }
}

- (void)_didLongPressLikeButton:(id)arg1 {
    if ([SCIUtils getBoolPref:@"like_confirm_reels"]) {
        NSLog(@"[PekiWare] Confirm reels like triggered (long press hack)");

        [self _didTapLikeButton:nil];
    }
    else {
        return %orig;
    }
}

- (void)_didTapRepostButton:(id)arg1 {
    if (showingVerticalUFIConfirm) return;

    if ([SCIUtils getBoolPref:@"repost_confirm"]) {
        NSLog(@"[PekiWare] Confirm repost triggered");

        showingVerticalUFIConfirm = YES;

        [SCIUtils showConfirmation:^(void) { %orig; showingVerticalUFIConfirm = NO; }
                     cancelHandler:^(void) { showingVerticalUFIConfirm = NO; }];
    }
    else {
        return %orig;
    }
}

- (void)_didLongPressRepostButton:(id)arg1 {
    if ([SCIUtils getBoolPref:@"repost_confirm"]) {
        NSLog(@"[PekiWare] Confirm repost triggered (long press hack)");

        [self _didTapRepostButton:nil];
    }
    else {
        return %orig;
    }
}
%end

/////////////////////////////////////////////////////////////////////////////

// FLEX explorer gesture handler
%hook IGRootViewController
- (void)viewDidLoad {
    %orig;
    
    // Recognize 5-finger long press
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = 1;
    longPress.numberOfTouchesRequired = 5;
    [self.view addGestureRecognizer:longPress];
}
%new - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) return;

    if ([SCIUtils getBoolPref:@"flex_instagram"]) {
        [[objc_getClass("FLEXManager") sharedManager] showExplorer];
    }
}
%end

// Disable safe mode (defaults reset upon subsequent crashes)
%hook IGSafeModeChecker
- (id)initWithInstacrashCounterProvider:(void *)provider crashThreshold:(unsigned long long)threshold {
    if ([SCIUtils getBoolPref:@"disable_safe_mode"]) return nil;

    return %orig(provider, threshold);
}
- (unsigned long long)crashCount {
    if ([SCIUtils getBoolPref:@"disable_safe_mode"]) {
        return 0;
    }

    return %orig;
}
%end

/////////////////////////////////////////////////////////////////////////////

// Local-only blue verification badge on own profile
%hook IGProfileViewController

- (void)viewDidLoad {
    %orig;
    
    NSLog(@"[PekiWare] IGProfileViewController viewDidLoad called");
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;

    [self sci_addPekiLocalVerificationBadgeIfNeeded];
    [self sci_updateCustomFollowerCountIfNeeded];
}

- (void)viewDidLayoutSubviews {
    %orig;
    
    // Re-apply verification badge and follower count on layout changes
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self sci_addPekiLocalVerificationBadgeIfNeeded];
        [self sci_updateCustomFollowerCountIfNeeded];
    });
}

%new - (BOOL)sci_isViewingOwnProfile {
    id user = nil;

    @try {
        if ([self respondsToSelector:@selector(user)]) {
            user = [self performSelector:@selector(user)];
        } else {
            user = [self valueForKey:@"user"];
        }
    } @catch (NSException *exception) {
        user = nil;
    }

    if (!user) return NO;

    BOOL isSelf = NO;

    if ([user respondsToSelector:@selector(isCurrentUser)]) {
        BOOL (*func)(id, SEL) = (BOOL (*)(id, SEL))objc_msgSend;
        isSelf = func(user, @selector(isCurrentUser));
    } else if ([user respondsToSelector:@selector(isLoggedInUser)]) {
        BOOL (*func)(id, SEL) = (BOOL (*)(id, SEL))objc_msgSend;
        isSelf = func(user, @selector(isLoggedInUser));
    } else if ([user respondsToSelector:@selector(isSelf)]) {
        BOOL (*func)(id, SEL) = (BOOL (*)(id, SEL))objc_msgSend;
        isSelf = func(user, @selector(isSelf));
    }

    return isSelf;
}

%new - (void)sci_addPekiLocalVerificationBadgeIfNeeded {
    NSLog(@"[PekiWare] sci_addPekiLocalVerificationBadgeIfNeeded called");
    
    BOOL isOwnProfile = [self sci_isViewingOwnProfile];
    NSLog(@"[PekiWare] Is viewing own profile: %@", isOwnProfile ? @"YES" : @"NO");
    
    if (!isOwnProfile) {
        NSLog(@"[PekiWare] Not viewing own profile, skipping verification badge");
        return;
    }

    BOOL verificationEnabled = [SCIUtils getBoolPref:@"peki_local_verification"];
    NSLog(@"[PekiWare] Local verification enabled: %@", verificationEnabled ? @"YES" : @"NO");
    
    if (!verificationEnabled) {
        NSLog(@"[PekiWare] Local verification disabled, skipping badge");
        return;
    }

    NSLog(@"[PekiWare] Adding verification badge...");

    // Avoid recreating if already set
    if ([self.navigationItem.titleView isKindOfClass:[UIView class]] &&
        [self.navigationItem.titleView viewWithTag:987321] != nil) {
        return;
    }

    // Prefer actual username from IGUser, fall back to controller title
    NSString *titleText = nil;
    @try {
        id user = nil;
        if ([self respondsToSelector:@selector(user)]) {
            user = [self performSelector:@selector(user)];
        } else {
            user = [self valueForKey:@"user"];
        }

        if (user && [user respondsToSelector:@selector(username)]) {
            titleText = [user valueForKey:@"username"];
        }
    } @catch (NSException *exception) {
        // Ignore and fall back to self.title
    }

    if (titleText.length == 0) {
        titleText = self.title ?: @"";
    }

    UILabel *titleLabel = [UILabel new];
    titleLabel.text = titleText;
    titleLabel.textColor = [UIColor labelColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:17.0];
    [titleLabel sizeToFit];

    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:14.0
                                                                                          weight:UIImageSymbolWeightSemibold];
    UIImage *badgeImage = [UIImage systemImageNamed:@"checkmark.seal.fill" withConfiguration:config];

    UIImageView *badgeView = [[UIImageView alloc] initWithImage:badgeImage];
    badgeView.tintColor = [UIColor systemBlueColor];
    badgeView.tag = 987321;
    [badgeView sizeToFit];

    CGFloat spacing = 4.0;
    CGFloat width = titleLabel.bounds.size.width + spacing + badgeView.bounds.size.width;
    CGFloat height = MAX(titleLabel.bounds.size.height, badgeView.bounds.size.height);

    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];

    CGRect titleFrame = titleLabel.frame;
    titleFrame.origin.x = 0.0;
    titleFrame.origin.y = (height - titleFrame.size.height) / 2.0;
    titleLabel.frame = titleFrame;

    CGRect badgeFrame = badgeView.frame;
    badgeFrame.origin.x = CGRectGetMaxX(titleFrame) + spacing;
    badgeFrame.origin.y = (height - badgeFrame.size.height) / 2.0;
    badgeView.frame = badgeFrame;

    [container addSubview:titleLabel];
    [container addSubview:badgeView];

    self.navigationItem.titleView = container;
}

%new - (void)sci_updateCustomFollowerCountIfNeeded {
    NSLog(@"[PekiWare] sci_updateCustomFollowerCountIfNeeded called");
    
    BOOL isOwnProfile = [self sci_isViewingOwnProfile];
    NSLog(@"[PekiWare] Is viewing own profile: %@", isOwnProfile ? @"YES" : @"NO");
    
    if (!isOwnProfile) {
        NSLog(@"[PekiWare] Not viewing own profile, skipping follower count");
        return;
    }

    BOOL followersEnabled = [SCIUtils getBoolPref:@"peki_enable_custom_followers"];
    NSLog(@"[PekiWare] Custom follower count enabled: %@", followersEnabled ? @"YES" : @"NO");
    
    if (!followersEnabled) {
        NSLog(@"[PekiWare] Custom follower count disabled");
        return;
    }

    NSInteger customCount = [SCIUtils getIntegerPref:@"peki_custom_follower_count"];
    NSLog(@"[PekiWare] Custom follower count: %ld", (long)customCount);
    
    if (customCount <= 0) {
        NSLog(@"[PekiWare] Custom follower count is 0 or less, skipping");
        return;
    }

    // Find follower count labels by traversing the view hierarchy
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"[PekiWare] Searching for follower labels...");
        [self findAndUpdateFollowerLabels:customCount];
    });
}

%new - (void)findAndUpdateFollowerLabels:(NSInteger)count {
    // Try to find follower count labels in the profile view
    UIView *profileView = self.view;
    
    // Look for common label patterns that might contain follower count
    for (UIView *subview in profileView.subviews) {
        [self searchAndUpdateLabelsInView:subview targetCount:count];
    }
}

%new - (void)searchAndUpdateLabelsInView:(UIView *)view targetCount:(NSInteger)count {
    // Recursively search for UILabels that might contain follower counts
    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        NSString *text = label.text;
        
        // Look for patterns like "123 followers", "123K followers", etc.
        if ([text containsString:@"followers"] || [text containsString:@"follower"]) {
            NSString *formattedCount = [self formatFollowerCount:count];
            label.text = [NSString stringWithFormat:@"%@ followers", formattedCount];
        }
    }
    
    // Search subviews recursively
    for (UIView *subview in view.subviews) {
        [self searchAndUpdateLabelsInView:subview targetCount:count];
    }
}

%new - (NSString *)formatFollowerCount:(NSInteger)count {
    if (count >= 1000000) {
        return [NSString stringWithFormat:@"%.1fM", count / 1000000.0];
    } else if (count >= 1000) {
        return [NSString stringWithFormat:@"%.1fK", count / 1000.0];
    } else {
        return [NSString stringWithFormat:@"%ld", (long)count];
    }
}

%end

// Hook for navigation bar to ensure verification badge persists
%hook UINavigationBar
- (void)layoutSubviews {
    %orig;
    
    // Check if this is a profile navigation bar
    UIViewController *topViewController = self.topItem;
    if (topViewController && [topViewController isKindOfClass:%c(IGProfileViewController)]) {
        // Re-apply verification badge after navigation layout
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [(IGProfileViewController *)topViewController sci_addPekiLocalVerificationBadgeIfNeeded];
        });
    }
}
%end
