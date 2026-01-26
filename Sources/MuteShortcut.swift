import Cocoa

/// Represents the available mute shortcuts for different applications
enum MuteShortcut: String, CaseIterable {
    case tandem  // Command+Shift+M
    case zoom    // Command+Shift+A
    case meet    // Command+D

    /// The key code to send for this shortcut
    var keyCode: CGKeyCode {
        switch self {
        case .tandem: return 0x2E  // M key
        case .zoom:   return 0x00  // A key
        case .meet:   return 0x02  // D key
        }
    }

    /// The modifier flags for this shortcut
    var modifiers: CGEventFlags {
        switch self {
        case .tandem: return [.maskCommand, .maskShift]
        case .zoom:   return [.maskCommand, .maskShift]
        case .meet:   return [.maskCommand]
        }
    }

    /// Display name for the menu
    var displayName: String {
        switch self {
        case .tandem: return "\u{2318}\u{21E7}M (Tandem)"
        case .zoom:   return "\u{2318}\u{21E7}A (Zoom)"
        case .meet:   return "\u{2318}D (Meet)"
        }
    }

    /// Short description of the target app
    var appName: String {
        switch self {
        case .tandem: return "Tandem"
        case .zoom:   return "Zoom"
        case .meet:   return "Google Meet"
        }
    }
}
