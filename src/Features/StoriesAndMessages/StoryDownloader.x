#import "../../Utils.h"
#import "../../InstagramHeaders.h"

// Story Downloader - Skidaj sa jednim prstom
%hook IGStoryViewer
- (void)viewDidLoad {
    %orig;
    
    if ([SCIUtils getBoolPref:@"story_downloader"]) {
        NSLog(@"[PekiWare] Adding story download button");
        
        // Dodaj download dugme
        UIButton *downloadBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [downloadBtn setTitle:@"⬇️" forState:UIControlStateNormal];
        downloadBtn.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:0.9];
        [downloadBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        downloadBtn.layer.cornerRadius = 25;
        downloadBtn.frame = CGRectMake(self.view.frame.size.width - 80, 100, 60, 50);
        downloadBtn.translatesAutoresizingMaskIntoConstraints = NO;
        
        [downloadBtn addTarget:self action:@selector(downloadStory) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:downloadBtn];
        
        // Auto-layout
        [NSLayoutConstraint activateConstraints:@[
            [downloadBtn.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-20],
            [downloadBtn.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:100],
            [downloadBtn.widthAnchor constraintEqualToConstant:60],
            [downloadBtn.heightAnchor constraintEqualToConstant:50]
        ]];
    }
}

%new - (void)downloadStory {
    NSLog(@"[PekiWare] Downloading story...");
    
    @try {
        // Pronadji trenutni story
        id currentStory = [self valueForKey:@"currentStory"];
        if (currentStory) {
            // Uzmi URL story-ja
            id mediaURL = [currentStory valueForKey:@"url"];
            if (mediaURL) {
                // Skini story
                [SCIUtils downloadMediaFromURL:mediaURL withFilename:@"story"];
                [SCIUtils showSuccessHUD:@"Story downloaded!"];
            } else {
                [SCIUtils showErrorHUD:@"No media URL found"];
            }
        } else {
            [SCIUtils showErrorHUD:@"No story found"];
        }
    } @catch (NSException *exception) {
        NSLog(@"[PekiWare] Error downloading story: %@", exception.reason);
        [SCIUtils showErrorHUD:@"Download failed"];
    }
}

// Long press za download
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    %orig;
    
    if ([SCIUtils getBoolPref:@"story_downloader"]) {
        UITouch *touch = [touches anyObject];
        if (touch.tapCount == 1 && [touches count] == 1) {
            // Jedan prst - start timer za long press
            [self performSelector:@selector(handleLongPress:) withObject:touch afterDelay:1.0];
        }
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    %orig;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

%new - (void)handleLongPress:(UITouch *)touch {
    NSLog(@"[PekiWare] Long press detected - downloading story");
    [self downloadStory];
}
%end
