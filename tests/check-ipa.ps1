param(
    [Parameter(Mandatory = $true)]
    [string]$Path
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

# Read only bounded ranges from ZIP entries; never extract or execute app code.
function Read-EntryRange($Entry, [long]$Offset, [int]$Count) {
    if ($Offset -lt 0 -or $Count -lt 0 -or $Offset + $Count -gt $Entry.Length) {
        throw 'Invalid Mach-O range in IPA'
    }
    $inputStream = $Entry.Open()
    try {
        $discard = New-Object byte[] 65536
        $remaining = $Offset
        while ($remaining -gt 0) {
            $read = $inputStream.Read($discard, 0, [int][Math]::Min($remaining, $discard.Length))
            if ($read -eq 0) { throw 'Truncated ZIP entry' }
            $remaining -= $read
        }
        $bytes = New-Object byte[] $Count
        $position = 0
        while ($position -lt $Count) {
            $read = $inputStream.Read($bytes, $position, $Count - $position)
            if ($read -eq 0) { throw 'Truncated ZIP entry' }
            $position += $read
        }
        return ,$bytes
    } finally {
        $inputStream.Dispose()
    }
}

function Read-BigEndian($Bytes, [int]$Offset, [int]$Width) {
    $value = New-Object byte[] $Width
    [Array]::Copy($Bytes, $Offset, $value, 0, $Width)
    [Array]::Reverse($value)
    if ($Width -eq 8) { return [BitConverter]::ToUInt64($value, 0) }
    return [BitConverter]::ToUInt32($value, 0)
}

function Read-MachO($Entry) {
    $header = Read-EntryRange $Entry 0 32
    $slice = 0L
    $fatMagic = Read-BigEndian $header 0 4
    if ($fatMagic -eq 3405691582 -or $fatMagic -eq 3405691583) {
        $count = Read-BigEndian $header 4 4
        if ($count -lt 1 -or $count -gt 32) { throw 'Invalid fat Mach-O architecture count' }
        $width = if ($fatMagic -eq 3405691583) { 32 } else { 20 }
        $table = Read-EntryRange $Entry 8 ([int]($count * $width))
        for ($index = 0; $index -lt $count; $index++) {
            $position = $index * $width
            $cpu = Read-BigEndian $table $position 4
            if ($index -eq 0 -or $cpu -eq 16777228) {
                $offsetWidth = if ($width -eq 32) { 8 } else { 4 }
                $offset = Read-BigEndian $table ($position + 8) $offsetWidth
                if ($offset -gt $Entry.Length - 32) { throw 'Invalid fat Mach-O slice offset' }
                $slice = [long]$offset
            }
            if ($cpu -eq 16777228) { break }
        }
        $header = Read-EntryRange $Entry $slice 32
    }
    $magic = [BitConverter]::ToUInt32($header, 0)
    if ($magic -ne 4277009103 -and $magic -ne 4277009102) { throw 'Unsupported Mach-O header' }
    $headerSize = if ($magic -eq 4277009103) { 32 } else { 28 }
    $commandCount = [BitConverter]::ToUInt32($header, 16)
    $commandBytes = [BitConverter]::ToUInt32($header, 20)
    if ($commandCount -gt 4096 -or $commandBytes -gt 4194304) { throw 'Invalid Mach-O command bounds' }
    $commands = Read-EntryRange $Entry ($slice + $headerSize) ([int]$commandBytes)
    $libraries = @()
    $cryptID = 0
    $position = 0
    for ($index = 0; $index -lt $commandCount; $index++) {
        if ($position + 8 -gt $commands.Length) { throw 'Truncated Mach-O command' }
        $command = [BitConverter]::ToUInt32($commands, $position) -band 2147483647
        $size = [BitConverter]::ToUInt32($commands, $position + 4)
        if ($size -lt 8 -or $size -gt $commands.Length - $position) { throw 'Invalid Mach-O command size' }
        if ($command -in @(12, 24, 31, 32, 35)) {
            if ($size -lt 24) { throw 'Invalid dylib load command' }
            $nameOffset = [BitConverter]::ToUInt32($commands, $position + 8)
            if ($nameOffset -lt 24 -or $nameOffset -ge $size) { throw 'Invalid dylib name offset' }
            $start = $position + [int]$nameOffset
            $end = $start
            while ($end -lt $position + $size -and $commands[$end] -ne 0) { $end++ }
            if ($end -eq $position + $size) { throw 'Unterminated dylib name' }
            $libraries += [Text.Encoding]::UTF8.GetString($commands, $start, $end - $start)
        }
        if ($command -in @(33, 44)) {
            if ($size -lt 20) { throw 'Invalid encryption command' }
            $cryptID = [BitConverter]::ToUInt32($commands, $position + 16)
        }
        $position += [int]$size
    }
    return [pscustomobject]@{
        Libraries = $libraries
        CryptID = $cryptID
        FileType = [BitConverter]::ToUInt32($header, 12)
    }
}

$archive = [IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $Path).Path)
try {
    $appInfo = @($archive.Entries | Where-Object { $_.FullName -match '^Payload/[^/]+\.app/Info\.plist$' })
    if ($appInfo.Count -ne 1) { throw 'Expected exactly one main app in IPA' }
    $root = $appInfo[0].FullName.Substring(0, $appInfo[0].FullName.Length - 'Info.plist'.Length)
    $tweaks = @($archive.Entries | Where-Object {
        $_.FullName.StartsWith($root) -and $_.FullName -match '/SCInsta\.dylib$|/SCInsta\.framework/SCInsta$'
    })
    if ($tweaks.Count -ne 1) {
        throw 'IPA_MISSING_TWEAK: SCInsta.dylib is missing or ambiguous. Do not upload the original Instagram IPA.'
    }
    $main = $archive.GetEntry($root + 'Instagram')
    if (-not $main) { throw 'Instagram executable is missing from IPA' }
    $mainInfo = Read-MachO $main
    if ($mainInfo.CryptID -ne 0) { throw 'IPA_ENCRYPTED: use a decrypted Instagram input IPA' }
    $linked = @($mainInfo.Libraries | Where-Object { $_ -match '/SCInsta\.dylib$|/SCInsta\.framework/SCInsta$' })
    if ($linked.Count -eq 0) { throw 'IPA_NOT_LINKED: Instagram does not load the SCInsta tweak' }
    $tweak = $tweaks[0]
    if ($tweak.Length -gt 67108864) { throw 'Unexpectedly large SCInsta library' }
    $tweakInfo = Read-MachO $tweak
    if ($tweakInfo.FileType -ne 6) { throw 'SCInsta is not a Mach-O dynamic library' }
    $bytes = Read-EntryRange $tweak 0 ([int]$tweak.Length)
    $text = [Text.Encoding]::ASCII.GetString($bytes)
    foreach ($marker in @('SCILicenseManager', 'SCILicenseViewController',
        'PekiScripterLicenseStateDidChange', 'peki-keyaux-bridge.uknownepoznat.workers.dev',
        'Peki Scripter V2', 'https://discord.gg/qTB3G7gCAp')) {
        if (-not $text.Contains($marker)) { throw ('IPA_STALE_TWEAK: required license marker missing: ' + $marker) }
    }
    Write-Output 'PASS: IPA contains and links SCInsta with the license gate and configured Worker URL.'
    Write-Output 'This is a packaging check, not an iPhone runtime or valid-license test.'
} finally {
    $archive.Dispose()
}
