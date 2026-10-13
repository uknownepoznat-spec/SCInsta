#import "../../Utils.h"

@interface IGUFIButtonBarView (SCInstaConfirm)
- (void)_onLikeButtonPressed:(id)arg1;
@end
@interface IGFeedPhotoView (SCInstaConfirm)
- (void)_onDoubleTap:(id)arg1;
@end
@interface IGVideoPlayerOverlayContainerView (SCInstaConfirm)
- (void)_handleDoubleTapGesture:(id)arg1;
@end
@interface IGSundialViewerVideoCell (SCInstaConfirm)
- (void)controlsOverlayControllerDidTapLikeButton:(id)arg1;
- (void)controlsOverlayControllerDidLongPressLikeButton:(id)arg1 gestureRecognizer:(id)arg2;
- (void)gestureController:(id)arg1 didObserveDoubleTap:(id)arg2;
@end
@interface IGSundialViewerPhotoCell (SCInstaConfirm)
- (void)controlsOverlayControllerDidTapLikeButton:(id)arg1;
- (void)gestureController:(id)arg1 didObserveDoubleTap:(id)arg2;
@end
@interface IGSundialViewerCarouselCell (SCInstaConfirm)
- (void)controlsOverlayControllerDidTapLikeButton:(id)arg1;
- (void)gestureController:(id)arg1 didObserveDoubleTap:(id)arg2;
@end
@interface IGCommentCellController (SCInstaConfirm)
- (void)commentCell:(id)arg1 didTapLikeButton:(id)arg2;
- (void)commentCell:(id)arg1 didTapLikedByButtonForUser:(id)arg2;
- (void)commentCellDidLongPressOnLikeButton:(id)arg1;
- (void)commentCellDidEndLongPressOnLikeButton:(id)arg1;
- (void)commentCellDidDoubleTap:(id)arg1;
@end
@interface IGFeedItemPreviewCommentCell (SCInstaConfirm)
- (void)_didTapLikeButton;
@end
@interface IGStoryFullscreenDefaultFooterView (SCInstaConfirm)
- (void)_handleLikeTapped;
- (void)_likeTapped;
- (void)inputView:(id)arg1 didTapLikeButton:(id)arg2;
@end
@interface IGDirectThreadViewController (SCInstaLikeConfirm)
- (void)_didTapLikeButton;
@end

// Liking posts
%hook IGUFIButtonBarView
- (void)_onLikeButtonPressed:(id)arg1 {
    static BOOL confirming = NO;
    if ([SCIUtils getBoolPref:@"like_confirm"] && !confirming) {
        NSLog(@"[PekiWare] Confirm post like triggered");
        confirming = YES;
        [SCIUtils showConfirmation:^{
            confirming = NO;
            [(id)self _onLikeButtonPressed:arg1];
        } cancelHandler:^{
            confirming = NO;
        }];
        return;
    }
    return %orig;
}
%end
%hook IGFeedPhotoView
- (void)_onDoubleTap:(id)arg1 {
    static BOOL confirming = NO;
    if ([SCIUtils getBoolPref:@"like_confirm"] && !confirming) {
        NSLog(@"[PekiWare] Confirm post like triggered");
        confirming = YES;
        [SCIUtils showConfirmation:^{
            confirming = NO;
            [(id)self _onDoubleTap:arg1];
        } cancelHandler:^{
            confirming = NO;
        }];
        return;
    }
    return %orig;
}
%end
%hook IGVideoPlayerOverlayContainerView
- (void)_handleDoubleTapGesture:(id)arg1 {
    static BOOL confirming = NO;
    if ([SCIUtils getBoolPref:@"like_confirm"] && !confirming) {
        NSLog(@"[PekiWare] Confirm post like triggered");
        confirming = YES;
        [SCIUtils showConfirmation:^{
            confirming = NO;
            [(id)self _handleDoubleTapGesture:arg1];
        } cancelHandler:^{
            confirming = NO;
        }];
        return;
    }
    return %orig;
}
%end

