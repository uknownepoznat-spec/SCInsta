#import "SCITheme.h"
#import "../Utils.h"
#import <objc/runtime.h>
#import <math.h>

@interface SCIWindowAppearanceState : NSObject
@property (nonatomic, weak) UIViewController *root;
@property (nonatomic, strong) UIColor *originalTint;
@property (nonatomic) UIUserInterfaceStyle originalStyle;
@property (nonatomic) NSUInteger revision;
@end
@implementation SCIWindowAppearanceState
@end

static char SCIWindowAppearanceKey;
static NSUInteger SCIThemeRevision = 1;

static CGFloat SCILuminance(UIColor *color) {
    CGFloat red = 0, green = 0, blue = 0, alpha = 1;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    CGFloat components[] = {red, green, blue};
    for (NSUInteger index = 0; index < 3; index++) {
        CGFloat value = components[index];
        components[index] = value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4);
    }
    return components[0] * 0.2126 + components[1] * 0.7152 + components[2] * 0.0722;
}

static UIColor *SCITextOn(UIColor *color) {
    CGFloat luminance = SCILuminance(color);
    CGFloat whiteContrast = 1.05 / (luminance + 0.05);
    CGFloat blackContrast = (luminance + 0.05) / 0.05;
    return whiteContrast > blackContrast ? UIColor.whiteColor : UIColor.blackColor;
}

// Never theme LiveContainer's launcher or unrelated windows. Only accept an
// Instagram-owned root hierarchy; a presented guest on a host root is skipped.
static BOOL SCIInstagramOwnsRoot(UIViewController *root) {
    if (!root) return NO;
    NSString *name = NSStringFromClass(root.class);
    if ([name hasPrefix:@"LC"] || [name containsString:@"LiveContainer"]) return NO;
    if ([name hasPrefix:@"IG"]) return YES;
    if ([root isKindOfClass:[UINavigationController class]]) {
        return SCIInstagramOwnsRoot(((UINavigationController *)root).viewControllers.firstObject);
    }
    if ([root isKindOfClass:[UITabBarController class]]) {
        for (UIViewController *controller in ((UITabBarController *)root).viewControllers) {
            if (SCIInstagramOwnsRoot(controller)) return YES;
        }
    }
    return NO;
}

static BOOL SCILiveContainerOwnsRoot(UIViewController *root) {
    if (!root) return NO;
    NSString *name = NSStringFromClass(root.class);
    if ([name hasPrefix:@"LC"] || [name containsString:@"LiveContainer"]) return YES;
    if ([root isKindOfClass:UINavigationController.class]) {
        return SCILiveContainerOwnsRoot(((UINavigationController *)root).viewControllers.firstObject);
    }
    if ([root isKindOfClass:UITabBarController.class]) {
        for (UIViewController *controller in ((UITabBarController *)root).viewControllers) {
            if (SCILiveContainerOwnsRoot(controller)) return YES;
        }
    }
    return NO;
}

@implementation SCITheme
+ (NSArray<NSDictionary<NSString *,NSString *> *> *)presets {
    static NSArray *themes;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        // id, display name, background, surface, accent. Solid colors only.
        NSArray *rows = @[
            @[@"carbon", @"Carbon", @"0D0F12", @"171A1F", @"A8BACD"],
            @[@"midnight", @"Midnight", @"0C111B", @"151E2C", @"80ADFF"],
            @[@"graphite", @"Graphite", @"171717", @"242424", @"C9CED6"],
            @[@"oled", @"OLED black", @"000000", @"0B0B0B", @"E4E8EF"],
            @[@"slate", @"Slate", @"121B23", @"1C2935", @"9CC5DF"],
            @[@"ocean", @"Ocean", @"08171D", @"10272F", @"68D3D6"],
            @[@"forest", @"Forest", @"0C1712", @"17291E", @"8DCCAA"],
            @[@"moss", @"Moss", @"14180F", @"252C1B", @"BECF84"],
            @[@"espresso", @"Espresso", @"17120F", @"291F19", @"D0AA82"],
            @[@"copper", @"Copper", @"1C1411", @"2D201A", @"DFAC8B"],
            @[@"burgundy", @"Burgundy", @"1B1015", @"2F1B24", @"E6A1B7"],
            @[@"indigo", @"Indigo", @"121322", @"202239", @"AAAEEA"],
            @[@"dusk", @"Dusk", @"191622", @"2B2537", @"C2B0DF"],
            @[@"paper", @"Paper", @"F2F3F5", @"FFFFFF", @"315A9C"],
            @[@"pearl", @"Pearl", @"EAF0F4", @"FFFFFF", @"3C607C"],
            @[@"sand", @"Sand", @"EDE8DE", @"FAF8F2", @"75572D"]
        ];
        NSMutableArray *result = [NSMutableArray new];
        for (NSArray *row in rows) {
            [result addObject:@{@"id": row[0], @"name": row[1], @"background": row[2],
                @"surface": row[3], @"accent": row[4]}];
        }
        themes = [result copy];
    });
    return themes;
}

