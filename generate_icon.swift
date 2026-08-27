import Cocoa

func createIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let context = NSGraphicsContext.current!.cgContext
    let rect = CGRect(x: 0, y: 0, width: size, height: size)

    // Rounded Squircle Background
    let cornerRadius = size * 0.22
    let insetRect = rect.insetBy(dx: size * 0.05, dy: size * 0.05)
    let clipPath = CGPath(roundedRect: insetRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    context.addPath(clipPath)
    context.clip()

    // Vibrant Background Gradient (Red to Purple to Dark Slate)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let colors = [
        NSColor(red: 0.95, green: 0.15, blue: 0.35, alpha: 1.0).cgColor,
        NSColor(red: 0.55, green: 0.10, blue: 0.75, alpha: 1.0).cgColor,
        NSColor(red: 0.10, green: 0.10, blue: 0.18, alpha: 1.0).cgColor
    ] as CFArray

    let locations: [CGFloat] = [0.0, 0.6, 1.0]
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: size),
            end: CGPoint(x: size, y: 0),
            options: []
        )
    }

    // Inner Glow Stroke
    context.addPath(clipPath)
    context.setStrokeColor(NSColor.white.withAlphaComponent(0.3).cgColor)
    context.setLineWidth(size * 0.02)
    context.strokePath()

    // Center Download / Video Arrow Symbol
    context.setFillColor(NSColor.white.cgColor)
    let cx = size / 2.0
    let cy = size / 2.0

    // Stem
    let stemWidth = size * 0.12
    let stemHeight = size * 0.25
    let stemRect = CGRect(x: cx - stemWidth / 2, y: cy - size * 0.05, width: stemWidth, height: stemHeight)
    context.fill(stemRect)

    // Arrow Head
    let arrowPath = CGMutablePath()
    arrowPath.move(to: CGPoint(x: cx - size * 0.24, y: cy - size * 0.04))
    arrowPath.addLine(to: CGPoint(x: cx + size * 0.24, y: cy - size * 0.04))
    arrowPath.addLine(to: CGPoint(x: cx, y: cy - size * 0.28))
    arrowPath.closeSubpath()
    context.addPath(arrowPath)
    context.fillPath()

    // Base Bar
    let barWidth = size * 0.48
    let barHeight = size * 0.07
    let barRect = CGRect(x: cx - barWidth / 2, y: cy - size * 0.38, width: barWidth, height: barHeight)
    let barPath = CGPath(roundedRect: barRect, cornerWidth: barHeight / 2, cornerHeight: barHeight / 2, transform: nil)
    context.addPath(barPath)
    context.fillPath()

    image.unlockFocus()
    return image
}

let iconsetDir = "/tmp/Ascent.iconset"
try? FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let sizes: [Int] = [16, 32, 64, 128, 256, 512, 1024]
for s in sizes {
    let img = createIcon(size: CGFloat(s))
    if let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff), let png = rep.representation(using: .png, properties: [:]) {
        try? png.write(to: URL(fileURLWithPath: "\(iconsetDir)/icon_\(s)x\(s).png"))
    }
    if s <= 512 {
        let img2x = createIcon(size: CGFloat(s * 2))
        if let tiff2 = img2x.tiffRepresentation, let rep2 = NSBitmapImageRep(data: tiff2), let png2 = rep2.representation(using: .png, properties: [:]) {
            try? png2.write(to: URL(fileURLWithPath: "\(iconsetDir)/icon_\(s)x\(s)@2x.png"))
        }
    }
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetDir, "-o", "Ascent.app/Contents/Resources/AppIcon.icns"]
try? process.run()
process.waitUntilExit()
print("Generated AppIcon.icns successfully!")
