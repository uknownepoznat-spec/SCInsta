# Peki Scripter: custom build behavior

## Saving
- **Saving** has separate enable switches, finger counts (1–4), and hold durations (0.25–10 seconds) for feed posts, stories, reels and profile pictures.
- Existing recognizers update when preferences change; repeated view attachment does not install duplicate download gestures.
- Old global finger/time preferences are used as initial per-media values.
- New/unset saving gestures default to **2 fingers / 0.5 seconds**, including profile pictures. Explicit user choices are preserved. **Saving → Reset gestures to two fingers** resets all four media types after confirmation.
- Defaults initialize from the known Instagram delegate, media gesture installation, or the explicitly opened tweak menu; the private delegate hook is no longer the only initialization path. Host-window layout does not register guest defaults.
- **Open with → Share & save** opens the system share sheet; **Preview** uses Quick Look.
- There is one story-saving switch, not an additional dummy "Story Downloader" switch.

## License access
- Production builds default to an online KeyAux license check through the Cloudflare Worker in `server/keyaux-worker/`. The Worker and dedicated D1 database were deployed on 2026-11-21, and the public URL is set in `src/License/SCILicenseConfig.m`. See the server README for secret-setup and acceptance-test status.
- App secrets stay in Worker secrets. The exposed conversation secret is not used. App/Owner IDs and version are public configuration.
- The access screen covers recognized Instagram-owned guest windows. Initial settings presentation and media saving also check authorization. It is not an Instagram-account login.
- Device binding uses a SHA-256 P-256 public-key fingerprint internally. The native client requires a Secure Enclave key; unsupported Keychain/signing setups fail closed with a short error. Device IDs and diagnostic controls are not displayed on the license screen.
- Worker challenges are short-lived, one-use and signature-checked. KeyAux verifies the current activation before attempting a new activation.
- Authorization exists only as an active-app, monotonic lease of at most 300 seconds. Offline/expired/revoked/invalid requests do not grant access. Foreground return requires rechecking.
- Keychain/access-group/container changes can change or lose the device key. This is not a permanent IMEI/serial identifier, remote hardware attestation, or unbreakable anti-repack DRM.
- The **Peki Scripter V2** access screen has a fixed black/white palette, dark fields/buttons, a monochrome camera mark, `Enter your licence` and `Activate`. It shows only short errors when needed; device-code, retry, forget and diagnostic widgets are removed from this screen.
- Login keeps `@pekifn` and `TikTok: @pekiscripter`. Its separate **Join Discord** button opens `https://discord.gg/qTB3G7gCAp`. The invite is compiled into the client, independent of Worker configuration.
- `V2` is display branding; the KeyAux protocol/application version remains `1.0`. Device proof, Keychain credentials and online authorization are unchanged.
- The redirect repair was deployed on 2026-11-22. All 21 local tests pass, including a real workerd/local-D1 integration test with a mocked provider. Live configuration, signed-proof/replay handling and nonexistent-license denial also pass. A valid-license login and native LiveContainer behavior still require a rebuilt guest IPA and on-device acceptance tests.

## Deleted text
- Enable **Stories and messages → Retain deleted text locally** before opening the chat.
- Text observed through supported message getters/setters is cached locally. Supported deletion events mark those snapshots as retained. Own unsend attempts also snapshot the supplied message when available.
- **Open local archive** provides read/copy, individual deletion and Clear.
- This does **not** restore messages in Instagram's chat/server, stop someone else's unsend, recover old unsent text, or back up images/videos.
- Up to 500 snapshots (including pending copies), 16,000 characters each. Stored in Application Support with iOS file protection and excluded from backup.
- The archive is **device-wide across accounts on this installation**. Turning capture off stops new copies; use Clear to erase existing copies. Capture defaults off for new installations.
- If Instagram uses different model classes or selectors, these hooks may not see a message. The compatibility-report helper remains in `SCIUtils` for developer diagnostics, but its old Debug menu entry is removed. Method presence is not proof of successful runtime behavior.
- **Vencord-style retention/red marking inside the original chat is not implemented.** This was explicitly deferred pending the target Instagram's runtime report; the separate archive is not a substitute for that requested UI.

