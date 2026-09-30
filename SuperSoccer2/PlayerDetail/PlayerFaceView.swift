import CoreGraphics
import SwiftUI
import UIKit

/// Club kit, or the old keeper pink, painted into the portrait at draw time.
enum PlayerFaceTones {
    static func colors(position: Position, clubID: String) -> (primary: FaceByte, secondary: FaceByte) {
        if position == .keeper {
            return (FaceByte(230, 34, 214), FaceByte(255, 255, 255))
        }
        guard let kit = LeagueDraft.kit(for: clubID) else {
            return (FaceByte(0, 0, 0), FaceByte(255, 255, 255))
        }
        return (FaceByte(kit.primary), FaceByte(kit.secondary))
    }
}

struct FaceByte: Equatable, Sendable {
    var red: Int
    var green: Int
    var blue: Int

    init(_ red: Int, _ green: Int, _ blue: Int) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    init(_ color: KitColor) {
        red = Self.channel(color.red)
        green = Self.channel(color.green)
        blue = Self.channel(color.blue)
    }

    private static func channel(_ value: Double) -> Int {
        Int((value * 255).rounded())
    }
}

/// Stacks the old face layers. The background's white regions are flood-filled, antialiasing off, tolerance 100.
enum PlayerFaceRenderer {
    /// Points the old factory sampled, top-left origin, on the 64×64 background.
    private static let facePoint = (x: 32, y: 22)
    private static let neckPoint = (x: 32, y: 47)
    private static let secondaryPoint = (x: 32, y: 55)
    private static let primaryPoint = (x: 32, y: 61)
    private static let mattePoint = (x: 0, y: 0)
    private static let tolerance = 100

    @MainActor
    static func image(face: PlayerFace, primary: FaceByte, secondary: FaceByte) -> UIImage? {
        let backgroundName = PlayerFaceCatalog.asset("bg", face.background)
        guard let background = FaceArt.image(named: backgroundName),
              var buffer = PortraitBuffer(image: background) else { return nil }
        let skin = PlayerFaceCatalog.skins.indices.contains(face.skin)
            ? PlayerFaceCatalog.skins[face.skin]
            : PlayerFaceCatalog.skins[0]
        buffer.replace(at: facePoint, with: .opaque(skin.red, skin.green, skin.blue), tolerance: tolerance)
        buffer.replace(at: neckPoint, with: .opaque(skin.red, skin.green, skin.blue), tolerance: tolerance)
        buffer.replace(at: secondaryPoint, with: .opaque(secondary.red, secondary.green, secondary.blue), tolerance: tolerance)
        buffer.replace(at: primaryPoint, with: .opaque(primary.red, primary.green, primary.blue), tolerance: tolerance)
        // The field around the head is white. The old screen was light. This one is not, so the field is clear.
        buffer.replace(at: mattePoint, with: .clear, tolerance: tolerance)
        return composite(base: buffer, layers: layerNames(for: face))
    }

    @MainActor
    static func sample(_ image: UIImage, x: Int, y: Int) -> FaceSample? {
        guard let cgImage = image.cgImage,
              let buffer = PortraitBuffer(image: cgImage) else { return nil }
        return buffer.pixel(x, y)
    }

    private static func layerNames(for face: PlayerFace) -> [String] {
        var names = [PlayerFaceCatalog.asset("eyes", face.eyes)]
        if let eyebrows = face.eyebrows {
            names.append(PlayerFaceCatalog.asset("eyebrows", eyebrows))
        }
        names.append(PlayerFaceCatalog.asset("mouth", face.mouth))
        if let mustache = face.mustache {
            names.append(PlayerFaceCatalog.asset("mustache", mustache))
        }
        names.append(PlayerFaceCatalog.asset("nose", face.nose))
        if let beard = face.beard {
            names.append(PlayerFaceCatalog.asset("beard", beard))
        }
        if let hair = face.hair {
            names.append(PlayerFaceCatalog.asset("hair", hair))
        }
        return names
    }

