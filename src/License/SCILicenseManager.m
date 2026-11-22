#import "SCILicenseManager.h"
#import "SCILicenseConfig.h"
#import "SCILicenseDeviceKey.h"
#import "SCILicenseViewController.h"
#import "../Appearance/SCITheme.h"
#import "../Utils.h"

NSString * const SCILicenseStateDidChangeNotification = @"PekiScripterLicenseStateDidChange";

@interface SCILicenseGateRecord : NSObject
@property (nonatomic, weak) UIWindow *source;
@property (nonatomic, strong) UIWindow *cover;
@property (nonatomic) BOOL suspendedByHost;
@end
@implementation SCILicenseGateRecord
@end

@interface SCILicenseManager ()
@property (nonatomic, readwrite) BOOL busy;
@property (nonatomic, copy, readwrite) NSString *message;
@property (nonatomic, strong, readwrite) NSURL *supportURL;
@property (nonatomic, strong) SCILicenseDeviceKey *deviceKey;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionDataTask *request;
@property (nonatomic, strong) NSMutableArray<SCILicenseGateRecord *> *records;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, copy) NSString *currentLicense;
@property (nonatomic) NSTimeInterval validUntilUptime;
@property (nonatomic) NSUInteger attempt;
@property (nonatomic) BOOL triedDevice;
@property (nonatomic) BOOL triedSavedLicense;
@property (nonatomic) BOOL updatingWindows;
@property (nonatomic) BOOL fetchedConfig;
@property (nonatomic) BOOL loadingDevice;
@end

static BOOL SCILicenseTrue(id value) {
    return [value isKindOfClass:NSNumber.class] && CFGetTypeID((__bridge CFTypeRef)value) == CFBooleanGetTypeID()
        && [value boolValue];
}

@implementation SCILicenseManager
+ (instancetype)sharedManager {
    static SCILicenseManager *manager;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ manager = [self new]; });
    return manager;
}
- (instancetype)init {
    if ((self = [super init])) {
        _records = [NSMutableArray new];
        _message = SCILicenseConfig.required ? @"Preparing license access…" : @"Licensing is disabled in this development build.";
        NSURLSessionConfiguration *configuration = NSURLSessionConfiguration.ephemeralSessionConfiguration;
        configuration.timeoutIntervalForRequest = 20;
        configuration.timeoutIntervalForResource = 25;
        configuration.URLCache = nil;
        configuration.HTTPCookieStorage = nil;
        configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(becameActive:)
            name:UIApplicationDidBecomeActiveNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(resigning:)
            name:UIApplicationWillResignActiveNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(windowChanged:)
            name:UIWindowDidBecomeKeyNotification object:nil];
    }
    return self;
}
- (NSString *)deviceID { return self.deviceKey.deviceID; }
- (BOOL)isAuthorized {
    return !SCILicenseConfig.required || (self.validUntilUptime > NSProcessInfo.processInfo.systemUptime
        && UIApplication.sharedApplication.applicationState == UIApplicationStateActive);
}
- (void)notify {
    [NSNotificationCenter.defaultCenter postNotificationName:SCILicenseStateDidChangeNotification object:nil];
    [self updateCovers];
}

