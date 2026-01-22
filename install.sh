#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.local/bin"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
BINARY_NAME="capslockmute"

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║           Caps Lock Mute for Tandem — Installer           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Check for Karabiner-Elements conflict
if pgrep -q "karabiner" || [ -d "/Applications/Karabiner-Elements.app" ]; then
    echo "⚠️  WARNING: Karabiner-Elements detected!"
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

# Check if we need to compile or can use pre-built binary
NEED_COMPILE=true
if [ -f "$SCRIPT_DIR/$BINARY_NAME" ]; then
    # Pre-built binary exists
    if command -v swiftc &> /dev/null; then
        # swiftc available, compile fresh
        NEED_COMPILE=true
    else
        # No swiftc, use pre-built
        NEED_COMPILE=false
        echo "Step 1/5: Using pre-built binary..."
        echo "         (No Swift compiler found, using included binary)"
        echo "         ✓ Binary ready"
    fi
else
    # No pre-built binary, must compile
    if ! command -v swiftc &> /dev/null; then
        echo "❌ Swift compiler not found and no pre-built binary available."
        echo ""
        echo "   You need Xcode Command Line Tools installed."
        echo "   Run this command and follow the prompts:"
        echo ""
        echo "      xcode-select --install"
        echo ""
        echo "   After installation completes, run this installer again."
        exit 1
    fi
fi

if [ "$NEED_COMPILE" = true ]; then
    echo "Step 1/5: Compiling..."
    swiftc -O -o "$SCRIPT_DIR/$BINARY_NAME" "$SCRIPT_DIR/Sources/main.swift" 2>&1
    echo "         ✓ Compiled successfully"
fi
echo ""

# 2. Install binary
echo "Step 2/5: Installing binary..."
mkdir -p "$INSTALL_DIR"
cp "$SCRIPT_DIR/$BINARY_NAME" "$INSTALL_DIR/$BINARY_NAME"
chmod +x "$INSTALL_DIR/$BINARY_NAME"
echo "         ✓ Installed to $INSTALL_DIR/$BINARY_NAME"
echo ""

# 3. Install LaunchAgents
echo "Step 3/5: Setting up auto-start..."
mkdir -p "$LAUNCH_AGENTS_DIR"
cp "$SCRIPT_DIR/LaunchAgents/com.user.capslock-hidutil.plist" "$LAUNCH_AGENTS_DIR/"
sed "s|/usr/local/bin/capslockmute|$INSTALL_DIR/capslockmute|g" \
    "$SCRIPT_DIR/LaunchAgents/com.user.capslockmute.plist" > "$LAUNCH_AGENTS_DIR/com.user.capslockmute.plist"
echo "         ✓ LaunchAgents installed"
echo ""

# 4. Load LaunchAgents
echo "Step 4/5: Starting services..."
launchctl unload "$LAUNCH_AGENTS_DIR/com.user.capslock-hidutil.plist" 2>/dev/null || true
launchctl unload "$LAUNCH_AGENTS_DIR/com.user.capslockmute.plist" 2>/dev/null || true
launchctl load "$LAUNCH_AGENTS_DIR/com.user.capslock-hidutil.plist"
launchctl load "$LAUNCH_AGENTS_DIR/com.user.capslockmute.plist"
echo "         ✓ Services started"
echo ""

# 5. Apply hidutil mapping immediately
echo "Step 5/5: Remapping Caps Lock → F18..."
/usr/bin/hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x70000006D}]}' > /dev/null
echo "         ✓ Key remap applied"
echo ""

# Installation complete
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                  Installation Complete!                   ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "⚠️  ONE MORE STEP REQUIRED: Grant Accessibility Permission"
echo ""
echo "   Without this permission, the app cannot detect your"
echo "   Caps Lock key press. This is a macOS security requirement."
echo ""
echo "   Opening System Preferences now..."
echo ""

# Open System Preferences to Accessibility pane
# macOS Ventura+ uses different URL scheme
if [[ $(sw_vers -productVersion | cut -d. -f1) -ge 13 ]]; then
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
else
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
fi

sleep 1

echo "   ┌─────────────────────────────────────────────────────────┐"
echo "   │  In the window that just opened:                       │"
echo "   │                                                        │"
echo "   │  1. Click the 🔒 lock icon (bottom left)               │"
echo "   │  2. Enter your password                                │"
echo "   │  3. Find 'capslockmute' in the list                    │"
echo "   │  4. Check the box ☑ next to it                         │"
echo "   │                                                        │"
echo "   │  If 'capslockmute' isn't listed, click + and go to:    │"
echo "   │  $INSTALL_DIR/$BINARY_NAME"
echo "   └─────────────────────────────────────────────────────────┘"
echo ""
echo "   Once you've granted permission, test it:"
echo "   → Open Tandem and join a call"
echo "   → Press Caps Lock"
echo "   → Your mic should mute/unmute!"
echo ""
echo "   Having trouble? See the README for troubleshooting tips."
echo ""
