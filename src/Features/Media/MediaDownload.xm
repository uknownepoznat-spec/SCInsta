#import "../../InstagramHeaders.h"
#import "../../Utils.h"
#import "../../Downloader/Download.h"
#import "SCIMediaGesture.h"
#import "../../License/SCILicenseManager.h"

static void SCIDownloadMedia(NSURL *url, BOOL video) {
    if (!SCILicenseManager.sharedManager.authorized) return;
    if (!url) {
        [SCIUtils showErrorHUDWithDescription:@"This media format is not supported by this Instagram version."];
        return;
    }
    static SCIDownloadDelegate *shareDownload;
    static SCIDownloadDelegate *previewDownload;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        shareDownload = [[SCIDownloadDelegate alloc] initWithAction:share showProgress:YES];
        previewDownload = [[SCIDownloadDelegate alloc] initWithAction:quickLook showProgress:YES];
    });
    if (shareDownload.downloading || previewDownload.downloading) return;
    SCIDownloadDelegate *downloader = [[SCIUtils getStringPref:@"download_destination"] isEqualToString:@"preview"]
        ? previewDownload : shareDownload;
    NSString *extension = url.pathExtension.length ? url.pathExtension : (video ? @"mp4" : @"jpg");
    [downloader downloadFileWithURL:url fileExtension:extension hudLabel:@"Preparing media"];
}

static void SCIDownloadStory(UIView *view, BOOL video) {
    id item = [SCIUtils mediaValueForObject:view key:@"item"];
    if (!item) {
        id delegate = [SCIUtils mediaValueForObject:view key:@"captionDelegate"];
        item = [SCIUtils mediaValueForObject:delegate key:@"currentStoryItem"];
    }
    if (!item) {
        id controller = [SCIUtils nearestViewControllerForView:view];
        id dataSource = [SCIUtils mediaValueForObject:controller key:@"dataSource"];
        item = [SCIUtils mediaValueForObject:dataSource key:@"currentMessage"];
    }
    NSURL *url = video ? [SCIUtils getVideoUrlForMedia:item] : [SCIUtils getPhotoUrlForMedia:item];
    SCIDownloadMedia(url, video);
}

%hook IGFeedPhotoView
- (void)didMoveToSuperview {
    %orig;
    SCIInstallMediaDownloadGesture(self, @"feed", ^(UIView *view) {
        id delegate = [SCIUtils mediaValueForObject:view key:@"delegate"];
        id configuration = [SCIUtils mediaValueForObject:delegate key:@"configuration"];
        id photo = [SCIUtils mediaValueForObject:configuration key:@"photo"];
        if (!photo) {
            id post = [SCIUtils mediaValueForObject:delegate key:@"pagePhotoPost"];
            photo = [SCIUtils mediaValueForObject:post key:@"photo"];
        }
        SCIDownloadMedia([SCIUtils getPhotoUrl:photo], NO);
    });
}
%end

%hook IGModernFeedVideoCell.IGModernFeedVideoCell
- (void)didMoveToSuperview {
    %orig;
    SCIInstallMediaDownloadGesture(self, @"feed", ^(UIView *view) {
        id item = [SCIUtils mediaValueForObject:view key:@"mediaCellFeedItem"];
        SCIDownloadMedia([SCIUtils getVideoUrlForMedia:item], YES);
    });
}
%end

%hook IGSundialViewerPhotoView
- (void)didMoveToSuperview {
    %orig;
    SCIInstallMediaDownloadGesture(self, @"reels", ^(UIView *view) {
        id photo = [SCIUtils mediaValueForObject:view key:@"photo"];
        SCIDownloadMedia([SCIUtils getPhotoUrl:photo], NO);
    });
}
%end

%hook IGSundialViewerVideoCell
- (void)didMoveToSuperview {
    %orig;
    SCIInstallMediaDownloadGesture(self, @"reels", ^(UIView *view) {
        id video = [SCIUtils mediaValueForObject:view key:@"video"];
        SCIDownloadMedia([SCIUtils getVideoUrlForMedia:video], YES);
    });
}
%end

%hook IGStoryPhotoView
- (void)didMoveToSuperview {
    %orig;
    SCIInstallMediaDownloadGesture(self, @"stories", ^(UIView *view) { SCIDownloadStory(view, NO); });
}
%end

%hook IGStoryModernVideoView
- (void)didMoveToSuperview {
    %orig;
    SCIInstallMediaDownloadGesture(self, @"stories", ^(UIView *view) { SCIDownloadStory(view, YES); });
}
%end

%hook IGStoryVideoView
- (void)didMoveToSuperview {
    %orig;
    SCIInstallMediaDownloadGesture(self, @"stories", ^(UIView *view) { SCIDownloadStory(view, YES); });
}
%end

%hook IGProfilePictureImageView
- (void)didMoveToSuperview {
    %orig;
    SCIInstallMediaDownloadGesture(self, @"profile", ^(UIView *view) {
        id imageView = [SCIUtils mediaValueForObject:view key:@"imageView"];
        id specifier = [SCIUtils mediaValueForObject:imageView key:@"imageSpecifier"];
        id url = [SCIUtils mediaValueForObject:specifier key:@"url"];
        if ([url isKindOfClass:[NSString class]]) url = [NSURL URLWithString:url];
        SCIDownloadMedia([url isKindOfClass:[NSURL class]] ? url : nil, NO);
    });
}
%end
