#import "../../Utils.h"
#import "../../InstagramHeaders.h"

@interface IGFollowController (SCInstaConfirm)
- (void)_didPressFollowButton;
@end
@interface IGDiscoverPeopleButtonGroupView (SCInstaConfirm)
- (void)_onFollowButtonTapped:(id)arg1;
- (void)_onFollowingButtonTapped:(id)arg1;
@end
@interface IGHScrollAYMFCell (SCInstaConfirm)
- (void)_didTapAYMFActionButton;
@end
@interface IGHScrollAYMFActionButton (SCInstaConfirm)
- (void)_didTapTextActionButton;
@end
@interface IGUnifiedVideoFollowButton (SCInstaConfirm)
- (void)_hackilyHandleOurOwnButtonTaps:(id)arg1 event:(id)arg2;
@end
@interface IGProfileViewController (SCInstaConfirm)
- (void)navigationItemsControllerDidTapHeaderFollowButton:(id)arg1;
@end
@interface IGStorySectionController (SCInstaConfirm)
- (void)followButtonTapped:(id)arg1 cell:(id)arg2;
@end

// Follow button on profile page
%hook IGFollowController
- (void)_didPressFollowButton {
    // Get user follow status (check if already following user)
    NSInteger UserFollowStatus = self.user.followStatus;

    // Only show confirm dialog if user is not following
    if (UserFollowStatus == 2) {
        static BOOL confirming = NO;
        if ([SCIUtils getBoolPref:@"follow_confirm"] && !confirming) {
            NSLog(@"[PekiWare] Confirm follow triggered");
            confirming = YES;
            [SCIUtils showConfirmation:^{
                confirming = NO;
                [(id)self _didPressFollowButton];
            } cancelHandler:^{
                confirming = NO;
            }];
            return;
        }
        return %orig;
    }
    else {
        return %orig;
    }
}
%end

// Follow button on discover people page
%hook IGDiscoverPeopleButtonGroupView
- (void)_onFollowButtonTapped:(id)arg1 {
    static BOOL confirming = NO;
    if ([SCIUtils getBoolPref:@"follow_confirm"] && !confirming) {
        NSLog(@"[PekiWare] Confirm follow triggered");
        confirming = YES;
        [SCIUtils showConfirmation:^{
            confirming = NO;
            [(id)self _onFollowButtonTapped:arg1];
        } cancelHandler:^{
            confirming = NO;
        }];
        return;
    }
    return %orig;
}
- (void)_onFollowingButtonTapped:(id)arg1 {
    static BOOL confirming = NO;
    if ([SCIUtils getBoolPref:@"follow_confirm"] && !confirming) {
        NSLog(@"[PekiWare] Confirm follow triggered");
        confirming = YES;
        [SCIUtils showConfirmation:^{
            confirming = NO;
            [(id)self _onFollowingButtonTapped:arg1];
        } cancelHandler:^{
            confirming = NO;
        }];
        return;
    }
    return %orig;
}
%end

// Suggested for you (home feed & profile) follow button
%hook IGHScrollAYMFCell
- (void)_didTapAYMFActionButton {
    static BOOL confirming = NO;
    if ([SCIUtils getBoolPref:@"follow_confirm"] && !confirming) {
        NSLog(@"[PekiWare] Confirm follow triggered");
        confirming = YES;
        [SCIUtils showConfirmation:^{
            confirming = NO;
            [(id)self _didTapAYMFActionButton];
        } cancelHandler:^{
            confirming = NO;
        }];
        return;
    }
    return %orig;
}
%end
%hook IGHScrollAYMFActionButton
- (void)_didTapTextActionButton {
    static BOOL confirming = NO;
    if ([SCIUtils getBoolPref:@"follow_confirm"] && !confirming) {
        NSLog(@"[PekiWare] Confirm follow triggered");
        confirming = YES;
        [SCIUtils showConfirmation:^{
            confirming = NO;
            [(id)self _didTapTextActionButton];
        } cancelHandler:^{
            confirming = NO;
        }];
        return;
    }
    return %orig;
}
%end

// Follow button on reels
%hook IGUnifiedVideoFollowButton
- (void)_hackilyHandleOurOwnButtonTaps:(id)arg1 event:(id)arg2 {
    static BOOL confirming = NO;
    if ([SCIUtils getBoolPref:@"follow_confirm"] && !confirming) {
        NSLog(@"[PekiWare] Confirm follow triggered");
        confirming = YES;
        [SCIUtils showConfirmation:^{
            confirming = NO;
            [(id)self _hackilyHandleOurOwnButtonTaps:arg1 event:arg2];
        } cancelHandler:^{
            confirming = NO;
        }];
        return;
    }
    return %orig;
}
%end

// Follow text on profile (when collapsed into top bar) 
%hook IGProfileViewController
- (void)navigationItemsControllerDidTapHeaderFollowButton:(id)arg1 {
    static BOOL confirming = NO;
    if ([SCIUtils getBoolPref:@"follow_confirm"] && !confirming) {
        NSLog(@"[PekiWare] Confirm follow triggered");
        confirming = YES;
        [SCIUtils showConfirmation:^{
            confirming = NO;
            [(id)self navigationItemsControllerDidTapHeaderFollowButton:arg1];
        } cancelHandler:^{
            confirming = NO;
        }];
        return;
    }
    return %orig;
}
%end

// Follow button on suggested friends (in story section)
%hook IGStorySectionController
- (void)followButtonTapped:(id)arg1 cell:(id)arg2 {
    static BOOL confirming = NO;
    if ([SCIUtils getBoolPref:@"follow_confirm"] && !confirming) {
        NSLog(@"[PekiWare] Confirm follow triggered");
        confirming = YES;
        [SCIUtils showConfirmation:^{
            confirming = NO;
            [(id)self followButtonTapped:arg1 cell:arg2];
        } cancelHandler:^{
            confirming = NO;
        }];
        return;
    }
    return %orig;
}
%end

// Follow all button in group chats (3+ members) people view
static void (*orig_listSectionController)(id, SEL, id, id);

static void hooked_listSectionController(id self, SEL _cmd, id arg1, id arg2) {
    if ([SCIUtils getBoolPref:@"follow_confirm"]) {

        [SCIUtils showConfirmation:^{
            orig_listSectionController(self, _cmd, arg1, arg2);
        }];

        return;
    }

    orig_listSectionController(self, _cmd, arg1, arg2);
}

%ctor {
    Class cls = objc_getClass("IGDirectDetailMembersKit.IGDirectThreadDetailsMembersListViewController");
    if (!cls) return;

    MSHookMessageEx(
        cls,
        @selector(listSectionController:didTapHeaderButtonWithViewModel:),
        (IMP)hooked_listSectionController,
        (IMP *)&orig_listSectionController
    );
}
