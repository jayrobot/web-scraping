<#
.SYNOPSIS
    Downloads the MP3s and cover image from a Musify.club release page and zips them.

.PARAMETER Url
    The release page URL, e.g. https://musify.club/release/artist-album-2020-123456

.PARAMETER OutputDirectory
    Where the finished zip is written. Defaults to the current directory.

.PARAMETER KeepFiles
    Keep the downloaded files after zipping instead of deleting the temp folder.

.EXAMPLE
    .\Get-MusifyRelease.ps1 -Url "https://musify.club/release/some-album-123456"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidatePattern('^https?://')]
    [string]$Url,

    [string]$OutputDirectory = (Get-Location).Path,

    [switch]$KeepFiles
)

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'   # Invoke-WebRequest is much faster without the progress bar

Add-Type -AssemblyName System.Web

$UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36'
$Headers   = @{ Referer = $Url }

function Get-SafeFileName {
    param([string]$Name)
    $invalid = [IO.Path]::GetInvalidFileNameChars() -join ''
    $clean   = ($Name -replace "[$([regex]::Escape($invalid))]", '_').Trim().TrimEnd('.')
    if ([string]::IsNullOrWhiteSpace($clean)) { 'download' } else { $clean }
}

function Resolve-AbsoluteUrl {
    param([string]$Base, [string]$Relative)
    $decoded = [System.Web.HttpUtility]::HtmlDecode($Relative)
    ([Uri]::new([Uri]$Base, $decoded)).AbsoluteUri
}

# --- Fetch page --------------------------------------------------------------
Write-Host "Fetching $Url"
$html = (Invoke-WebRequest -Uri $Url -UserAgent $UserAgent -UseBasicParsing).Content

# --- Title from <h1> ----------------------------------------------------------
$h1Match = [regex]::Match($html, '<h1[^>]*>(.*?)</h1>', 'Singleline,IgnoreCase')
if (-not $h1Match.Success) { throw 'No <h1> element found on the page.' }
$title = [regex]::Replace($h1Match.Groups[1].Value, '<[^>]+>', '')        # strip nested tags
$title = [System.Web.HttpUtility]::HtmlDecode($title) -replace '\s+', ' '
$title = Get-SafeFileName $title
Write-Host "Release: $title"

# --- MP3 links ----------------------------------------------------------------
# Picks up href / data-url / src attributes that point at an .mp3 (absolute or relative).
$mp3Urls = [regex]::Matches($html, '(?:href|data-url|src)\s*=\s*"([^"]+?\.mp3(?:\?[^"]*)?)"', 'IgnoreCase') |
    ForEach-Object { Resolve-AbsoluteUrl $Url $_.Groups[1].Value } |
    Select-Object -Unique

if (-not $mp3Urls) { throw 'No MP3 links found on the page.' }
Write-Host "Found $(@($mp3Urls).Count) MP3(s)"

# --- Cover image (element with class "hero-image") ---------------------------
$coverUrl = $null
foreach ($img in [regex]::Matches($html, '<img\b[^>]*>', 'IgnoreCase')) {
    $tag = $img.Value
    if ($tag -match 'class\s*=\s*"[^"]*\bhero-image\b[^"]*"') {
        # Prefer lazy-load attributes, fall back to src
        foreach ($attr in 'data-src', 'data-original', 'src') {
            if ($tag -match "\b$attr\s*=\s*`"([^`"]+)`"") {
                $coverUrl = Resolve-AbsoluteUrl $Url $Matches[1]
                break
            }
        }
        if ($coverUrl) { break }
    }
}

# --- Download -----------------------------------------------------------------
$workDir = Join-Path ([IO.Path]::GetTempPath()) ("musify_" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $workDir | Out-Null

try {
    $i = 0
    $total = @($mp3Urls).Count
    foreach ($mp3 in $mp3Urls) {
        $i++
        $leaf = [Uri]::UnescapeDataString(([Uri]$mp3).Segments[-1])
        $file = Join-Path $workDir (Get-SafeFileName $leaf)
        Write-Host ("[{0}/{1}] {2}" -f $i, $total, $leaf)
        try {
            Invoke-WebRequest -Uri $mp3 -OutFile $file -UserAgent $UserAgent -Headers $Headers -UseBasicParsing
        }
        catch {
            Write-Warning "Failed to download $mp3 : $($_.Exception.Message)"
        }
    }

    if ($coverUrl) {
        $ext = [IO.Path]::GetExtension(([Uri]$coverUrl).AbsolutePath)
        if (-not $ext) { $ext = '.jpg' }
        Write-Host "Downloading cover: $coverUrl"
        try {
            Invoke-WebRequest -Uri $coverUrl -OutFile (Join-Path $workDir "cover$ext") -UserAgent $UserAgent -Headers $Headers -UseBasicParsing
        }
        catch {
            Write-Warning "Failed to download cover: $($_.Exception.Message)"
        }
    }
    else {
        Write-Warning 'No image with class "hero-image" found; zipping without a cover.'
    }

    if (-not (Get-ChildItem $workDir -File)) { throw 'Nothing was downloaded.' }

    # --- Zip --------------------------------------------------------------------
    if (-not (Test-Path $OutputDirectory)) { New-Item -ItemType Directory -Path $OutputDirectory | Out-Null }
    $zipPath = Join-Path (Resolve-Path $OutputDirectory) "$title.zip"
    Compress-Archive -Path (Join-Path $workDir '*') -DestinationPath $zipPath -Force
    Write-Host "Created $zipPath" -ForegroundColor Green
}
finally {
    if ($KeepFiles) {
        Write-Host "Files kept in $workDir"
    }
    else {
        Remove-Item $workDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
