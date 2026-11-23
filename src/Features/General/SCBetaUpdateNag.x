#import <Foundation/Foundation.h>

// Instagram 418.1.0 (890980569): dedicated TestFlight reminder NSObject.
// Decline creation before its initializer can schedule presentation.
// Keep this scoped to the observed class/signature, not general update UI,
// receipt checks, application versions, or the separate license gate.
%hook IGTestFlightUpdateNagController
- (id)initWithAnalyticsLogger:(id)logger initWithLauncherSet:(id)launcherSet userDefaults:(id)defaults {
    return nil;
}
%end
