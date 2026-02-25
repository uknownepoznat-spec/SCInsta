#import "../../Utils.h"

%hook IGDirectThreadViewController
- (void)swipeableScrollManagerDidEndDraggingAboveSwipeThreshold:(id)arg1 {
    if ([SCIUtils getBoolPref:@"shh_mode_confirm"]) {
        NSLog(@"[PekiWare] Confirm shh mode triggered");

        [SCIUtils showConfirmation:^(void) { %orig; }];
    } else {
        return %orig;
    }
}

- (void)shhModeTransitionButtonDidTap:(id)arg1 {
    if ([SCIUtils getBoolPref:@"shh_mode_confirm"]) {
        NSLog(@"[PekiWare] Confirm shh mode triggered");

        [SCIUtils showConfirmation:^(void) { %orig; }];
    } else {
        return %orig;
    }
}

- (void)messageListViewControllerDidToggleShhMode:(id)arg1 {
    if ([SCIUtils getBoolPref:@"shh_mode_confirm"]) {
        NSLog(@"[PekiWare] Confirm shh mode triggered");

        [SCIUtils showConfirmation:^(void) { %orig; }];
    } else {
        return %orig;
    }
}
%end