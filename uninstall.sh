#!/bin/bash

INSTALL_DIR="$HOME/.local/bin"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║          Caps Lock Mute for Tandem — Uninstaller          ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# 1. Unload LaunchAgents
echo "Step 1/4: Stopping services..."
launchctl unload "$LAUNCH_AGENTS_DIR/com.user.capslockmute.plist" 2>/dev/null || true
launchctl unload "$LAUNCH_AGENTS_DIR/com.user.capslock-hidutil.plist" 2>/dev/null || true
echo "         ✓ Services stopped"
echo ""

# 2. Remove LaunchAgent plists
echo "Step 2/4: Removing auto-start configuration..."
rm -f "$LAUNCH_AGENTS_DIR/com.user.capslockmute.plist"
rm -f "$LAUNCH_AGENTS_DIR/com.user.capslock-hidutil.plist"
echo "         ✓ LaunchAgents removed"
echo ""

# 3. Remove binary
echo "Step 3/4: Removing binary..."
rm -f "$INSTALL_DIR/capslockmute"
echo "         ✓ Binary removed"
echo ""

# 4. Reset hidutil mapping
echo "Step 4/4: Restoring Caps Lock..."
/usr/bin/hidutil property --set '{"UserKeyMapping":[]}' > /dev/null
echo "         ✓ Caps Lock restored to normal"
echo ""

# Clean up log file
rm -f /tmp/capslockmute.log

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                 Uninstallation Complete!                  ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "   Caps Lock is now back to normal."
echo ""
echo "   You can also remove Accessibility permission manually:"
echo "   System Preferences → Privacy & Security → Accessibility"
echo "   → Remove 'capslockmute' from the list"
echo ""
