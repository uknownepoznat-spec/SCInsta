#import "../../InstagramHeaders.h"
#import "../../Utils.h"
#import "../../Downloader/Download.h"
#import <objc/runtime.h>

static SCIDownloadDelegate *imageDownloadDelegate;
static SCIDownloadDelegate *videoDownloadDelegate;

static void initDownloaders () {
    // Init downloaders only once
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imageDownloadDelegate = [[SCIDownloadDelegate alloc] initWithAction:quickLook showProgress:NO];
        videoDownloadDelegate = [[SCIDownloadDelegate alloc] initWithAction:share showProgress:YES];
    });
}

@interface SCIStoryDownloadGesture : UILongPressGestureRecognizer <UIGestureRecognizerDelegate>
@end

@implementation SCIStoryDownloadGesture
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture
        shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)other {
    return ![other isKindOfClass:[SCIStoryDownloadGesture class]];
}
@end

static char SCIStoryGestureKey;
static void SCIInstallStoryGesture(UIView *view) {
    if (objc_getAssociatedObject(view, &SCIStoryGestureKey)) return;
    SCIStoryDownloadGesture *gesture = [[SCIStoryDownloadGesture alloc]
        initWithTarget:view action:NSSelectorFromString(@"handleLongPress:")];
    gesture.minimumPressDuration = MAX(0.3, [SCIUtils getDoublePref:@"dw_finger_duration"]);
    gesture.numberOfTouchesRequired = MAX(1, MIN(5, (NSInteger)[SCIUtils getDoublePref:@"dw_finger_count"]));
    gesture.cancelsTouchesInView = NO;
    gesture.delegate = gesture;
    [view addGestureRecognizer:gesture];
    objc_setAssociatedObject(view, &SCIStoryGestureKey, gesture, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
    if (!url) {
        NSLog(@"[Peki Scripter] Unsupported story media: view=%@ item=%@",
            NSStringFromClass(view.class), NSStringFromClass([item class]));
        [SCIUtils showErrorHUDWithDescription:@"This story format is not supported yet. Try reopening the story."];
        return;
    }
    initDownloaders();
    // Share both media types, so Save Image/Save Video is available consistently.
    NSString *extension = url.pathExtension.length ? url.pathExtension : (video ? @"mp4" : @"jpg");
    [videoDownloadDelegate downloadFileWithURL:url fileExtension:extension hudLabel:@"Saving story"];
}

/* * Feed * */

// Download feed images
%hook IGFeedPhotoView
- (void)didMoveToSuperview {
    %orig;

    if ([SCIUtils getBoolPref:@"dw_feed_posts"]) {
        [self addLongPressGestureRecognizer];
    }

    return;
}
%new - (void)addLongPressGestureRecognizer {
    NSLog(@"[Peki Scripter] Adding feed photo download long press gesture recognizer");

    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = [SCIUtils getDoublePref:@"dw_finger_duration"];
    longPress.numberOfTouchesRequired = [SCIUtils getDoublePref:@"dw_finger_count"];

    [self addGestureRecognizer:longPress];
}
%new - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) return;

    // Get photo instance
    IGPhoto *photo;

    if ([self.delegate isKindOfClass:%c(IGFeedItemPhotoCell)]) {
        IGFeedItemPhotoCellConfiguration *_configuration = MSHookIvar<IGFeedItemPhotoCellConfiguration *>(self.delegate, "_configuration");
        if (!_configuration) return;

        photo = MSHookIvar<IGPhoto *>(_configuration, "_photo");
    }
    else if ([self.delegate isKindOfClass:%c(IGFeedItemPagePhotoCell)]) {
        IGFeedItemPagePhotoCell *pagePhotoCell = self.delegate;

        photo = pagePhotoCell.pagePhotoPost.photo;
    }

    NSURL *photoUrl = [SCIUtils getPhotoUrl:photo];
    if (!photoUrl) {
        [SCIUtils showErrorHUDWithDescription:@"Could not extract photo url from post"];
        
        return;
    }

    // Download image & show in share menu
    initDownloaders();
    [imageDownloadDelegate downloadFileWithURL:photoUrl
                                 fileExtension:[[photoUrl lastPathComponent]pathExtension]
                                      hudLabel:nil];
}
%end

// Download feed videos
%hook IGModernFeedVideoCell.IGModernFeedVideoCell
- (void)didMoveToSuperview {
    %orig;

    if ([SCIUtils getBoolPref:@"dw_feed_posts"]) {
        [self addLongPressGestureRecognizer];
    }

    return;
}
%new - (void)addLongPressGestureRecognizer {
    NSLog(@"[Peki Scripter] Adding feed video download long press gesture recognizer");

    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = [SCIUtils getDoublePref:@"dw_finger_duration"];
    longPress.numberOfTouchesRequired = [SCIUtils getDoublePref:@"dw_finger_count"];

    [self addGestureRecognizer:longPress];
}
%new - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) return;

    NSURL *videoUrl = [SCIUtils getVideoUrlForMedia:[self mediaCellFeedItem]];
    if (!videoUrl) {
        [SCIUtils showErrorHUDWithDescription:@"Could not extract video url from post"];

        return;
    }

    // Download video & show in share menu
    initDownloaders();
    [videoDownloadDelegate downloadFileWithURL:videoUrl
                                 fileExtension:[[videoUrl lastPathComponent] pathExtension]
                                      hudLabel:nil];
}
%end