- (void)considerWindow:(UIWindow *)window {
    if (!SCILicenseConfig.required || self.updatingWindows || !NSThread.isMainThread) return;
    BOOL guest = [SCITheme isInstagramWindow:window] && !window.hidden;
    SCILicenseGateRecord *existing = nil;
    for (SCILicenseGateRecord *record in self.records) if (record.source == window) existing = record;
    if (existing && !guest && !existing.suspendedByHost) {
        existing.suspendedByHost = YES;
        if (![self hasVisibleGuest]) {
            [self invalidateAttempt];
            self.busy = self.loadingDevice;
            self.triedSavedLicense = NO;
        }
    }
    if (guest) {
        if (!existing) {
            SCILicenseGateRecord *record = [SCILicenseGateRecord new];
            record.source = window;
            record.suspendedByHost = !window.isKeyWindow;
            [self.records addObject:record];
        } else if (window.isKeyWindow && existing.suspendedByHost) {
            existing.suspendedByHost = NO;
            [self invalidateAttempt];
            self.busy = self.loadingDevice;
            self.triedSavedLicense = NO;
        }
    }
    [self updateCovers];
    if (guest && [self hasVisibleGuest]) {
        [SCIUtils registerGuestDefaults];
        [self prepareDevice];
        [self restoreOnce];
        [self fetchPublicConfiguration];
    }
}
- (void)updateCovers {
    if (self.updatingWindows) return;
    self.updatingWindows = YES;
    @try {
        for (SCILicenseGateRecord *record in [self.records copy]) {
            UIWindow *source = record.source;
            BOOL visibleGuest = source && !source.hidden && !record.suspendedByHost && [SCITheme isInstagramWindow:source];
            BOOL mustCover = visibleGuest && !self.authorized;
            if (mustCover) {
                if (!record.cover) {
                    [source endEditing:YES];
                    record.cover = source.windowScene ? [[UIWindow alloc] initWithWindowScene:source.windowScene]
                        : [[UIWindow alloc] initWithFrame:source.frame];
                    record.cover.windowLevel = UIWindowLevelAlert + 2;
                    record.cover.hidden = YES;
                    record.cover.rootViewController = [SCILicenseViewController new];
                }
                if (!CGRectEqualToRect(record.cover.frame, source.frame)) record.cover.frame = source.frame;
                if (record.cover.hidden || source.isKeyWindow) {
                    [source endEditing:YES];
                    [record.cover makeKeyAndVisible];
                }
            } else if (record.cover) {
                BOOL wasKey = record.cover.isKeyWindow;
                [record.cover endEditing:YES];
                record.cover.hidden = YES;
                record.cover = nil;
                BOOL restoredHost = source.rootViewController && ![SCITheme isInstagramWindow:source];
                if (wasKey && source && !source.hidden && (!record.suspendedByHost || restoredHost)) [source makeKeyWindow];
            }
            if (!source) [self.records removeObject:record];
        }
    } @finally {
        self.updatingWindows = NO;
    }
}
- (BOOL)hasVisibleGuest {
    for (SCILicenseGateRecord *record in self.records) {
        if (record.source && !record.source.hidden && !record.suspendedByHost && [SCITheme isInstagramWindow:record.source]) return YES;
    }
    return NO;
}
- (void)scanWindows {
    if (self.updatingWindows || !SCILicenseConfig.required) return;
    for (UIWindow *window in UIApplication.sharedApplication.windows) [self considerWindow:window];
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if ([scene isKindOfClass:UIWindowScene.class]) {
            for (UIWindow *window in ((UIWindowScene *)scene).windows) [self considerWindow:window];
        }
    }
    [self updateCovers];
}
- (void)windowChanged:(NSNotification *)notification {
    if (self.updatingWindows || !SCILicenseConfig.required) return;
    UIWindow *window = notification.object;
    if (![window isKindOfClass:UIWindow.class]) return;
    BOOL guest = [SCITheme isInstagramWindow:window];
    BOOL host = [SCITheme isLiveContainerWindow:window];
    // A text-selection/keyboard/system window is not a host transition.
    if ([window isKindOfClass:UIWindow.class] && (guest || host)) {
        BOOL changed = NO;
        for (SCILicenseGateRecord *record in self.records) {
            if (![SCITheme isInstagramWindow:record.source]) continue;
            if (record.source.windowScene == window.windowScene && record.suspendedByHost == guest) {
                record.suspendedByHost = !guest;
                changed = YES;
            }
        }
        if (changed) {
            [self invalidateAttempt];
            self.busy = self.loadingDevice;
            self.triedSavedLicense = NO;
            self.message = @"Access will be checked when Instagram opens.";
        }
    }
    [self scanWindows];
}
- (void)becameActive:(NSNotification *)notification {
    self.triedSavedLicense = NO;
    [self scanWindows];
}
- (void)invalidateAttempt {
    self.attempt++;
    [self.request cancel];
    self.request = nil;
    self.validUntilUptime = 0;
    [self.timer invalidate];
    self.timer = nil;
}
- (void)resigning:(NSNotification *)notification {
    [self invalidateAttempt];
    self.busy = self.loadingDevice;
    self.triedSavedLicense = NO;
    self.message = @"Access will be checked online when you return.";
    [self notify];
}

