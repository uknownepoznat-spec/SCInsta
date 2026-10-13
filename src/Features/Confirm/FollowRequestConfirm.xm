#import "../../Utils.h"

%hook IGPendingRequestView
- (void)_onApproveButtonTapped {
    static BOOL confirming = NO;
    if ([SCIUtils getBoolPref:@"follow_request_confirm"] && !confirming) {
        NSLog(@"[PekiWare] Confirm follow request triggered");

        confirming = YES;
        [SCIUtils showConfirmation:^{
            confirming = NO;
            [(id)self _onApproveButtonTapped];
        } cancelHandler:^{
            confirming = NO;
        }];
        return;
    }
    return %orig;
}
- (void)_onIgnoreButtonTapped {
    static BOOL confirmingIgnore = NO;
    if ([SCIUtils getBoolPref:@"follow_request_confirm"] && !confirmingIgnore) {
        NSLog(@"[PekiWare] Confirm follow request triggered");

        confirmingIgnore = YES;
        [SCIUtils showConfirmation:^{
            confirmingIgnore = NO;
            [(id)self _onIgnoreButtonTapped];
        } cancelHandler:^{
            confirmingIgnore = NO;
        }];
        return;
    }
    return %orig;
}
%end
