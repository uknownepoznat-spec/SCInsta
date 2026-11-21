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
- [ ] Check nested settings, switches, menu buttons, Done, Discord copy and TikTok link.
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
- [ ] If message capture fails, copy Debug → Compatibility report and record the reproduction steps.
