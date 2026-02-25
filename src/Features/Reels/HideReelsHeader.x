#import "../../Utils.h"

%hook IGSundialViewerNavigationBarOld
- (void)didMoveToWindow {
    %orig;

    if ([SCIUtils getBoolPref:@"hide_reels_header"]) {
        NSLog(@"[PekiWare] Hiding reels header");

        [self removeFromSuperview];
    }
}
%end
