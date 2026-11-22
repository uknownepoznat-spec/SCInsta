#import <UIKit/UIKit.h>

extern NSString * const SCILicenseStateDidChangeNotification;

@interface SCILicenseManager : NSObject <NSURLSessionTaskDelegate>
@property (nonatomic, readonly, getter=isAuthorized) BOOL authorized;
@property (nonatomic, readonly) BOOL busy;
@property (nonatomic, copy, readonly) NSString *message;
@property (nonatomic, copy, readonly) NSString *deviceID;
@property (nonatomic, strong, readonly) NSURL *supportURL;
+ (instancetype)sharedManager;
- (void)considerWindow:(UIWindow *)window;
- (void)submitLicense:(NSString *)key;
- (void)retry;
- (void)forgetLicense;
@end
