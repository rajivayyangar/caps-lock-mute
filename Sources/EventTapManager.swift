import Cocoa

/// Manages the CGEventTap for intercepting key events
class EventTapManager {
    static let shared = EventTapManager()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var permissionCheckTimer: Timer?
    private var hasShownPermissionAlert = false

    /// Key code for F18 (our proxy key remapped from Caps Lock)
    private let f18KeyCode: CGKeyCode = 0x4F  // 79

    /// Double-tap detection
    private var lastF18PressTime: Date?
    private let doubleTapThreshold: TimeInterval = 0.3  // 300ms

    private init() {}

    /// Check if accessibility permission is granted
    func checkAccessibility() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    /// Start the event tap
    func start() {
        // Already running
        guard eventTap == nil else { return }

        // Check accessibility - if not granted, show alert and start polling
        if !checkAccessibility() {
            print("Accessibility permission required. Will retry when granted.")
            showPermissionAlert()
            startPermissionPolling()
            return
        }

        // Create event tap for key events
        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)

        // Store self in a pointer for the callback
        let refcon = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { proxy, type, event, refcon -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else {
                    return Unmanaged.passUnretained(event)
                }
                let manager = Unmanaged<EventTapManager>.fromOpaque(refcon).takeUnretainedValue()
                return manager.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: refcon
        ) else {
            print("Failed to create event tap. Accessibility permission may not be granted.")
            return
        }

        eventTap = tap

        // Create run loop source and add to current run loop
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)

        // Enable the tap
        CGEvent.tapEnable(tap: tap, enable: true)

        print("Event tap started. Listening for Caps Lock (F18).")
    }

    /// Stop the event tap
    func stop() {
        permissionCheckTimer?.invalidate()
        permissionCheckTimer = nil

        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    /// Start polling for accessibility permission
    private func startPermissionPolling() {
        // Don't start multiple timers
        guard permissionCheckTimer == nil else { return }

        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if AXIsProcessTrusted() {
                self.permissionCheckTimer?.invalidate()
                self.permissionCheckTimer = nil
                print("Accessibility permission granted. Starting event tap.")
                self.start()
            }
        }
    }

    /// Show alert dialog when permissions are missing
    private func showPermissionAlert() {
        guard !hasShownPermissionAlert else { return }
        hasShownPermissionAlert = true

        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = "CapslockMute needs Accessibility permission to detect your Caps Lock key.\n\nIf you recently updated the app, you may need to re-grant this permission."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Later")

            if alert.runModal() == .alertFirstButtonReturn {
                // Open Accessibility settings
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }

    /// Handle an event from the tap
    private func handleEvent(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        // Handle tap being disabled by the system
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        // Only handle key down events
        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))

        // Check for F18
        if keyCode == f18KeyCode {
            let now = Date()
            let isDoubleTap: Bool

            if let lastPress = lastF18PressTime,
               now.timeIntervalSince(lastPress) < doubleTapThreshold {
                // Double tap detected
                isDoubleTap = true
                lastF18PressTime = nil  // Reset to avoid triple-tap issues
            } else {
                // Single press (so far)
                isDoubleTap = false
                lastF18PressTime = now
            }

            if isDoubleTap {
                // Double tap: toggle LED only (no mute shortcut)
                LEDController.shared.toggle()
            } else {
                // Single press: toggle LED and send mute shortcut
                LEDController.shared.toggle()
                postShortcut()
            }

            return nil  // Suppress the original F18 event
        }

        return Unmanaged.passUnretained(event)
    }

    /// Post the currently configured shortcut
    private func postShortcut() {
        let shortcut = SettingsManager.shared.selectedShortcut
        let source = CGEventSource(stateID: .hidSystemState)

        // Key down with modifiers
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: shortcut.keyCode, keyDown: true) {
            keyDown.flags = shortcut.modifiers
            keyDown.post(tap: .cghidEventTap)
        }

        // Key up with modifiers
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: shortcut.keyCode, keyDown: false) {
            keyUp.flags = shortcut.modifiers
            keyUp.post(tap: .cghidEventTap)
        }
    }
}