## Privacy and replay
- Removed fake `IGUser.isOnline/isActive` overrides, which only changed the local display. Supported outbound presence hooks remain; also turn off Activity Status in Instagram itself.
- Story-view hiding uses the existing seen-uploader hook. Restart after changing it.
- Read receipts and visual-message view receipts retain their session toolbar overrides.
- Fixed visual-message playback callbacks being swallowed even when unlimited replay was turned off.
- All private Instagram hooks are version dependent. Already-sent receipts cannot be undone.

## Menu
- **Peki Scripter V2** title, search, plain icons and standard grouped settings. Decorative category cards, repeated descriptions, promotional theme footers and the large theme-preview card are removed. Short usage hints, restart notices and local-archive limits remain.
- The hidden menu has no Instagram logo/handle header, extra Privacy/Gestures shortcuts or story-summary strip; actual controls remain under Saving and Stories and messages.
- The default palette is **Peki V2**: black background, charcoal surfaces and white lettering/accents matching the license screen. Contact titles and navigation text follow the readable text color instead of a saved colored accent. The stored preference ID remains `carbon`, so the old default adopts the updated colors without overwriting explicit theme/accent choices.
- Existing builds can use **Appearance → Theme → OLED black** and **Accent → Monochrome** for a black/white hidden menu without rebuilding. The fixed login styling changes only after rebuilding the IPA.
- **Appearance → Theme** still offers 16 palettes: Peki V2, Midnight, Graphite, OLED black, Slate, Ocean, Forest, Moss, Espresso, Copper, Burgundy, Indigo, Dusk, Paper, Pearl and Sand.
- **Custom** supports a native RGB picker and validated `#RRGGBB` entry for background, surface and accent. Body text automatically chooses black/white for each surface. Accent overrides are independent of preset surfaces.
- Preferences starts with **Stories and messages → Saving → General**, followed by Feed, Reels, Navigation, Confirm actions, Appearance and Support. The Debug page is removed; stored preferences and licence checks are not reset.
- **Preferences → Support → Join Discord** opens the purchase server, not the licence form.
- Contact rows are **Instagram `@pekifn` → Discord `pekiscripter` → TikTok `@pekiscripter`**, in that order. Both Discord actions open the configured server.

## Instagram appearance / LiveContainer
- **Appearance → Instagram** offers app-default/dark/light native appearance plus an optional theme accent; this integration remains version-dependent.
- This uses window-level UIKit overrides only on recognizable Instagram-owned roots, not global `UIAppearance` proxies. LC/LiveContainer roots, unrelated windows and guests presented on a host-owned root are skipped.
- It does not recolor every SwiftUI component, explicitly colored Instagram control, story ring, image/video, or DM bubble. If Instagram overrides a control's tint/style, that part may not change.
- Native accent shade adapts when needed for contrast on Instagram's light/dark UIKit surfaces. The custom-menu palette retains your chosen RGB values.
- Defaults leave Instagram's appearance untouched. Disabling overrides restores the captured native values; changing the window root also restores the baseline.
- In LiveContainer, update/re-sign the **guest IPA**, not a rootless `.deb`. Keep its existing data container when updating if you want preferences/local files preserved. Deleting or resetting guest data erases those files.
- These changes are not yet device-verified in LiveContainer.

## Removed rather than misrepresented
The old auto-reply, message scheduler, extra message encryption, HD profile-picture modifier and unseen-story counter had no implementation. Their switches and no-op hooks were removed. They are **not implemented** in this build. The fake scheduler that could swallow outgoing messages was also removed.

## Validation
`pwsh -File tests/check-source.ps1` checks source structure, wiring, palette data and body-text contrast, not UIKit/runtime functionality. Build with Theos and run the device scenarios in `RELEASE_CHECKLIST.md` before claiming support for an Instagram version.