    @MainActor
    private static func composite(base: PortraitBuffer, layers: [String]) -> UIImage? {
        guard let baseImage = base.makeImage() else { return nil }
        let width = base.width
        let height = base.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else { return nil }
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        context.interpolationQuality = .none
        context.draw(baseImage, in: rect)
        for name in layers {
            guard let layer = FaceArt.image(named: name) else { continue }
            context.draw(layer, in: rect)
        }
        guard let composited = context.makeImage() else { return nil }
        return UIImage(cgImage: composited, scale: 1, orientation: .up)
    }
}

struct FaceSample: Equatable, Sendable {
    var red: UInt8
    var green: UInt8
    var blue: UInt8
    var alpha: UInt8
}

/// The portrait beside the name. 128 points is the old player screen, two pixels per source pixel.
struct PlayerFaceView: View {
    var face: PlayerFace
    var position: Position
    var clubID: String

    var body: some View {
        let tones = PlayerFaceTones.colors(position: position, clubID: clubID)
        let portrait = PlayerFaceRenderer.image(
            face: face,
            primary: tones.primary,
            secondary: tones.secondary
        )
        Group {
            if let portrait {
                Image(uiImage: portrait)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
            }
        }
        .frame(width: 128, height: 128)
        .accessibilityHidden(true)
    }
}

@MainActor
private enum FaceArt {
    static func image(named name: String) -> CGImage? {
        if let image = UIImage(named: name)?.cgImage { return image }
        guard let bundle = Bundle(identifier: "dev.personal.SuperSoccer2") else { return nil }
        return UIImage(named: name, in: bundle, compatibleWith: nil)?.cgImage
    }
}

private struct FacePixel {
    var red: UInt8
    var green: UInt8
    var blue: UInt8
    var alpha: UInt8

    static let clear = FacePixel(red: 0, green: 0, blue: 0, alpha: 0)

    static func opaque(_ red: Int, _ green: Int, _ blue: Int) -> FacePixel {
        FacePixel(red: UInt8(clamping: red), green: UInt8(clamping: green), blue: UInt8(clamping: blue), alpha: 255)
    }

    var word: UInt32 {
        (UInt32(alpha) << 24) | (UInt32(red) << 16) | (UInt32(green) << 8) | UInt32(blue)
    }

    static func unpack(_ memory: UInt32) -> FacePixel {
        FacePixel(
            red: UInt8((memory >> 16) & 255),
            green: UInt8((memory >> 8) & 255),
            blue: UInt8(memory & 255),
            alpha: UInt8((memory >> 24) & 255)
        )
    }

    /// Squared channel distance, the same sum the old paint bucket used.
    func difference(from other: FacePixel) -> Int {
        func gap(_ left: UInt8, _ right: UInt8) -> Int {
            let value = Int(max(left, right)) - Int(min(left, right))
            return value * value
        }
        return gap(red, other.red) + gap(green, other.green) + gap(blue, other.blue) + gap(alpha, other.alpha)
    }
}

/// 4-connected fill. The old bucket walked scanlines with antialiasing off, which paints the same pixels.
private struct PortraitBuffer {
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

    mutating func replace(at point: (x: Int, y: Int), with color: FacePixel, tolerance: Int) {
        guard let start = pixel(point.x, point.y) else { return }
        let target = FacePixel(red: start.red, green: start.green, blue: start.blue, alpha: start.alpha)
        if target.difference(from: color) == 0 { return }
        let replacement = color.word
        var stack = [(point.x, point.y)]
        var seen = [Bool](repeating: false, count: words.count)
        while let (x, y) = stack.popLast() {
            guard x >= 0, y >= 0, x < width, y < height else { continue }
            let index = y * width + x
            if seen[index] { continue }
            seen[index] = true
            if FacePixel.unpack(words[index]).difference(from: target) > tolerance { continue }
            words[index] = replacement
            stack.append((x - 1, y))
            stack.append((x + 1, y))
            stack.append((x, y - 1))
            stack.append((x, y + 1))
        }
    }

    func pixel(_ x: Int, _ y: Int) -> FaceSample? {
        guard x >= 0, y >= 0, x < width, y < height else { return nil }
        let pixel = FacePixel.unpack(words[y * width + x])
        return FaceSample(red: pixel.red, green: pixel.green, blue: pixel.blue, alpha: pixel.alpha)
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
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }
}
