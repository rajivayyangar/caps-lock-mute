# Caps Lock Mute for Tandem

Press **Caps Lock** to toggle your microphone mute in [Tandem](https://tandem.chat).

This tool remaps your Caps Lock key to send ⌘⇧M (Command+Shift+M), which is Tandem's mute shortcut.

## Download

**[Download CapslockMute-v1.2.zip](https://github.com/rajivayyangar/caps-lock-mute/releases/latest/download/CapslockMute-v1.2.zip)** (macOS 10.15+)

1. Download and unzip
2. Drag `CapslockMute.app` to Applications
3. Launch and grant Accessibility permission when prompted

The app is signed and notarized by Apple — no Gatekeeper warnings.

---

## Requirements

- macOS 10.15 (Catalina) or later
- Tandem app installed
- **No Karabiner-Elements** — it conflicts with this tool. Uninstall it first if you have it.

---

## Installation

### Step 1: Download

**Option A: Download the zip** (easiest)
1. Go to the [Releases page](../../releases)
2. Download the latest `caps-lock-mute.zip`
3. Double-click to unzip it
4. Open the `caps-lock-mute` folder

**Option B: Clone with git** (for developers)
```bash
git clone https://github.com/YOUR_USERNAME/caps-lock-mute.git
cd caps-lock-mute
```

### Step 2: Run the installer

1. Open **Terminal** (press ⌘Space, type "Terminal", press Enter)
2. Drag the `caps-lock-mute` folder into the Terminal window — this types the path for you
3. You should see something like `/Users/yourname/Downloads/caps-lock-mute`
4. Type `cd ` (with a space) before that path, so it looks like:
   ```
   cd /Users/yourname/Downloads/caps-lock-mute
   ```
5. Press **Enter**
6. Type this command and press **Enter**:
   ```bash
   ./install.sh
   ```

You'll see output like this:
```
=== CapsLockMute Installer ===

Compiling capslockmute...
✓ Compiled successfully
Installing binary to /Users/you/.local/bin...
✓ Binary installed
...
```

### Step 3: Grant Accessibility Permission (Required!)

This is the most important step. macOS requires you to explicitly allow this app to monitor your keyboard.

The installer will automatically open System Preferences to the right place. If it doesn't:

1. Open **System Preferences** (or **System Settings** on macOS Ventura+)
2. Go to **Privacy & Security**
3. Click **Accessibility** in the left sidebar
4. Click the **lock icon** at the bottom and enter your password
5. Look for **capslockmute** in the list
   - If it's there, make sure it's **checked** ✓
   - If it's NOT there, click the **+** button and navigate to:
     ```
     /Users/YOURNAME/.local/bin/capslockmute
     ```
     (Press ⌘⇧G in the file picker and paste that path, replacing YOURNAME with your username)

6. Make sure the checkbox next to **capslockmute** is **enabled**

### Step 4: Test it!

1. Open Tandem and join a room (or start a call)
2. Press **Caps Lock**
3. Your microphone should mute/unmute!

---

## Troubleshooting

### "Caps Lock isn't doing anything"

1. **Check Accessibility permission** — This is the #1 issue. Go back to Step 3 and make sure capslockmute is listed AND checked.

2. **Restart the app** — Run these commands in Terminal:
   ```bash
   launchctl unload ~/Library/LaunchAgents/com.user.capslockmute.plist
   launchctl load ~/Library/LaunchAgents/com.user.capslockmute.plist
   ```

3. **Check if it's running**:
   ```bash
   pgrep -l capslockmute
   ```
   You should see a process ID and "capslockmute". If not, the app isn't running.

4. **Check the log**:
   ```bash
   cat /tmp/capslockmute.log
   ```

### "Caps Lock still toggles caps lock"

The key remap might not have applied. Run:
```bash
/usr/bin/hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x70000006D}]}'
```

### "I have Karabiner-Elements installed"

Karabiner conflicts with this tool — they both try to remap keys at the same level. You need to either:
- Uninstall Karabiner-Elements, OR
- Configure this remap inside Karabiner instead (advanced)

### "It works in some apps but not others"

Some apps (especially those with "secure input" like password managers or banking apps) block keyboard monitoring for security. This is expected and intentional.

---

## Uninstalling

Run the uninstaller:
```bash
cd /path/to/caps-lock-mute
./uninstall.sh
```

This will:
- Stop the running processes
- Remove the LaunchAgents
- Reset Caps Lock to normal behavior
- Remove the installed binary

You can also manually remove Accessibility permission in System Preferences.

---

## How It Works

Caps Lock is special on macOS — it has built-in delays and toggle behavior that can't be intercepted normally. This tool uses a two-stage approach:

1. **Stage 1**: Uses Apple's `hidutil` to remap Caps Lock → F18 at the hardware driver level
2. **Stage 2**: A small background app intercepts F18 and sends ⌘⇧M to Tandem

Both stages run automatically at login via LaunchAgents.

---

## Customization

Want to use a different shortcut? Edit `Sources/main.swift`:

```swift
// Change this to your desired key code
let kMKeyCode: CGKeyCode = 0x2E    // 46 - 'M' key

// Change these flags for different modifiers
keyDown.flags = [.maskCommand, .maskShift]
```

Then recompile: `swiftc -O -o capslockmute Sources/main.swift`

---

## License

MIT — do whatever you want with it.
