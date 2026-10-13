#import "../../Utils.h"

%hook IGStoryViewerTapTarget
- (void)_didTap:(id)arg1 forEvent:(id)arg2 {
    static BOOL confirming = NO;
    if ([SCIUtils getBoolPref:@"sticker_interact_confirm"] && !confirming) {
        NSLog(@"[PekiWare] Confirm sticker interact triggered");

        confirming = YES;
        [SCIUtils showConfirmation:^{
            confirming = NO;
            [self _didTap:arg1 forEvent:arg2];
        } cancelHandler:^{
            confirming = NO;
        }];
        return;
    }
    return %orig;
}
%end
