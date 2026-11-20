#import "../../Utils.h"

%hook IGSundialViewerNavigationBarOld
- (void)didMoveToWindow {
    %orig;

    if ([SCIUtils getBoolPref:@"hide_reels_header"]) {
        NSLog(@"[Peki Scripter] Hiding reels header");

        [self removeFromSuperview];
    }
}
%end
