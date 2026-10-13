#import "../../Utils.h"

%hook IGCommentComposer.IGCommentComposerController
- (void)onSendButtonTap {
    static BOOL confirming = NO;
    if ([SCIUtils getBoolPref:@"post_comment_confirm"] && !confirming) {
        NSLog(@"[PekiWare] Confirm post comment triggered");

        confirming = YES;
        [SCIUtils showConfirmation:^{
            confirming = NO;
            [(id)self onSendButtonTap];
        } cancelHandler:^{
            confirming = NO;
        }];
        return;
    }
    return %orig;
}
%end
