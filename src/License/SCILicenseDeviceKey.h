#import <Foundation/Foundation.h>

@interface SCILicenseDeviceKey : NSObject
@property (nonatomic, copy, readonly) NSString *deviceID;
@property (nonatomic, copy, readonly) NSString *publicKeyBase64;
- (instancetype)initWithError:(NSError **)error;
- (NSString *)signMessage:(NSString *)message error:(NSError **)error;
- (NSString *)storedLicense;
- (BOOL)storeLicense:(NSString *)license;
- (void)removeStoredLicense;
+ (NSString *)sha256Data:(NSData *)data;
+ (NSString *)sha256String:(NSString *)string;
@end
