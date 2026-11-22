#import <Foundation/Foundation.h>

#ifndef SCI_LICENSE_REQUIRED
#define SCI_LICENSE_REQUIRED 1
#endif

@interface SCILicenseConfig : NSObject
+ (BOOL)required;
+ (NSURL *)baseURL;
+ (NSString *)appID;
+ (NSString *)clientVersion;
+ (NSString *)supportUsername;
@end
