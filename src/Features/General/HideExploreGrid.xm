#import "../../Utils.h"
#import "../../InstagramHeaders.h"

%hook IGExploreGridViewController
- (void)viewDidLoad {
    if ([SCIUtils getBoolPref:@"hide_explore_grid"]) {
        NSLog(@"[PekiWare] Hiding explore grid");

        [[self view] removeFromSuperview];

        return;
    }
    
    return %orig;
}
%end

%hook IGExploreViewController
- (void)viewDidLoad {
    %orig;

    if ([SCIUtils getBoolPref:@"hide_explore_grid"]) {
        NSLog(@"[PekiWare] Hiding explore grid");

        IGShimmeringGridView *shimmeringGridView = MSHookIvar<IGShimmeringGridView *>(self, "_shimmeringGridView");
        if (shimmeringGridView != nil) {
            [shimmeringGridView removeFromSuperview];
        }
    }
}
%end