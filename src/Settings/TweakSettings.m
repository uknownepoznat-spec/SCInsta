#import "TweakSettings.h"
#import "SCISetting.h"
#import "SCISymbol.h"
#import "../Utils.h"
#import "../Tweak.h"

@implementation SCITweakSettings

#pragma mark - Sections

+ (NSArray *)sections {
    return @[
        @{
            @"header": @"",
            @"rows": @[
                [SCISetting navigationCellWithTitle:@"General"
                                           subtitle:@""
                                               icon:[SCISymbol symbolWithName:@"gear"]
                                        navSections:@[@{
                                            @"header": @"",
                                            @"rows": @[
                                                [SCISetting switchCellWithTitle:@"Hide ads" subtitle:@"Removes all ads from Instagram app" defaultsKey:@"hide_ads"],
                                                [SCISetting switchCellWithTitle:@"Hide Meta AI" subtitle:@"Hides meta ai buttons/functionality within app" defaultsKey:@"hide_meta_ai"],
                                                [SCISetting switchCellWithTitle:@"Copy description" subtitle:@"Copy description text fields by long-pressing on them" defaultsKey:@"copy_description"],
                                                [SCISetting switchCellWithTitle:@"Do not save recent searches" subtitle:@"Search bars will no longer save your recent searches" defaultsKey:@"no_recent_searches"],
                                                [SCISetting switchCellWithTitle:@"Use detailed color picker" subtitle:@"Long press on the eyedropper tool in stories to customize text color more precisely" defaultsKey:@"detailed_color_picker"],
                                                [SCISetting switchCellWithTitle:@"Enable liquid glass buttons" subtitle:@"Enables experimental liquid glass buttons within app" defaultsKey:@"liquid_glass_buttons" requiresRestart:YES],
                                                [SCISetting switchCellWithTitle:@"Enable teen app icons" subtitle:@"When enabled, hold down on Instagram logo to change app icon" defaultsKey:@"teen_app_icons" requiresRestart:YES]
                                            ]
                                        },
                                        @{
                                            @"header": @"Notes",
                                            @"rows": @[
                                                [SCISetting switchCellWithTitle:@"Hide notes tray" subtitle:@"Hides notes tray in dm inbox" defaultsKey:@"hide_notes_tray"],
                                                [SCISetting switchCellWithTitle:@"Hide friends map" subtitle:@"Hides friends map icon in notes tray" defaultsKey:@"hide_friends_map"],
                                                [SCISetting switchCellWithTitle:@"Enable note theming" subtitle:@"Enables ability to use notes theme picker" defaultsKey:@"enable_notes_customization"],
                                                [SCISetting switchCellWithTitle:@"Custom note themes" subtitle:@"Provides an option to set custom emojis and background/text colors" defaultsKey:@"custom_note_themes"],
                                            ]
                                        },
                                        @{
                                            @"header": @"Focus/distractions",
                                            @"rows": @[
                                                [SCISetting switchCellWithTitle:@"Hide explore posts grid" subtitle:@"Hides grid of suggested posts on explore/search tab" defaultsKey:@"hide_explore_grid"],
                                                [SCISetting switchCellWithTitle:@"Hide trending searches" subtitle:@"Hides trending searches under explore search bar" defaultsKey:@"hide_trending_searches"],
                                                [SCISetting switchCellWithTitle:@"No suggested chats" subtitle:@"Hides suggested broadcast channels in direct messages" defaultsKey:@"no_suggested_chats"],
                                                [SCISetting switchCellWithTitle:@"No suggested users" subtitle:@"Hides all suggested users for you to follow, outside your feed" defaultsKey:@"no_suggested_users"]
                                            ]
                                        }
                ],
                [SCISetting navigationCellWithTitle:@"Feed"
                                           subtitle:@""
                                               icon:[SCISymbol symbolWithName:@"rectangle.stack"]
                                        navSections:@[@{
                                            @"header": @"",
                                            @"rows": @[
                                                [SCISetting switchCellWithTitle:@"Hide stories tray" subtitle:@"Hides story tray at the top and within your feed" defaultsKey:@"hide_stories_tray"],
                                                [SCISetting switchCellWithTitle:@"Hide entire feed" subtitle:@"Removes all content from your home feed, including posts" defaultsKey:@"hide_entire_feed"],
                                                [SCISetting switchCellWithTitle:@"No suggested posts" subtitle:@"Removes suggested posts from your feed" defaultsKey:@"no_suggested_post"],
                                                [SCISetting switchCellWithTitle:@"No suggested for you" subtitle:@"Hides suggested accounts for you to follow" defaultsKey:@"no_suggested_account"],
                                                [SCISetting switchCellWithTitle:@"No suggested reels" subtitle:@"Hides suggested reels to watch" defaultsKey:@"no_suggested_reels"],
                                                [SCISetting switchCellWithTitle:@"No suggested threads posts" subtitle:@"Hides suggested threads posts" defaultsKey:@"no_suggested_threads"]
                                            ]
                                        }
                },
                [SCISetting navigationCellWithTitle:@"Reels"
                                           subtitle:@""
                                               icon:[SCISymbol symbolWithName:@"film.stack"]
                                        navSections:@[@{
                                            @"header": @"",
                                            @"rows": @[
                                                [SCISetting menuCellWithTitle:@"Tap Controls" subtitle:@"Change what happens when you tap on a reel" menu:[self menus][@"reels_tap_control"]],
                                                [SCISetting switchCellWithTitle:@"Always show progress scrubber" subtitle:@"Forces progress bar to appear on every reel" defaultsKey:@"reels_show_scrubber"],
                                                [SCISetting switchCellWithTitle:@"Confirm reel refresh" subtitle:@"Shows an alert when you trigger a reels refresh" defaultsKey:@"refresh_reel_confirm"],
                                                [SCISetting switchCellWithTitle:@"Hide reels header" subtitle:@"Hides top navigation bar when watching reels" defaultsKey:@"hide_reels_header"]
                                            ]
                                        },
                                        @{
                                            @"header": @"",
                                            @"rows": @[
                                                [SCISetting switchCellWithTitle:@"Disable scrolling reels" subtitle:@"Prevents reels from being scrolled to the next video" defaultsKey:@"disable_scrolling_reels" requiresRestart:YES]
                                            ]
                                        }
                ],
                [SCISetting navigationCellWithTitle:@"Saving"
                                           subtitle:@""
                                               icon:[SCISymbol symbolWithName:@"tray.and.arrow.down"]
                                        navSections:@[@{
                                            @"header": @"",
                                            @"rows": @[
                                                [SCISetting switchCellWithTitle:@"Download feed posts" subtitle:@"Long-press with finger(s) to download posts in home tab" defaultsKey:@"dw_feed_posts"],
                                                [SCISetting switchCellWithTitle:@"Download reels" subtitle:@"Long-press with finger(s) on a reel to download" defaultsKey:@"dw_reels"],
                                                [SCISetting switchCellWithTitle:@"Download stories" subtitle:@"Long-press with finger(s) while viewing someone's story to download" defaultsKey:@"dw_story"],
                                                [SCISetting switchCellWithTitle:@"Save profile picture" subtitle:@"On someone's profile, click their profile picture to enlarge it, then hold to download" defaultsKey:@"save_profile"]
                                            ]
                                        },
                                        @{
                                            @"header": @"Customize gestures",
                                            @"rows": @[
                                                [SCISetting stepperCellWithTitle:@"Finger count for long-press" subtitle:@"Downloads with %@ %@" defaultsKey:@"dw_finger_count" min:1 max:5 step:1 label:@"fingers" singularLabel:@"finger"],
                                                [SCISetting stepperCellWithTitle:@"Long-press hold time" subtitle:@"Press finger(s) for %@ %@" defaultsKey:@"dw_finger_duration" min:0 max:10 step:0.25 label:@"sec" singularLabel:@"sec"]
                                            ]
                                        }
                ],
                [SCISetting navigationCellWithTitle:@"Stories and messages"
                                           subtitle:@""
                                               icon:[SCISymbol symbolWithName:@"rectangle.portrait.on.rectangle.portrait.angled"]
                                        navSections:@[@{
                                            @"header": @"",
                                            @"rows": @[
                                                [SCISetting switchCellWithTitle:@"Keep deleted messages" subtitle:@"Saves deleted messages in chat conversations" defaultsKey:@"keep_deleted_message"],
                                                [SCISetting switchCellWithTitle:@"Disable screenshot detection" subtitle:@"Removes screenshot-prevention features for visual messages in DMs" defaultsKey:@"remove_screenshot_alert"],
                                                [SCISetting switchCellWithTitle:@"Unlimited replay of direct stories" subtitle:@"Replays direct messages normal/once stories unlimited times (toggle with image check icon)" defaultsKey:@"unlimited_replay"],
                                                [SCISetting switchCellWithTitle:@"Disable sending read receipts" subtitle:@"Removes seen text for others when you view a message (toggle with message check icon)" defaultsKey:@"remove_lastseen"],
                                                [SCISetting switchCellWithTitle:@"Disable story seen receipt" subtitle:@"Hides notification for others when you view their story" defaultsKey:@"no_seen_receipt"],
                                                [SCISetting switchCellWithTitle:@"Disable view-once limitations" subtitle:@"Makes view-once messages behave like normal visual messages (loopable/pauseable)" defaultsKey:@"disable_view_once_limitations"]
                                            ]
                                        }
                ],
                [SCISetting navigationCellWithTitle:@"Navigation"
                                           subtitle:@""
                                               icon:[SCISymbol symbolWithName:@"hand.draw.fill"]
                                        navSections:@[@{
                                            @"header": @"",
                                            @"rows": @[
                                                [SCISetting menuCellWithTitle:@"Icon order" subtitle:@"The order of icons on the bottom navigation bar" menu:[self menus][@"nav_icon_ordering"]],
                                                [SCISetting menuCellWithTitle:@"Swipe between tabs" subtitle:@"Lets you swipe to switch between navigation bar tabs" menu:[self menus][@"swipe_nav_tabs"]],
                                            ]
                                        },
                                        @{
                                            @"header": @"Hiding tabs",
                                            @"rows": @[
                                                [SCISetting switchCellWithTitle:@"Hide feed tab" subtitle:@"Hides feed/home tab on the bottom navigation bar" defaultsKey:@"hide_feed_tab" requiresRestart:YES],
                                                [SCISetting switchCellWithTitle:@"Hide explore tab" subtitle:@"Hides explore/search tab on the bottom navigation bar" defaultsKey:@"hide_explore_tab" requiresRestart:YES],
                                                [SCISetting switchCellWithTitle:@"Hide reels tab" subtitle:@"Hides reels tab on the bottom navigation bar" defaultsKey:@"hide_reels_tab" requiresRestart:YES],
                                                [SCISetting switchCellWithTitle:@"Hide create tab" subtitle:@"Hides create tab on the bottom navigation bar" defaultsKey:@"hide_create_tab" requiresRestart:YES]
                                            ]
                                        }
                ],
                [SCISetting navigationCellWithTitle:@"Confirm actions"
                                           subtitle:@""
                                               icon:[SCISymbol symbolWithName:@"checkmark"]
                                        navSections:@[@{
                                            @"header": @"",
                                            @"rows": @[
                                                [SCISetting switchCellWithTitle:@"Confirm like: Posts/Stories" subtitle:@"Shows an alert when you click like button on posts or stories to confirm like" defaultsKey:@"like_confirm"],
                                                [SCISetting switchCellWithTitle:@"Confirm like: Reels" subtitle:@"Shows an alert when you click like button on reels to confirm like" defaultsKey:@"like_confirm_reels"],
                                                [SCISetting switchCellWithTitle:@"Confirm follow" subtitle:@"Shows an alert when you click follow button to confirm follow" defaultsKey:@"follow_confirm"],
                                                [SCISetting switchCellWithTitle:@"Confirm repost" subtitle:@"Shows an alert when you click repost button to confirm before reposting" defaultsKey:@"repost_confirm"],
                                                [SCISetting switchCellWithTitle:@"Confirm call" subtitle:@"Shows an alert when you click audio/video call button to confirm before calling" defaultsKey:@"call_confirm"],
                                                [SCISetting switchCellWithTitle:@"Confirm voice messages" subtitle:@"Shows an alert to confirm before sending a voice message" defaultsKey:@"voice_message_confirm"],
                                                [SCISetting switchCellWithTitle:@"Confirm follow requests" subtitle:@"Shows an alert when you accept/decline a follow request" defaultsKey:@"follow_request_confirm"],
                                                [SCISetting switchCellWithTitle:@"Confirm shh mode" subtitle:@"Shows an alert to confirm before toggling disappearing messages" defaultsKey:@"shh_mode_confirm"],
                                                [SCISetting switchCellWithTitle:@"Confirm posting comment" subtitle:@"Shows an alert when you click post comment button to confirm" defaultsKey:@"post_comment_confirm"],
                                                [SCISetting switchCellWithTitle:@"Confirm changing theme" subtitle:@"Shows an alert when you change a chat theme to confirm" defaultsKey:@"change_direct_theme_confirm"],
                                                [SCISetting switchCellWithTitle:@"Confirm sticker interaction" subtitle:@"Shows an alert when you click a sticker on someone's story to confirm action" defaultsKey:@"sticker_interact_confirm"]
                                            ]
                                        }
                ],
                [SCISetting navigationCellWithTitle:@"Extra Settings"
                                           subtitle:@"PekiWare custom features"
                                               icon:[SCISymbol symbolWithName:@"star.circle"]
                                        navSections:@[@{
                                            @"header": @"PekiWare Custom",
                                            @"rows": @[
                                                [SCISetting switchCellWithTitle:@"Local blue verification" subtitle:@"Show blue verification badge on your profile" defaultsKey:@"peki_local_verification"],
                                                [SCISetting textFieldCellWithTitle:@"Custom follower count" subtitle:@"Enter custom follower count" defaultsKey:@"peki_custom_follower_count" placeholder:@"Enter number..."],
                                                [SCISetting switchCellWithTitle:@"Enable custom follower count" subtitle:@"Show custom follower count on your profile (only visible to you)" defaultsKey:@"peki_enable_custom_followers"],
                                                [SCISetting buttonCellWithTitle:@"Reset onboarding completion state"
                                                                           subtitle:@""
                                                                               icon:nil
                                                                             action:^(void) { [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SCInstaFirstRun"]; [SCIUtils showRestartConfirmation];}
                                                ],
                                            ]
                                        },
                                        @{
                                            @"header": @"Advanced",
                                            @"rows": @[
                                                [SCISetting switchCellWithTitle:@"Ghost Mode" subtitle:@"Appear offline and inactive to everyone" defaultsKey:@"ghost_mode"],
                                                [SCISetting switchCellWithTitle:@"Hide typing indicator" subtitle:@"Others won't see when you're typing" defaultsKey:@"hide_typing_indicator"],
                                                [SCISetting switchCellWithTitle:@"Story Ghost Mode" subtitle:@"View stories without being seen" defaultsKey:@"story_ghost_mode"],
                                                [SCISetting switchCellWithTitle:@"Anti-Delete" subtitle:@"Protect your messages from being deleted by others" defaultsKey:@"anti_delete"],
                                                [SCISetting switchCellWithTitle:@"Story Downloader" subtitle:@"Download any story with one tap" defaultsKey:@"story_downloader"],
                                                [SCISetting switchCellWithTitle:@"HD Profile Pictures" subtitle:@"Always load profile pictures in HD quality" defaultsKey:@"hd_profile_pics"],
                                                [SCISetting switchCellWithTitle:@"Unseen Stories Counter" subtitle:@"Show count of unseen stories" defaultsKey:@"unseen_counter"],
                                                [SCISetting switchCellWithTitle:@"Message Encryption" subtitle:@"Add encryption tag to messages" defaultsKey:@"message_encryption"],
                                                [SCISetting textFieldCellWithTitle:@"Auto Reply Text" subtitle:@"Text for automatic replies" defaultsKey:@"auto_reply_text" placeholder:@"Enter auto reply..."],
                                                [SCISetting switchCellWithTitle:@"Enable Auto Reply" subtitle:@"Automatically reply to messages" defaultsKey:@"auto_reply_enabled"],
                                                [SCISetting textFieldCellWithTitle:@"Message Schedule" subtitle:@"Schedule messages (HH:MM format)" defaultsKey:@"message_schedule_time" placeholder:@"14:30"]
                                            ]
                                        },
                                        @{
                                            @"header": @"Instagram",
                                            @"rows": @[
                                                [SCISetting switchCellWithTitle:@"Disable safe mode" subtitle:@"Makes Instagram not reset settings after subsequent crashes (at your own risk)" defaultsKey:@"disable_safe_mode"]
                                            ]
                                        }]
                                }
                            ]
                        },
                [SCISetting linkCellWithTitle:@"Developer Peki Scripter"
                                     subtitle:@"Creator of PekiWare"
                                         icon:[SCISymbol symbolWithName:@"person.crop.circle.fill"
                                                                  color:[UIColor systemBlueColor]
                                                                   size:22.0]
                                          url:@"https://discord.gg/ZbZCBGazAM"],
                [SCISetting linkCellWithTitle:@"Discord server"
                                     subtitle:@"Join to Peki community"
                                         icon:[SCISymbol symbolWithName:@"bubble.left.and.bubble.right.fill"
                                                                  color:[UIColor systemBlueColor]
                                                                   size:20.0]
                                          url:@"https://discord.gg/ZbZCBGazAM"]
            ]
        }
    ];
}

#pragma mark - Title

+ (NSString *)title {
    return @"PekiWare Settings";
}

#pragma mark - Menus

+ (NSDictionary *)menus {
    return @{
        @"reels_tap_control": [self menuWithItems:@[
            @{@"title": @"Default", @"value": @"default"},
            @{@"title": @"Play/Pause", @"value": @"play_pause"},
            @{@"title": @"Mute/Unmute", @"value": @"mute_unmute"},
            @{@"title": @"Like", @"value": @"like"},
            @{@"title": @"Comment", @"value": @"comment"},
            @{@"title": @"Share", @"value": @"share"},
            @{@"title": @"None", @"value": @"none"}
        ]],
        @"nav_icon_ordering": [self menuWithItems:@[
            @{@"title": @"Default", @"value": @"default"},
            @{@"title": @"Create first", @"value": @"create_first"},
            @{@"title": @"Reels first", @"value": @"reels_first"},
            @{@"title": @"Shop first", @"value": @"shop_first"},
            @{@"title": @"No create", @"value": @"no_create"},
            @{@"title": @"No reels", @"value": @"no_reels"},
            @{@"title": @"No shop", @"value": @"no_shop"}
        ]],
        @"swipe_nav_tabs": [self menuWithItems:@[
            @{@"title": @"Default", @"value": @"default"},
            @{@"title": @"Enabled", @"value": @"enabled"},
            @{@"title": @"Disabled", @"value": @"disabled"}
        ]]
    };
}

@end
