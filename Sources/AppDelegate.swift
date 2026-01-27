import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var shortcutMenuItems: [MuteShortcut: NSMenuItem] = [:]

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        EventTapManager.shared.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        EventTapManager.shared.stop()
    }

    // MARK: - Menu Bar Setup

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            // Create a simple "C" icon with adjusted baseline for centering
            let font = NSFont.boldSystemFont(ofSize: 20)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .baselineOffset: -3  // Lower the text slightly
            ]
            button.attributedTitle = NSAttributedString(string: "C", attributes: attributes)
        }

        statusItem.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        // Change shortcut submenu
        let shortcutMenuItem = NSMenuItem(title: "Change shortcut", action: nil, keyEquivalent: "")
        shortcutMenuItem.submenu = buildShortcutSubmenu()
        menu.addItem(shortcutMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Send feedback
        let feedbackItem = NSMenuItem(title: "Send feedback", action: #selector(sendFeedback), keyEquivalent: "")
        feedbackItem.target = self
        menu.addItem(feedbackItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit CapslockMute", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        menu.addItem(NSMenuItem.separator())

        // Version footer (disabled)
        let versionItem = NSMenuItem(title: "v1.2 by Rajiv, \u{00A9}2026", action: nil, keyEquivalent: "")
        versionItem.isEnabled = false
        menu.addItem(versionItem)

        return menu
    }

    private func buildShortcutSubmenu() -> NSMenu {
        let submenu = NSMenu()
        let currentShortcut = SettingsManager.shared.selectedShortcut

        for shortcut in MuteShortcut.allCases {
            let item = NSMenuItem(
                title: shortcut.displayName,
                action: #selector(shortcutSelected(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = shortcut
            item.state = (shortcut == currentShortcut) ? .on : .off
            submenu.addItem(item)
            shortcutMenuItems[shortcut] = item
        }

        return submenu
    }

    // MARK: - Actions

    @objc private func shortcutSelected(_ sender: NSMenuItem) {
        guard let shortcut = sender.representedObject as? MuteShortcut else { return }

        // Show Zoom alert if selecting Zoom for the first time
        if shortcut == .zoom && !SettingsManager.shared.zoomAlertDismissed {
            showZoomAlert { proceed in
                if proceed {
                    self.applyShortcut(shortcut)
                }
            }
        } else {
            applyShortcut(shortcut)
        }
    }

    private func applyShortcut(_ shortcut: MuteShortcut) {
        // Update settings
        SettingsManager.shared.selectedShortcut = shortcut

        // Update checkmarks
        for (s, item) in shortcutMenuItems {
            item.state = (s == shortcut) ? .on : .off
        }
    }

    private func showZoomAlert(completion: @escaping (Bool) -> Void) {
        let alert = NSAlert()
        alert.messageText = "Using with Zoom"
        alert.informativeText = """
            Note: Zoom's default mute shortcut is \u{2318}\u{21E7}A.

            Make sure this shortcut is enabled in Zoom:
            Settings \u{2192} Keyboard Shortcuts \u{2192} Mute/Unmute My Audio

            If you've customized Zoom's shortcut, you may need to adjust it.
            """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")

        // Add "Don't show again" checkbox
        let checkbox = NSButton(checkboxWithTitle: "Don't show this again", target: nil, action: nil)
        checkbox.state = .off
        alert.accessoryView = checkbox

        let response = alert.runModal()

        if checkbox.state == .on {
            SettingsManager.shared.zoomAlertDismissed = true
        }

        completion(response == .alertFirstButtonReturn)
    }

    @objc private func sendFeedback() {
        let alert = NSAlert()
        alert.messageText = "Send Feedback"
        alert.informativeText = """
            Have questions, suggestions, or found a bug?

            Email: capslockmute@gmail.com

            Click "Copy Email" to copy the address to your clipboard.
            """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Copy Email")
        alert.addButton(withTitle: "Close")

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString("capslockmute@gmail.com", forType: .string)
        }
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
