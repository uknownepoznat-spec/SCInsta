# New Version - Release Checklist

### Before git pushing
- [ ] Update version string in `control`
- [ ] Update version string in `src/Tweak.x`
- [ ] Update version string at top of `README.md` 
- [ ] Update compatible Instagram app version at top of `README.md`
- [ ] Update features list in  `README.md`
- [ ] (Optional) Update screenshots

### Creating new release
- [ ] Ensure new tag is created with proper format
- [ ] Make sure to include full changelog in release notes
- [ ] Include rootful & rootless deb files in release

### Story downloads and settings regression checks (on device)
- [ ] Enable Saving → Stories → Enable saving; set its Fingers to 1 for testing.
- [ ] Save an image story and a video story from both a followed account and a public account.
- [ ] Confirm the share sheet offers Save Image / Save Video and the saved file opens in Photos.
- [ ] Revisit a story several times; one hold must start only one download.
- [ ] Cancel a download, retry, and try offline: the HUD must dismiss and errors must not open the share sheet.
- [ ] An expired/unsupported story should show an error instead of crashing.
- [ ] Verify feed/reel downloads still work after the shared URL/downloader changes.
- [ ] Open settings via the profile menu; check dashboard sizing on iPhone/iPad and larger text sizes.
- [ ] Check nested settings, switches, menu buttons, Done, the Discord server link and TikTok link.
- [ ] Confirm the menu title is Peki Scripter V2, its default palette is black/white and there is no Instagram logo/handle header or blank header spacing; Privacy/Gestures shortcuts and story-summary clutter are absent.
- [ ] Confirm Preferences → Support shows Join Discord rather than reopening the licence form, and both it and the initial screen's Join Discord button open the configured server.
- [ ] Confirm Saving and Stories and messages still contain their original gesture/privacy controls and remain searchable.
- [ ] Confirm Preferences starts with Stories and messages, Saving, General; Debug is absent, and Contact lists Instagram, Discord, TikTok in that order.
- [ ] Check standard grouped rows and plain symbols; no decorative category tiles or theme-preview card. Ensure useful hints, restart confirmations, HEX validation and local-archive scope/limits remain clear.
- [ ] If a crash persists, record Instagram/iOS versions and export the matching Instagram .ips crash log.

### Customization and archive regression checks (on device)
- [ ] Run `pwsh -File tests/check-source.ps1`, then build with Theos.
- [ ] Change fingers/time independently for feed, stories, reels and profiles while existing media views remain loaded; verify changes apply immediately.
- [ ] Disable each media kind; its gesture must stop working while the others remain enabled.
- [ ] Switch Share & save / Preview; verify both image and video output.
- [ ] Change themes and accents; verify root/nested screens update and preferences survive relaunch.
- [ ] Search for a switch/gesture, change it from search, cancel search, and open the original category.
- [ ] Enable local text retention, open a chat, unsend your own visible text; verify it appears in the local archive and Instagram still performs its normal unsend.
- [ ] Receive/read text, then have the sender unsend it; verify a local copy if this Instagram build uses the supported hooks.
- [ ] Relaunch and check archive persistence; test copy, individual removal, Clear, and capture disabled.
- [ ] Verify archive contains no media attachments and does not claim to recover messages never observed.
- [ ] Turn unlimited replay off; normal playback callbacks must still run.
- [ ] Check read/view receipts from a second account; do not infer privacy from local UI alone.
- [ ] If message capture fails, record Instagram/iOS versions, reproduction steps and any matching .ips log; the Debug menu is no longer exposed.

### Appearance / LiveContainer
- [ ] New guest data: feed/stories/reels/profile saving defaults to two fingers and 0.5 seconds.
- [ ] Existing explicitly configured gestures are preserved; Reset asks for confirmation and updates visible labels/recognizers.
- [ ] Check default initialization from opening the tweak menu/media views when the private app-delegate hook is unavailable; host launcher windows must not initialize guest defaults.
- [ ] Check all 16 palettes, including Paper/Pearl/Sand light surfaces, and reopen the app to verify persistence.
- [ ] Custom palette: test the native picker and valid/invalid HEX entry; changing a color must not detach an active color picker.
- [ ] Try mixed light/dark custom background/surface colors and confirm body text remains readable.
- [ ] Test larger accessibility text sizes in the menu and theme editor.
- [ ] Enable Instagram tint/native appearance in the guest; verify only supported inherited UIKit controls change.
- [ ] Turn overrides off, then return to LiveContainer's launcher; its native tint/appearance must remain unchanged.
- [ ] Test both scene-based and legacy guest window lifecycles; unrelated/keyboard windows must be skipped.
- [ ] Update the guest without resetting its data container; confirm preferences survive.

### KeyAux / Cloudflare access gate
- [ ] Rotate the exposed app secret; store the replacement only as a Worker secret.
- [x] Deploy a fresh D1/Worker as documented in `server/keyaux-worker/README.md`; set the public URL in native config.
- [x] Run source/palette checks and `node --test` in `server/keyaux-worker`.
- [x] Deploy the redirect repair and pass live configuration, proof/replay and nonexistent-license smoke checks.
- [ ] Build with `LICENSE_REQUIRED=1`; an unset URL/secret or an unavailable network must not unlock.
- [ ] On the target signed LiveContainer, confirm Secure Enclave/Keychain works and a fresh one-activation test key binds to that device on its first successful activation.
- [ ] Check the minimal Peki Scripter V2 screen: black background, white lettering, dark controls, camera mark, Enter your licence, Activate and Join Discord; no device ID or diagnostic widgets.
- [ ] With the keyboard visible and larger accessibility text enabled, verify the licence field, action and short errors remain reachable.
- [ ] Verify valid login, invalid key, expiry, ban, wrong-device use, foreground return, and periodic online checks against the real provider.
- [ ] Confirm repeated checks do not consume another activation.
- [ ] Test a current story/modal, rotation, multitasking, app switching, keyboard and text-selection/Paste UI while locked.
- [ ] Returning to LC's launcher must hide the guest cover and must not cause an authentication request for the host.
- [ ] A generic keyboard/text-selection window must not be treated as a host transition or expose the guest.
- [ ] Check keychain restoration across guest updates, then explicit reset/reapproval on a signing/access-group change.
- [ ] Confirm Join Discord and the Contact Discord row open `https://discord.gg/qTB3G7gCAp`; Instagram opens `@pekifn` and TikTok opens `@peki_scripter`.
# Beta reminder device checks

- [ ] Build the updated IPA and confirm cold launch reaches Instagram without the "It's time to update Instagram beta" screen.
- [ ] Confirm background/foreground and account switching work without a crash or a blank screen; the scoped reminder initializer now returns nil.
- [ ] Confirm the licence gate still requires activation and unrelated Instagram alerts still work. This change is not tested on-device and does not replace an expired or server-blocked Instagram build.
# Remembered activation device checks

- [ ] Activate once, relaunch and repeatedly background/foreground: no licence-screen flash.
- [ ] Disconnect the network after activation: cached access remains; reconnect and confirm background refresh succeeds.
- [ ] Revoke/expire the licence in the provider dashboard: a confirmed denial must show activation again.
- [ ] Delete the Instagram guest AND its data in LiveContainer, reinstall, and confirm licence entry is required despite surviving Keychain items.
- [ ] Confirm replacing only the IPA with preserved guest data keeps activation. Native build/device tests are still required.
