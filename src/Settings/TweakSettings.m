#import "TweakSettings.h"
#import "SCIMessageArchiveViewController.h"
#import "SCIThemeEditorViewController.h"
#import "../License/SCILicenseViewController.h"
#import "../License/SCILicenseConfig.h"

static UIMenu *SCIChoiceMenu(NSString *key, NSArray<NSArray<NSString *> *> *choices) {
    NSMutableArray *children = [NSMutableArray new];
    for (NSArray *choice in choices) {
        [children addObject:[UICommand commandWithTitle:choice[0] image:nil
            action:NSSelectorFromString(@"menuChanged:") propertyList:@{@"defaultsKey": key, @"value": choice[1]}]];
    }
    return [UIMenu menuWithChildren:children];
}

@implementation SCITweakSettings

#pragma mark - Sections

///
/// This returns an array of sections, with each section consisting of a dictionary
///
/// `"title"`: The section title (leave blank for no title)
///
/// `"rows"`: An array of **SCISetting** classes, potentially containing a "navigationCellWithTitle" initializer to allow for nested setting pages.
///
/// `"footer`: The section footer (leave blank for no footer)

+ (NSArray *)sections {
    [SCIUtils registerGuestDefaults];
    return @[
        @{
            @"header": @"Preferences",
            @"footer": @"",
            @"rows": @[
                [SCISetting controllerCellWithTitle:@"License" subtitle:@"Access and support"
                    icon:[SCISymbol symbolWithName:@"key"]
                    factory:^UIViewController *(void) { return [SCILicenseViewController new]; }],
                [SCISetting navigationCellWithTitle:@"Appearance" subtitle:@"16 themes, custom colors and Instagram tint"
                    icon:[SCISymbol symbolWithName:@"slider.horizontal.3"]
                    navSections:@[@{
                        @"header": @"Peki Scripter V2",
                        @"footer": @"Menu themes apply immediately. Custom RGB colors are stored locally.",
                        @"rows": @[
                            [SCISetting controllerCellWithTitle:@"Themes & custom palette" subtitle:@"16 presets, color picker and HEX input"
                                icon:[SCISymbol symbolWithName:@"paintpalette"]
                                factory:^UIViewController *(void) { return [SCIThemeEditorViewController new]; }],
                            [SCISetting menuCellWithTitle:@"Accent" subtitle:@"Use the palette's accent or choose an override"
                                menu:SCIChoiceMenu(@"settings_accent", @[@[@"Theme default", @"theme"], @[@"Blue", @"blue"],
                                    @[@"Ice", @"ice"], @[@"Mint", @"mint"], @[@"Lime", @"lime"], @[@"Amber", @"amber"],
                                    @[@"Copper", @"copper"], @[@"Red", @"red"], @[@"Rose", @"rose"], @[@"Indigo", @"indigo"],
                                    @[@"Monochrome", @"white"], @[@"Custom RGB", @"custom"]])]
                        ]
                    }, @{
                        @"header": @"Instagram · experimental",
                        @"footer": @"Only Instagram-owned windows are changed; LiveContainer's launcher is excluded. Native appearance and tint-inheriting UIKit controls are supported. Instagram can override them. This does not recolor every SwiftUI view, story ring or DM bubble.",
                        @"rows": @[
                            [SCISetting menuCellWithTitle:@"Native appearance" subtitle:@"Use Instagram's existing light/dark rendering"
                                menu:SCIChoiceMenu(@"instagram_appearance", @[@[@"App default", @"system"], @[@"Dark", @"dark"], @[@"Light", @"light"]])],
                            [SCISetting switchCellWithTitle:@"Use theme accent in Instagram" subtitle:@"Tint supported native controls using your selected accent"
                                defaultsKey:@"instagram_theme_accent"]
                        ]
                    }]],
                  [SCISetting navigationCellWithTitle:@"General"
                                             subtitle:@"Ads, search, notes and tools"
                                               icon:[SCISymbol symbolWithName:@"gear"]
                                        navSections:@[@{
                                            @"header": @"",
                                            @"rows": @[
                                                [SCISetting switchCellWithTitle:@"Hide ads" subtitle:@"Removes all ads from the Instagram app" defaultsKey:@"hide_ads"],
                                                [SCISetting switchCellWithTitle:@"Hide Meta AI" subtitle:@"Hides the meta ai buttons/functionality within the app" defaultsKey:@"hide_meta_ai"],
                                                [SCISetting switchCellWithTitle:@"Copy description" subtitle:@"Copy description text fields by long-pressing on them" defaultsKey:@"copy_description"],
                                                [SCISetting switchCellWithTitle:@"Do not save recent searches" subtitle:@"Search bars will no longer save your recent searches" defaultsKey:@"no_recent_searches"],
                                                [SCISetting switchCellWithTitle:@"Use detailed color picker" subtitle:@"Long press on the eyedropper tool in stories to customize the text color more precisely" defaultsKey:@"detailed_color_picker"],
                                                [SCISetting switchCellWithTitle:@"Enable liquid glass buttons" subtitle:@"Enables experimental liquid glass buttons within the app" defaultsKey:@"liquid_glass_buttons" requiresRestart:YES],
                                                [SCISetting switchCellWithTitle:@"Enable teen app icons" subtitle:@"When enabled, hold down on the Instagram logo to change the app icon" defaultsKey:@"teen_app_icons" requiresRestart:YES]
                                            ]
                                        },
                                        @{
                                            @"header": @"Notes",
                                            @"rows": @[
                                                [SCISetting switchCellWithTitle:@"Hide notes tray" subtitle:@"Hides the notes tray in the dm inbox" defaultsKey:@"hide_notes_tray"],
                                                [SCISetting switchCellWithTitle:@"Hide friends map" subtitle:@"Hides the friends map icon in the notes tray" defaultsKey:@"hide_friends_map"],
                                                [SCISetting switchCellWithTitle:@"Enable note theming" subtitle:@"Enables the ability to use the notes theme picker" defaultsKey:@"enable_notes_customization"],
                                                [SCISetting switchCellWithTitle:@"Custom note themes" subtitle:@"Provides an option to set custom emojis and background/text colors" defaultsKey:@"custom_note_themes"],
                                            ]
                                        },
                                        @{
                                            @"header": @"Focus/distractions",
                                            @"rows": @[
                                                [SCISetting switchCellWithTitle:@"Hide explore posts grid" subtitle:@"Hides the grid of suggested posts on the explore/search tab" defaultsKey:@"hide_explore_grid"],
                                                [SCISetting switchCellWithTitle:@"Hide trending searches" subtitle:@"Hides the trending searches under the explore search bar" defaultsKey:@"hide_trending_searches"],
                                                [SCISetting switchCellWithTitle:@"No suggested chats" subtitle:@"Hides the suggested broadcast channels in direct messages" defaultsKey:@"no_suggested_chats"],
                                                [SCISetting switchCellWithTitle:@"No suggested users" subtitle:@"Hides all suggested users for you to follow, outside your feed" defaultsKey:@"no_suggested_users"]
                                            ]
                                        }]
                ],
                  [SCISetting navigationCellWithTitle:@"Feed"
                                             subtitle:@"Feed visibility and suggestions"
                                               icon:[SCISymbol symbolWithName:@"rectangle.stack"]
                                        navSections:@[@{
                                            @"header": @"",
                                            @"rows": @[
                                                [SCISetting switchCellWithTitle:@"Hide stories tray" subtitle:@"Hides the story tray at the top and within your feed" defaultsKey:@"hide_stories_tray"],
                                                [SCISetting switchCellWithTitle:@"Hide entire feed" subtitle:@"Removes all content from your home feed, including posts" defaultsKey:@"hide_entire_feed"],
                                                [SCISetting switchCellWithTitle:@"No suggested posts" subtitle:@"Removes suggested posts from your feed" defaultsKey:@"no_suggested_post"],
                                                [SCISetting switchCellWithTitle:@"No suggested for you" subtitle:@"Hides suggested accounts for you to follow" defaultsKey:@"no_suggested_account"],
                                                [SCISetting switchCellWithTitle:@"No suggested reels" subtitle:@"Hides suggested reels to watch" defaultsKey:@"no_suggested_reels"],
                                                [SCISetting switchCellWithTitle:@"No suggested threads posts" subtitle:@"Hides suggested threads posts" defaultsKey:@"no_suggested_threads"]
                                            ]
                                        }]
                ],
                  [SCISetting navigationCellWithTitle:@"Reels"
                                             subtitle:@"Playback and scrolling"
                                               icon:[SCISymbol symbolWithName:@"film.stack"]
                                        navSections:@[@{
                                            @"header": @"",
                                            @"rows": @[
                                                [SCISetting menuCellWithTitle:@"Tap Controls" subtitle:@"Change what happens when you tap on a reel" menu:[self menus][@"reels_tap_control"]],
                                                [SCISetting switchCellWithTitle:@"Always show progress scrubber" subtitle:@"Forces the progress bar to appear on every reel" defaultsKey:@"reels_show_scrubber"],
                                                [SCISetting switchCellWithTitle:@"Confirm reel refresh" subtitle:@"Shows an alert when you trigger a reels refresh" defaultsKey:@"refresh_reel_confirm"],
                                                [SCISetting switchCellWithTitle:@"Hide reels header" subtitle:@"Hides the top navigation bar when watching reels" defaultsKey:@"hide_reels_header"]
                                            ]
                                        },
                                        @{
                                            @"header": @"",
                                            @"rows": @[
                                                [SCISetting switchCellWithTitle:@"Disable scrolling reels" subtitle:@"Prevents reels from being scrolled to the next video" defaultsKey:@"disable_scrolling_reels" requiresRestart:YES]
                                            ]
                                        }]
                ],
                  [SCISetting navigationCellWithTitle:@"Saving"
                                              subtitle:@"Finger count, hold duration and output"
                                                icon:[SCISymbol symbolWithName:@"tray.and.arrow.down"]
                                         navSections:[self downloadSections]
                ],
                  [SCISetting navigationCellWithTitle:@"Stories and messages"
                                             subtitle:@"Privacy, receipts and local copies"
                                               icon:[SCISymbol symbolWithName:@"rectangle.portrait.on.rectangle.portrait.angled"]
                                        navSections:@[@{
                                             @"header": @"PRIVACY",
                                             @"footer": @"For reliable activity hiding, also turn off Activity Status in Instagram. Read/view receipts already sent cannot be undone. Reopen a chat after changing its toolbar options.",
                                             @"rows": @[
                                                 [SCISetting switchCellWithTitle:@"Block activity updates" subtitle:@"Stops supported outgoing presence updates; does not change Instagram's server settings" defaultsKey:@"ghost_mode"],
                                                 [SCISetting switchCellWithTitle:@"Hide typing indicator" subtitle:@"Others won't see when you're typing a message" defaultsKey:@"hide_typing_indicator"],
                                                 [SCISetting switchCellWithTitle:@"Hide story views" subtitle:@"Blocks supported story-view receipts; restart after changing" defaultsKey:@"no_seen_receipt" requiresRestart:YES],
                                                 [SCISetting switchCellWithTitle:@"Hide message seen" subtitle:@"Read receipts stay off unless you enable the checkmark-message button for this session" defaultsKey:@"remove_lastseen"]
                                            ]
                                        },
                                        @{
                                            @"header": @"LOCAL MESSAGE COPIES",
                                            @"footer": @"Keeps text observed after enabling, including your own unsend attempts. Copies live in this device's archive, not the original chat. Old deleted messages and attachments cannot be recovered. Turning this off stops capture; Clear removes stored copies. The archive is shared across accounts on this installation.",
                                            @"rows": @[
                                                [SCISetting switchCellWithTitle:@"Retain deleted text locally" subtitle:@"Caches visible text on this device while enabled" defaultsKey:@"keep_deleted_message"],
                                                [SCISetting controllerCellWithTitle:@"Open local archive" subtitle:@"Read, copy or erase retained text"
                                                    icon:[SCISymbol symbolWithName:@"archivebox"]
                                                    factory:^UIViewController *(void) { return [SCIMessageArchiveViewController new]; }]
                                            ]
                                        },
                                        @{
                                             @"header": @"DISAPPEARING MEDIA",
                                             @"rows": @[
                                                 [SCISetting switchCellWithTitle:@"Disable screenshot detection" subtitle:@"Removes the screenshot-prevention features for visual messages in DMs" defaultsKey:@"remove_screenshot_alert"],
                                                 [SCISetting switchCellWithTitle:@"Unlimited replay of direct stories" subtitle:@"Replays direct messages normal/once stories unlimited times (toggle with image check icon)" defaultsKey:@"unlimited_replay"],
                                                 [SCISetting switchCellWithTitle:@"Disable view-once limitations" subtitle:@"Makes view-once messages behave like normal visual messages (loopable/pauseable)" defaultsKey:@"disable_view_once_limitations"]
                                            ]
                                        }]
                ],
                  [SCISetting navigationCellWithTitle:@"Navigation"
                                             subtitle:@"Tabs, order and swipe behavior"
                                               icon:[SCISymbol symbolWithName:@"hand.draw.fill"]
                                        navSections:@[@{
                                            @"header": @"",
                                            @"rows": @[
                                                [SCISetting menuCellWithTitle:@"Icon order" subtitle:@"The order of the icons on the bottom navigation bar" menu:[self menus][@"nav_icon_ordering"]],
                                                [SCISetting menuCellWithTitle:@"Swipe between tabs" subtitle:@"Lets you swipe to switch between navigation bar tabs" menu:[self menus][@"swipe_nav_tabs"]],
                                            ]
                                        },
                                        @{
                                            @"header": @"Hiding tabs",
                                            @"rows": @[
                                                [SCISetting switchCellWithTitle:@"Hide feed tab" subtitle:@"Hides the feed/home tab on the bottom navigation bar" defaultsKey:@"hide_feed_tab" requiresRestart:YES],
                                                [SCISetting switchCellWithTitle:@"Hide explore tab" subtitle:@"Hides the explore/search tab on the bottom navigation bar" defaultsKey:@"hide_explore_tab" requiresRestart:YES],
                                                [SCISetting switchCellWithTitle:@"Hide reels tab" subtitle:@"Hides the reels tab on the bottom navigation bar" defaultsKey:@"hide_reels_tab" requiresRestart:YES],
                                                [SCISetting switchCellWithTitle:@"Hide create tab" subtitle:@"Hides the create tab on the bottom navigation bar" defaultsKey:@"hide_create_tab" requiresRestart:YES]
                                            ]
                                        }]
                ],
                  [SCISetting navigationCellWithTitle:@"Confirm actions"
                                             subtitle:@"Confirm before sending or interacting"
                                               icon:[SCISymbol symbolWithName:@"checkmark"]
                                        navSections:@[@{
                                            @"header": @"",
                                            @"rows": @[
                                                [SCISetting switchCellWithTitle:@"Confirm like: Posts/Stories" subtitle:@"Shows an alert when you click the like button on posts or stories to confirm the like" defaultsKey:@"like_confirm"],
                                                [SCISetting switchCellWithTitle:@"Confirm like: Reels" subtitle:@"Shows an alert when you click the like button on reels to confirm the like" defaultsKey:@"like_confirm_reels"]
                                            ]
                                        },
                                        @{
                                            @"header": @"",
                                            @"rows": @[
                                                [SCISetting switchCellWithTitle:@"Confirm follow" subtitle:@"Shows an alert when you click the follow button to confirm the follow" defaultsKey:@"follow_confirm"],
                                                [SCISetting switchCellWithTitle:@"Confirm repost" subtitle:@"Shows an alert when you click the repost button to confirm before resposting" defaultsKey:@"repost_confirm"],
                                                [SCISetting switchCellWithTitle:@"Confirm call" subtitle:@"Shows an alert when you click the audio/video call button to confirm before calling" defaultsKey:@"call_confirm"],
                                                [SCISetting switchCellWithTitle:@"Confirm voice messages" subtitle:@"Shows an alert to confirm before sending a voice message" defaultsKey:@"voice_message_confirm"],
                                                [SCISetting switchCellWithTitle:@"Confirm follow requests" subtitle:@"Shows an alert when you accept/decline a follow request" defaultsKey:@"follow_request_confirm"],
                                                [SCISetting switchCellWithTitle:@"Confirm shh mode" subtitle:@"Shows an alert to confirm before toggling disappearing messages" defaultsKey:@"shh_mode_confirm"],
                                                [SCISetting switchCellWithTitle:@"Confirm posting comment" subtitle:@"Shows an alert when you click the post comment button to confirm" defaultsKey:@"post_comment_confirm"],
                                                [SCISetting switchCellWithTitle:@"Confirm changing theme" subtitle:@"Shows an alert when you change a chat theme to confirm" defaultsKey:@"change_direct_theme_confirm"],
                                                [SCISetting switchCellWithTitle:@"Confirm sticker interaction" subtitle:@"Shows an alert when you click a sticker on someone's story to confirm the action" defaultsKey:@"sticker_interact_confirm"]
                                            ]
                                        }]
                ]
            ]
        },
        @{
            @"header": @"",
            @"rows": @[
                 [SCISetting navigationCellWithTitle:@"Debug"
                                            subtitle:@"Compatibility report and developer tools"
                                               icon:[SCISymbol symbolWithName:@"ladybug"]
                                        navSections:@[@{
                                            @"header": @"FLEX",
                                            @"rows": @[
                                                [SCISetting switchCellWithTitle:@"Enable FLEX gesture" subtitle:@"Allows you to hold 5 fingers on the screen to open the FLEX explorer" defaultsKey:@"flex_instagram"],
                                                [SCISetting switchCellWithTitle:@"Open FLEX on app launch" subtitle:@"Automatically opens the FLEX explorer when the app launches" defaultsKey:@"flex_app_launch"],
                                                [SCISetting switchCellWithTitle:@"Open FLEX on app focus" subtitle:@"Automatically opens the FLEX explorer when the app is focused" defaultsKey:@"flex_app_start"]
                                            ]
                                        },
                                         @{
                                             @"header": @"Peki Scripter",
                                             @"rows": @[
                                                 [SCISetting buttonCellWithTitle:@"Copy compatibility report"
                                                     subtitle:@"Instagram/iOS versions and available hook methods; no message contents"
                                                     icon:[SCISymbol symbolWithName:@"doc.on.doc"]
                                                     action:^{
                                                         UIPasteboard.generalPasteboard.string = [SCIUtils compatibilityReport];
                                                     }],
                                                 [SCISetting switchCellWithTitle:@"Show tweak settings on app launch" subtitle:@"Automatically opens the Peki Scripter settings when the app launches" defaultsKey:@"tweak_settings_app_launch"],
                                                 [SCISetting buttonCellWithTitle:@"Reset onboarding completion state"
                                                                           subtitle:@""
                                                                               icon:nil
                                                                              action:^(void) { [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SCInstaFirstRun"]; [SCIUtils showRestartConfirmation];}
                                                 ],
                                             ]
                                         },
                                         @{
                                             @"header": @"Instagram",
                                            @"rows": @[
                                                [SCISetting switchCellWithTitle:@"Disable safe mode" subtitle:@"Makes Instagram not reset settings after subsequent crashes (at your own risk)" defaultsKey:@"disable_safe_mode"]
                                            ]
                                        }
                                        ]
                ]
            ]
        },
        @{
            @"header": @"Contact",
            @"footer": @"",
            @"rows": @[
                [SCISetting linkCellWithTitle:@"Instagram" subtitle:@"@pekifn"
                    icon:[SCISymbol symbolWithName:@"camera"] url:@"https://www.instagram.com/pekifn/"],
                [SCISetting linkCellWithTitle:@"Discord" subtitle:@"pekiscripter"
                    icon:[SCISymbol symbolWithName:@"bubble.left.and.bubble.right"]
                    url:SCILicenseConfig.supportURL.absoluteString],
                [SCISetting linkCellWithTitle:@"TikTok" subtitle:@"@peki_scripter"
                    icon:[SCISymbol symbolWithName:@"play.rectangle"] url:@"https://www.tiktok.com/@peki_scripter"]
            ]
        }
    ];
}


#pragma mark - Title

///
/// This is the title displayed on the initial settings page view controller
///

+ (NSString *)title {
    return @"Peki Scripter V2";
}

+ (NSArray *)downloadSections {
    NSMutableArray *sections = [NSMutableArray new];
    [sections addObject:@{
        @"header": @"AFTER DOWNLOAD",
        @"footer": @"Share sheet offers Save Image / Save Video or Save to Files. Existing gestures update immediately without an app restart.",
        @"rows": @[
            [SCISetting menuCellWithTitle:@"Open with" subtitle:@"What happens after a download"
                menu:SCIChoiceMenu(@"download_destination", @[@[@"Share & save", @"share"], @[@"Preview", @"preview"]])],
            [SCISetting buttonCellWithTitle:@"Reset gestures to two fingers" subtitle:@"All media types · 2 fingers · 0.5 seconds"
                icon:[SCISymbol symbolWithName:@"arrow.counterclockwise"]
                action:^{
                    [SCIUtils showConfirmation:^{
                        for (NSString *kind in @[@"feed", @"stories", @"reels", @"profile"]) {
                            [NSUserDefaults.standardUserDefaults setInteger:2 forKey:[NSString stringWithFormat:@"dw_%@_fingers", kind]];
                            [NSUserDefaults.standardUserDefaults setDouble:0.5 forKey:[NSString stringWithFormat:@"dw_%@_duration", kind]];
                        }
                        [NSNotificationCenter.defaultCenter postNotificationName:SCISettingsDidChangeNotification object:nil];
                    } title:@"Reset all saving gestures?"];
                }]
        ]
    }];
    NSArray *groups = @[
        @[@"feed", @"FEED POSTS", @"dw_feed_posts"],
        @[@"stories", @"STORIES", @"dw_story"],
        @[@"reels", @"REELS", @"dw_reels"],
        @[@"profile", @"PROFILE PICTURES", @"save_profile"]
    ];
    for (NSArray *group in groups) {
        NSString *kind = group[0];
        [sections addObject:@{
            @"header": group[1],
            @"footer": [kind isEqualToString:@"profile"]
                ? @"Hold on the profile image to save the available source image."
                : @"Hold on the media with this many fingers for the chosen duration.",
            @"rows": @[
                [SCISetting switchCellWithTitle:@"Enable saving" subtitle:@"Allow the hold gesture on this media type" defaultsKey:group[2]],
                [SCISetting stepperCellWithTitle:@"Fingers" subtitle:@"Hold with %@ %@" defaultsKey:[NSString stringWithFormat:@"dw_%@_fingers", kind]
                    min:1 max:4 step:1 label:@"fingers" singularLabel:@"finger"],
                [SCISetting stepperCellWithTitle:@"Hold duration" subtitle:@"Press for %@ %@" defaultsKey:[NSString stringWithFormat:@"dw_%@_duration", kind]
                    min:0.25 max:10 step:0.25 label:@"seconds" singularLabel:@"second"]
            ]
        }];
    }
    return sections;
}


#pragma mark - Menus

///
/// This returns a dictionary where each key corresponds to a certain menu that can be displayed.
/// Each "propertyList"  item is an NSDictionary containing the following items:
///
/// `"defaultsKey"`: The key to save the selected value under in NSUserDefaults
///
/// `"value"`: A unique string corresponding to the menu item which is selected
///
/// `"requiresRestart"`: (optional) Causes a popup to appear detailing you have to restart to use these features
///

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

+ (NSDictionary *)menus {
    return @{
        @"reels_tap_control": [UIMenu menuWithChildren:@[
            [UICommand commandWithTitle:@"Default"
                                    image:nil
                                    action:@selector(menuChanged:)
                            propertyList:@{
                                @"defaultsKey": @"reels_tap_control",
                                @"value": @"default",
                                @"requiresRestart": @YES
                            }
            ],
            [UIMenu menuWithTitle:@""
                            image:nil
                        identifier:nil
                            options:UIMenuOptionsDisplayInline
                            children:@[
                                [UICommand commandWithTitle:@"Pause/Play"
                                                        image:nil
                                                        action:@selector(menuChanged:)
                                                propertyList:@{
                                                    @"defaultsKey": @"reels_tap_control",
                                                    @"value": @"pause",
                                                    @"requiresRestart": @YES
                                                }
                                ],
                                [UICommand commandWithTitle:@"Mute/Unmute"
                                                        image:nil
                                                        action:@selector(menuChanged:)
                                                propertyList:@{
                                                    @"defaultsKey": @"reels_tap_control",
                                                    @"value": @"mute",
                                                    @"requiresRestart": @YES
                                                }
                                ]
                            ]
            ]
        ]],

        @"nav_icon_ordering": [UIMenu menuWithChildren:@[
            [UICommand commandWithTitle:@"Default"
                                    image:nil
                                    action:@selector(menuChanged:)
                            propertyList:@{
                                @"defaultsKey": @"nav_icon_ordering",
                                @"value": @"default",
                                @"requiresRestart": @YES
                            }
            ],
            [UIMenu menuWithTitle:@""
                            image:nil
                        identifier:nil
                            options:UIMenuOptionsDisplayInline
                            children:@[
                                [UICommand commandWithTitle:@"Classic"
                                                        image:nil
                                                        action:@selector(menuChanged:)
                                                propertyList:@{
                                                    @"defaultsKey": @"nav_icon_ordering",
                                                    @"value": @"classic",
                                                    @"requiresRestart": @YES
                                                }
                                ],
                                [UICommand commandWithTitle:@"Standard"
                                                        image:nil
                                                        action:@selector(menuChanged:)
                                                propertyList:@{
                                                    @"defaultsKey": @"nav_icon_ordering",
                                                    @"value": @"standard",
                                                    @"requiresRestart": @YES
                                                }
                                ],
                                [UICommand commandWithTitle:@"Alternate"
                                                        image:nil
                                                        action:@selector(menuChanged:)
                                                propertyList:@{
                                                    @"defaultsKey": @"nav_icon_ordering",
                                                    @"value": @"alternate",
                                                    @"requiresRestart": @YES
                                                }
                                ]
                            ]
            ]
        ]],
        @"swipe_nav_tabs": [UIMenu menuWithChildren:@[
            [UICommand commandWithTitle:@"Default"
                                    image:nil
                                    action:@selector(menuChanged:)
                            propertyList:@{
                                @"defaultsKey": @"swipe_nav_tabs",
                                @"value": @"default",
                                @"requiresRestart": @YES
                            }
            ],
            [UIMenu menuWithTitle:@""
                            image:nil
                        identifier:nil
                            options:UIMenuOptionsDisplayInline
                            children:@[
                                [UICommand commandWithTitle:@"Enabled"
                                                        image:nil
                                                        action:@selector(menuChanged:)
                                                propertyList:@{
                                                    @"defaultsKey": @"swipe_nav_tabs",
                                                    @"value": @"enabled",
                                                    @"requiresRestart": @YES
                                                }
                                ],
                                [UICommand commandWithTitle:@"Disabled"
                                                        image:nil
                                                        action:@selector(menuChanged:)
                                                propertyList:@{
                                                    @"defaultsKey": @"swipe_nav_tabs",
                                                    @"value": @"disabled",
                                                    @"requiresRestart": @YES
                                                }
                                ]
                            ]
            ]
        ]]
    };
}

#pragma clang diagnostic pop

@end
