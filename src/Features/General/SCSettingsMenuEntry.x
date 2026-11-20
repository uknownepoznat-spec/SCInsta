#import "../../InstagramHeaders.h"
#import "../../Settings/SCISettingsViewController.h"
#import <objc/runtime.h>

// Show Peki Scripter tweak settings by holding on the settings/more icon under profile for ~1 second
static char SCILongPressInstalledKey;

%hook IGBadgedNavigationButton
- (void)didMoveToWindow {
    %orig;
    [self scInstallSettingsLongPressIfNeeded];
}

- (void)layoutSubviews {
    %orig;
    [self scInstallSettingsLongPressIfNeeded];
}

%new - (void)scInstallSettingsLongPressIfNeeded {
    NSString *identifier = [self.accessibilityIdentifier.lowercaseString stringByReplacingOccurrencesOfString:@"_" withString:@"-"];
    NSString *label = self.accessibilityLabel.lowercaseString;
    if ([identifier containsString:@"profile-more"]
        || [identifier containsString:@"profile-options"]
        || [identifier containsString:@"profile-settings"]
        || [label containsString:@"settings"]
        || [label containsString:@"options"]
        || [label containsString:@"more"]) {
        [self addLongPressGestureRecognizer];
    }
}

%new - (void)addLongPressGestureRecognizer {
    if (!objc_getAssociatedObject(self, &SCILongPressInstalledKey)) {
        NSLog(@"[Peki Scripter] Adding tweak settings long press gesture recognizer");

        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        longPress.minimumPressDuration = 0.8;
        longPress.cancelsTouchesInView = NO;
        [self addGestureRecognizer:longPress];
        objc_setAssociatedObject(self, &SCILongPressInstalledKey, longPress, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}
%new - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) return;
    
    NSLog(@"[Peki Scripter] Tweak settings gesture activated");

    UIViewController *presenter = [[self window] rootViewController];
    while (presenter.presentedViewController != nil) {
        presenter = presenter.presentedViewController;
    }
    if ([presenter isKindOfClass:[UINavigationController class]]
        && [((UINavigationController *)presenter).viewControllers.firstObject isKindOfClass:[SCISettingsViewController class]]) {
        return;
    }

    SCISettingsViewController *settingsViewController = [SCISettingsViewController new];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
    
    [presenter presentViewController:navigationController animated:YES completion:nil];
}
%end