- (void)prepareDevice {
    if (self.deviceKey || self.triedDevice || self.busy || self.loadingDevice) return;
    self.triedDevice = YES;
    self.loadingDevice = YES;
    self.busy = YES;
    self.message = @"Preparing the device's security key…";
    [self notify];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSError *error = nil;
        SCILicenseDeviceKey *device = [[SCILicenseDeviceKey alloc] initWithError:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.loadingDevice = NO;
            self.deviceKey = device;
            self.busy = NO;
            self.message = device ? (SCILicenseConfig.baseURL ? @"Enter your license key to continue."
                : @"License server not configured. The developer must set the Worker URL and deploy the server.")
                : [NSString stringWithFormat:@"%@ (code %ld)", error.localizedDescription
                    ?: @"Device-key access is unavailable in this LiveContainer setup.", (long)error.code];
            [self notify];
            [self restoreOnce];
        });
    });
}
- (void)restoreOnce {
    if (!self.deviceKey || self.busy || self.triedSavedLicense || ![self hasVisibleGuest]
        || UIApplication.sharedApplication.applicationState != UIApplicationStateActive) return;
    self.triedSavedLicense = YES;
    NSString *saved = self.currentLicense ?: [self.deviceKey storedLicense];
    if (saved.length && SCILicenseConfig.baseURL) [self submitLicense:saved];
}
- (void)retry {
    if (self.busy) return;
    self.fetchedConfig = NO;
    [self fetchPublicConfiguration];
    if (!self.deviceKey) {
        self.triedDevice = NO;
        [self prepareDevice];
        return;
    }
    self.triedSavedLicense = NO;
    [self restoreOnce];
    if (!self.currentLicense.length && ![self.deviceKey storedLicense].length) {
        self.message = SCILicenseConfig.baseURL ? @"No saved license. Enter a key to activate access."
            : @"The developer must configure and deploy the license server first.";
        [self notify];
    }
}
- (void)forgetLicense {
    [self invalidateAttempt];
    [self.deviceKey removeStoredLicense];
    self.currentLicense = nil;
    self.busy = NO;
    self.triedSavedLicense = YES;
    self.message = @"Saved license forgotten. Enter a key to activate access.";
    [self notify];
}

