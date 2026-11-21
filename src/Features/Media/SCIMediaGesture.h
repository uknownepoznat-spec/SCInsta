#import <UIKit/UIKit.h>

// Shared by Objective-C (.m) and Objective-C++ (.xm) translation units.
#ifdef __cplusplus
extern "C" {
#endif

void SCIInstallMediaDownloadGesture(UIView *view, NSString *kind, void (^download)(UIView *view));

#ifdef __cplusplus
}
#endif
