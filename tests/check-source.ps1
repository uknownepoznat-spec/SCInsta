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
$media = Read-Source 'src/Features/Media/MediaDownload.xm'
$archive = Read-Source 'src/Archive/SCIMessageArchive.m'
$hooks = Read-Source 'src/Features/StoriesAndMessages/KeepDeletedMessages.x'
$seen = Read-Source 'src/Features/StoriesAndMessages/SeenButtons.x'

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
Assert-Source ((Read-Source 'src/Tweak.x').Contains('@"keep_deleted_message": @(NO)')) 'New installations must opt into local text capture'
Assert-Source ([regex]::Matches($seen, '!dmVisualMsgsViewedButtonEnabled\) return;\s*%orig;').Count -eq 2) 'Media playback must call the original when replay override is off'
Write-Output "PASS: $($files.Count) source delimiter checks and feature wiring contracts."
Write-Output 'Runtime behavior still requires a Theos build and testing on the target Instagram/iOS version.'
