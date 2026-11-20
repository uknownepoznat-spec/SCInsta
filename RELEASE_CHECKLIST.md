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
- [ ] Enable both story download switches; set Saving → Finger count to 1 for testing.
- [ ] Save an image story and a video story from both a followed account and a public account.
- [ ] Confirm the share sheet offers Save Image / Save Video and the saved file opens in Photos.
- [ ] Revisit a story several times; one hold must start only one download.
- [ ] Cancel a download, retry, and try offline: the HUD must dismiss and errors must not open the share sheet.
- [ ] An expired/unsupported story should show an error instead of crashing.
- [ ] Verify feed/reel downloads still work after the shared URL/downloader changes.
- [ ] Open settings via the profile menu; check dashboard sizing on iPhone/iPad and larger text sizes.
- [ ] Check nested settings, switches, menu buttons, Done, Discord copy and TikTok link.
- [ ] If a crash persists, record Instagram/iOS versions and export the matching Instagram .ips crash log.
