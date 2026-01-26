import Foundation

/// Manages persistent settings using UserDefaults
class SettingsManager {
    static let shared = SettingsManager()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let selectedShortcut = "selectedShortcut"
        static let zoomAlertDismissed = "zoomAlertDismissed"
    }

    private init() {}

    /// The currently selected mute shortcut
    var selectedShortcut: MuteShortcut {
        get {
            guard let rawValue = defaults.string(forKey: Keys.selectedShortcut),
                  let shortcut = MuteShortcut(rawValue: rawValue) else {
                return .tandem  // Default to Tandem
            }
            return shortcut
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.selectedShortcut)
        }
    }

    /// Whether the Zoom warning alert has been dismissed
    var zoomAlertDismissed: Bool {
        get {
            return defaults.bool(forKey: Keys.zoomAlertDismissed)
        }
        set {
            defaults.set(newValue, forKey: Keys.zoomAlertDismissed)
        }
    }
}
