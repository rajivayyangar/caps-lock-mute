#!/bin/bash
set -e

# ============================================
# CapslockMute Release Build Script
# ============================================
# This script builds, signs, notarizes, and packages
# the app for distribution via GitHub Releases.
#
# Prerequisites:
# - Developer ID Application certificate installed
# - Notarization credentials stored via:
#   xcrun notarytool store-credentials "CapslockMute" \
#     --apple-id "your@email.com" \
#     --team-id "49Z88YPG95" \
#     --password "app-specific-password"
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_NAME="CapslockMute"
APP_BUNDLE="$APP_NAME.app"
BUNDLE_ID="com.rajiv.capslockmute"
VERSION="1.2"
SIGNING_IDENTITY="Developer ID Application: Rajiv Ayyangar (49Z88YPG95)"
NOTARY_PROFILE="CapslockMute"

# Output directories
BUILD_DIR="$PROJECT_DIR/build"
DIST_DIR="$PROJECT_DIR/dist"
ZIP_NAME="CapslockMute-v${VERSION}.zip"

echo ""
echo "========================================="
echo "   CapslockMute Release Build v${VERSION}"
echo "========================================="
echo ""

# Clean previous builds
echo "Step 1/6: Cleaning previous builds..."
rm -rf "$BUILD_DIR"
rm -rf "$DIST_DIR"
mkdir -p "$BUILD_DIR/$APP_BUNDLE/Contents/MacOS"
mkdir -p "$BUILD_DIR/$APP_BUNDLE/Contents/Resources"
mkdir -p "$DIST_DIR"
echo "         Done"
echo ""

# Compile with optimizations
echo "Step 2/6: Compiling with optimizations..."
SWIFT_FILES=(
    "$PROJECT_DIR/Sources/MuteShortcut.swift"
    "$PROJECT_DIR/Sources/SettingsManager.swift"
    "$PROJECT_DIR/Sources/EventTapManager.swift"
    "$PROJECT_DIR/Sources/AppDelegate.swift"
    "$PROJECT_DIR/Sources/main.swift"
)

swiftc -O \
    -whole-module-optimization \
    -o "$BUILD_DIR/$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
    "${SWIFT_FILES[@]}"

# Copy resources
cp "$PROJECT_DIR/Info.plist" "$BUILD_DIR/$APP_BUNDLE/Contents/"
cp "$PROJECT_DIR/Resources/AppIcon.icns" "$BUILD_DIR/$APP_BUNDLE/Contents/Resources/"
echo "         Compiled successfully"
echo ""

# Code sign with Developer ID
echo "Step 3/6: Code signing with Developer ID..."
codesign --force --options runtime --timestamp \
    --sign "$SIGNING_IDENTITY" \
    "$BUILD_DIR/$APP_BUNDLE"

# Verify signature
codesign --verify --deep --strict "$BUILD_DIR/$APP_BUNDLE"
echo "         Signed and verified"
echo ""

# Create zip for notarization
echo "Step 4/6: Creating zip for notarization..."
cd "$BUILD_DIR"
ditto -c -k --keepParent "$APP_BUNDLE" "$DIST_DIR/$ZIP_NAME"
cd "$PROJECT_DIR"
echo "         Created $ZIP_NAME"
echo ""

# Notarize
echo "Step 5/6: Submitting for notarization..."
echo "         (This may take a few minutes)"
xcrun notarytool submit "$DIST_DIR/$ZIP_NAME" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait

echo "         Notarization complete"
echo ""

# Staple the ticket to the app bundle
echo "Step 6/6: Stapling notarization ticket..."
xcrun stapler staple "$BUILD_DIR/$APP_BUNDLE"

# Recreate the zip with stapled app
rm "$DIST_DIR/$ZIP_NAME"
cd "$BUILD_DIR"
ditto -c -k --keepParent "$APP_BUNDLE" "$DIST_DIR/$ZIP_NAME"
cd "$PROJECT_DIR"
echo "         Stapled and repackaged"
echo ""

# Clean up build directory
rm -rf "$BUILD_DIR"

# Done!
echo "========================================="
echo "   Build Complete!"
echo "========================================="
echo ""
echo "   Output: dist/$ZIP_NAME"
echo ""
echo "   Next steps:"
echo "   1. Test the zip on another Mac"
echo "   2. Create GitHub release:"
echo ""
echo "      gh release create v${VERSION} dist/$ZIP_NAME \\"
echo "        --title \"v${VERSION}\" \\"
echo "        --notes \"Initial release\""
echo ""
echo "   3. Enable GitHub Pages (Settings > Pages > Source: /docs)"
echo ""
