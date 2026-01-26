#!/usr/bin/env swift

import Cocoa

/// Generates app icon images matching the menu bar "C" style
/// Usage: swift generate-icon.swift <output-directory>

guard CommandLine.arguments.count > 1 else {
    print("Usage: swift generate-icon.swift <output-directory>")
    exit(1)
}

let outputDir = CommandLine.arguments[1]

// Icon sizes required for macOS .icns file
let sizes: [(size: Int, scale: Int, suffix: String)] = [
    (16, 1, "16x16"),
    (16, 2, "16x16@2x"),
    (32, 1, "32x32"),
    (32, 2, "32x32@2x"),
    (128, 1, "128x128"),
    (128, 2, "128x128@2x"),
    (256, 1, "256x256"),
    (256, 2, "256x256@2x"),
    (512, 1, "512x512"),
    (512, 2, "512x512@2x")
]

/// Generate an icon image with the "C" character
func generateIcon(pixelSize: Int) -> NSImage {
    let size = NSSize(width: pixelSize, height: pixelSize)
    let image = NSImage(size: size)

    image.lockFocus()

    // Background - rounded rectangle with a nice blue gradient
    let bgRect = NSRect(origin: .zero, size: size)
    let cornerRadius = CGFloat(pixelSize) * 0.2
    let path = NSBezierPath(roundedRect: bgRect, xRadius: cornerRadius, yRadius: cornerRadius)

    // Gradient background (dark blue to lighter blue)
    let gradient = NSGradient(
        starting: NSColor(calibratedRed: 0.2, green: 0.4, blue: 0.8, alpha: 1.0),
        ending: NSColor(calibratedRed: 0.3, green: 0.5, blue: 0.9, alpha: 1.0)
    )
    gradient?.draw(in: path, angle: -90)

    // Draw the "C" character
    let fontSize = CGFloat(pixelSize) * 0.65
    let font = NSFont.boldSystemFont(ofSize: fontSize)

    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white
    ]

    let text = "C"
    let textSize = text.size(withAttributes: attributes)

    // Center the text
    let textRect = NSRect(
        x: (CGFloat(pixelSize) - textSize.width) / 2,
        y: (CGFloat(pixelSize) - textSize.height) / 2,
        width: textSize.width,
        height: textSize.height
    )

    text.draw(in: textRect, withAttributes: attributes)

    image.unlockFocus()

    return image
}

/// Save image as PNG
func savePNG(image: NSImage, to path: String) -> Bool {
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        return false
    }

    do {
        try pngData.write(to: URL(fileURLWithPath: path))
        return true
    } catch {
        print("Error saving \(path): \(error)")
        return false
    }
}

// Create output directory
let fileManager = FileManager.default
let iconsetPath = "\(outputDir)/AppIcon.iconset"

try? fileManager.removeItem(atPath: iconsetPath)
try! fileManager.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

print("Generating icon images...")

// Generate all required sizes
for (size, scale, suffix) in sizes {
    let pixelSize = size * scale
    let image = generateIcon(pixelSize: pixelSize)
    let filename = "icon_\(suffix).png"
    let path = "\(iconsetPath)/\(filename)"

    if savePNG(image: image, to: path) {
        print("  Created \(filename) (\(pixelSize)x\(pixelSize))")
    } else {
        print("  FAILED: \(filename)")
        exit(1)
    }
}

print("Icon images generated in \(iconsetPath)")
print("Run 'iconutil -c icns \(iconsetPath)' to create AppIcon.icns")
