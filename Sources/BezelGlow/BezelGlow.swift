import SwiftUI

/// Bezel glow. Drop it over a screen, a card, or a pill.
///
/// The full perimeter is the listening-screen look. A single edge rises and sweeps
/// with `level`. Pass microphone RMS in 0...1; attack and release are
/// applied here, so a noisy meter still reads as light.
public struct BezelGlow: View {
    public var region: GlowRegion
    public var level: Double
    public var active: Bool
    public var mood: GlowMood
    public var cornerRadius: CGFloat
    public var palette: GlowPalette
    /// One color or many. Empty falls back to `palette`.
    public var colors: [GlowColor]
    public var composite: GlowComposite
    public var attack: Double
    public var release: Double
    public var idlePresence: Double?
    /// How hard voice pushes the fade inward. The resting border does not thicken.
    public var intensity: Double
    /// A color wave traveling around the border.
    public var wave: Bool
    /// Thickness of the solid color on the border, in points.
    public var borderSize: CGFloat
    /// How far the fade can reach inward when there is voice, in points.
    public var fadeDepth: CGFloat
    /// How much the colors flare while speaking. 0...1.
    public var voiceColor: Double
    /// Color strength in the fade band. 0...1.
    public var fadeColor: Double
    /// Loose ends: true is convex (peak in the middle), false is concave (valley in the middle).
    public var convexEnds: Bool
    public var waveSpeed: Double
    /// Wave height along the border, in points.
    public var waveAmplitude: CGFloat
    /// How many waves fit around the screen.
    public var waveCount: Double
    /// 0 ends on its own side. 1 reaches the neighboring side.
    public var endHeight: Double
    /// 0 touches and spills onto the neighbor. 1 stays centered and does not touch it.
    public var centralize: Double

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var clock = GlowClock()

    public init(
        region: GlowRegion = .all,
        level: Double = 0,
        active: Bool = true,
        mood: GlowMood = .listening,
        cornerRadius: CGFloat = 55,
        palette: GlowPalette = .siri,
        colors: [GlowColor] = [],
        color: GlowColor? = nil,
        composite: GlowComposite = .automatic,
        attack: Double = 0.07,
        release: Double = 0.32,
        idlePresence: Double? = nil,
        intensity: Double = 1,
        wave: Bool = false,
        borderSize: CGFloat = 18,
        fadeDepth: CGFloat = 42,
        voiceColor: Double = 0.7,
        fadeColor: Double = 0.85,
        convexEnds: Bool = true,
        waveSpeed: Double = 1,
        waveAmplitude: CGFloat = 10,
        waveCount: Double = 2,
        endHeight: Double = 1,
        centralize: Double = 0
    ) {
        self.region = region
        self.level = level
        self.active = active
        self.mood = mood
        self.cornerRadius = cornerRadius
        self.palette = palette
        if let color {
            self.colors = [color]
        } else {
            self.colors = colors
        }
        self.composite = composite
        self.attack = attack
        self.release = release
        self.idlePresence = idlePresence
        self.intensity = intensity
        self.wave = wave
        self.borderSize = borderSize
        self.fadeDepth = fadeDepth
        self.voiceColor = voiceColor
        self.fadeColor = fadeColor
        self.convexEnds = convexEnds
        self.waveSpeed = waveSpeed
        self.waveAmplitude = waveAmplitude
        self.waveCount = waveCount
        self.endHeight = endHeight
        self.centralize = centralize
    }

    public var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !active && clock.smoothed < 0.02)) { timeline in
                let sample = clock.sample(
                    at: timeline.date,
                    level: level,
                    active: active,
                    floor: idlePresence ?? mood.idlePresence,
                    attack: attack,
                    release: release
                )
                glowRect(size: proxy.size, sample: sample)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            clock.lastDate = .now
            if active { clock.armIntro() }
        }
        .onChange(of: active) { _, isOn in
            if isOn { clock.armIntro() }
        }
    }

    private func glowRect(size: CGSize, sample: GlowSample) -> some View {
        let shader = makeShader(size: size, sample: sample)
        return Rectangle()
            .foregroundStyle(.white)
            .colorEffect(shader)
            .blendMode(resolvedBlend)
            .opacity(active || sample.voice > 0.02 ? 1 : 0)
            .animation(.easeOut(duration: 0.35), value: active)
    }

    private var resolvedBlend: BlendMode {
        switch composite {
        case .light: return .plusLighter
        case .over: return .normal
        case .automatic: return colorScheme == .dark ? .plusLighter : .normal
        }
    }

    private func makeShader(size: CGSize, sample: GlowSample) -> Shader {
        let voice = Float(sample.voice)
        let appearance: Float = colorScheme == .dark ? 0 : 1
        let elapsed = reduceMotion ? 0 : Float(sample.elapsed)
        let mask = edgeMask
        let talkReach = max(0, fadeDepth)

        return ShaderLibrary.bundle(.module).bezelEdgeGlow(
            .float2(size),
            .float(elapsed),
            .float(cornerRadius),
            .float(max(0, borderSize)),
            .float(talkReach),
            .float(voice),
            .float4(mask.top, mask.right, mask.bottom, mask.left),
            .float4(
                Float(waveSpeed),
                Float(max(1, waveCount)),
                wave && !reduceMotion ? 1 : 0,
                convexEnds ? 1 : 0
            ),
            .float4(
                Float(min(1, max(0, voiceColor))),
                Float(min(1, max(0, fadeColor))),
                Float(min(1, max(0, intensity))),
                Float(min(40, max(0, waveAmplitude)))
            ),
            .float4(palette.purple.r, palette.purple.g, palette.purple.b, appearance),
            .float4(palette.pink.r, palette.pink.g, palette.pink.b, Float(min(1, max(0, centralize)))),
            .float4(palette.orange.r, palette.orange.g, palette.orange.b, 1),
            .float4(palette.blue.r, palette.blue.g, palette.blue.b, Float(min(1, max(0, endHeight)))),
            .colorArray(shaderColors)
        )
    }

    /// One color paints the whole rim. Several colors travel the border in the given order.
    private var shaderColors: [Color] {
        let stops = colors.isEmpty ? palette.stops : colors
        return stops.map {
            Color(red: Double($0.r), green: Double($0.g), blue: Double($0.b))
        }
    }

    /// Shader space is top-left, +x right. Leading/trailing follow layout direction.
    private var edgeMask: (top: Float, right: Float, bottom: Float, left: Float) {
        let leadingIsLeft = layoutDirection == .leftToRight
        let leftOn = region.contains(leadingIsLeft ? .leading : .trailing)
        let rightOn = region.contains(leadingIsLeft ? .trailing : .leading)
        return (
            top: region.contains(.top) ? 1 : 0,
            right: rightOn ? 1 : 0,
            bottom: region.contains(.bottom) ? 1 : 0,
            left: leftOn ? 1 : 0
        )
    }
}