+ (NSDictionary *)selectedPreset {
    NSString *identifier = [SCIUtils getStringPref:@"settings_theme"];
    for (NSDictionary *preset in [self presets]) {
        if ([preset[@"id"] isEqualToString:identifier]) return preset;
    }
    return [self presets].firstObject;
}

+ (NSString *)normalizedHex:(NSString *)hex {
    if (![hex isKindOfClass:[NSString class]]) return nil;
    NSString *value = [[hex stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] uppercaseString];
    if ([value hasPrefix:@"#"]) value = [value substringFromIndex:1];
    if (value.length != 6) return nil;
    NSCharacterSet *invalid = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCDEF"] invertedSet];
    return [value rangeOfCharacterFromSet:invalid].location == NSNotFound ? value : nil;
}

+ (UIColor *)colorFromHex:(NSString *)hex fallback:(UIColor *)fallback {
    NSString *value = [self normalizedHex:hex];
    if (!value) return fallback;
    unsigned int rgb = 0;
    [[NSScanner scannerWithString:value] scanHexInt:&rgb];
    return [UIColor colorWithRed:((rgb >> 16) & 255) / 255.0
        green:((rgb >> 8) & 255) / 255.0 blue:(rgb & 255) / 255.0 alpha:1];
}

+ (NSString *)hexFromColor:(UIColor *)color {
    CGFloat red = 0, green = 0, blue = 0, alpha = 1;
    if (![color getRed:&red green:&green blue:&blue alpha:&alpha]) return @"808080";
    red = MAX(0, MIN(1, red));
    green = MAX(0, MIN(1, green));
    blue = MAX(0, MIN(1, blue));
    return [NSString stringWithFormat:@"%02X%02X%02X", (unsigned int)lround(red * 255),
        (unsigned int)lround(green * 255), (unsigned int)lround(blue * 255)];
}

+ (NSString *)name {
    return [[SCIUtils getStringPref:@"settings_theme"] isEqualToString:@"custom"] ? @"Custom" : [self selectedPreset][@"name"];
}

+ (UIColor *)colorForComponent:(NSString *)component {
    NSString *hex = [self selectedPreset][component];
    if ([[SCIUtils getStringPref:@"settings_theme"] isEqualToString:@"custom"]) {
        NSString *custom = [SCIUtils getStringPref:[@"settings_custom_" stringByAppendingString:component]];
        if ([self normalizedHex:custom]) hex = custom;
    }
    return [self colorFromHex:hex fallback:UIColor.blackColor];
}

+ (UIColor *)backgroundColor { return [self colorForComponent:@"background"]; }
+ (UIColor *)surfaceColor { return [self colorForComponent:@"surface"]; }
+ (UIColor *)textColor { return SCITextOn([self backgroundColor]); }
+ (UIColor *)cellTextColor { return SCITextOn([self surfaceColor]); }
+ (UIColor *)secondaryTextColor { return [[self textColor] colorWithAlphaComponent:0.60]; }
+ (UIColor *)cellSecondaryTextColor { return [[self cellTextColor] colorWithAlphaComponent:0.62]; }
+ (UIColor *)borderColor { return [[self cellTextColor] colorWithAlphaComponent:0.08]; }
+ (UIUserInterfaceStyle)interfaceStyle {
    return SCILuminance([self backgroundColor]) > 0.18 ? UIUserInterfaceStyleLight : UIUserInterfaceStyleDark;
}

+ (UIColor *)accentColor {
    NSString *selection = [SCIUtils getStringPref:@"settings_accent"];
    if ([selection isEqualToString:@"white"]) return [self cellTextColor];
    NSDictionary *accents = @{@"blue": @"4F8CFF", @"ice": @"50D1EB", @"mint": @"74D6B2",
        @"lime": @"B2DB6C", @"amber": @"E7BE76", @"copper": @"D5A384", @"red": @"EC8D8D",
        @"rose": @"E2A3BC", @"indigo": @"ABAFF0"};
    if ([selection isEqualToString:@"custom"]) {
        return [self colorFromHex:[SCIUtils getStringPref:@"settings_custom_accent"] fallback:[self colorForComponent:@"accent"]];
    }
    return accents[selection] ? [self colorFromHex:accents[selection] fallback:UIColor.systemBlueColor]
        : [self colorForComponent:@"accent"];
}

