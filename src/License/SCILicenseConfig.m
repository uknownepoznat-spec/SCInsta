#import "SCILicenseConfig.h"

@implementation SCILicenseConfig
+ (BOOL)required { return SCI_LICENSE_REQUIRED != 0; }
+ (NSURL *)baseURL {
    // Public deployment URL; change only when moving the backend.
    // Never put a KeyAux app/seller secret in the iOS source or IPA.
    NSString *address = @"https://peki-keyaux-bridge.uknownepoznat.workers.dev";
    NSURL *url = [NSURL URLWithString:address];
    if ([address containsString:@"YOUR-"] || ![url.scheme isEqualToString:@"https"]
        || !url.host.length || url.user || url.password || url.query || url.fragment || url.path.length > 1) return nil;
    return url;
}
+ (NSString *)appID { return @"mvxsb1isyfo10q2lo1auzklj"; }
+ (NSString *)clientVersion { return @"1.0"; }
+ (NSString *)supportUsername { return @"pekiscripter"; }
@end
