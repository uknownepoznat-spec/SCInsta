#import "../../Utils.h"
#import "../../InstagramHeaders.h"

// Channels dms tab (header)
%hook IGDirectInboxHeaderSectionController
- (id)viewModel {
    id _origModel = %orig;
    if ([[_origModel title] isEqualToString:@"Suggested"]) {

        if ([SCIUtils getBoolPref:@"no_suggested_chats"]) {
            NSLog(@"[PekiWare] Hiding suggested chats (header: channels tab)");

            return nil;
        }

    }

    return _origModel;
}
%end