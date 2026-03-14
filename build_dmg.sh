#!/usr/bin/env bash
# build_dmg.sh - Build NDLOCR-Lite.app and package it as NDLOCR-Lite.dmg
#
# Prerequisites (macOS only):
#   brew install create-dmg
#   pip install flet[all]==0.27.6
#
# Usage:
#   bash build_dmg.sh [--sign "Developer ID Application: Your Name (XXXXXXXXXX)"]
#
# The finished DMG is written to the repository root as NDLOCR-Lite.dmg.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUI_DIR="$REPO_ROOT/ndlocr-lite-gui"
BUILD_DIR="$REPO_ROOT/macos"
APP_NAME="NDLOCR-Lite"
DMG_NAME="${APP_NAME}.dmg"
ICON="$GUI_DIR/assets/icon.png"
SIGN_IDENTITY=""

# Parse optional --sign argument
while [[ $# -gt 0 ]]; do
  case "$1" in
    --sign)
      SIGN_IDENTITY="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

# -----------------------------------------------------------------------
# Step 1: Copy OCR engine sources into the GUI directory (required by Flet)
# -----------------------------------------------------------------------
echo "==> Copying src/ into ndlocr-lite-gui/src/ ..."
cp -r "$REPO_ROOT/src" "$GUI_DIR/src"

# -----------------------------------------------------------------------
# Step 2: Build the macOS .app bundle with Flet
# -----------------------------------------------------------------------
echo "==> Building macOS .app with flet build ..."
cd "$GUI_DIR"
flet build macos \
  --output "$BUILD_DIR" \
  --project "$APP_NAME" \
  --product "$APP_NAME"

APP_PATH="$BUILD_DIR/${APP_NAME}.app"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Error: .app bundle not found at $APP_PATH" >&2
  exit 1
fi

# -----------------------------------------------------------------------
# Step 3: Replace Flet's default icns with the project icon (if available)
# -----------------------------------------------------------------------
if command -v sips &>/dev/null && [[ -f "$ICON" ]]; then
  echo "==> Converting icon.png to AppIcon.icns ..."
  ICONSET_DIR="$(mktemp -d)/AppIcon.iconset"
  mkdir -p "$ICONSET_DIR"
  for SIZE in 16 32 64 128 256 512; do
    sips -z $SIZE $SIZE "$ICON" --out "$ICONSET_DIR/icon_${SIZE}x${SIZE}.png" &>/dev/null
    sips -z $((SIZE*2)) $((SIZE*2)) "$ICON" --out "$ICONSET_DIR/icon_${SIZE}x${SIZE}@2x.png" &>/dev/null
  done
  iconutil -c icns "$ICONSET_DIR" -o /tmp/AppIcon.icns
  ICNS_DST="$APP_PATH/Contents/Resources/AppIcon.icns"
  if [[ -f "$ICNS_DST" ]]; then
    cp /tmp/AppIcon.icns "$ICNS_DST"
    echo "   Icon updated: $ICNS_DST"
  fi
fi

# -----------------------------------------------------------------------
# Step 4: Optional code signing
# -----------------------------------------------------------------------
if [[ -n "$SIGN_IDENTITY" ]]; then
  echo "==> Signing .app with identity: $SIGN_IDENTITY ..."
  codesign --deep --force --verify --verbose \
    --sign "$SIGN_IDENTITY" \
    --options runtime \
    "$APP_PATH"
fi

# -----------------------------------------------------------------------
# Step 5: Create the DMG with create-dmg
# -----------------------------------------------------------------------
echo "==> Creating $DMG_NAME ..."
cd "$REPO_ROOT"
rm -f "$DMG_NAME"

create-dmg \
  --volname "$APP_NAME" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "${APP_NAME}.app" 150 180 \
  --hide-extension "${APP_NAME}.app" \
  --app-drop-link 450 180 \
  "$DMG_NAME" \
  "$BUILD_DIR/"

echo ""
echo "==> Done! Created: $REPO_ROOT/$DMG_NAME"