/* * Reels * */

// Download reels (photos)
%hook IGSundialViewerPhotoView
- (void)didMoveToSuperview {
    %orig;

    if ([SCIUtils getBoolPref:@"dw_reels"]) {
        [self addLongPressGestureRecognizer];
    }

    return;
}
%new - (void)addLongPressGestureRecognizer {
    NSLog(@"[Peki Scripter] Adding reels photo download long press gesture recognizer");

    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = [SCIUtils getDoublePref:@"dw_finger_duration"];
    longPress.numberOfTouchesRequired = [SCIUtils getDoublePref:@"dw_finger_count"];

    [self addGestureRecognizer:longPress];
}
%new - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) return;

    IGPhoto *_photo = MSHookIvar<IGPhoto *>(self, "_photo");

    NSURL *photoUrl = [SCIUtils getPhotoUrl:_photo];
    if (!photoUrl) {
        [SCIUtils showErrorHUDWithDescription:@"Could not extract photo url from reel"];

        return;
    }

    // Download image & show in share menu
    initDownloaders();
    [imageDownloadDelegate downloadFileWithURL:photoUrl
                                 fileExtension:[[photoUrl lastPathComponent]pathExtension]
                                      hudLabel:nil];
}
%end

// Download reels (videos)
%hook IGSundialViewerVideoCell
- (void)didMoveToSuperview {
    %orig;

    if ([SCIUtils getBoolPref:@"dw_reels"]) {
        [self addLongPressGestureRecognizer];
    }

    return;
}
%new - (void)addLongPressGestureRecognizer {
    NSLog(@"[Peki Scripter] Adding reels video download long press gesture recognizer");

    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = [SCIUtils getDoublePref:@"dw_finger_duration"];
    longPress.numberOfTouchesRequired = [SCIUtils getDoublePref:@"dw_finger_count"];

    [self addGestureRecognizer:longPress];
}
%new - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) return;
    
    NSURL *videoUrl = [SCIUtils getVideoUrlForMedia:self.video];
    if (!videoUrl) {
        [SCIUtils showErrorHUDWithDescription:@"Could not extract video url from reel"];

        return;
    }

    // Download video & show in share menu
    initDownloaders();
    [videoDownloadDelegate downloadFileWithURL:videoUrl
                                 fileExtension:[[videoUrl lastPathComponent] pathExtension]
                                      hudLabel:nil];
}
%end


/* * Stories * */

// Download story (images)
%hook IGStoryPhotoView
- (void)didMoveToSuperview {
    %orig;

    if ([SCIUtils getBoolPref:@"dw_story"] && [SCIUtils getBoolPref:@"story_downloader"]) {
        [self addLongPressGestureRecognizer];
    }

    return;
}
%new - (void)addLongPressGestureRecognizer {
    SCIInstallStoryGesture(self);
}
%new - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) return;
    SCIDownloadStory(self, NO);
}
%end

// Download story (videos)
%hook IGStoryModernVideoView
- (void)didMoveToSuperview {
    %orig;

    if ([SCIUtils getBoolPref:@"dw_story"] && [SCIUtils getBoolPref:@"story_downloader"]) {
        [self addLongPressGestureRecognizer];
    }

    return;
}
%new - (void)addLongPressGestureRecognizer {
    SCIInstallStoryGesture(self);
}
%new - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) return;
    SCIDownloadStory(self, YES);
}
%end

// Download story (videos, legacy)
%hook IGStoryVideoView
- (void)didMoveToSuperview {
    %orig;

    if ([SCIUtils getBoolPref:@"dw_story"] && [SCIUtils getBoolPref:@"story_downloader"]) {
        [self addLongPressGestureRecognizer];
    }

    return;
}
%new - (void)addLongPressGestureRecognizer {
    SCIInstallStoryGesture(self);
}
%new - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) return;
    SCIDownloadStory(self, YES);
}
%end


/* * Profile pictures * */

%hook IGProfilePictureImageView
- (void)didMoveToSuperview {
    %orig;

    if ([SCIUtils getBoolPref:@"save_profile"]) {
        [self addLongPressGestureRecognizer];
    }

    return;
}
%new - (void)addLongPressGestureRecognizer {
    NSLog(@"[Peki Scripter] Adding profile picture long press gesture recognizer");

    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [self addGestureRecognizer:longPress];
}
%new - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) return;

    IGImageView *_imageView = MSHookIvar<IGImageView *>(self, "_imageView");
    if (!_imageView) return;
    
    IGImageSpecifier *imageSpecifier = _imageView.imageSpecifier;
    if (!imageSpecifier) return;

    NSURL *imageUrl = imageSpecifier.url;
    if (!imageUrl) return;

    // Download image & preview in quick look
    initDownloaders();
    [imageDownloadDelegate downloadFileWithURL:imageUrl
                                 fileExtension:[[imageUrl lastPathComponent] pathExtension]
                                      hudLabel:@"Loading"];
}
%end
