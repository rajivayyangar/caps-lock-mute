import Cocoa
import Foundation

// Key codes
let kF18KeyCode: CGKeyCode = 0x4F  // 79 - our proxy key (remapped from Caps Lock)
let kMKeyCode: CGKeyCode = 0x2E    // 46 - 'M' key

// Global reference for re-enabling tap if system disables it
var gEventTap: CFMachPort?

// Post ⌘⇧M key event
func postCommandShiftM() {
    let source = CGEventSource(stateID: .hidSystemState)

    // Key down with ⌘⇧
    if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: kMKeyCode, keyDown: true) {
        keyDown.flags = [.maskCommand, .maskShift]
        keyDown.post(tap: .cghidEventTap)
    }

    // Key up with ⌘⇧
    if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: kMKeyCode, keyDown: false) {
        keyUp.flags = [.maskCommand, .maskShift]
        keyUp.post(tap: .cghidEventTap)
    }
}

// Event tap callback
func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {

    // Handle tap disabled (system can disable taps if they're slow)
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap = gEventTap {
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
    if keyCode == kF18KeyCode {
        postCommandShiftM()
        return nil  // Suppress the original F18 event
    }

    return Unmanaged.passUnretained(event)
}

// Check accessibility permission
func checkAccessibility() -> Bool {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
    return AXIsProcessTrustedWithOptions(options as CFDictionary)
}

// Main
func main() {
    print("CapsLockMute starting...")

    // Check accessibility
    if !checkAccessibility() {
        print("⚠️  Accessibility permission required.")
        print("   Grant permission in: System Preferences → Security & Privacy → Privacy → Accessibility")
        print("   Then restart this app.")
        // Continue anyway — the tap will fail but the prompt was shown
    }

    // Create event tap for key events
    let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)

    guard let eventTap = CGEvent.tapCreate(
        tap: .cgSessionEventTap,
        place: .headInsertEventTap,
        options: .defaultTap,
        eventsOfInterest: eventMask,
        callback: eventTapCallback,
        userInfo: nil
    ) else {
        print("❌ Failed to create event tap.")
        print("   Make sure Accessibility permission is granted.")
        exit(1)
    }

    // Store tap reference globally for re-enabling if system disables it
    gEventTap = eventTap

    // Create a mach port run loop source
    let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)

    // Enable the tap
    CGEvent.tapEnable(tap: eventTap, enable: true)

    print("✓ CapsLockMute running. Press Caps Lock (F18) to send ⌘⇧M.")
    print("  Press Ctrl+C to quit.")

    // Run forever
    CFRunLoopRun()
}

main()
