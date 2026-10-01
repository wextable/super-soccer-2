import UIKit

/// The old top-down token. The red shirt takes the club kit. The brown hair stays as drawn.
@MainActor
enum PitchPlayerIcon {
    static func image(shirt: KitColor) -> UIImage? {
        let key = cacheKey(shirt)
        if let cached = cache[key] { return cached }
        guard let painted = paint(shirt) else { return nil }
        cache[key] = painted
        return painted
    }

    static func sample(_ image: UIImage, x: Int, y: Int) -> (red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8)? {
        guard let cgImage = image.cgImage, let buffer = IconBuffer(image: cgImage) else { return nil }
        return buffer.pixel(x, y)
    }

    private static var cache: [UInt32: UIImage] = [:]

    private static func paint(_ shirt: KitColor) -> UIImage? {
        guard let source = artwork(), let buffer = IconBuffer(image: source) else { return nil }
        var painted = buffer
        let red = channel(shirt.red)
        let green = channel(shirt.green)
        let blue = channel(shirt.blue)
        painted.replaceShirt(red: red, green: green, blue: blue)
        guard let image = painted.makeImage() else { return nil }
        return UIImage(cgImage: image, scale: 1, orientation: .up)
    }

    private static func artwork() -> CGImage? {
        if let image = UIImage(named: "icon_player")?.cgImage { return image }
        guard let bundle = Bundle(identifier: "dev.personal.SuperSoccer2") else { return nil }
        return UIImage(named: "icon_player", in: bundle, compatibleWith: nil)?.cgImage
    }

    private static func cacheKey(_ color: KitColor) -> UInt32 {
        (UInt32(channel(color.red)) << 16) | (UInt32(channel(color.green)) << 8) | UInt32(channel(color.blue))
    }

    private static func channel(_ value: Double) -> UInt8 {
        UInt8(clamping: Int((value * 255).rounded()))
    }
}

private func isPitchShirt(_ red: UInt8, _ green: UInt8, _ blue: UInt8, _ alpha: UInt8) -> Bool {
    guard alpha > 0 else { return false }
    let dr = Int(red) - 251
    let dg = Int(green)
    let db = Int(blue) - 7
    return dr * dr + dg * dg + db * db <= 1
}

/// Same bitmap layout as the portrait painter, so a top-left sample lands on the source pixel.
private struct IconBuffer {
    let width: Int
    let height: Int
    var words: [UInt32]

    init?(image: CGImage) {
        width = image.width
        height = image.height
        guard width > 0, height > 0 else { return nil }
        words = [UInt32](repeating: 0, count: width * height)
        var drew = false
        words.withUnsafeMutableBytes { raw in
            guard let context = CGContext(
                data: raw.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
            ) else { return }
            context.interpolationQuality = .none
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            drew = true
        }
        guard drew else { return nil }
    }

    mutating func replaceShirt(red: UInt8, green: UInt8, blue: UInt8) {
        let replacement = (UInt32(255) << 24) | (UInt32(red) << 16) | (UInt32(green) << 8) | UInt32(blue)
        for index in words.indices {
            let pixel = words[index]
            let redChannel = UInt8((pixel >> 16) & 255)
            let greenChannel = UInt8((pixel >> 8) & 255)
            let blueChannel = UInt8(pixel & 255)
            let alpha = UInt8((pixel >> 24) & 255)
            guard isPitchShirt(redChannel, greenChannel, blueChannel, alpha) else { continue }
            words[index] = replacement
        }
    }

    func pixel(_ x: Int, _ y: Int) -> (red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8)? {
        guard x >= 0, y >= 0, x < width, y < height else { return nil }
        let pixel = words[y * width + x]
        return (
            UInt8((pixel >> 16) & 255),
            UInt8((pixel >> 8) & 255),
            UInt8(pixel & 255),
            UInt8((pixel >> 24) & 255)
        )
    }

    func makeImage() -> CGImage? {
        let data = words.withUnsafeBytes { Data($0) }
        guard let provider = CGDataProvider(data: data as CFData) else { return nil }
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(
                rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
            ),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }
}
