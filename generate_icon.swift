import Cocoa

func loadSourceImage() -> NSImage? {
    let projectIconPath = "Resources/AppIcon.png"
    let downloadsIconPath = "\(NSHomeDirectory())/Downloads/yt download.png"

    if FileManager.default.fileExists(atPath: projectIconPath),
       let img = NSImage(contentsOfFile: projectIconPath) {
        return img
    }
    if FileManager.default.fileExists(atPath: downloadsIconPath),
       let img = NSImage(contentsOfFile: downloadsIconPath) {
        return img
    }
    return nil
}

guard let rawSource = loadSourceImage(),
      let tiff = rawSource.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff) else {
    print("Error: Could not load source image.")
    exit(1)
}

let w = rep.pixelsWide
let h = rep.pixelsHigh

// Find exact bounding box of the non-white glyph
var minX = w, maxX = 0, minY = h, maxY = 0
for y in 0..<h {
    for x in 0..<w {
        if let c = rep.colorAt(x: x, y: y) {
            // If pixel is dark / not pure white
            if c.redComponent < 0.92 || c.greenComponent < 0.92 || c.blueComponent < 0.92 {
                if x < minX { minX = x }
                if x > maxX { maxX = x }
                if y < minY { minY = y }
                if y > maxY { maxY = y }
            }
        }
    }
}

// Add small padding to bounding box
let padding = 4
let cropMinX = max(0, minX - padding)
let cropMaxX = min(w, maxX + padding)
let cropMinY = max(0, minY - padding)
let cropMaxY = min(h, maxY + padding)
let glyphWidth = CGFloat(cropMaxX - cropMinX)
let glyphHeight = CGFloat(cropMaxY - cropMinY)

// Extract the cropped glyph as an image with transparent background (so white becomes transparent)
func createCroppedGlyph() -> NSImage {
    let cropped = NSImage(size: NSSize(width: glyphWidth, height: glyphHeight))
    cropped.lockFocus()

    let context = NSGraphicsContext.current!.cgContext
    context.interpolationQuality = .high

    for y in 0..<Int(glyphHeight) {
        for x in 0..<Int(glyphWidth) {
            let srcX = cropMinX + x
            if let c = rep.colorAt(x: srcX, y: (cropMinY + y)) {
                // Invert darkness to alpha: black = 1.0 alpha, white = 0.0 alpha
                let luminance = 0.299 * c.redComponent + 0.587 * c.greenComponent + 0.114 * c.blueComponent
                let alpha = max(0.0, min(1.0, 1.0 - luminance))
                if alpha > 0.05 {
                    context.setFillColor(NSColor.black.withAlphaComponent(alpha).cgColor)
                    context.fill(CGRect(x: CGFloat(x), y: CGFloat((Int(glyphHeight) - 1) - y), width: 1, height: 1))
                }
            }
        }
    }

    cropped.unlockFocus()
    return cropped
}

let glyphImage = createCroppedGlyph()

// Render standard macOS Apple Squircle icon with transparent margins
func createAppleStyleIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let context = NSGraphicsContext.current!.cgContext
    context.interpolationQuality = .high
    context.setShouldAntialias(true)

    // Standard macOS App Icon squircle size and corner radius (~82% of canvas, perfectly centered)
    let margin = size * 0.09
    let tileRect = CGRect(x: margin, y: margin, width: size - (margin * 2), height: size - (margin * 2))
    let cornerRadius = tileRect.width * 0.2237
    let squirclePath = CGPath(roundedRect: tileRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    // 1. Soft drop shadow under the squircle tile
    context.saveGState()
    context.setShadow(
        offset: CGSize(width: 0, height: -size * 0.03),
        blur: size * 0.06,
        color: NSColor.black.withAlphaComponent(0.22).cgColor
    )
    context.addPath(squirclePath)
    context.setFillColor(NSColor.white.cgColor)
    context.fillPath()
    context.restoreGState()

    // 2. Draw Squircle Tile Base (Pure crisp white with subtle inner gradient)
    context.saveGState()
    context.addPath(squirclePath)
    context.clip()

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let tileColors = [
        NSColor(white: 0.99, alpha: 1.0).cgColor,
        NSColor(white: 0.95, alpha: 1.0).cgColor
    ] as CFArray
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: tileColors, locations: [0.0, 1.0]) {
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: tileRect.maxY),
            end: CGPoint(x: 0, y: tileRect.minY),
            options: []
        )
    }

    // 3. Draw Centered Glyph inside squircle
    let maxGlyphDim = tileRect.width * 0.58
    let scale = min(maxGlyphDim / glyphWidth, maxGlyphDim / glyphHeight)
    let drawW = glyphWidth * scale
    let drawH = glyphHeight * scale
    let drawX = tileRect.midX - (drawW / 2)
    let drawY = tileRect.midY - (drawH / 2)

    glyphImage.draw(
        in: NSRect(x: drawX, y: drawY, width: drawW, height: drawH),
        from: .zero,
        operation: .sourceOver,
        fraction: 1.0
    )

    // 4. Subtle Inner Border Stroke
    context.addPath(squirclePath)
    context.setStrokeColor(NSColor.black.withAlphaComponent(0.08).cgColor)
    context.setLineWidth(max(1.0, size * 0.01))
    context.strokePath()

    context.restoreGState()

    image.unlockFocus()
    return image
}

let iconsetDir = "/tmp/Ascent.iconset"
try? FileManager.default.removeItem(atPath: iconsetDir)
try? FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let sizes: [Int] = [16, 32, 64, 128, 256, 512, 1024]
for s in sizes {
    let img = createAppleStyleIcon(size: CGFloat(s))
    if let tiff = img.tiffRepresentation,
       let rep = NSBitmapImageRep(data: tiff),
       let png = rep.representation(using: .png, properties: [:]) {
        try? png.write(to: URL(fileURLWithPath: "\(iconsetDir)/icon_\(s)x\(s).png"))
    }
    if s <= 512 {
        let img2x = createAppleStyleIcon(size: CGFloat(s * 2))
        if let tiff2 = img2x.tiffRepresentation,
           let rep2 = NSBitmapImageRep(data: tiff2),
           let png2 = rep2.representation(using: .png, properties: [:]) {
            try? png2.write(to: URL(fileURLWithPath: "\(iconsetDir)/icon_\(s)x\(s)@2x.png"))
        }
    }
}

let outputPath = "Ascent.app/Contents/Resources/AppIcon.icns"
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetDir, "-o", outputPath]

do {
    try process.run()
    process.waitUntilExit()
    print("Generated borderless Apple-standard AppIcon.icns successfully!")
} catch {
    print("Failed to run iconutil: \(error)")
}
