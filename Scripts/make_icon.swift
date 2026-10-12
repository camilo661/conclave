// Renders the macOS icon set from the logo artwork.
// Usage: swift make_icon.swift <logo image> <output .iconset directory>

import AppKit

let arguments = CommandLine.arguments
guard arguments.count == 3, let artwork = NSImage(contentsOfFile: arguments[1]) else {
    FileHandle.standardError.write(Data("usage: make_icon.swift <logo image> <output.iconset>\n".utf8))
    exit(1)
}
let iconset = URL(fileURLWithPath: arguments[2])
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

/// Draws the artwork centred on a white rounded tile, following the macOS icon grid.
func renderIcon(pixels: Int) -> Data {
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    bitmap.size = NSSize(width: pixels, height: pixels)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    NSGraphicsContext.current?.imageInterpolation = .high

    let canvas = CGFloat(pixels)
    let tile = NSRect(x: 0, y: 0, width: canvas, height: canvas).insetBy(dx: canvas * 0.1, dy: canvas * 0.1)
    let tilePath = NSBezierPath(roundedRect: tile, xRadius: tile.width * 0.225, yRadius: tile.width * 0.225)
    NSColor.white.setFill()
    tilePath.fill()
    tilePath.addClip()

    let content = tile.insetBy(dx: tile.width * 0.07, dy: tile.height * 0.07)
    let scale = min(content.width / artwork.size.width, content.height / artwork.size.height)
    let drawSize = NSSize(width: artwork.size.width * scale, height: artwork.size.height * scale)
    let drawRect = NSRect(
        x: content.midX - drawSize.width / 2,
        y: content.midY - drawSize.height / 2,
        width: drawSize.width,
        height: drawSize.height
    )
    artwork.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1)

    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using: .png, properties: [:])!
}

for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let suffix = scale == 1 ? "" : "@2x"
        let file = iconset.appendingPathComponent("icon_\(points)x\(points)\(suffix).png")
        try renderIcon(pixels: points * scale).write(to: file)
    }
}
