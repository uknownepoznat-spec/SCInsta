#import "SCILicenseDeviceKey.h"
#import <Security/Security.h>
#import <CommonCrypto/CommonDigest.h>

@interface SCILicenseDeviceKey ()
@property (nonatomic, copy, readwrite) NSString *deviceID;
@property (nonatomic, copy, readwrite) NSString *publicKeyBase64;
@end

static NSError *SCIDeviceError(NSString *message, NSInteger code) {
    return [NSError errorWithDomain:@"PekiScripter.DeviceKey" code:code
        userInfo:@{NSLocalizedDescriptionKey: message}];
}

@implementation SCILicenseDeviceKey {
    SecKeyRef _privateKey;
}

- (instancetype)initWithError:(NSError **)error {
    if (!(self = [super init])) return nil;
    NSData *tag = [@"com.pekiscripter.license-device-key.v1" dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassKey,
        (__bridge id)kSecAttrKeyType: (__bridge id)kSecAttrKeyTypeECSECPrimeRandom,
        (__bridge id)kSecAttrKeyClass: (__bridge id)kSecAttrKeyClassPrivate,
        (__bridge id)kSecAttrApplicationTag: tag,
        (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne,
        (__bridge id)kSecReturnRef: @YES
    };
    CFTypeRef found = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &found);
    if (status == errSecSuccess && found && CFGetTypeID(found) == SecKeyGetTypeID()) {
        _privateKey = (SecKeyRef)found; // SecItemCopyMatching transferred +1.
    } else if (status == errSecItemNotFound) {
        CFErrorRef nativeError = NULL;
        SecAccessControlRef access = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly, kSecAccessControlPrivateKeyUsage, &nativeError);
        if (!access) {
            NSInteger code = nativeError ? CFErrorGetCode(nativeError) : status;
            if (nativeError) CFRelease(nativeError);
            if (error) *error = SCIDeviceError(@"Device-key access is unavailable in this LiveContainer/signing setup.", code);
            return nil;
        }
        NSDictionary *attributes = @{
            (__bridge id)kSecAttrKeyType: (__bridge id)kSecAttrKeyTypeECSECPrimeRandom,
            (__bridge id)kSecAttrKeySizeInBits: @256,
            (__bridge id)kSecAttrTokenID: (__bridge id)kSecAttrTokenIDSecureEnclave,
            (__bridge id)kSecPrivateKeyAttrs: @{
                (__bridge id)kSecAttrIsPermanent: @YES,
                (__bridge id)kSecAttrApplicationTag: tag,
                (__bridge id)kSecAttrAccessControl: (__bridge id)access
            }
        };
        _privateKey = SecKeyCreateRandomKey((__bridge CFDictionaryRef)attributes, &nativeError);
        CFRelease(access);
        if (!_privateKey) {
            NSInteger code = nativeError ? CFErrorGetCode(nativeError) : errSecUnimplemented;
            if (nativeError) CFRelease(nativeError);
            if (error) *error = SCIDeviceError(@"Could not create a Secure Enclave key. This LiveContainer/signing setup may not support it.", code);
            return nil; // No silent software-key/UUID fallback.
        }
        if (nativeError) CFRelease(nativeError);
    } else {
        if (found) CFRelease(found);
        if (error) *error = SCIDeviceError(@"Cannot access the saved device key. Unlock the phone or contact the developer.", status);
        return nil;
    }
    NSDictionary *attributes = CFBridgingRelease(SecKeyCopyAttributes(_privateKey));
    if (![attributes[(__bridge id)kSecAttrTokenID] isEqual:(__bridge id)kSecAttrTokenIDSecureEnclave]) {
        if (error) *error = SCIDeviceError(@"The saved key is not Secure Enclave-backed. Contact the developer.", -1);
        return nil;
    }
    SecKeyRef publicKey = SecKeyCopyPublicKey(_privateKey);
    CFErrorRef exportError = NULL;
    NSData *raw = publicKey ? CFBridgingRelease(SecKeyCopyExternalRepresentation(publicKey, &exportError)) : nil;
    if (publicKey) CFRelease(publicKey);
    if (exportError) CFRelease(exportError);
    if (raw.length != 65 || ((const uint8_t *)raw.bytes)[0] != 4) {
        if (error) *error = SCIDeviceError(@"Could not export the device's public key.", -2);
        return nil;
    }
    self.publicKeyBase64 = [raw base64EncodedStringWithOptions:0];
    self.deviceID = [SCILicenseDeviceKey sha256Data:raw];
    return self;
}

- (void)dealloc { if (_privateKey) CFRelease(_privateKey); }

+ (NSString *)sha256Data:(NSData *)data {
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (CC_LONG)data.length, digest);
    NSMutableString *hex = [NSMutableString stringWithCapacity:64];
    for (NSUInteger index = 0; index < sizeof(digest); index++) [hex appendFormat:@"%02x", digest[index]];
    return hex;
}
+ (NSString *)sha256String:(NSString *)string {
    return [self sha256Data:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

- (NSString *)signMessage:(NSString *)message error:(NSError **)error {
    if (!_privateKey || !SecKeyIsAlgorithmSupported(_privateKey, kSecKeyOperationTypeSign, kSecKeyAlgorithmECDSASignatureMessageX962SHA256)) {
        if (error) *error = SCIDeviceError(@"This device cannot sign a license challenge.", -3);
        return nil;
    }
    CFErrorRef nativeError = NULL;
    NSData *signature = CFBridgingRelease(SecKeyCreateSignature(_privateKey,
        kSecKeyAlgorithmECDSASignatureMessageX962SHA256,
        (__bridge CFDataRef)[message dataUsingEncoding:NSUTF8StringEncoding], &nativeError));
    if (!signature) {
        NSInteger code = nativeError ? CFErrorGetCode(nativeError) : -4;
        if (error) *error = SCIDeviceError(@"The device could not sign the challenge. Unlock the phone and retry.", code);
    }
    if (nativeError) CFRelease(nativeError);
    return [signature base64EncodedStringWithOptions:0];
}

- (NSDictionary *)credentialQuery {
    return @{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: @"com.pekiscripter.license.v1",
        (__bridge id)kSecAttrAccount: self.deviceID};
}
- (NSString *)storedLicense {
    NSMutableDictionary *query = [[self credentialQuery] mutableCopy];
    query[(__bridge id)kSecReturnData] = @YES;
    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    CFTypeRef result = NULL;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)query, &result) != errSecSuccess) return nil;
    NSData *data = CFBridgingRelease(result);
    return [data isKindOfClass:NSData.class] ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : nil;
}
- (BOOL)storeLicense:(NSString *)license {
    NSDictionary *attributes = @{(__bridge id)kSecValueData: [license dataUsingEncoding:NSUTF8StringEncoding],
        (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly};
    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)[self credentialQuery], (__bridge CFDictionaryRef)attributes);
    if (status == errSecItemNotFound) {
        NSMutableDictionary *item = [[self credentialQuery] mutableCopy];
        [item addEntriesFromDictionary:attributes];
        item[(__bridge id)kSecAttrSynchronizable] = @NO;
        status = SecItemAdd((__bridge CFDictionaryRef)item, NULL);
    }
    return status == errSecSuccess;
}
- (void)removeStoredLicense {
    SecItemDelete((__bridge CFDictionaryRef)[self credentialQuery]);
}
@end