// Liking reels
%hook IGSundialViewerVideoCell
- (void)controlsOverlayControllerDidTapLikeButton:(id)arg1 {
    static BOOL confirming = NO;
    if ([SCIUtils getBoolPref:@"like_confirm_reels"] && !confirming) {
        NSLog(@"[PekiWare] Confirm reels like triggered");
        confirming = YES;
        [SCIUtils showConfirmation:^{
            confirming = NO;
            [(id)self controlsOverlayControllerDidTapLikeButton:arg1];
        } cancelHandler:^{
            confirming = NO;
        }];
        return;
    }
    return %orig;
}
- (void)controlsOverlayControllerDidLongPressLikeButton:(id)arg1 gestureRecognizer:(id)arg2 {
    static BOOL confirming = NO;
    if ([SCIUtils getBoolPref:@"like_confirm_reels"] && !confirming) {
        NSLog(@"[PekiWare] Confirm reels like triggered");
        confirming = YES;
        [SCIUtils showConfirmation:^{
            confirming = NO;
            [(id)self controlsOverlayControllerDidLongPressLikeButton:arg1 gestureRecognizer:arg2];
        } cancelHandler:^{
            confirming = NO;
        }];
        return;
    }
    return %orig;
}
- (void)gestureController:(id)arg1 didObserveDoubleTap:(id)arg2 {
    static BOOL confirming = NO;
    if ([SCIUtils getBoolPref:@"like_confirm_reels"] && !confirming) {
        NSLog(@"[PekiWare] Confirm reels like triggered");
        confirming = YES;
        [SCIUtils showConfirmation:^{
            confirming = NO;
            [(id)self gestureController:arg1 didObserveDoubleTap:arg2];
        } cancelHandler:^{
            confirming = NO;
        }];
        return;
    }
    return %orig;
}
%end
%hook IGSundialViewerPhotoCell
- (void)controlsOverlayControllerDidTapLikeButton:(id)arg1 {
    static BOOL confirming = NO;
    if ([SCIUtils getBoolPref:@"like_confirm_reels"] && !confirming) {
        NSLog(@"[PekiWare] Confirm reels like triggered");
        confirming = YES;
        [SCIUtils showConfirmation:^{
            confirming = NO;
            [(id)self controlsOverlayControllerDidTapLikeButton:arg1];
        } cancelHandler:^{
            confirming = NO;
        }];
        return;
    }
    return %orig;
}
- (void)gestureController:(id)arg1 didObserveDoubleTap:(id)arg2 {
    static BOOL confirming = NO;
    if ([SCIUtils getBoolPref:@"like_confirm_reels"] && !confirming) {
        NSLog(@"[PekiWare] Confirm reels like triggered");
        confirming = YES;
        [SCIUtils showConfirmation:^{
            confirming = NO;
            [(id)self gestureController:arg1 didObserveDoubleTap:arg2];
        } cancelHandler:^{
            confirming = NO;
        }];
        return;
    }
    return %orig;
}
%end
%hook IGSundialViewerCarouselCell
- (void)controlsOverlayControllerDidTapLikeButton:(id)arg1 {
    static BOOL confirming = NO;
    if ([SCIUtils getBoolPref:@"like_confirm_reels"] && !confirming) {
        NSLog(@"[PekiWare] Confirm reels like triggered");
        confirming = YES;
        [SCIUtils showConfirmation:^{
            confirming = NO;
            [(id)self controlsOverlayControllerDidTapLikeButton:arg1];
        } cancelHandler:^{
            confirming = NO;
        }];
        return;
    }
    return %orig;
}
- (void)gestureController:(id)arg1 didObserveDoubleTap:(id)arg2 {
    static BOOL confirming = NO;
    if ([SCIUtils getBoolPref:@"like_confirm_reels"] && !confirming) {
        NSLog(@"[PekiWare] Confirm reels like triggered");
        confirming = YES;
        [SCIUtils showConfirmation:^{
            confirming = NO;
            [(id)self gestureController:arg1 didObserveDoubleTap:arg2];
        } cancelHandler:^{
            confirming = NO;
        }];
        return;
    }
    return %orig;
}
%end

