#import "../../Utils.h"
#import "../../InstagramHeaders.h"

// Disable notes tray data source
%hook IGDirectNotesModelsDataSource
- (id)initWithUserSession:(id)arg1 {
    if ([SCIUtils getBoolPref:@"hide_notes_tray"]) {
        NSLog(@"[PekiWare] Hide notes tray");
        return nil;
    }

    return %orig;
}
%end

// Remove notes tray
%hook IGDirectNotesTrayRowSectionController
- (id)initWithUserSession:(id)arg1 delegate:(id)arg2 containerModule:(id)arg3 {
    if ([SCIUtils getBoolPref:@"hide_notes_tray"]) {
        NSLog(@"[PekiWare] Hiding notes tray");
        return nil;
    }
    return %orig(arg1, arg2, arg3);
}
%end