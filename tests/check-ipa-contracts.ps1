$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

# Synthetic ZIP/Mach-O fixtures check packaging logic only, not native execution.
function New-MachOFixture([bool]$Library, [bool]$Linked, [bool]$Encrypted, [bool]$Current) {
    $commands = [IO.MemoryStream]::new()
    $writer = [IO.BinaryWriter]::new($commands)
    $count = 0
    if ($Linked) {
        $name = [Text.Encoding]::ASCII.GetBytes("@rpath/SCInsta.dylib`0")
        $size = [int]([Math]::Ceiling((24 + $name.Length) / 8.0) * 8)
        foreach ($value in @(12, $size, 24, 0, 0, 0)) { $writer.Write([uint32]$value) }
        $writer.Write($name)
        $writer.Write((New-Object byte[] ($size - 24 - $name.Length)))
        $count++
    }
    if ($Encrypted) {
        foreach ($value in @(44, 24, 0, 0, 1, 0)) { $writer.Write([uint32]$value) }
        $count++
    }
    $writer.Flush()
    $commandBytes = $commands.ToArray()
    $writer.Dispose()
    $binary = [IO.MemoryStream]::new()
    $writer = [IO.BinaryWriter]::new($binary)
    $fileType = if ($Library) { 6 } else { 2 }
    foreach ($value in @(4277009103, 16777228, 0, $fileType, $count, $commandBytes.Length, 0, 0)) {
        $writer.Write([uint32]$value)
    }
    $writer.Write($commandBytes)
    if ($Library -and $Current) {
        $writer.Write([Text.Encoding]::ASCII.GetBytes(
            "SCILicenseManager`0SCILicenseViewController`0PekiScripterLicenseStateDidChange`0peki-keyaux-bridge.uknownepoznat.workers.dev`0"))
    }
    $writer.Flush()
    $result = $binary.ToArray()
    $writer.Dispose()
    return ,$result
}

function New-IPAFixture([string]$File, [bool]$HasTweak, [bool]$Linked, [bool]$Encrypted, [bool]$Current) {
    $archive = [IO.Compression.ZipFile]::Open($File, [IO.Compression.ZipArchiveMode]::Create)
    try {
        $entries = @{
            'Payload/Instagram.app/Info.plist' = [Text.Encoding]::UTF8.GetBytes('<plist><dict><key>CFBundleExecutable</key><string>Instagram</string></dict></plist>')
            'Payload/Instagram.app/Instagram' = (New-MachOFixture $false $Linked $Encrypted $false)
        }
        if ($HasTweak) {
            $entries['Payload/Instagram.app/Frameworks/SCInsta.dylib'] = New-MachOFixture $true $false $false $Current
        }
        foreach ($name in $entries.Keys) {
            $entry = $archive.CreateEntry($name)
            $stream = $entry.Open()
            try { $stream.Write($entries[$name], 0, $entries[$name].Length) } finally { $stream.Dispose() }
        }
    } finally { $archive.Dispose() }
}

$base = [IO.Path]::GetTempPath()
$approvedTemp = $null
if ($env:LOCALAPPDATA) { $approvedTemp = Join-Path $env:LOCALAPPDATA 'Temp/opencode' }
if ($approvedTemp -and (Test-Path -LiteralPath $approvedTemp)) { $base = $approvedTemp }
$directory = Join-Path $base ('peki-ipa-contract-' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($directory) | Out-Null
$fixtures = @(
    @{ Name = 'complete'; HasTweak = $true; Linked = $true; Encrypted = $false; Current = $true; Error = '' },
    @{ Name = 'plain-instagram'; HasTweak = $false; Linked = $false; Encrypted = $false; Current = $false; Error = 'IPA_MISSING_TWEAK' },
    @{ Name = 'not-linked'; HasTweak = $true; Linked = $false; Encrypted = $false; Current = $true; Error = 'IPA_NOT_LINKED' },
    @{ Name = 'stale-library'; HasTweak = $true; Linked = $true; Encrypted = $false; Current = $false; Error = 'IPA_STALE_TWEAK' },
    @{ Name = 'encrypted-input'; HasTweak = $true; Linked = $true; Encrypted = $true; Current = $true; Error = 'IPA_ENCRYPTED' }
)
try {
    foreach ($fixture in $fixtures) {
        $file = Join-Path $directory ($fixture.Name + '.ipa')
        New-IPAFixture $file $fixture.HasTweak $fixture.Linked $fixture.Encrypted $fixture.Current
        $caught = ''
        try { $result = & (Join-Path $PSScriptRoot 'check-ipa.ps1') -Path $file } catch { $caught = $_.Exception.Message }
        if ($fixture.Error) {
            if (-not $caught.Contains($fixture.Error)) {
                throw ("Fixture '{0}' expected {1}; received '{2}'" -f $fixture.Name, $fixture.Error, $caught)
            }
        } elseif ($caught) { throw $caught }
        Write-Output ('PASS: IPA packaging fixture ' + $fixture.Name)
    }
} finally {
    foreach ($fixture in $fixtures) {
        $file = Join-Path $directory ($fixture.Name + '.ipa')
        if (Test-Path -LiteralPath $file) { [IO.File]::Delete($file) }
    }
    [IO.Directory]::Delete($directory, $false)
}
