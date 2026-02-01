import Foundation

/// Controls the Caps Lock LED state via bundled keyboard-leds binary
class LEDController {
    static let shared = LEDController()

    /// Current LED state (true = on/muted, false = off/unmuted)
    private(set) var isLEDOn = false

    private init() {}

    /// Toggle the LED state
    func toggle() {
        isLEDOn.toggle()
        setLED(on: isLEDOn)
    }

    /// Set the LED to a specific state
    func setLED(on: Bool) {
        isLEDOn = on

        guard let binaryURL = Bundle.main.url(forResource: "keyboard-leds", withExtension: nil, subdirectory: nil) else {
            // Try looking in MacOS directory (where we copy it in build script)
            let macOSURL = Bundle.main.bundleURL
                .appendingPathComponent("Contents/MacOS/keyboard-leds")

            if FileManager.default.fileExists(atPath: macOSURL.path) {
                executeLEDBinary(at: macOSURL, on: on)
            } else {
                print("LED binary not found in bundle")
            }
            return
        }

        executeLEDBinary(at: binaryURL, on: on)
    }

    private func executeLEDBinary(at url: URL, on: Bool) {
        let process = Process()
        process.executableURL = url
        process.arguments = [on ? "-c1" : "-c0"]

        // Silence stdout/stderr
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            // Don't wait - fire and forget for responsiveness
        } catch {
            print("Failed to execute LED binary: \(error)")
        }
    }
}