public extension View {
    /// Glow around this view's own bounds. Match `cornerRadius` to the host shape.
    func bezelGlow(
        _ region: GlowRegion = .all,
        level: Double = 0,
        active: Bool = true,
        mood: GlowMood = .listening,
        cornerRadius: CGFloat = 28,
        palette: GlowPalette = .siri,
        colors: [GlowColor] = [],
        color: GlowColor? = nil,
        composite: GlowComposite = .automatic,
        intensity: Double = 1,
        wave: Bool = false,
        borderSize: CGFloat = 18,
        fadeDepth: CGFloat = 42,
        voiceColor: Double = 0.7,
        fadeColor: Double = 0.85,
        convexEnds: Bool = true,
        waveSpeed: Double = 1,
        waveAmplitude: CGFloat = 10,
        waveCount: Double = 2,
        endHeight: Double = 1,
        centralize: Double = 0
    ) -> some View {
        overlay {
            BezelGlow(
                region: region,
                level: level,
                active: active,
                mood: mood,
                cornerRadius: cornerRadius,
                palette: palette,
                colors: colors,
                color: color,
                composite: composite,
                intensity: intensity,
                wave: wave,
                borderSize: borderSize,
                fadeDepth: fadeDepth,
                voiceColor: voiceColor,
                fadeColor: fadeColor,
                convexEnds: convexEnds,
                waveSpeed: waveSpeed,
                waveAmplitude: waveAmplitude,
                waveCount: waveCount,
                endHeight: endHeight,
                centralize: centralize
            )
        }
    }

    /// Full-bleed bezel glow, past the safe area. This is the listening-screen look.
    func bezelGlowScreen(
        _ region: GlowRegion = .all,
        level: Double = 0,
        active: Bool = true,
        mood: GlowMood = .listening,
        cornerRadius: CGFloat = 55,
        palette: GlowPalette = .siri,
        colors: [GlowColor] = [],
        color: GlowColor? = nil,
        composite: GlowComposite = .automatic,
        intensity: Double = 1,
        wave: Bool = false,
        borderSize: CGFloat = 18,
        fadeDepth: CGFloat = 42,
        voiceColor: Double = 0.7,
        fadeColor: Double = 0.85,
        convexEnds: Bool = true,
        waveSpeed: Double = 1,
        waveAmplitude: CGFloat = 10,
        waveCount: Double = 2,
        endHeight: Double = 1,
        centralize: Double = 0
    ) -> some View {
        overlay {
            BezelGlow(
                region: region,
                level: level,
                active: active,
                mood: mood,
                cornerRadius: cornerRadius,
                palette: palette,
                colors: colors,
                color: color,
                composite: composite,
                intensity: intensity,
                wave: wave,
                borderSize: borderSize,
                fadeDepth: fadeDepth,
                voiceColor: voiceColor,
                fadeColor: fadeColor,
                convexEnds: convexEnds,
                waveSpeed: waveSpeed,
                waveAmplitude: waveAmplitude,
                waveCount: waveCount,
                endHeight: endHeight,
                centralize: centralize
            )
            .ignoresSafeArea()
        }
    }
}

private struct GlowSample {
    var voice: Double
    var elapsed: TimeInterval
    var intro: Float
}

private final class GlowClock {
    var smoothed: Double = 0
    var lastDate: Date = .now
    var origin: Date = .now
    var introStart: Date = .now

    func armIntro() {
        introStart = .now
        origin = .now
    }

    func sample(
        at now: Date,
        level: Double,
        active: Bool,
        floor: Double,
        attack: Double,
        release: Double
    ) -> GlowSample {
        let dt = now.timeIntervalSince(lastDate)
        lastDate = now
        let target = active ? min(1, max(level, floor)) : 0
        smoothed = GlowEnvelope.step(
            current: smoothed,
            target: target,
            deltaTime: dt,
            attack: attack,
            release: release
        )
        let introT = now.timeIntervalSince(introStart)
        let intro = Float(min(1, max(0, introT / 0.55)))
        return GlowSample(
            voice: smoothed,
            elapsed: now.timeIntervalSince(origin),
            intro: active ? intro : 1
        )
    }
}

#Preview("Bezel") {
    ZStack {
        Color.black.ignoresSafeArea()
        BezelGlow(region: .all, level: 0.55)
            .ignoresSafeArea()
    }
}

#Preview("Bottom") {
    ZStack {
        Color.black.ignoresSafeArea()
        BezelGlow(region: .bottom, level: 0.8, cornerRadius: 55)
            .ignoresSafeArea()
    }
}
