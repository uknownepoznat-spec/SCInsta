#import "SCIMediaGesture.h"
#import "../../Utils.h"
#import <objc/runtime.h>

@interface SCIMediaLongPress : UILongPressGestureRecognizer
@end
@implementation SCIMediaLongPress
@end

@interface SCIMediaGestureHandler : NSObject <UIGestureRecognizerDelegate>
@property (nonatomic, strong) SCIMediaLongPress *gesture;
@property (nonatomic, copy) NSString *kind;
@property (nonatomic, copy) void (^download)(UIView *);
- (void)configure;
- (void)recognize:(UILongPressGestureRecognizer *)gesture;
@end

@implementation SCIMediaGestureHandler
- (void)configure {
    NSDictionary *keys = @{@"feed": @"dw_feed_posts", @"reels": @"dw_reels",
        @"stories": @"dw_story", @"profile": @"save_profile"};
    self.gesture.enabled = [SCIUtils getBoolPref:keys[self.kind]];
    self.gesture.minimumPressDuration = [SCIUtils downloadHoldDurationForKind:self.kind];
    self.gesture.numberOfTouchesRequired = [SCIUtils downloadFingerCountForKind:self.kind];
}
- (void)recognize:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan && gesture.view && self.download) {
        self.download(gesture.view);
    }
}
- (void)settingsChanged:(NSNotification *)notification {
    [self configure];
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)other {
    return ![other isKindOfClass:[SCIMediaLongPress class]];
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end

void SCIInstallMediaDownloadGesture(UIView *view, NSString *kind, void (^download)(UIView *)) {
    static char key;
    SCIMediaGestureHandler *handler = objc_getAssociatedObject(view, &key);
    if (handler) {
        [handler configure];
        return;
    }
    handler = [SCIMediaGestureHandler new];
    handler.kind = kind;
    handler.download = download;
    handler.gesture = [[SCIMediaLongPress alloc] initWithTarget:handler action:@selector(recognize:)];
    handler.gesture.delegate = handler;
    handler.gesture.cancelsTouchesInView = NO;
    [handler configure];
    [view addGestureRecognizer:handler.gesture];
    objc_setAssociatedObject(view, &key, handler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [[NSNotificationCenter defaultCenter] addObserver:handler selector:@selector(settingsChanged:)
        name:SCISettingsDidChangeNotification object:nil];
}
