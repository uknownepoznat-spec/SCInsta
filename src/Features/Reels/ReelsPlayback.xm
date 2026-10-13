#import "../../Utils.h"

%hook IGSundialPlaybackControlsTestConfiguration
- (id)initWithLauncherSet:(id)set
                     tapToPauseEnabled:(_Bool)tapPauseEnabled
      combineSingleTapPlaybackControls:(_Bool)controls
        isVideoPreviewThumbnailEnabled:(_Bool)previewThumbEnabled
                minScrubberDurationSec:(long long)minSec
         seekResumeScrubberCooldownSec:(double)seekSec
          tapResumeScrubberCooldownSec:(double)tapSec
    persistentScrubberMinVideoDuration:(long long)duration
        isScrubberForShortVideoEnabled:(_Bool)shortScrubberEnabled
{
    _Bool userTapPauseEnabled = tapPauseEnabled;
    if ([[SCIUtils getStringPref:@"reels_tap_control"] isEqualToString:@"pause"]) userTapPauseEnabled = true;
    else if ([[SCIUtils getStringPref:@"reels_tap_control"] isEqualToString:@"mute"]) userTapPauseEnabled = false;

    long long userMinSec = minSec;
    long long userDuration = duration;
    _Bool userShortScrubberEnabled = shortScrubberEnabled;
    if ([SCIUtils getBoolPref:@"reels_show_scrubber"]) {
        userMinSec = 0;
        userDuration = 0;
        userShortScrubberEnabled = true;
    }

    return %orig(set, userTapPauseEnabled, controls, previewThumbEnabled, userMinSec, seekSec, tapSec, userDuration, userShortScrubberEnabled);
}
%end

%hook IGSundialFeedViewController
- (void)triggerRefreshFromTabTap {
    static BOOL confirmingRefresh = NO;
    if ([SCIUtils getBoolPref:@"refresh_reel_confirm"] && !confirmingRefresh) {
        NSLog(@"[PekiWare] Reel refresh triggered");

        confirmingRefresh = YES;
        [SCIUtils showConfirmation:^{
            confirmingRefresh = NO;
            [self triggerRefreshFromTabTap];
        } cancelHandler:^{
            confirmingRefresh = NO;
        } title:@"Refresh Reels"];
        return;
    }
    return %orig;
}
- (void)_refreshReelsWithParamsForNetworkRequest:(NSInteger)arg1 userDidPullToRefresh:(BOOL)arg2 {
    static BOOL confirmingRefreshParams = NO;
    if ([SCIUtils getBoolPref:@"refresh_reel_confirm"] && !confirmingRefreshParams) {
        NSLog(@"[PekiWare] Reel refresh triggered");

        confirmingRefreshParams = YES;
        [SCIUtils showConfirmation:^{
            confirmingRefreshParams = NO;
            [self _refreshReelsWithParamsForNetworkRequest:arg1 userDidPullToRefresh:arg2];
        }
                     cancelHandler:^(void) {
                         confirmingRefreshParams = NO;
                         IGRefreshControl *_refreshControl = MSHookIvar<IGRefreshControl *>(self, "_refreshControl");
                         [self refreshControlDidEndFinishLoadingAnimation:_refreshControl];
                     }
                             title:@"Refresh Reels"];
        return;
    }
    return %orig(arg1, arg2);
}
%end