#!/usr/bin/env sh
# Giit installer — resolves and downloads the latest signed release from GitHub.
# Usage: curl -fsSL https://giit.danielkaufman.dev/install.sh | sh
set -eu

REPO="DanKaufmanDev/giit"
API="https://api.github.com/repos/${REPO}/releases/latest"
RELEASES="https://github.com/${REPO}/releases"

info() { printf '\033[0;36m%s\033[0m\n' "$1"; }
warn() { printf '\033[0;33m%s\033[0m\n' "$1" >&2; }
err()  { printf '\033[0;31m%s\033[0m\n' "$1" >&2; }

# --- detect platform -------------------------------------------------------
os="$(uname -s)"
arch="$(uname -m)"

case "$os" in
  Darwin) platform="macos"; exts="dmg" ;;
  Linux)  platform="linux"; exts="AppImage deb rpm" ;;
  *)
    err "Unsupported OS: ${os}."
    err "Windows users: winget install DanKaufmanDev.Giit  (or see ${RELEASES})"
    exit 1
    ;;
esac

# Architecture aliases used by Tauri asset names (universal builds match either).
case "$arch" in
  x86_64 | amd64)  arch_alias="x86_64|amd64|x64|universal" ;;
  arm64 | aarch64) arch_alias="aarch64|arm64|universal" ;;
  *) err "Unsupported architecture: ${arch}."; exit 1 ;;
esac

# --- pick a downloader -----------------------------------------------------
if command -v curl >/dev/null 2>&1; then
  fetch() { curl -fsSL "$1"; }
  fetch_to() { curl -fsSL "$1" -o "$2"; }
elif command -v wget >/dev/null 2>&1; then
  fetch() { wget -qO- "$1"; }
  fetch_to() { wget -qO "$2" "$1"; }
else
  err "Need either curl or wget installed."
  exit 1
fi

# --- resolve the latest release -------------------------------------------
info "Resolving the latest Giit release for ${platform}/${arch}…"
release="$(fetch "$API" 2>/dev/null || true)"

tag="$(printf '%s' "$release" | grep -m1 '"tag_name"' | sed -E 's/.*"tag_name" *: *"([^"]+)".*/\1/')"

if [ -z "${tag:-}" ]; then
  warn "No published release found yet."
  warn "Track the launch at ${RELEASES}"
  exit 1
fi

# Installable asset URLs (drop signatures and the updater manifest).
urls="$(printf '%s' "$release" \
  | grep -Eo '"browser_download_url" *: *"[^"]+"' \
  | sed -E 's/.*"(https[^"]+)".*/\1/' \
  | grep -viE '\.sig$|latest\.json$')"

# Prefer an arch-specific asset for the first matching extension, else any.
asset_url=""
for ext in $exts; do
  asset_url="$(printf '%s\n' "$urls" | grep -iE "\.${ext}$" | grep -iE "$arch_alias" | head -n1)"
  [ -z "$asset_url" ] && asset_url="$(printf '%s\n' "$urls" | grep -iE "\.${ext}$" | head -n1)"
  [ -n "$asset_url" ] && break
done

if [ -z "${asset_url:-}" ]; then
  err "No ${platform} asset attached to ${tag}."
  err "Browse the available files at ${RELEASES}/tag/${tag}"
  exit 1
fi

# --- download --------------------------------------------------------------
tmp="$(mktemp -d)"
file="${tmp}/$(basename "$asset_url")"

info "Downloading Giit ${tag}…"
fetch_to "$asset_url" "$file"

# Releases are signed with minisign (.sig assets). Automated verification needs
# the Tauri updater public key, so note it rather than failing the install.
if printf '%s' "$release" | grep -q "$(basename "$asset_url").sig"; then
  info "Signed release (minisign .sig published alongside the asset)."
fi

info ""
info "Giit ${tag} downloaded to:"
info "  ${file}"
info ""
info "Open the installer to finish setup, or move the binary onto your PATH."
echo "$file"
