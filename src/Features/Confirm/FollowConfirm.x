#import "../../Utils.h"
#import "../../InstagramHeaders.h"

////////////////////////////////////////////////////////
// NOTE: Never pass %orig through macros or inside blocks.

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
                [self _didPressFollowButton];
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
            [self _onFollowButtonTapped:arg1];
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
            [self _onFollowingButtonTapped:arg1];
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
            [self _didTapAYMFActionButton];
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
            [self _didTapTextActionButton];
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
            [self _hackilyHandleOurOwnButtonTaps:arg1 event:arg2];
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
            [self navigationItemsControllerDidTapHeaderFollowButton:arg1];
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
            [self followButtonTapped:arg1 cell:arg2];
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
