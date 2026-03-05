#import "InstagramHeaders.h"
#import "Utils.h"

// Story Downloader - Simple implementation to avoid compilation errors
%hook IGStoryViewer
- (void)viewDidLoad {
    %orig;
    
    if ([SCIUtils getBoolPref:@"story_downloader"]) {
        NSLog(@"[PekiWare] Story Downloader: Feature enabled");
        // Story downloader functionality will be handled through existing download mechanisms
    }
}
%end