- (NSURL *)endpoint:(NSString *)path {
    NSURL *base = SCILicenseConfig.baseURL;
    return base ? [base URLByAppendingPathComponent:path] : nil;
}
- (BOOL)identityMatches:(NSDictionary *)body {
    return [body[@"app_id"] isEqual:SCILicenseConfig.appID] && [body[@"version"] isEqual:SCILicenseConfig.clientVersion];
}
- (void)readSupportURL:(id)value {
    if (![value isKindOfClass:NSString.class]) return;
    self.supportURL = nil;
    NSURL *url = [NSURL URLWithString:value];
    if (![url.scheme isEqualToString:@"https"] || url.user || url.password || url.port || url.query || url.fragment) return;
    BOOL invite = [url.host isEqualToString:@"discord.gg"] && url.path.length > 1;
    BOOL discord = [url.host isEqualToString:@"discord.com"]
        && ([url.path hasPrefix:@"/invite/"] || [url.path hasPrefix:@"/users/"]);
    if (invite || discord) self.supportURL = url;
}
- (void)fetchPublicConfiguration {
    NSURL *url = [self endpoint:@"v1/config"];
    if (self.fetchedConfig || !url) return;
    self.fetchedConfig = YES;
    [[self.session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error || !data.length || data.length > 8192 || ![response isKindOfClass:NSHTTPURLResponse.class]
            || ((NSHTTPURLResponse *)response).statusCode != 200) return;
        id result = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (![result isKindOfClass:NSDictionary.class] || ![self identityMatches:result]) return;
        dispatch_async(dispatch_get_main_queue(), ^{ [self readSupportURL:result[@"discord_url"]]; });
    }] resume];
}
- (void)post:(NSString *)path body:(NSDictionary *)body attempt:(NSUInteger)attempt
    completion:(void (^)(NSDictionary *, NSInteger, NSError *))completion {
    NSURL *url = [self endpoint:path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    self.request = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSInteger status = [response isKindOfClass:NSHTTPURLResponse.class] ? ((NSHTTPURLResponse *)response).statusCode : 0;
        NSDictionary *result = nil;
        if (data.length && data.length <= 8192) {
            id decoded = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if ([decoded isKindOfClass:NSDictionary.class]) result = decoded;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (attempt != self.attempt || UIApplication.sharedApplication.applicationState != UIApplicationStateActive) return;
            completion(result, status, error);
        });
    }];
    [self.request resume];
}
- (void)failed:(NSDictionary *)body error:(NSError *)error {
    self.busy = NO;
    self.validUntilUptime = 0;
    NSString *message = body[@"message"];
    if (error) self.message = @"Cannot reach the license server. Internet access is required; please retry.";
    else if ([message isKindOfClass:NSString.class] && message.length <= 300) self.message = message;
    else self.message = @"The license server returned an unsupported response. Contact the developer.";
    [self readSupportURL:body[@"discord_url"]];
    [self notify];
}
- (void)submitLicense:(NSString *)input {
    if (self.busy) return;
    NSString *key = [input stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (!self.deviceKey || !SCILicenseConfig.baseURL || !key.length || key.length > 256
        || [key rangeOfCharacterFromSet:NSCharacterSet.controlCharacterSet].location != NSNotFound) {
        self.message = !SCILicenseConfig.baseURL ? @"License server not configured. Contact the developer."
            : !self.deviceKey ? @"Device key unavailable. Retry or contact the developer." : @"Enter a valid license key.";
        [self notify];
        return;
    }
    [self invalidateAttempt];
    NSUInteger attempt = self.attempt;
    self.busy = YES;
    self.message = @"Checking license online…";
    [self notify];
    NSString *digest = [SCILicenseDeviceKey sha256String:key];
    SCILicenseDeviceKey *device = self.deviceKey;
    [self post:@"v1/challenge" body:@{@"version": SCILicenseConfig.clientVersion,
        @"public_key": device.publicKeyBase64, @"license_hash": digest} attempt:attempt
        completion:^(NSDictionary *body, NSInteger status, NSError *error) {
        NSString *identifier = body[@"challenge_id"];
        NSString *nonce = body[@"nonce"];
        BOOL validID = [identifier isKindOfClass:NSString.class] && [[NSUUID alloc] initWithUUIDString:identifier] != nil;
        BOOL validNonce = [nonce isKindOfClass:NSString.class] && nonce.length == 43
            && [nonce rangeOfCharacterFromSet:[[NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"] invertedSet]].location == NSNotFound;
        if (error || status != 200 || !SCILicenseTrue(body[@"success"]) || ![self identityMatches:body]
            || !validID || !validNonce || ![body[@"hwid"] isEqual:device.deviceID] || ![body[@"license_hash"] isEqual:digest]) {
            [self failed:body error:error];
            return;
        }
        // Construct the protocol locally; never sign arbitrary server-provided text.
        NSString *message = [@[ @"peki-license-v1", SCILicenseConfig.appID, SCILicenseConfig.clientVersion,
            identifier, nonce, device.deviceID, digest ] componentsJoinedByString:@"\n"];
        NSError *signError = nil;
        NSString *signature = [device signMessage:message error:&signError];
        if (!signature) {
            self.busy = NO;
            self.message = signError.localizedDescription ?: @"Device signature failed.";
            [self notify];
            return;
        }
        [self post:@"v1/license/check" body:@{@"version": SCILicenseConfig.clientVersion, @"key": key,
            @"public_key": device.publicKeyBase64, @"challenge_id": identifier, @"signature": signature}
            attempt:attempt completion:^(NSDictionary *result, NSInteger code, NSError *networkError) {
            id seconds = result[@"lease_seconds"];
            BOOL duration = [seconds isKindOfClass:NSNumber.class]
                && CFGetTypeID((__bridge CFTypeRef)seconds) != CFBooleanGetTypeID()
                && [seconds doubleValue] >= 1 && [seconds doubleValue] <= 300;
            if (networkError || code != 200 || !SCILicenseTrue(result[@"success"])
                || !SCILicenseTrue(result[@"authorized"]) || ![self identityMatches:result]
                || ![result[@"hwid"] isEqual:device.deviceID] || !duration) {
                [self failed:result error:networkError];
                return;
            }
            self.busy = NO;
            self.currentLicense = key;
            BOOL stored = [device storeLicense:key];
            self.validUntilUptime = NSProcessInfo.processInfo.systemUptime + [seconds doubleValue];
            self.message = stored ? @"License verified. Access is active."
                : @"Access is active for this session. Keychain could not remember the license.";
            __weak typeof(self) weakSelf = self;
            self.timer = [NSTimer scheduledTimerWithTimeInterval:MAX(1, [seconds doubleValue] - 1)
                repeats:NO block:^(NSTimer *timer) {
                SCILicenseManager *manager = weakSelf;
                [manager invalidateAttempt];
                [manager notify];
                if ([manager hasVisibleGuest] && UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
                    [manager submitLicense:manager.currentLicense];
                }
            }];
            [self notify];
        }];
    }];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
    willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request
    completionHandler:(void (^)(NSURLRequest *))completionHandler {
    completionHandler(nil); // Never forward a license credential to a redirect.
}
@end
