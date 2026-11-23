#import "TweakSettings.h"
#import "SCIMessageArchiveViewController.h"
#import "SCIThemeEditorViewController.h"
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
                [SCISetting navigationCellWithTitle:@"Support" subtitle:@""
                    icon:[SCISymbol symbolWithName:@"bubble.left.and.bubble.right"]
                    navSections:@[@{
                        @"header": @"",
                        @"rows": @[
                            [SCISetting linkCellWithTitle:@"Join Discord" subtitle:@""
                                icon:[SCISymbol symbolWithName:@"bubble.left.and.bubble.right"]
                                url:SCILicenseConfig.supportURL.absoluteString]
                        ]
                    }]],
                [SCISetting navigationCellWithTitle:@"Appearance" subtitle:@""
                    icon:[SCISymbol symbolWithName:@"slider.horizontal.3"]
                    navSections:@[@{
                        @"header": @"",
                        @"footer": @"",
                        @"rows": @[
                            [SCISetting controllerCellWithTitle:@"Theme" subtitle:@""
                                icon:[SCISymbol symbolWithName:@"paintpalette"]
                                factory:^UIViewController *(void) { return [SCIThemeEditorViewController new]; }],
                            [SCISetting menuCellWithTitle:@"Accent" subtitle:@""
                                menu:SCIChoiceMenu(@"settings_accent", @[@[@"Theme default", @"theme"], @[@"Blue", @"blue"],
                                    @[@"Ice", @"ice"], @[@"Mint", @"mint"], @[@"Lime", @"lime"], @[@"Amber", @"amber"],
                                    @[@"Copper", @"copper"], @[@"Red", @"red"], @[@"Rose", @"rose"], @[@"Indigo", @"indigo"],
                                    @[@"Monochrome", @"white"], @[@"Custom RGB", @"custom"]])]
                        ]
                    }, @{
                        @"header": @"Instagram",
                        @"footer": @"Some controls keep Instagram's own colors.",
                        @"rows": @[
                            [SCISetting menuCellWithTitle:@"Appearance" subtitle:@""
                                menu:SCIChoiceMenu(@"instagram_appearance", @[@[@"App default", @"system"], @[@"Dark", @"dark"], @[@"Light", @"light"]])],
                            [SCISetting switchCellWithTitle:@"Use theme accent in Instagram" subtitle:@""
                                defaultsKey:@"instagram_theme_accent"]
                        ]
                    }]],
                  [SCISetting navigationCellWithTitle:@"General"
                                             subtitle:@""
                                               icon:[SCISymbol symbolWithName:@"gear"]
                                        navSections:@[@{
                                            @"header": @"",
                                            @"rows": @[
                                                [SCISetting switchCellWithTitle:@"Hide ads" subtitle:@"" defaultsKey:@"hide_ads"],
                                                [SCISetting switchCellWithTitle:@"Hide Meta AI" subtitle:@"" defaultsKey:@"hide_meta_ai"],
                                                [SCISetting switchCellWithTitle:@"Copy description" subtitle:@"Press and hold a description." defaultsKey:@"copy_description"],
                                                [SCISetting switchCellWithTitle:@"Do not save recent searches" subtitle:@"" defaultsKey:@"no_recent_searches"],
                                                [SCISetting switchCellWithTitle:@"Detailed color picker" subtitle:@"Hold the eyedropper in stories." defaultsKey:@"detailed_color_picker"],
                                                [SCISetting switchCellWithTitle:@"Liquid Glass buttons" subtitle:@"Restart required." defaultsKey:@"liquid_glass_buttons" requiresRestart:YES],
                                                [SCISetting switchCellWithTitle:@"Alternate app icons" subtitle:@"Hold Instagram's logo to choose." defaultsKey:@"teen_app_icons" requiresRestart:YES]
                                            ]
                                        },
                                        @{
                                            @"header": @"Notes",
                                            @"rows": @[
                                                [SCISetting switchCellWithTitle:@"Hide notes tray" subtitle:@"" defaultsKey:@"hide_notes_tray"],
                                                [SCISetting switchCellWithTitle:@"Hide friends map" subtitle:@"" defaultsKey:@"hide_friends_map"],
                                                [SCISetting switchCellWithTitle:@"Note themes" subtitle:@"" defaultsKey:@"enable_notes_customization"],
                                                [SCISetting switchCellWithTitle:@"Custom note themes" subtitle:@"" defaultsKey:@"custom_note_themes"],
                                            ]
                                        },
                                        @{
                                            @"header": @"Suggestions",
                                            @"rows": @[
                                                [SCISetting switchCellWithTitle:@"Hide explore grid" subtitle:@"" defaultsKey:@"hide_explore_grid"],
                                                [SCISetting switchCellWithTitle:@"Hide trending searches" subtitle:@"" defaultsKey:@"hide_trending_searches"],
                                                [SCISetting switchCellWithTitle:@"No suggested chats" subtitle:@"" defaultsKey:@"no_suggested_chats"],
                                                [SCISetting switchCellWithTitle:@"No suggested users" subtitle:@"" defaultsKey:@"no_suggested_users"]
                                            ]
                                        }]
                ],
                  [SCISetting navigationCellWithTitle:@"Feed"
                                             subtitle:@""
                                               icon:[SCISymbol symbolWithName:@"rectangle.stack"]
                                        navSections:@[@{
                                            @"header": @"",
                                            @"rows": @[
                                                [SCISetting switchCellWithTitle:@"Hide stories tray" subtitle:@"" defaultsKey:@"hide_stories_tray"],
                                                [SCISetting switchCellWithTitle:@"Hide entire feed" subtitle:@"" defaultsKey:@"hide_entire_feed"],
                                                [SCISetting switchCellWithTitle:@"No suggested posts" subtitle:@"" defaultsKey:@"no_suggested_post"],
                                                [SCISetting switchCellWithTitle:@"No suggested for you" subtitle:@"" defaultsKey:@"no_suggested_account"],
                                                [SCISetting switchCellWithTitle:@"No suggested reels" subtitle:@"" defaultsKey:@"no_suggested_reels"],
                                                [SCISetting switchCellWithTitle:@"No suggested Threads posts" subtitle:@"" defaultsKey:@"no_suggested_threads"]
                                            ]
                                        }]
                ],
                  [SCISetting navigationCellWithTitle:@"Reels"
                                             subtitle:@""
                                               icon:[SCISymbol symbolWithName:@"film.stack"]
                                        navSections:@[@{
                                            @"header": @"",
                                            @"rows": @[
                                                [SCISetting menuCellWithTitle:@"Tap action" subtitle:@"" menu:[self menus][@"reels_tap_control"]],
                                                [SCISetting switchCellWithTitle:@"Always show progress bar" subtitle:@"" defaultsKey:@"reels_show_scrubber"],
                                                [SCISetting switchCellWithTitle:@"Confirm reel refresh" subtitle:@"" defaultsKey:@"refresh_reel_confirm"],
                                                [SCISetting switchCellWithTitle:@"Hide reels header" subtitle:@"" defaultsKey:@"hide_reels_header"]
                                            ]
                                        },
                                        @{
                                            @"header": @"",
                                            @"rows": @[
                                                [SCISetting switchCellWithTitle:@"Disable reel scrolling" subtitle:@"Restart required." defaultsKey:@"disable_scrolling_reels" requiresRestart:YES]
                                            ]
                                        }]
                ],
                  [SCISetting navigationCellWithTitle:@"Saving"
                                              subtitle:@""
                                                icon:[SCISymbol symbolWithName:@"tray.and.arrow.down"]
                                         navSections:[self downloadSections]
                ],
                  [SCISetting navigationCellWithTitle:@"Stories and messages"
                                             subtitle:@""
                                               icon:[SCISymbol symbolWithName:@"rectangle.portrait.on.rectangle.portrait.angled"]
                                        navSections:@[@{
                                             @"header": @"Privacy",
                                             @"footer": @"Also turn off Activity Status in Instagram. Reopen chats after changing receipt controls.",
                                             @"rows": @[
                                                 [SCISetting switchCellWithTitle:@"Block activity updates" subtitle:@"Outgoing presence updates only." defaultsKey:@"ghost_mode"],
                                                 [SCISetting switchCellWithTitle:@"Hide typing indicator" subtitle:@"" defaultsKey:@"hide_typing_indicator"],
                                                 [SCISetting switchCellWithTitle:@"Hide story views" subtitle:@"Restart required." defaultsKey:@"no_seen_receipt" requiresRestart:YES],
                                                 [SCISetting switchCellWithTitle:@"Hide message seen" subtitle:@"The session checkmark button can send receipts." defaultsKey:@"remove_lastseen"]
                                            ]
                                        },
                                        @{
                                            @"header": @"Local copies",
                                            @"footer": @"Local text only, shared across accounts. Old messages and attachments cannot be recovered. Turning this off does not erase saved text.",
                                            @"rows": @[
                                                [SCISetting switchCellWithTitle:@"Retain deleted text locally" subtitle:@"Text seen on this device." defaultsKey:@"keep_deleted_message"],
                                                [SCISetting controllerCellWithTitle:@"Local archive" subtitle:@""
                                                    icon:[SCISymbol symbolWithName:@"archivebox"]
                                                    factory:^UIViewController *(void) { return [SCIMessageArchiveViewController new]; }]
                                            ]
                                        },
                                        @{
                                             @"header": @"Disappearing media",
                                             @"rows": @[
                                                 [SCISetting switchCellWithTitle:@"Disable screenshot detection" subtitle:@"For disappearing media." defaultsKey:@"remove_screenshot_alert"],
                                                 [SCISetting switchCellWithTitle:@"Unlimited replay of direct stories" subtitle:@"Controlled by the image checkmark." defaultsKey:@"unlimited_replay"],
                                                 [SCISetting switchCellWithTitle:@"Disable view-once limitations" subtitle:@"Replay, pause and loop." defaultsKey:@"disable_view_once_limitations"]
                                            ]
                                        }]
                ],
                  [SCISetting navigationCellWithTitle:@"Navigation"
                                             subtitle:@""
                                               icon:[SCISymbol symbolWithName:@"hand.draw.fill"]
                                        navSections:@[@{
                                            @"header": @"",
                                            @"rows": @[
                                                [SCISetting menuCellWithTitle:@"Icon order" subtitle:@"" menu:[self menus][@"nav_icon_ordering"]],
                                                [SCISetting menuCellWithTitle:@"Swipe between tabs" subtitle:@"" menu:[self menus][@"swipe_nav_tabs"]],
                                            ]
                                        },
                                        @{
                                            @"header": @"Hiding tabs",
                                            @"rows": @[
                                                [SCISetting switchCellWithTitle:@"Hide feed tab" subtitle:@"Restart required." defaultsKey:@"hide_feed_tab" requiresRestart:YES],
                                                [SCISetting switchCellWithTitle:@"Hide explore tab" subtitle:@"Restart required." defaultsKey:@"hide_explore_tab" requiresRestart:YES],
                                                [SCISetting switchCellWithTitle:@"Hide reels tab" subtitle:@"Restart required." defaultsKey:@"hide_reels_tab" requiresRestart:YES],
                                                [SCISetting switchCellWithTitle:@"Hide create tab" subtitle:@"Restart required." defaultsKey:@"hide_create_tab" requiresRestart:YES]
                                            ]
                                        }]
                ],
                  [SCISetting navigationCellWithTitle:@"Confirm actions"
                                             subtitle:@""
                                               icon:[SCISymbol symbolWithName:@"checkmark"]
                                        navSections:@[@{
                                            @"header": @"",
                                            @"rows": @[
                                                [SCISetting switchCellWithTitle:@"Confirm like: Posts/Stories" subtitle:@"" defaultsKey:@"like_confirm"],
                                                [SCISetting switchCellWithTitle:@"Confirm like: Reels" subtitle:@"" defaultsKey:@"like_confirm_reels"]
                                            ]
                                        },
                                        @{
                                            @"header": @"",
                                            @"rows": @[
                                                [SCISetting switchCellWithTitle:@"Confirm follow" subtitle:@"" defaultsKey:@"follow_confirm"],
                                                [SCISetting switchCellWithTitle:@"Confirm repost" subtitle:@"" defaultsKey:@"repost_confirm"],
                                                [SCISetting switchCellWithTitle:@"Confirm call" subtitle:@"" defaultsKey:@"call_confirm"],
                                                [SCISetting switchCellWithTitle:@"Confirm voice messages" subtitle:@"" defaultsKey:@"voice_message_confirm"],
                                                [SCISetting switchCellWithTitle:@"Confirm follow requests" subtitle:@"" defaultsKey:@"follow_request_confirm"],
                                                [SCISetting switchCellWithTitle:@"Confirm vanish mode" subtitle:@"" defaultsKey:@"shh_mode_confirm"],
                                                [SCISetting switchCellWithTitle:@"Confirm posting comment" subtitle:@"" defaultsKey:@"post_comment_confirm"],
                                                [SCISetting switchCellWithTitle:@"Confirm changing theme" subtitle:@"" defaultsKey:@"change_direct_theme_confirm"],
                                                [SCISetting switchCellWithTitle:@"Confirm sticker interaction" subtitle:@"" defaultsKey:@"sticker_interact_confirm"]
                                            ]
                                        }]
                ]
            ]
        },
        @{
            @"header": @"",
            @"rows": @[
                 [SCISetting navigationCellWithTitle:@"Debug"
                                            subtitle:@""
                                               icon:[SCISymbol symbolWithName:@"ladybug"]
                                        navSections:@[@{
                                            @"header": @"FLEX",
                                            @"rows": @[
                                                [SCISetting switchCellWithTitle:@"FLEX gesture" subtitle:@"Hold five fingers." defaultsKey:@"flex_instagram"],
                                                [SCISetting switchCellWithTitle:@"Open FLEX on app launch" subtitle:@"" defaultsKey:@"flex_app_launch"],
                                                [SCISetting switchCellWithTitle:@"Open FLEX on app focus" subtitle:@"" defaultsKey:@"flex_app_start"]
                                            ]
                                        },
                                         @{
                                             @"header": @"App",
                                             @"rows": @[
                                                 [SCISetting buttonCellWithTitle:@"Copy compatibility report"
                                                     subtitle:@"App version and hook status."
                                                     icon:[SCISymbol symbolWithName:@"doc.on.doc"]
                                                     action:^{
                                                         UIPasteboard.generalPasteboard.string = [SCIUtils compatibilityReport];
                                                     }],
                                                 [SCISetting switchCellWithTitle:@"Open settings on launch" subtitle:@"" defaultsKey:@"tweak_settings_app_launch"],
                                                 [SCISetting buttonCellWithTitle:@"Reset first launch"
                                                                           subtitle:@""
                                                                               icon:nil
                                                                              action:^(void) { [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SCInstaFirstRun"]; [SCIUtils showRestartConfirmation];}
                                                 ],
                                             ]
                                         },
                                         @{
                                             @"header": @"Instagram",
                                            @"rows": @[
                                                [SCISetting switchCellWithTitle:@"Disable safe mode" subtitle:@"Keep settings after crashes. May cause startup loops." defaultsKey:@"disable_safe_mode"]
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
        @"header": @"After saving",
        @"footer": @"",
        @"rows": @[
            [SCISetting menuCellWithTitle:@"Open with" subtitle:@""
                menu:SCIChoiceMenu(@"download_destination", @[@[@"Share & save", @"share"], @[@"Preview", @"preview"]])],
            [SCISetting buttonCellWithTitle:@"Reset gestures to two fingers" subtitle:@"2 fingers, 0.5 seconds"
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
        @[@"feed", @"Feed", @"dw_feed_posts"],
        @[@"stories", @"Stories", @"dw_story"],
        @[@"reels", @"Reels", @"dw_reels"],
        @[@"profile", @"Profile pictures", @"save_profile"]
    ];
    for (NSArray *group in groups) {
        NSString *kind = group[0];
        [sections addObject:@{
            @"header": group[1],
            @"footer": [kind isEqualToString:@"profile"]
                ? @"Press and hold the profile photo."
                : @"",
            @"rows": @[
                [SCISetting switchCellWithTitle:@"Enable saving" subtitle:@"" defaultsKey:group[2]],
                [SCISetting stepperCellWithTitle:@"Fingers" subtitle:@"%@ %@" defaultsKey:[NSString stringWithFormat:@"dw_%@_fingers", kind]
                    min:1 max:4 step:1 label:@"fingers" singularLabel:@"finger"],
                [SCISetting stepperCellWithTitle:@"Hold duration" subtitle:@"%@ %@" defaultsKey:[NSString stringWithFormat:@"dw_%@_duration", kind]
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
