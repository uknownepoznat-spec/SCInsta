#import "../../InstagramHeaders.h"
#import "../../Utils.h"

@interface IGDirectThreadThemePickerViewController : UIViewController
- (void)themeNewPickerSectionController:(id)arg1 didSelectTheme:(id)arg2 atIndex:(NSInteger)arg3;
- (void)themePickerSectionController:(id)arg1 didSelectThemeId:(id)arg2;
@end

%hook IGDirectThreadThemePickerViewController
- (void)themeNewPickerSectionController:(id)arg1 didSelectTheme:(id)arg2 atIndex:(NSInteger)arg3 {
    static BOOL confirming = NO;
    if ([SCIUtils getBoolPref:@"change_direct_theme_confirm"] && !confirming) {
        NSLog(@"[PekiWare] Confirm change direct theme triggered");

        confirming = YES;
        [SCIUtils showConfirmation:^{
            confirming = NO;
            [(id)self themeNewPickerSectionController:arg1 didSelectTheme:arg2 atIndex:arg3];
        } cancelHandler:^{
            confirming = NO;
        }];
        return;
    }
    return %orig;
}
- (void)themePickerSectionController:(id)arg1 didSelectThemeId:(id)arg2 {
    static BOOL confirmingId = NO;
    if ([SCIUtils getBoolPref:@"change_direct_theme_confirm"] && !confirmingId) {
        NSLog(@"[PekiWare] Confirm change direct theme triggered");

        confirmingId = YES;
        [SCIUtils showConfirmation:^{
            confirmingId = NO;
            [(id)self themePickerSectionController:arg1 didSelectThemeId:arg2];
        } cancelHandler:^{
            confirmingId = NO;
        }];
        return;
    }
    return %orig;
}
%end

%hook IGDirectThreadThemeKitSwift.IGDirectThreadThemePreviewController
- (void)primaryButtonTapped {
    static BOOL confirmingPrimary = NO;
    if ([SCIUtils getBoolPref:@"change_direct_theme_confirm"] && !confirmingPrimary) {
        NSLog(@"[PekiWare] Confirm change direct theme triggered");

        confirmingPrimary = YES;
        [SCIUtils showConfirmation:^{
            confirmingPrimary = NO;
            [(id)self performSelector:@selector(primaryButtonTapped)];
        } cancelHandler:^{
            confirmingPrimary = NO;
        }];
        return;
    }
    return %orig;
}
%end
