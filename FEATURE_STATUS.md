# Peki Scripter: custom build behavior

## Saving
- **Saving** has separate enable switches, finger counts (1–4), and hold durations (0.25–10 seconds) for feed posts, stories, reels and profile pictures.
- Existing recognizers update when preferences change; repeated view attachment does not install duplicate download gestures.
- Old global finger/time preferences are used as initial per-media values.
- **Open with → Share & save** opens the system share sheet; **Preview** uses Quick Look.
- There is one story-saving switch, not an additional dummy "Story Downloader" switch.

## Deleted text
- Enable **Stories and messages → Retain deleted text locally** before opening the chat.
- Text observed through supported message getters/setters is cached locally. Supported deletion events mark those snapshots as retained. Own unsend attempts also snapshot the supplied message when available.
- **Open local archive** provides read/copy, individual deletion and Clear.
- This does **not** restore messages in Instagram's chat/server, stop someone else's unsend, recover old unsent text, or back up images/videos.
- Up to 500 snapshots (including pending copies), 16,000 characters each. Stored in Application Support with iOS file protection and excluded from backup.
- The archive is **device-wide across accounts on this installation**. Turning capture off stops new copies; use Clear to erase existing copies. Capture defaults off for new installations.
- If Instagram uses different model classes or selectors, these hooks may not see a message. **Debug → Copy compatibility report** reports method availability without message/account contents. Method presence is not proof of successful runtime behavior.

## Privacy and replay
- Removed fake `IGUser.isOnline/isActive` overrides, which only changed the local display. Supported outbound presence hooks remain; also turn off Activity Status in Instagram itself.
- Story-view hiding uses the existing seen-uploader hook. Restart after changing it.
- Read receipts and visual-message view receipts retain their session toolbar overrides.
- Fixed visual-message playback callbacks being swallowed even when unlimited replay was turned off.
- All private Instagram hooks are version dependent. Already-sent receipts cannot be undone.

## Menu
- Independent category cards, search across settings, Privacy/Gestures shortcuts, and a live story-gesture summary.
- **Style studio** changes Midnight/Graphite/OLED surfaces and blue/ice/lime/monochrome accents immediately.
- Discord copies `pekiscripter`; TikTok opens `@peki_scripter`.

## Removed rather than misrepresented
The old auto-reply, message scheduler, extra message encryption, HD profile-picture modifier and unseen-story counter had no implementation. Their switches and no-op hooks were removed. They are **not implemented** in this build. The fake scheduler that could swallow outgoing messages was also removed.

## Validation
`pwsh -File tests/check-source.ps1` checks source structure and wiring, not runtime functionality. Build with Theos and run the device scenarios in `RELEASE_CHECKLIST.md` before claiming support for an Instagram version.
