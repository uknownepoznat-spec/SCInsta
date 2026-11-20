#import "Manager.h"

@implementation SCIDownloadManager

- (instancetype)initWithDelegate:(id<SCIDownloadDelegateProtocol>)downloadDelegate {
    self = [super init];
    
    if (self) {
        self.delegate = downloadDelegate;
    }

    return self;
}

- (void)downloadFileWithURL:(NSURL *)url fileExtension:(NSString *)fileExtension {
    if (![url isKindOfClass:[NSURL class]]
        || ![@[@"http", @"https"] containsObject:url.scheme.lowercaseString]) {
        [self.delegate downloadDidFinishWithError:[NSError errorWithDomain:@"PekiScripter.Download"
            code:1 userInfo:@{NSLocalizedDescriptionKey: @"The story has no valid download URL."}]];
        return;
    }
    // Properties
    self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    self.task = [self.session downloadTaskWithURL:url];
    
    // Default to jpg if no other reasonable length extension is provided
    NSString *extension = fileExtension.lowercaseString;
    self.fileExtension = [@[@"jpg", @"jpeg", @"png", @"heic", @"webp", @"mp4", @"mov"] containsObject:extension]
        ? extension : @"jpg";

    [self.task resume];
    [self.delegate downloadDidStart];
}

- (void)cancelDownload {
    [self.task cancel];
    [self.delegate downloadDidCancel];
}

// URLSession methods
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    NSLog(@"Task wrote %lld bytes of %lld bytes", bytesWritten, totalBytesExpectedToWrite);
    
    if (totalBytesExpectedToWrite <= 0) return;
    float progress = MIN(1.0, MAX(0.0, (float)totalBytesWritten / (float)totalBytesExpectedToWrite));

    [self.delegate downloadDidProgress:progress];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {    
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)downloadTask.response;
    if ([response isKindOfClass:[NSHTTPURLResponse class]]
        && (response.statusCode < 200 || response.statusCode >= 300)) {
        [self.delegate downloadDidFinishWithError:[NSError errorWithDomain:@"PekiScripter.Download"
            code:response.statusCode userInfo:@{NSLocalizedDescriptionKey:
                @"Instagram rejected the download. Reopen the story and try again."}]];
        return;
    }
    NSString *mime = response.MIMEType.lowercaseString;
    NSDictionary *extensions = @{@"video/mp4": @"mp4", @"video/quicktime": @"mov",
        @"image/jpeg": @"jpg", @"image/png": @"png", @"image/webp": @"webp", @"image/heic": @"heic"};
    if (extensions[mime ?: @""]) self.fileExtension = extensions[mime];
    if ([mime containsString:@"text/"] || [mime containsString:@"json"]) {
        [self.delegate downloadDidFinishWithError:[NSError errorWithDomain:@"PekiScripter.Download"
            code:2 userInfo:@{NSLocalizedDescriptionKey: @"Instagram returned an error instead of media."}]];
        return;
    }
    // Move downloaded file to cache directory
    NSURL *finalLocation = [self moveFileToCacheDir:location];

    if (finalLocation) {
        [self.delegate downloadDidFinishWithFileURL:finalLocation];
    } else {
        [self.delegate downloadDidFinishWithError:[NSError errorWithDomain:@"PekiScripter.Download"
            code:3 userInfo:@{NSLocalizedDescriptionKey: @"Could not store the downloaded media."}]];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSLog(@"Task completed with error: %@", error);
    
    if (error) [self.delegate downloadDidFinishWithError:error];
    [session finishTasksAndInvalidate];
}

// Rename downloaded file & move from documents dir -> cache dir
- (NSURL *)moveFileToCacheDir:(NSURL *)oldPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSString *cacheDirectoryPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    NSURL *newPath = [[NSURL fileURLWithPath:cacheDirectoryPath] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", NSUUID.UUID.UUIDString, self.fileExtension]];
    
    NSLog(@"[Peki Scripter] Download Handler: Moving file from: %@ to: %@", oldPath.absoluteString, newPath.absoluteString);

    // Move file to cache directory
    NSError *fileMoveError;
    [fileManager moveItemAtURL:oldPath toURL:newPath error:&fileMoveError];

    if (fileMoveError) {
        NSLog(@"[Peki Scripter] Download Handler: Error while moving file: %@", oldPath.absoluteString);
        NSLog(@"[Peki Scripter] Download Handler: %@", fileMoveError);
        return nil;
    }

    return newPath;
}

@end
