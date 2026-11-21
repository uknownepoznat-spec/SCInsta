#import "../../Utils.h"

// Intercept outbound updates, not IGUser.isOnline/isActive (which only changes
// what this device displays). These hooks remain Instagram-version dependent.
%hook IGPresenceManager
- (void)setPresence:(id)presence {
    if ([SCIUtils getBoolPref:@"ghost_mode"]) return;
    %orig;
}
- (void)markActivityForThread:(id)thread {
    if ([SCIUtils getBoolPref:@"ghost_mode"]) return;
    %orig;
}
%end

%hook IGDirectThreadViewController
- (void)sendTypingIndicator:(id)indicator {
    if ([SCIUtils getBoolPref:@"hide_typing_indicator"]) return;
    %orig;
}
%end

%hook IGStoryViewerData
- (void)markStoryAsViewed:(id)story {
    if ([SCIUtils getBoolPref:@"no_seen_receipt"] || [SCIUtils getBoolPref:@"story_ghost_mode"]) return;
    %orig;
}
%end
