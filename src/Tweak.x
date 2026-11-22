#import <substrate.h>
#import "InstagramHeaders.h"
#import "Tweak.h"
#import "Utils.h"
#import "Settings/SCISettingsViewController.h"
#import "License/SCILicenseManager.h"

///////////////////////////////////////////////////////////

// Screenshot handlers
// NOTE: Do not pass %orig as macro argument - Logos expansion contains commas
// which breaks single-arg function-like macros on newer Theos/clang.

///////////////////////////////////////////////////////////

// * Tweak version *
NSString *SCIVersionString = @"v1.0.0";

// Variables that work across features
BOOL seenButtonEnabled = false;
BOOL dmVisualMsgsViewedButtonEnabled = false;

// Tweak first-time setup
%hook IGInstagramAppDelegate
- (_Bool)application:(UIApplication *)application willFinishLaunchingWithOptions:(id)arg2 {
    [SCIUtils registerGuestDefaults];
    
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
        if (!SCILicenseManager.sharedManager.authorized) return;
        if (
            ![[[NSUserDefaults standardUserDefaults] objectForKey:@"SCInstaFirstRun"] isEqualToString:SCIVersionString]
            || [SCIUtils getBoolPref:@"tweak_settings_app_launch"]
        ) {
            NSLog(@"[Peki Scripter] First run, initializing");

            // Display settings modal on screen
            NSLog(@"[Peki Scripter] Displaying Peki Scripter first-time settings modal");
            UIViewController *rootController = [[(id)self window] rootViewController];
            SCISettingsViewController *settingsViewController = [SCISettingsViewController new];
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];

            [rootController presentViewController:navigationController animated:YES completion:nil];
        }
    });

    NSLog(@"[Peki Scripter] Cleaning cache...");
    [SCIUtils cleanCache];

    if (SCILicenseManager.sharedManager.authorized && [SCIUtils getBoolPref:@"flex_app_launch"]) {
        [[objc_getClass("FLEXManager") sharedManager] showExplorer];
    }

    return true;
}

