#!/bin/bash

APP_NAME="CapslockMute"
APP_BUNDLE="$APP_NAME.app"
INSTALL_DIR="/Applications"
OLD_INSTALL_DIR="$HOME/.local/bin"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"

echo ""
echo "========================================="
echo "   Caps Lock Mute - Uninstaller         "
echo "========================================="
echo ""

# 1. Quit the app if running
echo "Step 1/5: Stopping application..."
pkill -x "$APP_NAME" 2>/dev/null || true
sleep 0.5
echo "         Done"
echo ""

# 2. Unload LaunchAgents
echo "Step 2/5: Stopping services..."
launchctl unload "$LAUNCH_AGENTS_DIR/com.user.capslockmute.plist" 2>/dev/null || true
launchctl unload "$LAUNCH_AGENTS_DIR/com.user.capslock-hidutil.plist" 2>/dev/null || true
echo "         Done"
echo ""

# 3. Remove LaunchAgent plists
echo "Step 3/5: Removing auto-start configuration..."
rm -f "$LAUNCH_AGENTS_DIR/com.user.capslockmute.plist"
rm -f "$LAUNCH_AGENTS_DIR/com.user.capslock-hidutil.plist"
echo "         Done"
echo ""

# 4. Remove application
echo "Step 4/5: Removing application..."
rm -rf "$INSTALL_DIR/$APP_BUNDLE"
# Also remove old binary location if it exists
rm -f "$OLD_INSTALL_DIR/capslockmute"
echo "         Done"
echo ""

# 5. Reset hidutil mapping
echo "Step 5/5: Restoring Caps Lock..."
/usr/bin/hidutil property --set '{"UserKeyMapping":[]}' > /dev/null
echo "         Done"
echo ""

# Clean up log file and preferences
rm -f /tmp/capslockmute.log

echo "========================================="
echo "   Uninstallation Complete!             "
echo "========================================="
echo ""
echo "   Caps Lock is now back to normal."
echo ""
echo "   You can also remove Accessibility permission manually:"
echo "   System Settings -> Privacy & Security -> Accessibility"
echo "   -> Remove 'CapslockMute' from the list"
echo ""
echo "   To remove saved preferences, run:"
echo "   defaults delete com.rajiv.capslockmute"
echo ""
