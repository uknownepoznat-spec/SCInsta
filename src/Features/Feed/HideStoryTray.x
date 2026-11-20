#import "../../Utils.h"
#import "../../InstagramHeaders.h"

// Disable story data source
%hook IGMainStoryTrayDataSource
- (id)initWithUserSession:(id)arg1 {
    if ([SCIUtils getBoolPref:@"hide_stories_tray"]) {
        NSLog(@"[Peki Scripter] Hiding story tray");

        return nil;
    }
    
    return %orig;
}
%end