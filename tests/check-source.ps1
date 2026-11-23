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
$betaNag = Read-Source 'src/Features/General/SCBetaUpdateNag.x'
Assert-Source ($betaNag.Contains('%hook IGTestFlightUpdateNagController')) 'Beta reminder suppression must target only the observed TestFlight controller'
Assert-Source ($betaNag.Contains('initWithAnalyticsLogger:(id)logger initWithLauncherSet:(id)launcherSet userDefaults:(id)defaults')) 'Beta reminder hook must match the inspected initializer'
Assert-Source ($betaNag.Contains('return nil;') -and -not $betaNag.Contains('%orig')) 'Beta reminder initialization must not register its prompt'
Assert-Source (-not $betaNag.Contains('%hook UIViewController') -and -not $betaNag.Contains('%hook NSBundle')) 'Beta suppression must not intercept general presentation or bundle metadata'
$licenseConfig = Read-Source 'src/License/SCILicenseConfig.h'
$licenseManager = Read-Source 'src/License/SCILicenseManager.m'
$licenseView = Read-Source 'src/License/SCILicenseViewController.m'
$deviceKey = Read-Source 'src/License/SCILicenseDeviceKey.m'
$gateHook = Read-Source 'src/Features/General/SCSettingsMenuEntry.x'

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
Assert-Source (-not $controller.Contains('SCICategoryIcon') -and -not $controller.Contains('NSMutableArray *cards')) 'Settings must use plain symbols and grouped rows, not decorative category cards'
Assert-Source ($controller.Contains('cellContentConfig.image = [row.icon image]')) 'Plain setting icons must remain connected'
foreach ($verboseCopy in @('16 themes, custom colors and Instagram tint', '16 presets, color picker and HEX input',
    'Menu themes apply immediately. Custom RGB colors are stored locally.', 'Shows an alert when you click')) {
    Assert-Source (-not $settings.Contains($verboseCopy)) "Removed repetitive UI copy returned: $verboseCopy"
}
Assert-Source (-not $themeEditor.Contains('buildPreview') -and -not $themeEditor.Contains('No gradients or downloaded theme files')) 'The theme picker must not restore its promotional preview or footer'
Assert-Source ($settings.Contains('Old messages and attachments cannot be recovered') -and $settings.Contains('shared across accounts')) 'Shorter archive copy must retain recovery limits and shared-device scope'
Assert-Source ($settings.Contains('Restart required.') -and $settings.Contains('requiresRestart:YES')) 'Copy cleanup must preserve restart guidance and behavior'
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
$defaultPalette = $palettes | Where-Object { $_.Groups[1].Value -eq 'carbon' } | Select-Object -First 1
$accentLuminance = Get-PaletteLuminance $defaultPalette.Groups[5].Value
foreach ($component in @(3, 4)) {
    $surfaceLuminance = Get-PaletteLuminance $defaultPalette.Groups[$component].Value
    $contrast = ([Math]::Max($accentLuminance, $surfaceLuminance) + 0.05) / ([Math]::Min($accentLuminance, $surfaceLuminance) + 0.05)
    Assert-Source ($contrast -ge 4.5) 'V2 white controls must remain readable on the default menu surfaces'
}
$actionLuminance = Get-PaletteLuminance '1C1C1C'
Assert-Source ((1.05 / ($actionLuminance + 0.05)) -ge 4.5) 'The dark Activate action must retain readable white text'
Assert-Source ($licenseConfig.Contains('#define SCI_LICENSE_REQUIRED 1')) 'License checks must default on'
Assert-Source ((Read-Source 'Makefile').Contains('LICENSE_REQUIRED ?= 1')) 'Production builds must not silently disable licensing'
Assert-Source ((Read-Source 'src/License/SCILicenseConfig.m').Contains('containsString:@"YOUR-"')) 'An unset Worker URL must be rejected'
Assert-Source ($deviceKey.Contains('kSecAttrTokenIDSecureEnclave')) 'Device identity must require the declared Secure Enclave key'
Assert-Source ([regex]::Matches($deviceKey, 'kSecAttrAccessibleWhenUnlockedThisDeviceOnly').Count -ge 2) 'Device key and saved credential must be device-only'
Assert-Source ($deviceKey.Contains('SecKeyCreateSignature')) 'Device code alone must not authorize access'
Assert-Source ($licenseManager.Contains('validUntilUptime') -and $licenseManager.Contains('systemUptime')) 'Authorization must use an expiring monotonic in-memory lease'
Assert-Source ($licenseManager.Contains('UIApplicationWillResignActiveNotification')) 'Foreground return must recheck access'
Assert-Source ($licenseManager.Contains('completionHandler(nil)')) 'License credentials must not follow redirects'
Assert-Source ($licenseManager.Contains('[source endEditing:YES]')) 'The underlying Instagram keyboard must lose focus before the access cover is shown'
Assert-Source ($licenseManager.Contains('CFBooleanGetTypeID()')) 'A truthy string must not authorize the native client'
foreach ($text in @('Peki Scripter V2', '@pekifn', 'Join Discord', 'TikTok: @peki_scripter', 'Enter your licence')) {
    Assert-Source ($licenseView.Contains($text)) "Missing minimal license-screen identity or control: $text"
}
Assert-Source ($licenseView.Contains('configuration.title = @"Activate"')) 'The license screen must have a single primary Activate action'
foreach ($removed in @('No access', 'Buy a key', 'Device code', 'Copy device code', 'Retry saved license',
    'Forget saved license', 'Copy compatibility report', 'Never enter your Instagram password', 'Device code is a public-key')) {
    Assert-Source (-not $licenseView.Contains($removed)) "Removed license-screen clutter returned: $removed"
}
Assert-Source ($licenseView.Contains('manager.errorMessage') -and -not $licenseView.Contains('manager.message')) 'The minimal form must show short errors, not diagnostic paragraphs'
Assert-Source ($licenseView.Contains('SCIBrandMarkView') -and $licenseView.Contains('SCILicenseAccentColor()')) 'The license screen must retain its monochrome camera mark'
Assert-Source ($licenseView.Contains('self.view.backgroundColor = UIColor.blackColor') -and $licenseView.Contains('self.keyField.textColor = UIColor.whiteColor')) 'The license screen must use a black background with white lettering'
Assert-Source (-not $licenseView.Contains('colorWithRed:')) 'The monochrome login must not keep colored accents'
foreach ($removedIdentity in @('SCIBrandMarkView', '@pekifn', 'buildDashboardHeader', 'tableHeaderView')) {
    Assert-Source (-not $controller.Contains($removedIdentity)) "Removed hidden-menu identity header returned: $removedIdentity"
}
Assert-Source ($settings.Contains('linkCellWithTitle:@"Instagram" subtitle:@"@pekifn"')) 'Contact must include the requested Instagram profile'
Assert-Source (-not $settings.Contains('navigationCellWithTitle:@"Debug"')) 'The removed Debug page must not return'
Assert-Source ($settings.Contains('@"Stories and messages", @"Saving", @"General"')) 'Preferences must start with Stories and messages, Saving, General'
Assert-Source ($settings.Contains('orderedPreferences[@"rows"] = [orderedRows copy]') -and $settings.Contains('for (SCISetting *row in rows) if (![orderedRows containsObject:row])')) 'Category ordering must be applied without dropping future settings'
$instagramContact = $settings.IndexOf('linkCellWithTitle:@"Instagram"')
$discordContact = $settings.IndexOf('linkCellWithTitle:@"Discord"')
$tiktokContact = $settings.IndexOf('linkCellWithTitle:@"TikTok"')
Assert-Source ($instagramContact -ge 0 -and $discordContact -gt $instagramContact -and $tiktokContact -gt $discordContact) 'Contact order must be Instagram, Discord, TikTok'
Assert-Source ($settings.Contains('linkCellWithTitle:@"TikTok" subtitle:@"@peki_scripter"') -and $settings.Contains('https://www.tiktok.com/@peki_scripter')) 'The TikTok handle and URL must match the requested account'
Assert-Source ($controller.Contains('self.navigationItem.title = [SCITweakSettings title]') -and $settings.Contains('return @"Peki Scripter V2";')) 'The hidden menu must use Peki Scripter V2 branding'
foreach ($removedShortcut in @('shortcutWithTitle:', 'openPrivacy:', 'openGestures:', 'Story saving')) {
    Assert-Source (-not $controller.Contains($removedShortcut)) "Removed dashboard shortcut or summary returned: $removedShortcut"
}
Assert-Source ($settings.Contains('navigationCellWithTitle:@"Saving"') -and $settings.Contains('navigationCellWithTitle:@"Stories and messages"')) 'Removing dashboard shortcuts must not remove the gesture/privacy settings pages'
Assert-Source ($theme.Contains('@[@"carbon", @"Peki V2", @"000000", @"0E0E0E", @"FFFFFF"]')) 'The default palette must be black/white without changing preference IDs'
Assert-Source (-not $controller.Contains('cellContentConfig.textProperties.color = SCITheme.accentColor')) 'Contact titles must follow the readable text color instead of a saved colored accent'
Assert-Source ($settings.Contains('navigationCellWithTitle:@"Support"') -and $settings.Contains('linkCellWithTitle:@"Join Discord"')) 'Preferences must contain Support with the Join Discord action'
Assert-Source (-not $settings.Contains('controllerCellWithTitle:@"License"') -and -not $settings.Contains('[SCILicenseViewController new]')) 'The Support entry must not reopen the licensing form'
Assert-Source ($settings.Contains('url:SCILicenseConfig.supportURL.absoluteString')) 'The menu Discord contact must open the same purchase server as login'
Assert-Source ($licenseView.Contains('keyboardLayoutGuide') -and $licenseView.Contains('scrollRectToVisible:')) 'The license field must remain reachable with the keyboard open'
Assert-Source (-not $licenseView.Contains('SCITheme.') -and -not $licenseView.Contains('SCILicenseRed')) 'The license screen must retain its black/white styling independently of menu themes'
Assert-Source ($licenseView.Contains('discordStyle.title = @"Join Discord"') -and $licenseView.Contains('discord.configuration = discordStyle')) 'The initial screen must expose Join Discord as a button'
Assert-Source ((Read-Source 'src/License/SCILicenseConfig.m').Contains('https://discord.gg/qTB3G7gCAp')) 'The purchase contact must use the requested Discord server'
Assert-Source ($licenseView.Contains('openURL:SCILicenseConfig.supportURL')) 'The Discord control must open the configured purchase invite'
Assert-Source ($licenseManager.Contains('suspendedByHost') -and $licenseManager.Contains('isLiveContainerWindow:window')) 'The license cover must not take over the LC launcher or treat keyboard windows as a host transition'
Assert-Source ($gateHook.Contains('[SCILicenseManager.sharedManager considerWindow:self]')) 'License cover is not connected to the guest window lifecycle'
Assert-Source ($media.Contains('if (!SCILicenseManager.sharedManager.authorized) return;')) 'Media saving must respect the license gate'
$nativeSource = ($files | ForEach-Object { [IO.File]::ReadAllText($_.FullName) }) -join "`n"
Assert-Source (-not $nativeSource.Contains('@"X-App-Secret"')) 'KeyAux authentication belongs only on the Worker'
Assert-Source (-not [regex]::IsMatch($nativeSource, 'as_[A-Za-z0-9]{24,}')) 'An app secret must never be committed in native source'
$ipaWorkflow = Read-Source '.github/workflows/buildapp.yml'
Assert-Source ($ipaWorkflow.Contains('SOURCE_IPA="main/packages/Peki Scripter-sideloaded.ipa"')) 'IPA upload must use the explicit patched output, not the most recently modified package'
Assert-Source (-not $ipaWorkflow.Contains('$(ls -t')) 'IPA artifact selection must not depend on directory timestamps'
Assert-Source ($ipaWorkflow.Contains('./tests/check-ipa.ps1 -Path')) 'The packaged IPA must be checked for the injected license gate before upload'
Write-Output "PASS: $($files.Count) source delimiter checks and feature wiring contracts."
Write-Output "PASS: $($palettes.Count) unique RGB palettes and body-text contrast data checks."
Write-Output 'Runtime behavior still requires a Theos build and testing on the target Instagram/iOS version.'