- (void)applicationDidBecomeActive:(id)arg1 {
    %orig;
    
    if (SCILicenseManager.sharedManager.authorized && [SCIUtils getBoolPref:@"flex_app_start"]) {
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
- (void)setShouldBlockScreenshot:(BOOL)arg1 viewModel:(id)arg2 {
    if ([SCIUtils getBoolPref:@"remove_screenshot_alert"]) return;
    %orig;
}
%end

// Disable screenshot logging/detection
%hook IGDirectVisualMessageViewerSession
- (id)visualMessageViewerController:(id)arg1 didDetectScreenshotForVisualMessage:(id)arg2 atIndex:(NSInteger)arg3 {
    if ([SCIUtils getBoolPref:@"remove_screenshot_alert"]) return nil;
    return %orig;
}
%end

%hook IGDirectVisualMessageReplayService
- (id)visualMessageViewerController:(id)arg1 didDetectScreenshotForVisualMessage:(id)arg2 atIndex:(NSInteger)arg3 {
    if ([SCIUtils getBoolPref:@"remove_screenshot_alert"]) return nil;
    return %orig;
}
%end

%hook IGDirectVisualMessageReportService
- (id)visualMessageViewerController:(id)arg1 didDetectScreenshotForVisualMessage:(id)arg2 atIndex:(NSInteger)arg3 {
    if ([SCIUtils getBoolPref:@"remove_screenshot_alert"]) return nil;
    return %orig;
}
%end

%hook IGDirectVisualMessageScreenshotSafetyLogger
- (id)initWithUserSession:(id)arg1 entryPoint:(NSInteger)arg2 {
    if ([SCIUtils getBoolPref:@"remove_screenshot_alert"]) {
        NSLog(@"[Peki Scripter] Disable visual message screenshot safety logger");
        return nil;
    }

    return %orig;
}
%end

%hook IGScreenshotObserver
- (id)initForController:(id)arg1 {
    if ([SCIUtils getBoolPref:@"remove_screenshot_alert"]) return nil;
    return %orig;
}
%end

%hook IGScreenshotObserverDelegate
- (void)screenshotObserverDidSeeScreenshotTaken:(id)arg1 {
    if ([SCIUtils getBoolPref:@"remove_screenshot_alert"]) return;
    %orig;
}
- (void)screenshotObserverDidSeeActiveScreenCapture:(id)arg1 event:(NSInteger)arg2 {
    if ([SCIUtils getBoolPref:@"remove_screenshot_alert"]) return;
    %orig;
}
%end

%hook IGDirectMediaViewerViewController
- (void)screenshotObserverDidSeeScreenshotTaken:(id)arg1 {
    if ([SCIUtils getBoolPref:@"remove_screenshot_alert"]) return;
    %orig;
}
- (void)screenshotObserverDidSeeActiveScreenCapture:(id)arg1 event:(NSInteger)arg2 {
    if ([SCIUtils getBoolPref:@"remove_screenshot_alert"]) return;
    %orig;
}
%end

%hook IGStoryViewerViewController
- (void)screenshotObserverDidSeeScreenshotTaken:(id)arg1 {
    if ([SCIUtils getBoolPref:@"remove_screenshot_alert"]) return;
    %orig;
}
- (void)screenshotObserverDidSeeActiveScreenCapture:(id)arg1 event:(NSInteger)arg2 {
    if ([SCIUtils getBoolPref:@"remove_screenshot_alert"]) return;
    %orig;
}
%end

%hook IGSundialFeedViewController
- (void)screenshotObserverDidSeeScreenshotTaken:(id)arg1 {
    if ([SCIUtils getBoolPref:@"remove_screenshot_alert"]) return;
    %orig;
}
- (void)screenshotObserverDidSeeActiveScreenCapture:(id)arg1 event:(NSInteger)arg2 {
    if ([SCIUtils getBoolPref:@"remove_screenshot_alert"]) return;
    %orig;
}
%end

%hook IGDirectVisualMessageViewerController
- (void)screenshotObserverDidSeeScreenshotTaken:(id)arg1 {
    if ([SCIUtils getBoolPref:@"remove_screenshot_alert"]) return;
    %orig;
}
- (void)screenshotObserverDidSeeActiveScreenCapture:(id)arg1 event:(NSInteger)arg2 {
    if ([SCIUtils getBoolPref:@"remove_screenshot_alert"]) return;
    %orig;
}
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
                    NSLog(@"[Peki Scripter] Hiding suggested chats (header)");

                    shouldHide = YES;
                }
            }

            // Ask Meta AI
            else if ([[obj valueForKey:@"labelTitle"] isEqualToString:@"Ask Meta AI"]) {
                if ([SCIUtils getBoolPref:@"hide_meta_ai"]) {
                    NSLog(@"[Peki Scripter] Hiding meta ai suggested chats (header)");

                    shouldHide = YES;
                }
            }

            // AI
            else if ([[obj valueForKey:@"labelTitle"] isEqualToString:@"AI"]) {
                if ([SCIUtils getBoolPref:@"hide_meta_ai"]) {
                    NSLog(@"[Peki Scripter] Hiding ai suggested chats (header)");

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
                    NSLog(@"[Peki Scripter] Hiding suggested chats (ai agents)");

                shouldHide = YES;
            }

        }

        // Recipients list
        else if ([obj isKindOfClass:%c(IGDirectRecipientCellViewModel)]) {

            // Broadcast channels
            if ([[obj recipient] isBroadcastChannel]) {
                if ([SCIUtils getBoolPref:@"no_suggested_chats"]) {
                    NSLog(@"[Peki Scripter] Hiding suggested chats (broadcast channels recipient)");

                    shouldHide = YES;
                }
            }
            
            // Meta AI (special section types)
            else if (([obj sectionType] == 20) || [obj sectionType] == 18) {
                if ([SCIUtils getBoolPref:@"hide_meta_ai"]) {
                    NSLog(@"[Peki Scripter] Hiding meta ai suggested chats (meta ai recipient)");

                    shouldHide = YES;
                }
            }

            // Meta AI (catch-all)
            else if ([[[obj recipient] threadName] isEqualToString:@"Meta AI"]) {
                if ([SCIUtils getBoolPref:@"hide_meta_ai"]) {
                    NSLog(@"[Peki Scripter] Hiding meta ai suggested chats (meta ai recipient)");

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
                    NSLog(@"[Peki Scripter] Hiding meta ai: direct thread creation ai chats section");

                    shouldHide = YES;
                }

            }

            else if ([obj isKindOfClass:%c(IGDirectRecipientCellViewModel)]) {

                // Meta AI suggested user
                if ([[[obj recipient] threadName] isEqualToString:@"Meta AI"]) {
                    NSLog(@"[Peki Scripter] Hiding meta ai: direct thread creation ai suggestion");

                    shouldHide = YES;
                }

            }
            
        }

        // Invite friends to insta contacts upsell
        if ([SCIUtils getBoolPref:@"no_suggested_users"]) {
            if ([obj isKindOfClass:%c(IGContactInvitesSearchUpsellViewModel)]) {
                NSLog(@"[Peki Scripter] Hiding suggested users: invite contacts upsell");

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
                    NSLog(@"[Peki Scripter] Hiding suggested chats (header: messages tab)");

                    shouldHide = YES;
                }
            }

            // "Accounts to follow/message" header
            else if ([[obj title] hasPrefix:@"Accounts to"]) {
                if ([SCIUtils getBoolPref:@"no_suggested_users"]) {
                    NSLog(@"[Peki Scripter] Hiding suggested users: (header: inbox view)");

                    shouldHide = YES;
                }
            }

        }

        // Suggested recipients
        else if ([obj isKindOfClass:%c(IGDirectInboxSuggestedThreadCellViewModel)]) {
            if ([SCIUtils getBoolPref:@"hide_meta_ai"]) {
                NSLog(@"[Peki Scripter] Hiding suggested chats (recipients: channels tab)");

                shouldHide = YES;
            }
        }

        // "Accounts to follow" recipients
        else if ([obj isKindOfClass:%c(IGDiscoverPeopleItemConfiguration)] || [obj isKindOfClass:%c(IGDiscoverPeopleConnectionItemConfiguration)]) {
            if ([SCIUtils getBoolPref:@"no_suggested_users"]) {
                NSLog(@"[Peki Scripter] Hiding suggested chats: (recipients: inbox view)");

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
                NSLog(@"[Peki Scripter] Hiding suggested users: story tray");

                shouldHide = YES;
            }
        }

        if ([SCIUtils getBoolPref:@"hide_ads"]) {
            // "New!" account id is 3538572169
            if ([obj isKindOfClass:%c(IGStoryTrayViewModel)] && (obj.isUnseenNux == YES || [obj.pk isEqualToString:@"3538572169"])) {
                NSLog(@"[Peki Scripter] Removing ads: story tray");

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

@interface IGFeedItemUFICell (SCInstaConfirm)
- (void)UFIButtonBarDidTapOnLike:(id)arg1;
@end

%hook IGFeedItemUFICell
- (void)UFIButtonBarDidTapOnLike:(id)arg1 {
    static BOOL confirmingLike = NO;
    if ([SCIUtils getBoolPref:@"like_confirm"] && !confirmingLike) {
        NSLog(@"[Peki Scripter] Confirm post like triggered");

        confirmingLike = YES;
        [SCIUtils showConfirmation:^{
            confirmingLike = NO;
            [(id)self UFIButtonBarDidTapOnLike:arg1];
        } cancelHandler:^{
            confirmingLike = NO;
        }];
        return;
    }
    return %orig;
}

- (void)UFIButtonBarDidTapOnRepost:(id)arg1 {
    if (showingFeedItemUFIConfirm) return;

    if ([SCIUtils getBoolPref:@"repost_confirm"]) {
        NSLog(@"[Peki Scripter] Confirm repost triggered");

        showingFeedItemUFIConfirm = YES;

        [SCIUtils showConfirmation:^{
            showingFeedItemUFIConfirm = NO;
            [(id)self UFIButtonBarDidTapOnRepost:arg1];
        } cancelHandler:^(void) { showingFeedItemUFIConfirm = NO; }];
        return;
    }
    else {
        return %orig;
    }
}

- (void)UFIButtonBarDidLongPressOnRepost:(id)arg1 {
    if ([SCIUtils getBoolPref:@"repost_confirm"]) {
        NSLog(@"[Peki Scripter] Confirm repost triggered (long press hack)");

        [(id)self UFIButtonBarDidTapOnRepost:nil];
    }
    else {
        return %orig;
    }
}
- (void)UFIButtonBarDidLongPressOnRepost:(id)arg1 withGestureRecognizer:(id)arg2 {
    if ([SCIUtils getBoolPref:@"repost_confirm"]) {
        NSLog(@"[Peki Scripter] Confirm repost triggered (long press hack)");

        [(id)self UFIButtonBarDidTapOnRepost:nil];
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
        NSLog(@"[Peki Scripter] Confirm reels like triggered");

        showingVerticalUFIConfirm = YES;

        [SCIUtils showConfirmation:^{
            showingVerticalUFIConfirm = NO;
            [(id)self _didTapLikeButton:arg1];
        } cancelHandler:^(void) { showingVerticalUFIConfirm = NO; }];
        return;
    }
    else {
        return %orig;
    }
}

- (void)_didLongPressLikeButton:(id)arg1 {
    if ([SCIUtils getBoolPref:@"like_confirm_reels"]) {
        NSLog(@"[Peki Scripter] Confirm reels like triggered (long press hack)");

        [(id)self _didTapLikeButton:nil];
    }
    else {
        return %orig;
    }
}

- (void)_didTapRepostButton:(id)arg1 {
    if (showingVerticalUFIConfirm) return;

    if ([SCIUtils getBoolPref:@"repost_confirm"]) {
        NSLog(@"[Peki Scripter] Confirm repost triggered");

        showingVerticalUFIConfirm = YES;

        [SCIUtils showConfirmation:^{
            showingVerticalUFIConfirm = NO;
            [(id)self _didTapRepostButton:arg1];
        } cancelHandler:^(void) { showingVerticalUFIConfirm = NO; }];
        return;
    }
    else {
        return %orig;
    }
}

- (void)_didLongPressRepostButton:(id)arg1 {
    if ([SCIUtils getBoolPref:@"repost_confirm"]) {
        NSLog(@"[Peki Scripter] Confirm repost triggered (long press hack)");

        [(id)self _didTapRepostButton:nil];
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

    if (SCILicenseManager.sharedManager.authorized && [SCIUtils getBoolPref:@"flex_instagram"]) {
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
