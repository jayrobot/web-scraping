<#
.SYNOPSIS
    Packs the MP3s and cover.webp in a folder into a .7z archive.

.PARAMETER Name
    Name of the archive (".7z" is added if missing).

.PARAMETER Path
    Folder containing the *.mp3 files and cover.webp. Defaults to the current directory.

.PARAMETER OutputDirectory
    Where the archive is written. Defaults to the source folder.

.EXAMPLE
    .\New-Release7z.ps1 -Name "Artist - Album (2020)" -Path "D:\Music\Album"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$Name,

    [Parameter(Position = 1)]
    [string]$Path = (Get-Location).Path,

    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'

# --- Locate 7-Zip -------------------------------------------------------------
$sevenZip = (Get-Command 7z.exe, 7za.exe -ErrorAction SilentlyContinue | Select-Object -First 1).Source
if (-not $sevenZip) {
    $sevenZip = @(
        "$env:ProgramFiles\7-Zip\7z.exe"
        "${env:ProgramFiles(x86)}\7-Zip\7z.exe"
    ) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
}
if (-not $sevenZip) { throw '7-Zip not found. Install it from https://www.7-zip.org/ or add 7z.exe to PATH.' }

# --- Collect files ------------------------------------------------------------
$Path = (Resolve-Path $Path).Path
$mp3s = Get-ChildItem -LiteralPath $Path -Filter *.mp3 -File
if (-not $mp3s) { throw "No .mp3 files found in $Path" }

$files = @($mp3s.FullName)
$cover = Join-Path $Path 'cover.webp'
if (Test-Path -LiteralPath $cover) {
    $files += $cover
}
else {
    Write-Warning "cover.webp not found in $Path; archiving without a cover."
}

# --- Build archive path -------------------------------------------------------
$invalid  = [IO.Path]::GetInvalidFileNameChars() -join ''
$safeName = ($Name -replace "[$([regex]::Escape($invalid))]", '_').Trim().TrimEnd('.')
if ($safeName -notmatch '\.7z$') { $safeName += '.7z' }

if (-not $OutputDirectory) { $OutputDirectory = $Path }
if (-not (Test-Path $OutputDirectory)) { New-Item -ItemType Directory -Path $OutputDirectory | Out-Null }
$archive = Join-Path (Resolve-Path $OutputDirectory).Path $safeName

if (Test-Path -LiteralPath $archive) { Remove-Item -LiteralPath $archive -Force }

# --- Compress -----------------------------------------------------------------
# Pass the file list via a list file so long names / many tracks don't hit command-line limits.
$listFile = [IO.Path]::GetTempFileName()
try {
    [IO.File]::WriteAllLines($listFile, $files, [Text.UTF8Encoding]::new($false))
    Write-Host "Archiving $($files.Count) file(s) to $archive"
    & $sevenZip a -t7z -mx=9 -scsUTF-8 -bb0 -bd $archive "@$listFile" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "7-Zip failed with exit code $LASTEXITCODE" }
    Write-Host "Created $archive" -ForegroundColor Green
}
finally {
    Remove-Item -LiteralPath $listFile -Force -ErrorAction SilentlyContinue
}
