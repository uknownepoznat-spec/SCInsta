#import "../../Utils.h"

@interface IGDirectThreadCallButtonsCoordinator : NSObject
- (void)_didTapAudioButton:(id)arg1;
- (void)_didTapVideoButton:(id)arg1;
@end

%hook IGDirectThreadCallButtonsCoordinator
// Voice Call
- (void)_didTapAudioButton:(id)arg1 {
    static BOOL confirmingCall = NO;
    if ([SCIUtils getBoolPref:@"call_confirm"] && !confirmingCall) {
        NSLog(@"[PekiWare] Call confirm triggered");

        confirmingCall = YES;
        [SCIUtils showConfirmation:^{
            confirmingCall = NO;
            [(id)self _didTapAudioButton:arg1];
        } cancelHandler:^{
            confirmingCall = NO;
        }];
        return;
    }
    return %orig;
}

// Video Call
- (void)_didTapVideoButton:(id)arg1 {
    static BOOL confirmingVideoCall = NO;
    if ([SCIUtils getBoolPref:@"call_confirm"] && !confirmingVideoCall) {
        NSLog(@"[PekiWare] Call confirm triggered");

        confirmingVideoCall = YES;
        [SCIUtils showConfirmation:^{
            confirmingVideoCall = NO;
            [(id)self _didTapVideoButton:arg1];
        } cancelHandler:^{
            confirmingVideoCall = NO;
        }];
        return;
    }
    return %orig;
}
%end
