#import <UIKit/UIKit.h>

@interface SCITheme : NSObject
+ (NSArray<NSDictionary<NSString *, NSString *> *> *)presets;
+ (NSString *)name;
+ (UIColor *)backgroundColor;
+ (UIColor *)surfaceColor;
+ (UIColor *)textColor;
+ (UIColor *)secondaryTextColor;
+ (UIColor *)cellTextColor;
+ (UIColor *)cellSecondaryTextColor;
+ (UIColor *)borderColor;
+ (UIColor *)accentColor;
+ (UIColor *)nativeAccentColor;
+ (UIUserInterfaceStyle)interfaceStyle;
+ (NSString *)normalizedHex:(NSString *)hex;
+ (UIColor *)colorFromHex:(NSString *)hex fallback:(UIColor *)fallback;
+ (NSString *)hexFromColor:(UIColor *)color;
+ (void)applyToInstagramWindow:(UIWindow *)window;
+ (BOOL)isInstagramWindow:(UIWindow *)window;
+ (BOOL)isLiveContainerWindow:(UIWindow *)window;
+ (void)refreshInstagramWindows;
@end
