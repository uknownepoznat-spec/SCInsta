$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent

function Read-Source([string]$path) {
    return [IO.File]::ReadAllText((Join-Path $root $path))
}

function Assert-Source([bool]$condition, [string]$message) {
    if (-not $condition) { throw $message }
}

# Lightweight cross-platform source contracts, not a replacement for Theos or
# device testing. Run with: pwsh -File tests/check-source.ps1
$files = Get-ChildItem (Join-Path $root 'src') -Recurse -File |
    Where-Object { $_.Extension -in @('.m', '.h', '.x', '.xm') }
$literalOrComment = '(?s)/\*.*?\*/|//[^\r\n]*|@?"(?:\\.|[^"\\])*"|''(?:\\.|[^''\\])*'''
foreach ($file in $files) {
    $text = [IO.File]::ReadAllText($file.FullName)
    $clean = [regex]::Replace($text, $literalOrComment, '')
    $stack = [Collections.Generic.Stack[char]]::new()
    $pairs = @{')'='('; ']'='['; '}'='{'}
    foreach ($ch in $clean.ToCharArray()) {
        if ('([{'.Contains([string]$ch)) {
            $stack.Push($ch)
        } elseif (')]}'.Contains([string]$ch)) {
            Assert-Source ($stack.Count -gt 0) "Unexpected closing delimiter in $($file.Name)"
            Assert-Source ($stack.Pop() -eq $pairs[[string]$ch]) "Mismatched delimiter in $($file.Name)"
        }
    }
    Assert-Source ($stack.Count -eq 0) "Unclosed delimiter in $($file.Name)"
}

$settings = Read-Source 'src/Settings/TweakSettings.m'
$controller = Read-Source 'src/Settings/SCISettingsViewController.m'
$gesture = Read-Source 'src/Features/Media/SCIMediaGesture.m'
$gestureHeader = Read-Source 'src/Features/Media/SCIMediaGesture.h'
$media = Read-Source 'src/Features/Media/MediaDownload.xm'
$archive = Read-Source 'src/Archive/SCIMessageArchive.m'
$hooks = Read-Source 'src/Features/StoriesAndMessages/KeepDeletedMessages.x'
$seen = Read-Source 'src/Features/StoriesAndMessages/SeenButtons.x'
$theme = Read-Source 'src/Appearance/SCITheme.m'
$themeEditor = Read-Source 'src/Settings/SCIThemeEditorViewController.m'
$utils = Read-Source 'src/Utils.m'
$tweak = Read-Source 'src/Tweak.x'

