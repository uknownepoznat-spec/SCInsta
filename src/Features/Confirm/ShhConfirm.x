#import "../../Utils.h"

%hook IGDirectThreadViewController
- (void)swipeableScrollManagerDidEndDraggingAboveSwipeThreshold:(id)arg1 {
    static BOOL confirming = NO;
    if ([SCIUtils getBoolPref:@"shh_mode_confirm"] && !confirming) {
        NSLog(@"[PekiWare] Confirm shh mode triggered");

        confirming = YES;
        [SCIUtils showConfirmation:^{
            confirming = NO;
            [self swipeableScrollManagerDidEndDraggingAboveSwipeThreshold:arg1];
        } cancelHandler:^{
            confirming = NO;
        }];
        return;
    }
    return %orig;
}

- (void)shhModeTransitionButtonDidTap:(id)arg1 {
    static BOOL confirmingBtn = NO;
    if ([SCIUtils getBoolPref:@"shh_mode_confirm"] && !confirmingBtn) {
        NSLog(@"[PekiWare] Confirm shh mode triggered");

        confirmingBtn = YES;
        [SCIUtils showConfirmation:^{
            confirmingBtn = NO;
            [self shhModeTransitionButtonDidTap:arg1];
        } cancelHandler:^{
            confirmingBtn = NO;
        }];
        return;
    }
    return %orig;
}

- (void)messageListViewControllerDidToggleShhMode:(id)arg1 {
    static BOOL confirmingToggle = NO;
    if ([SCIUtils getBoolPref:@"shh_mode_confirm"] && !confirmingToggle) {
        NSLog(@"[PekiWare] Confirm shh mode triggered");

        confirmingToggle = YES;
        [SCIUtils showConfirmation:^{
            confirmingToggle = NO;
            [self messageListViewControllerDidToggleShhMode:arg1];
        } cancelHandler:^{
            confirmingToggle = NO;
        }];
        return;
    }
    return %orig;
}
%end
