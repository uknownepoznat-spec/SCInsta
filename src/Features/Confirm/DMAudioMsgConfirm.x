#import "../../Utils.h"

// Legacy hook (for non ai voices interface)
%hook IGDirectThreadViewController
- (void)voiceRecordViewController:(id)arg1 didRecordAudioClipWithURL:(id)arg2 waveform:(id)arg3 duration:(CGFloat)arg4 entryPoint:(NSInteger)arg5 {
    static BOOL confirming = NO;
    if ([SCIUtils getBoolPref:@"voice_message_confirm"] && !confirming) {
        NSLog(@"[PekiWare] DM audio message confirm triggered");

        confirming = YES;
        [SCIUtils showConfirmation:^{
            confirming = NO;
            [(id)self voiceRecordViewController:arg1 didRecordAudioClipWithURL:arg2 waveform:arg3 duration:arg4 entryPoint:arg5];
        } cancelHandler:^{
            confirming = NO;
        }];
        return;
    }
    return %orig;
}
%end

// Workaround until I can figure out how to stop long press recording from automatically sending
%hook IGDirectComposer
- (void)_didLongPressVoiceMessage:(id)arg1 {
    if ([SCIUtils getBoolPref:@"voice_message_confirm"]) {
        return;
    } else {
        return %orig;
    }
}
%end

// Demangled name: IGDirectAIVoiceUIKit.CompactBarContentView
%hook _TtC20IGDirectAIVoiceUIKitP33_5754F7617E0D924F9A84EFA352BBD29A21CompactBarContentView
- (void)didTapSend {
    static BOOL confirmingSend = NO;
    if ([SCIUtils getBoolPref:@"voice_message_confirm"] && !confirmingSend) {
        NSLog(@"[PekiWare] DM audio message confirm triggered");

        confirmingSend = YES;
        [SCIUtils showConfirmation:^{
            confirmingSend = NO;
            [(id)self didTapSend];
        } cancelHandler:^{
            confirmingSend = NO;
        }];
        return;
    }
    return %orig;
}
%end