foreach ($unsupported in @('message_encryption', 'enable_auto_reply', 'message_schedule',
    'hd_profile_pictures', 'unseen_stories_counter', 'story_downloader', 'anti_delete', 'test_menu_cell')) {
    Assert-Source (-not $settings.Contains('@"' + $unsupported + '"')) "Unsupported setting still exposed: $unsupported"
}
foreach ($kind in @('feed', 'stories', 'reels', 'profile')) {
    Assert-Source ($settings.Contains('@[@"' + $kind + '"')) "Missing gesture settings: $kind"
    Assert-Source ($media.Contains('@"' + $kind + '"')) "Missing media gesture consumer: $kind"
}
Assert-Source ($gesture.Contains('SCISettingsDidChangeNotification')) 'Gestures do not observe settings changes'
Assert-Source ($gesture.Contains('objc_getAssociatedObject')) 'Gesture deduplication missing'
Assert-Source ([regex]::IsMatch($gestureHeader, '(?s)#ifdef\s+__cplusplus\s+extern\s+"C"\s*\{\s*#endif\s+void\s+SCIInstallMediaDownloadGesture')) 'Shared media gesture function needs C linkage for Objective-C++ callers'
Assert-Source ([regex]::Matches($controller, 'postNotificationName:SCISettingsDidChangeNotification').Count -eq 3) 'Not all preference controls notify gesture consumers'
Assert-Source ($controller.Contains('[properties[@"requiresRestart"] boolValue]')) 'Menu restart flag uses object truthiness'
Assert-Source ($controller.Contains('updateSearchResultsForSearchController:')) 'Search UI has no implementation'
Assert-Source ($hooks.Contains('%init;')) 'Logos deletion factory hooks are not initialized'
Assert-Source (-not [regex]::IsMatch($hooks, '(?:messageID|arg1)\s*=\s*(?:NULL|nil)')) 'Unexpected NULL deletion logic'
Assert-Source (-not $hooks.Contains('%orig(nil)')) 'Deletion IDs must not be replaced'
Assert-Source ($hooks.Contains('signature.numberOfArguments')) 'Runtime archive hooks are not ABI checked'
Assert-Source ($archive.Contains('NSApplicationSupportDirectory')) 'Archive must survive cache cleanup'
Assert-Source ($archive.Contains('NSURLIsExcludedFromBackupKey')) 'Archive backup exclusion missing'
Assert-Source ($archive.Contains('NSDataWritingFileProtectionCompleteUntilFirstUserAuthentication')) 'Archive file protection missing'
Assert-Source ($archive.Contains('self.entries.count > 500')) 'Archive retention bound missing'
Assert-Source ($archive.Contains('SCIArchiveCapturing')) 'Archive getter recursion guard missing'
Assert-Source ($archive.Contains('if ([previous[@"deleted"] boolValue]) return;')) 'Retained text can be overwritten by a deletion placeholder'
Assert-Source ($utils.Contains('@"keep_deleted_message": @NO')) 'New installations must opt into local text capture'
Assert-Source ([regex]::Matches($seen, '!dmVisualMsgsViewedButtonEnabled\) return;\s*%orig;').Count -eq 2) 'Media playback must call the original when replay override is off'
Assert-Source ($utils.Contains('@"dw_finger_count": @(2)')) 'New installations must default to two fingers'
Assert-Source ($utils.Contains('value ? value.integerValue : 2')) 'Unregistered gesture fallback must use two fingers'
Assert-Source (-not $utils.Contains('@([SCIUtils downloadFingerCountForKind:kind])')) 'Guest startup must not seed a new default from an old per-kind registration domain'
Assert-Source ($gesture.Contains('[SCIUtils registerGuestDefaults]') -and $settings.Contains('[SCIUtils registerGuestDefaults]')) 'Defaults must also initialize when the guest app delegate hook is unavailable'
Assert-Source ($settings.Contains('Reset gestures to two fingers')) 'Existing users need an explicit reset without silently overwriting their settings'
Assert-Source ($theme.Contains('if (value.length != 6) return nil;')) 'Custom colors require strict six-digit RGB validation'
Assert-Source ($theme.Contains('0123456789ABCDEF')) 'Custom RGB validation must reject non-hex characters'
Assert-Source ($themeEditor.Contains('UIColorWell')) 'Custom palette has no color picker'
Assert-Source ($themeEditor.Contains('hexSaveAction.enabled')) 'Invalid HEX input must not be applied'
Assert-Source ($theme.Contains('[name hasPrefix:@"LC"]') -and $theme.Contains('LiveContainer')) 'LiveContainer host roots must be excluded'
Assert-Source ($theme.Contains('state.originalTint') -and $theme.Contains('state.originalStyle')) 'App appearance must restore its baseline when disabled'
Assert-Source (-not $theme.Contains('[UIView appearance')) 'Guest styling must not use a process-global appearance proxy'
Assert-Source ($theme.Contains('contrast >= 3.0')) 'Native tweak controls must retain visible light/dark contrast'

$palettes = [regex]::Matches($theme, '@\[@"([a-z]+)", @"([^"]+)", @"([0-9A-F]{6})", @"([0-9A-F]{6})", @"([0-9A-F]{6})"\]')
Assert-Source ($palettes.Count -eq 16) 'Expected 16 well-formed RGB theme palettes'
$ids = @($palettes | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
Assert-Source ($ids.Count -eq 16) 'Theme IDs must be unique'
function Get-PaletteLuminance([string]$hex) {
    $channels = @()
    for ($offset = 0; $offset -lt 6; $offset += 2) {
        $value = [Convert]::ToInt32($hex.Substring($offset, 2), 16) / 255.0
        $channels += $(if ($value -le 0.04045) { $value / 12.92 } else { [Math]::Pow(($value + 0.055) / 1.055, 2.4) })
    }
    return $channels[0] * 0.2126 + $channels[1] * 0.7152 + $channels[2] * 0.0722
}
foreach ($palette in $palettes) {
    foreach ($component in @(3, 4)) {
        $luminance = Get-PaletteLuminance $palette.Groups[$component].Value
        $contrast = [Math]::Max(1.05 / ($luminance + 0.05), ($luminance + 0.05) / 0.05)
        Assert-Source ($contrast -ge 4.5) "Unreadable body text in $($palette.Groups[1].Value)"
    }
}
Write-Output "PASS: $($files.Count) source delimiter checks and feature wiring contracts."
Write-Output "PASS: $($palettes.Count) unique RGB palettes and body-text contrast data checks."
Write-Output 'Runtime behavior still requires a Theos build and testing on the target Instagram/iOS version.'
