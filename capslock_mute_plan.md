# Caps Lock Mute — Technical Spec

Remap Caps Lock to ⌘⇧M (mute toggle for Tandem) on macOS.

## Why This Is Hard

Caps Lock is special on macOS:
- **Hardware-level toggle**: Built-in ~75ms delay, maintains on/off state
- **HID layer processing**: Handled before normal event taps see it
- **Can't intercept**: By the time `CGEventTap` sees it, toggle already happened

## Solution: Two-Stage Remap

```
┌─────────────────────────────────────────────────────────────────────┐
│                      macOS Keyboard Pipeline                        │
└─────────────────────────────────────────────────────────────────────┘

  Physical Key              Stage 1                    Stage 2
  ───────────              ─────────                  ─────────

  ┌──────────┐      ┌─────────────────┐      ┌─────────────────────┐
  │   Caps   │      │     hidutil     │      │   CapsLockMute App  │
  │   Lock   │─────▶│  (HID Layer)    │─────▶│   (CGEventTap)      │
  │          │      │                 │      │                     │
  └──────────┘      │  Caps Lock      │      │  F18 ──▶ ⌘⇧M       │
                    │      │          │      │                     │
                    │      ▼          │      │  Posts synthetic    │
                    │     F18         │      │  key event          │
                    └─────────────────┘      └─────────────────────┘
                                                       │
                                                       ▼
                                             ┌─────────────────────┐
                                             │    Tandem App       │
                                             │  Receives ⌘⇧M      │
                                             │  Toggles mute       │
                                             └─────────────────────┘
```

**Stage 1: hidutil** (Apple's built-in HID remapper)
- Runs at boot via LaunchAgent
- Remaps Caps Lock → F18 at the driver level
- Bypasses all Caps Lock quirks (delay, LED, toggle state)

**Stage 2: CapsLockMute** (Swift daemon)
- Runs at login via LaunchAgent
- Uses `CGEventTap` to intercept F18 key events
- Synthesizes and posts ⌘⇧M
- Requires Accessibility permission

## File Structure

```
caps-lock-mute/
├── capslock_mute_plan.md      # This file
├── Sources/
│   └── main.swift             # The Swift daemon
├── LaunchAgents/
│   ├── com.user.capslock-hidutil.plist   # hidutil remap config
│   └── com.user.capslockmute.plist       # App auto-start
├── install.sh                 # Installer
└── uninstall.sh               # Uninstaller
```

## Key Codes

| Key | CGKeyCode | Notes |
|-----|-----------|-------|
| Caps Lock | 0x39 (57) | Remapped away by hidutil |
| F18 | 0x4F (79) | Proxy key (unused by default) |
| M | 0x2E (46) | Target key |
| Command | modifier flag | kCGEventFlagMaskCommand |
| Shift | modifier flag | kCGEventFlagMaskShift |

## Requirements

- macOS 10.15+ (Catalina or later)
- Accessibility permission for CapsLockMute app
- No Karabiner-Elements (conflicts at HID layer)

## Known Limitations

1. **Caps Lock LED stays off** — hidutil remaps before LED logic
2. **No actual Caps Lock** — you lose the key entirely
3. **Secure input** — won't work in password fields (intentional)
4. **Per-keyboard** — hidutil applies to all keyboards by default
