#import "../../Settings/SCISettingsViewController.h"
#import "../../Appearance/SCITheme.h"
#import <objc/runtime.h>

static char SCISettingsGestureKey;

// Observe the window rather than a private Instagram button class, which can
// change between releases (including liquid-glass navigation).
@interface SCISettingsGestureHandler : NSObject <UIGestureRecognizerDelegate>
- (void)openSettings:(UILongPressGestureRecognizer *)gesture;
@end

@implementation SCISettingsGestureHandler

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldReceiveTouch:(UITouch *)touch {
    UIWindow *window = (UIWindow *)gesture.view;
    if (!window.rootViewController || window.windowLevel != UIWindowLevelNormal) return NO;

    UIViewController *visible = window.rootViewController;
    while (YES) {
        if (visible.presentedViewController) {
            visible = visible.presentedViewController;
        } else if ([visible isKindOfClass:[UINavigationController class]]) {
            visible = ((UINavigationController *)visible).visibleViewController;
        } else if ([visible isKindOfClass:[UITabBarController class]]) {
            visible = ((UITabBarController *)visible).selectedViewController;
        } else {
            break;
        }
        if (!visible) return NO;
    }
    if ([visible isKindOfClass:[SCISettingsViewController class]]) return NO;

    BOOL profileContext = [NSStringFromClass(visible.class).lowercaseString containsString:@"profile"];
    BOOL navigationButton = NO;
    BOOL menuLabel = NO;
    for (UIView *view = touch.view; view && view != window; view = view.superview) {
        NSString *identifier = [view.accessibilityIdentifier.lowercaseString
            stringByReplacingOccurrencesOfString:@"_" withString:@"-"];
        if ([identifier containsString:@"profile-more"]
            || [identifier containsString:@"profile-options"]
            || [identifier containsString:@"profile-settings"]) {
            return YES;
        }

        NSString *label = view.accessibilityLabel.lowercaseString;
        menuLabel |= [label containsString:@"settings"]
            || [label containsString:@"options"]
            || [label containsString:@"more"]
            || [label containsString:@"podešavanja"]
            || [label containsString:@"postavke"];
        NSString *className = NSStringFromClass(view.class).lowercaseString;
        navigationButton |= [view isKindOfClass:[UIControl class]]
            || [className containsString:@"navigationbutton"];

        // The actual profile controller can be a child of Instagram's custom
        // container rather than the selected/visible UIKit controller.
        UIResponder *responder = view.nextResponder;
        if ([responder isKindOfClass:[UIViewController class]]) {
            profileContext |= [NSStringFromClass(responder.class).lowercaseString containsString:@"profile"];
        }
    }

    // Fallback for releases with no accessibility identifier or localized labels.
    // Restrict this to a control in the profile's top-right navigation area.
    CGPoint point = [touch locationInView:window];
    BOOL topRight = point.x >= CGRectGetWidth(window.bounds) - 64
        && point.y >= window.safeAreaInsets.top
        && point.y <= window.safeAreaInsets.top + 64;
    return profileContext && topRight && (navigationButton || menuLabel);
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture
        shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)other {
    // Instagram's existing navigation recognizers must not block our hold.
    return YES;
}

- (void)openSettings:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) return;
    UIWindow *window = (UIWindow *)gesture.view;
    UIViewController *presenter = window.rootViewController;
    while (presenter.presentedViewController) {
        presenter = presenter.presentedViewController;
    }
    if (!presenter || presenter.isBeingDismissed || presenter.isBeingPresented) return;
    if ([presenter isKindOfClass:[UINavigationController class]]
        && [((UINavigationController *)presenter).viewControllers.firstObject
            isKindOfClass:[SCISettingsViewController class]]) return;

    NSLog(@"[Peki Scripter] Opening settings from profile menu hold");
    UINavigationController *navigation = [[UINavigationController alloc]
        initWithRootViewController:[SCISettingsViewController new]];
    [presenter presentViewController:navigation animated:YES completion:nil];
}

@end

%hook UIWindow
- (void)layoutSubviews {
    %orig;
    [SCITheme applyToInstagramWindow:self];
    if (!self.rootViewController || self.windowLevel != UIWindowLevelNormal
        || objc_getAssociatedObject(self, &SCISettingsGestureKey)) return;

    SCISettingsGestureHandler *handler = [SCISettingsGestureHandler new];
    UILongPressGestureRecognizer *gesture = [[UILongPressGestureRecognizer alloc]
        initWithTarget:handler action:@selector(openSettings:)];
    gesture.minimumPressDuration = 0.7;
    gesture.numberOfTouchesRequired = 1;
    gesture.cancelsTouchesInView = YES;
    gesture.delegate = handler;
    [self addGestureRecognizer:gesture];
    // Recognizers don't retain their delegate/target; keep the handler alive.
    objc_setAssociatedObject(self, &SCISettingsGestureKey, handler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%end
