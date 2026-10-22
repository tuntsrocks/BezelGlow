import CoreGraphics
import Foundation

/// Which edges of the host emit light.
///
/// Combine flags to build a frame: `.bottom` is the voice bar,
/// `[.bottom, .leading, .trailing]` is a U along the lower bezel,
/// `.all` is the full-screen listening glow.
public struct GlowRegion: OptionSet, Sendable, Hashable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let top = GlowRegion(rawValue: 1 << 0)
    public static let trailing = GlowRegion(rawValue: 1 << 1)
    public static let bottom = GlowRegion(rawValue: 1 << 2)
    public static let leading = GlowRegion(rawValue: 1 << 3)

    public static let all: GlowRegion = [.top, .trailing, .bottom, .leading]
    public static let horizontal: GlowRegion = [.leading, .trailing]
    public static let vertical: GlowRegion = [.top, .bottom]

    /// Full bezel. Same as `.all`, named for call sites that read as a preset.
    public static let screen: GlowRegion = .all

    /// Light rising from the bottom edge only.
    public static let voiceBottom: GlowRegion = .bottom

    /// Bottom edge plus both sides. The phone-frame voice look.
    public static let voiceFrame: GlowRegion = [.bottom, .leading, .trailing]

    public var isEmpty: Bool { rawValue == 0 }

    public var isFullPerimeter: Bool { self == .all }

    public var isSingleEdge: Bool { edgeCount == 1 }

    var edgeCount: Int {
        var n = 0
        if contains(.top) { n += 1 }
        if contains(.trailing) { n += 1 }
        if contains(.bottom) { n += 1 }
        if contains(.leading) { n += 1 }
        return n
    }
}

/// One RGB stop. Components are 0...1.
public struct GlowColor: Sendable, Equatable, Hashable {
    public var r: Float
    public var g: Float
    public var b: Float

    public init(_ r: Float, _ g: Float, _ b: Float) {
        self.r = r
        self.g = g
        self.b = b
    }

    public init(hex: UInt32) {
        r = Float((hex >> 16) & 0xFF) / 255
        g = Float((hex >> 8) & 0xFF) / 255
        b = Float(hex & 0xFF) / 255
    }
}

/// Four anchors the light field blends between.
public struct GlowPalette: Sendable, Equatable {
    public var purple: GlowColor
    public var pink: GlowColor
    public var orange: GlowColor
    public var blue: GlowColor

    public init(purple: GlowColor, pink: GlowColor, orange: GlowColor, blue: GlowColor) {
        self.purple = purple
        self.pink = pink
        self.orange = orange
        self.blue = blue
    }

    /// Luminous bezel colors of the listening edge light.
    public static let siri = GlowPalette(
        purple: GlowColor(hex: 0xC686FF),
        pink: GlowColor(hex: 0xFF6778),
        orange: GlowColor(hex: 0xFFBA71),
        blue: GlowColor(hex: 0x8D9FFF)
    )

    /// Softer stops, closer to the widely published listening-glow hexes.
    public static let pastel = GlowPalette(
        purple: GlowColor(hex: 0xBC82F3),
        pink: GlowColor(hex: 0xFF6778),
        orange: GlowColor(hex: 0xFFBA71),
        blue: GlowColor(hex: 0x8D9FFF)
    )

    public static let ocean = GlowPalette(
        purple: GlowColor(0.45, 0.35, 0.95),
        pink: GlowColor(0.35, 0.70, 1.00),
        orange: GlowColor(0.20, 0.85, 0.80),
        blue: GlowColor(0.15, 0.40, 1.00)
    )

    public static let sunset = GlowPalette(
        purple: GlowColor(0.85, 0.30, 0.55),
        pink: GlowColor(1.00, 0.42, 0.38),
        orange: GlowColor(1.00, 0.72, 0.28),
        blue: GlowColor(1.00, 0.50, 0.62)
    )

    public var stops: [GlowColor] {
        [purple, pink, orange, blue]
    }
}

/// One color or many. One color paints the whole rim. Several travel the border.
public enum GlowColors {
    public static let siri: [GlowColor] = [
        GlowColor(hex: 0xC686FF),
        GlowColor(hex: 0xFF6778),
        GlowColor(hex: 0xFFBA71),
        GlowColor(hex: 0x8D9FFF),
    ]

    /// Blue tones, bright enough for additive glass.
    public static let blues: [GlowColor] = [
        GlowColor(hex: 0x7EB6FF),
        GlowColor(hex: 0x3D7EFF),
        GlowColor(hex: 0x8EE7FF),
        GlowColor(hex: 0x4CC4FF),
        GlowColor(hex: 0xB7C6FF),
    ]

    public static let ocean: [GlowColor] = GlowPalette.ocean.stops
    public static let sunset: [GlowColor] = GlowPalette.sunset.stops

    public static let aurora: [GlowColor] = [
        GlowColor(hex: 0x5EEAD4),
        GlowColor(hex: 0x86EFAC),
        GlowColor(hex: 0x67E8F9),
        GlowColor(hex: 0xA3E635),
    ]

    public static let single = GlowColor(hex: 0x5EC8FF)
}

/// How much light stays when `level` is silent. The caller still owns the meter.
public enum GlowMood: String, Sendable, CaseIterable, Hashable {
    /// No floor. The glow follows `level` alone.
    case listening
    /// Working. A steady presence between words.
    case thinking
    /// Handing off. A little light remains.
    case responding
    /// Soft breath. A low floor, no urgency.
    case idle

    /// Floor while `level` is silent, so the light does not die between words.
    public var idlePresence: Double {
        switch self {
        case .listening: return 0
        case .thinking: return 0.46
        case .responding: return 0.20
        case .idle: return 0.18
        }
    }
}

/// How the glow composites over the host.
public enum GlowComposite: Sendable, Hashable {
    /// Additive light on dark, painted color on light. The usual choice.
    case automatic
    /// `plusLighter`. Right on black, invisible on white.
    case light
    /// Source-over. Visible on light backgrounds as well as on dark.
    case over
}

/// Attack/release follower for a 0...1 voice level.
public enum GlowEnvelope {
    public static func step(
        current: Double,
        target: Double,
        deltaTime: Double,
        attack: Double = 0.18,
        release: Double = 0.62
    ) -> Double {
        let dt = min(0.05, max(0, deltaTime))
        let tau = target > current ? max(attack, 0.0001) : max(release, 0.0001)
        let alpha = 1 - exp(-dt / tau)
        let next = current + (target - current) * alpha
        return min(1, max(0, next))
    }
}
