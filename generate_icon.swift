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

guard let sourceImage = loadSourceImage() else {
    print("Error: Could not load source icon image from Resources/AppIcon.png or Downloads.")
    exit(1)
}

func createResizedImage(source: NSImage, size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let context = NSGraphicsContext.current!.cgContext
    context.interpolationQuality = .high
    context.setShouldAntialias(true)

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    source.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)

    image.unlockFocus()
    return image
}

let iconsetDir = "/tmp/Ascent.iconset"
try? FileManager.default.removeItem(atPath: iconsetDir)
try? FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let sizes: [Int] = [16, 32, 64, 128, 256, 512, 1024]
for s in sizes {
    let img = createResizedImage(source: sourceImage, size: CGFloat(s))
    if let tiff = img.tiffRepresentation,
       let rep = NSBitmapImageRep(data: tiff),
       let png = rep.representation(using: .png, properties: [:]) {
        try? png.write(to: URL(fileURLWithPath: "\(iconsetDir)/icon_\(s)x\(s).png"))
    }
    if s <= 512 {
        let img2x = createResizedImage(source: sourceImage, size: CGFloat(s * 2))
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
    print("Generated AppIcon.icns successfully from yt download.png!")
} catch {
    print("Failed to run iconutil: \(error)")
}
