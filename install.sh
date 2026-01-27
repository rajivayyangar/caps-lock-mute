#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="CapslockMute"
APP_BUNDLE="$APP_NAME.app"
INSTALL_DIR="/Applications"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"

echo ""
echo "========================================="
echo "   Caps Lock Mute - Installer v1.1      "
echo "========================================="
echo ""

# Check for Karabiner-Elements conflict
if pgrep -q "karabiner" || [ -d "/Applications/Karabiner-Elements.app" ]; then
    echo "WARNING: Karabiner-Elements detected!"
    echo ""
    echo "   Karabiner conflicts with this tool. They both try to"
    echo "   remap keys at the same level and will interfere."
    echo ""
    echo "   Please uninstall Karabiner-Elements first, or configure"
    echo "   the Caps Lock remap inside Karabiner instead."
    echo ""
    read -p "   Continue anyway? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 1
    fi
    echo ""
fi

# Check for Swift compiler
if ! command -v swiftc &> /dev/null; then
    echo "ERROR: Swift compiler not found."
    echo ""
    echo "   You need Xcode Command Line Tools installed."
    echo "   Run this command and follow the prompts:"
    echo ""
    echo "      xcode-select --install"
    echo ""
    echo "   After installation completes, run this installer again."
    exit 1
fi

# Kill any running instance
echo "Step 1/7: Stopping any running instance..."
pkill -x "$APP_NAME" 2>/dev/null || true
launchctl unload "$LAUNCH_AGENTS_DIR/com.user.capslockmute.plist" 2>/dev/null || true
echo "         Done"
echo ""

# Build the app bundle
echo "Step 2/7: Building application..."

# Create app bundle structure
BUILD_DIR="$SCRIPT_DIR/build"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/$APP_BUNDLE/Contents/MacOS"
mkdir -p "$BUILD_DIR/$APP_BUNDLE/Contents/Resources"

# Compile all Swift source files
SWIFT_FILES=(
    "$SCRIPT_DIR/Sources/MuteShortcut.swift"
    "$SCRIPT_DIR/Sources/SettingsManager.swift"
    "$SCRIPT_DIR/Sources/EventTapManager.swift"
    "$SCRIPT_DIR/Sources/AppDelegate.swift"
    "$SCRIPT_DIR/Sources/main.swift"
)

swiftc -O \
    -o "$BUILD_DIR/$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
    "${SWIFT_FILES[@]}" \
    2>&1

# Copy Info.plist and icon
cp "$SCRIPT_DIR/Info.plist" "$BUILD_DIR/$APP_BUNDLE/Contents/"
cp "$SCRIPT_DIR/Resources/AppIcon.icns" "$BUILD_DIR/$APP_BUNDLE/Contents/Resources/"

echo "         Compiled successfully"
echo ""

# Code sign (ad-hoc)
echo "Step 3/7: Code signing..."
codesign --force --sign - "$BUILD_DIR/$APP_BUNDLE" 2>/dev/null || true
echo "         Done"
echo ""

# Install app bundle
echo "Step 4/7: Installing application..."
mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_DIR/$APP_BUNDLE"
cp -R "$BUILD_DIR/$APP_BUNDLE" "$INSTALL_DIR/"
echo "         Installed to $INSTALL_DIR/$APP_BUNDLE"
echo ""

# Install hidutil LaunchAgent (for Caps Lock -> F18 remap)
echo "Step 5/7: Setting up Caps Lock remapping..."
mkdir -p "$LAUNCH_AGENTS_DIR"
cp "$SCRIPT_DIR/LaunchAgents/com.user.capslock-hidutil.plist" "$LAUNCH_AGENTS_DIR/"
launchctl unload "$LAUNCH_AGENTS_DIR/com.user.capslock-hidutil.plist" 2>/dev/null || true
launchctl load "$LAUNCH_AGENTS_DIR/com.user.capslock-hidutil.plist"

# Apply hidutil mapping immediately
/usr/bin/hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x70000006D}]}' > /dev/null
echo "         Caps Lock remapped to F18"
echo ""

# Install app LaunchAgent (for auto-start at login)
echo "Step 6/7: Setting up auto-start at login..."
cp "$SCRIPT_DIR/LaunchAgents/com.user.capslockmute.plist" "$LAUNCH_AGENTS_DIR/"
launchctl unload "$LAUNCH_AGENTS_DIR/com.user.capslockmute.plist" 2>/dev/null || true
launchctl load "$LAUNCH_AGENTS_DIR/com.user.capslockmute.plist"
echo "         Auto-start configured"
echo ""

# Launch the app
echo "Step 7/7: Launching application..."
open "$INSTALL_DIR/$APP_BUNDLE"
echo "         Application started"
echo ""

# Clean up build directory
rm -rf "$BUILD_DIR"

# Installation complete
echo "========================================="
echo "   Installation Complete!               "
echo "========================================="
echo ""
echo "IMPORTANT: Grant Accessibility Permission"
echo ""
echo "   Without this permission, the app cannot detect your"
echo "   Caps Lock key press. This is a macOS security requirement."
echo ""
echo "   Opening System Settings now..."
echo ""

# Open System Preferences to Accessibility pane
if [[ $(sw_vers -productVersion | cut -d. -f1) -ge 13 ]]; then
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
else
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
fi

sleep 1

echo "   In the window that just opened:"
echo ""
echo "   1. Click the lock icon (bottom left)"
echo "   2. Enter your password"
echo "   3. Find 'CapslockMute' in the list"
echo "   4. Check the box next to it"
echo ""
echo "   If 'CapslockMute' isn't listed, click + and navigate to:"
echo "   $INSTALL_DIR/$APP_BUNDLE"
echo ""
echo "   Once you've granted permission, test it:"
echo "   - Open Tandem and join a call"
echo "   - Press Caps Lock"
echo "   - Your mic should mute/unmute!"
echo ""
echo "   Look for the 'C' icon in your menu bar to change settings."
echo ""
