#Requires -Version 5
<#
  Giit installer — resolves and downloads the latest signed release from GitHub.
  Usage: irm https://giit.danielkaufman.dev/install.ps1 | iex
#>
$ErrorActionPreference = 'Stop'

# GitHub (and most TLS endpoints) require TLS 1.2+; Windows PowerShell 5.1 may
# still default to older protocols.
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

$Repo     = 'DanKaufmanDev/giit'
$Api      = "https://api.github.com/repos/$Repo/releases/latest"
$Releases = "https://github.com/$Repo/releases"

function Write-Info($m) { Write-Host $m -ForegroundColor Cyan }
function Write-Warn($m) { Write-Host $m -ForegroundColor Yellow }
function Write-Err($m)  { Write-Host $m -ForegroundColor Red }

# --- detect architecture ---------------------------------------------------
$arch = $env:PROCESSOR_ARCHITECTURE
switch ($arch) {
  'ARM64' { $archRe = 'arm64|aarch64' }
  default { $archRe = 'x64|x86_64|amd64' }
}

# --- resolve the latest release -------------------------------------------
Write-Info "Resolving the latest Giit release for windows/$arch..."

try {
  $release = Invoke-RestMethod -Uri $Api -Headers @{
    'Accept'     = 'application/vnd.github+json'
    'User-Agent' = 'giit-install'
  }
} catch {
  Write-Err "Could not reach GitHub. Track the launch at $Releases"
  exit 1
}

$tag = $release.tag_name
if (-not $tag) {
  Write-Warn "No published release found yet."
  Write-Warn "Track the launch at $Releases"
  exit 1
}

# Installable assets only (drop signatures and the updater manifest).
$assets = $release.assets | Where-Object { $_.name -notmatch '\.sig$' -and $_.name -ne 'latest.json' }

# Prefer .msi, then .exe; favour the matching architecture when available.
$asset = $null
foreach ($ext in @('msi', 'exe')) {
  $candidates = $assets | Where-Object { $_.name -match "\.$ext$" }
  $asset = $candidates | Where-Object { $_.name -match $archRe } | Select-Object -First 1
  if (-not $asset) { $asset = $candidates | Select-Object -First 1 }
  if ($asset) { break }
}

if (-not $asset) {
  Write-Err "No Windows installer attached to $tag."
  Write-Err "Browse the available files at $Releases/tag/$tag"
  exit 1
}

# --- download --------------------------------------------------------------
$dest = Join-Path $env:TEMP $asset.name
Write-Info "Downloading Giit $tag..."
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $dest -UseBasicParsing

# Releases are signed with minisign (.sig assets) for the Tauri updater.
if ($release.assets | Where-Object { $_.name -eq "$($asset.name).sig" }) {
  Write-Info "Signed release (minisign .sig published alongside the installer)."
}

Write-Info ""
Write-Info "Giit $tag downloaded to:"
Write-Info "  $dest"
Write-Info ""
Write-Info "Launching the installer..."
Start-Process -FilePath $dest