// Liking comments
%hook IGCommentCellController
- (void)commentCell:(id)arg1 didTapLikeButton:(id)arg2 {
    static BOOL confirming = NO;
    if ([SCIUtils getBoolPref:@"like_confirm"] && !confirming) {
        NSLog(@"[PekiWare] Confirm post like triggered");
        confirming = YES;
        [SCIUtils showConfirmation:^{
            confirming = NO;
            [(id)self commentCell:arg1 didTapLikeButton:arg2];
        } cancelHandler:^{
            confirming = NO;
        }];
        return;
    }
    return %orig;
}
- (void)commentCell:(id)arg1 didTapLikedByButtonForUser:(id)arg2 {
    static BOOL confirming = NO;
    if ([SCIUtils getBoolPref:@"like_confirm"] && !confirming) {
        NSLog(@"[PekiWare] Confirm post like triggered");
        confirming = YES;
        [SCIUtils showConfirmation:^{
            confirming = NO;
            [(id)self commentCell:arg1 didTapLikedByButtonForUser:arg2];
        } cancelHandler:^{
            confirming = NO;
        }];
        return;
    }
    return %orig;
}
- (void)commentCellDidLongPressOnLikeButton:(id)arg1 {
    static BOOL confirming = NO;
    if ([SCIUtils getBoolPref:@"like_confirm"] && !confirming) {
        NSLog(@"[PekiWare] Confirm post like triggered");
        confirming = YES;
        [SCIUtils showConfirmation:^{
            confirming = NO;
            [(id)self commentCellDidLongPressOnLikeButton:arg1];
        } cancelHandler:^{
            confirming = NO;
        }];
        return;
    }
    return %orig;
}
- (void)commentCellDidEndLongPressOnLikeButton:(id)arg1 {
    static BOOL confirming = NO;
    if ([SCIUtils getBoolPref:@"like_confirm"] && !confirming) {
        NSLog(@"[PekiWare] Confirm post like triggered");
        confirming = YES;
        [SCIUtils showConfirmation:^{
            confirming = NO;
            [(id)self commentCellDidEndLongPressOnLikeButton:arg1];
        } cancelHandler:^{
            confirming = NO;
        }];
        return;
    }
    return %orig;
}
- (void)commentCellDidDoubleTap:(id)arg1 {
    static BOOL confirming = NO;
    if ([SCIUtils getBoolPref:@"like_confirm"] && !confirming) {
        NSLog(@"[PekiWare] Confirm post like triggered");
        confirming = YES;
        [SCIUtils showConfirmation:^{
            confirming = NO;
            [(id)self commentCellDidDoubleTap:arg1];
        } cancelHandler:^{
            confirming = NO;
        }];
        return;
    }
    return %orig;
}
%end
%hook IGFeedItemPreviewCommentCell
- (void)_didTapLikeButton {
    static BOOL confirming = NO;
    if ([SCIUtils getBoolPref:@"like_confirm"] && !confirming) {
        NSLog(@"[PekiWare] Confirm post like triggered");
        confirming = YES;
        [SCIUtils showConfirmation:^{
            confirming = NO;
            [(id)self _didTapLikeButton];
        } cancelHandler:^{
            confirming = NO;
        }];
        return;
    }
    return %orig;
}
%end

// Liking stories
%hook IGStoryFullscreenDefaultFooterView
- (void)_handleLikeTapped {
    static BOOL confirming = NO;
    if ([SCIUtils getBoolPref:@"like_confirm"] && !confirming) {
        NSLog(@"[PekiWare] Confirm post like triggered");
        confirming = YES;
        [SCIUtils showConfirmation:^{
            confirming = NO;
            [(id)self _handleLikeTapped];
        } cancelHandler:^{
            confirming = NO;
        }];
        return;
    }
    return %orig;
}
- (void)_likeTapped {
    static BOOL confirming = NO;
    if ([SCIUtils getBoolPref:@"like_confirm"] && !confirming) {
        NSLog(@"[PekiWare] Confirm post like triggered");
        confirming = YES;
        [SCIUtils showConfirmation:^{
            confirming = NO;
            [(id)self _likeTapped];
        } cancelHandler:^{
            confirming = NO;
        }];
        return;
    }
    return %orig;
}
- (void)inputView:(id)arg1 didTapLikeButton:(id)arg2 {
    static BOOL confirming = NO;
    if ([SCIUtils getBoolPref:@"like_confirm"] && !confirming) {
        NSLog(@"[PekiWare] Confirm post like triggered");
        confirming = YES;
        [SCIUtils showConfirmation:^{
            confirming = NO;
            [(id)self inputView:arg1 didTapLikeButton:arg2];
        } cancelHandler:^{
            confirming = NO;
        }];
        return;
    }
    return %orig;
}
%end

// DM like button (seems to be hidden)
%hook IGDirectThreadViewController
- (void)_didTapLikeButton {
    static BOOL confirming = NO;
    if ([SCIUtils getBoolPref:@"like_confirm"] && !confirming) {
        NSLog(@"[PekiWare] Confirm post like triggered");
        confirming = YES;
        [SCIUtils showConfirmation:^{
            confirming = NO;
            [(id)self _didTapLikeButton];
        } cancelHandler:^{
            confirming = NO;
        }];
        return;
    }
    return %orig;
}
%end