+ (UIColor *)nativeAccentColor {
    UIColor *selected = [self accentColor];
    // Keep tweak buttons visible on Instagram's light or dark native surface,
    // independent of the separately selected custom-menu surface.
    return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traits) {
        UIColor *background = [UIColor.systemBackgroundColor resolvedColorWithTraitCollection:traits];
        CGFloat backgroundLuminance = SCILuminance(background);
        CGFloat red = 0, green = 0, blue = 0, alpha = 1;
        [selected getRed:&red green:&green blue:&blue alpha:&alpha];
        CGFloat target = backgroundLuminance > 0.18 ? 0 : 1;
        for (NSUInteger step = 0; step <= 10; step++) {
            CGFloat blend = step / 10.0;
            UIColor *candidate = [UIColor colorWithRed:red + (target - red) * blend
                green:green + (target - green) * blend blue:blue + (target - blue) * blend alpha:1];
            CGFloat luminance = SCILuminance(candidate);
            CGFloat contrast = (MAX(luminance, backgroundLuminance) + 0.05)
                / (MIN(luminance, backgroundLuminance) + 0.05);
            if (contrast >= 3.0) return candidate;
        }
        return target == 0 ? UIColor.blackColor : UIColor.whiteColor;
    }];
}

+ (void)observeSettings {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(settingsChanged:)
            name:SCISettingsDidChangeNotification object:nil];
    });
}

+ (void)settingsChanged:(NSNotification *)notification {
    if (!NSThread.isMainThread) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self settingsChanged:notification]; });
        return;
    }
    SCIThemeRevision++;
    [self refreshInstagramWindows];
}

+ (void)restoreWindow:(UIWindow *)window state:(SCIWindowAppearanceState *)state {
    if (!state) return;
    window.tintColor = state.originalTint;
    window.overrideUserInterfaceStyle = state.originalStyle;
    objc_setAssociatedObject(window, &SCIWindowAppearanceKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void)applyToInstagramWindow:(UIWindow *)window {
    [self observeSettings];
    SCIWindowAppearanceState *state = objc_getAssociatedObject(window, &SCIWindowAppearanceKey);
    UIViewController *root = window.rootViewController;
    if (state && state.root != root) {
        [self restoreWindow:window state:state];
        state = nil;
    }
    if (state && !SCIInstagramOwnsRoot(root)) {
        [self restoreWindow:window state:state];
        return;
    }
    if (state && state.revision == SCIThemeRevision) return;
    NSString *mode = [SCIUtils getStringPref:@"instagram_appearance"];
    BOOL tint = [SCIUtils getBoolPref:@"instagram_theme_accent"];
    BOOL overrideStyle = [mode isEqualToString:@"dark"] || [mode isEqualToString:@"light"];
    if ((!tint && !overrideStyle) || window.windowLevel != UIWindowLevelNormal || !SCIInstagramOwnsRoot(root)) {
        [self restoreWindow:window state:state];
        return;
    }
    if (!state) {
        state = [SCIWindowAppearanceState new];
        state.root = root;
        state.originalTint = window.tintColor;
        state.originalStyle = window.overrideUserInterfaceStyle;
        objc_setAssociatedObject(window, &SCIWindowAppearanceKey, state, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    state.revision = SCIThemeRevision;
    window.overrideUserInterfaceStyle = [mode isEqualToString:@"dark"] ? UIUserInterfaceStyleDark
        : [mode isEqualToString:@"light"] ? UIUserInterfaceStyleLight : state.originalStyle;
    window.tintColor = tint ? [self nativeAccentColor] : state.originalTint;
}

+ (BOOL)isInstagramWindow:(UIWindow *)window {
    return window && window.windowLevel == UIWindowLevelNormal && SCIInstagramOwnsRoot(window.rootViewController);
}

+ (BOOL)isLiveContainerWindow:(UIWindow *)window {
    return window && window.windowLevel == UIWindowLevelNormal && SCILiveContainerOwnsRoot(window.rootViewController);
}

+ (void)refreshInstagramWindows {
    if (!NSThread.isMainThread) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self refreshInstagramWindows]; });
        return;
    }
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) continue;
        for (UIWindow *window in ((UIWindowScene *)scene).windows) [self applyToInstagramWindow:window];
    }
    // Some LiveContainer guest apps use the legacy window lifecycle.
    for (UIWindow *window in UIApplication.sharedApplication.windows) [self applyToInstagramWindow:window];
}
@end
