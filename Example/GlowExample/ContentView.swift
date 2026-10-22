import BezelGlow
import SwiftUI
import UIKit

/// Lab screen. This file is not part of the package.
/// Tune here, copy the call, and paste it into your app.
private enum GlowPreset: String, CaseIterable, Identifiable {
    case siri = "Siri"
    case blues = "Blues"
    case ocean = "Ocean"
    case sunset = "Sunset"
    case aurora = "Aurora"
    case single = "One color"

    var id: String { rawValue }

    var colors: [GlowColor] {
        switch self {
        case .siri: return GlowColors.siri
        case .blues: return GlowColors.blues
        case .ocean: return GlowColors.ocean
        case .sunset: return GlowColors.sunset
        case .aurora: return GlowColors.aurora
        case .single: return [GlowColors.single]
        }
    }

    var codeName: String {
        switch self {
        case .siri: return "GlowColors.siri"
        case .blues: return "GlowColors.blues"
        case .ocean: return "GlowColors.ocean"
        case .sunset: return "GlowColors.sunset"
        case .aurora: return "GlowColors.aurora"
        case .single: return "GlowColors.single"
        }
    }
}

private enum LevelSource: String, CaseIterable, Identifiable {
    case mic = "Microphone"
    case manual = "Manual"

    var id: String { rawValue }
}

struct ContentView: View {
    @StateObject private var mic = ExampleMic()
    @State private var source = LevelSource.mic
    @State private var manualLevel = 0.45
    @State private var glowTop = true
    @State private var glowBottom = true
    @State private var glowLeading = true
    @State private var glowTrailing = true
    @State private var intensity = 0.8
    @State private var sensitivity = 0.65
    @State private var wave = true
    @State private var borderSize = 5.0
    @State private var fadeDepth = 46.0
    @State private var voiceColor = 0.7
    @State private var fadeColor = 0.85
    @State private var convexEnds = true
    @State private var endHeight = 1.0
    @State private var centralize = 0.0
    @State private var preset = GlowPreset.siri
    @State private var waveSpeed = 0.4
    @State private var waveAmplitude = 4.0
    @State private var waveCount = 4.0
    @State private var copied = false

    var body: some View {
        lab
            .preferredColorScheme(.dark)
            .bezelGlowScreen(
                glowRegion,
                level: sensedLevel,
                active: !glowRegion.isEmpty,
                mood: .listening,
                cornerRadius: 55,
                colors: preset == .single ? [] : preset.colors,
                color: preset == .single ? GlowColors.single : nil,
                composite: .light,
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

    private var sensedLevel: Double {
        switch source {
        case .manual:
            return manualLevel
        case .mic:
            guard mic.isLive else { return 0 }
            let threshold = 0.16 * (1 - sensitivity)
            let gain = 1 + sensitivity * 5.5
            return min(1, max(0, mic.level - threshold) * gain)
        }
    }

    private var glowRegion: GlowRegion {
        var region = GlowRegion()
        if glowTop { region.insert(.top) }
        if glowBottom { region.insert(.bottom) }
        if glowLeading { region.insert(.leading) }
        if glowTrailing { region.insert(.trailing) }
        return region
    }

    private var lab: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Lab")
                        .font(.system(.caption, design: .rounded).bold())
                        .foregroundStyle(.white.opacity(0.55))
                    Text("This screen is not in the package. Tune it, copy the call, and paste it into your app. The glow only takes a 0...1 level: microphone, app audio, or whatever you measure.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))

                    Picker("Source", selection: $source) {
                        ForEach(LevelSource.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)

                    if source == .manual {
                        sliderRow("Level", value: String(format: "%.0f%%", manualLevel * 100)) {
                            Slider(value: $manualLevel, in: 0...1).tint(.white)
                        }
                    }

                    HStack {
                        Text("Colors")
                        Spacer()
                        HStack(spacing: 3) {
                            ForEach(Array(preset.colors.enumerated()), id: \.offset) { _, stop in
                                Circle()
                                    .fill(Color(red: Double(stop.r), green: Double(stop.g), blue: Double(stop.b)))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        Picker("Colors", selection: $preset) {
                            ForEach(GlowPreset.allCases) { item in
                                Text(item.rawValue).tag(item)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.white)
                    }
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundStyle(.white.opacity(0.7))

                    Text("Sides")
                        .font(.system(.caption, design: .rounded).bold())
                        .foregroundStyle(.white.opacity(0.55))
                    HStack(spacing: 8) {
                        edgeCheck("Bottom", isOn: $glowBottom)
                        edgeCheck("Left", isOn: $glowLeading)
                        edgeCheck("Right", isOn: $glowTrailing)
                        edgeCheck("Top", isOn: $glowTop)
                    }
                    sliderRow("Thickness", value: String(format: "%.0f px", borderSize)) {
                        Slider(value: $borderSize, in: 0...400).tint(.white)
                    }
                    sliderRow("Fade", value: String(format: "%.0f px", fadeDepth)) {
                        Slider(value: $fadeDepth, in: 0...400).tint(.white)
                    }
                    sliderRow("Voice color", value: String(format: "%.0f%%", voiceColor * 100)) {
                        Slider(value: $voiceColor, in: 0...1).tint(.white)
                    }
                    sliderRow("Fade color", value: String(format: "%.0f%%", fadeColor * 100)) {
                        Slider(value: $fadeColor, in: 0...1).tint(.white)
                    }
                    sliderRow("Speak strength", value: String(format: "%.0f%%", intensity * 100)) {
                        Slider(value: $intensity, in: 0...1).tint(.white)
                    }
                    if source == .mic {
                        sliderRow("Sensitivity", value: String(format: "%.0f%%", sensitivity * 100)) {
                            Slider(value: $sensitivity, in: 0...1).tint(.white)
                        }
                    }
                    sliderRow("Wave speed", value: String(format: "%.1fx", waveSpeed)) {
                        Slider(value: $waveSpeed, in: 0.2...2.5).tint(.white)
                    }
                    sliderRow("Wave height", value: String(format: "%.0f px", waveAmplitude)) {
                        Slider(value: $waveAmplitude, in: 0...40).tint(.white)
                    }
                    sliderRow("Waves around", value: String(format: "%.0f", waveCount)) {
                        Slider(value: $waveCount, in: 1...6, step: 1).tint(.white)
                    }
                    HStack(spacing: 8) {
                        shapeButton("Convex", on: convexEnds) { convexEnds = true }
                        shapeButton("Concave", on: !convexEnds) { convexEnds = false }
                    }
                    sliderRow("End height", value: endHeight > 0.66 ? "Sides" : (endHeight < 0.33 ? "Own side" : String(format: "%.0f%%", endHeight * 100))) {
                        Slider(value: $endHeight, in: 0...1).tint(.white)
                    }
                    sliderRow("Center", value: centralize < 0.08 ? "Sides" : (centralize > 0.92 ? "Center" : String(format: "%.0f", centralize * 100))) {
                        Slider(value: $centralize, in: 0...1).tint(.white)
                    }
                    Button {
                        wave.toggle()
                    } label: {
                        HStack {
                            Image(systemName: wave ? "checkmark.square.fill" : "square")
                            Text("Border wave")
                            Spacer()
                        }
                        .font(.system(.caption, design: .rounded).bold())
                        .foregroundStyle(wave ? .white : .white.opacity(0.45))
                    }
                    .buttonStyle(.plain)

                    Text("Call for your app")
                        .font(.system(.caption, design: .rounded).bold())
                        .foregroundStyle(.white.opacity(0.55))
                    Text(callSnippet)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.82))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    Button {
                        UIPasteboard.general.string = callSnippet
                        copied = true
                    } label: {
                        Text(copied ? "Copied" : "Copy call")
                            .font(.system(.caption, design: .rounded).bold())
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(.white, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
            }
            if source == .mic {
                micBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 10)
                    .background(Color.black.opacity(0.92))
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onChange(of: callSnippet) { _, _ in copied = false }
    }

    private var micBar: some View {
        VStack(spacing: 8) {
            Button {
                mic.toggle()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: mic.isLive ? "stop.fill" : "mic.fill")
                    Text(mic.isLive ? "Stop microphone" : "Test microphone")
                }
                .font(.system(.callout, design: .rounded).bold())
                .foregroundStyle(mic.isLive ? .white : Color(red: 0.55, green: 0.85, blue: 1))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(mic.isLive ? Color(red: 0.90, green: 0.28, blue: 0.30) : .white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            if let error = mic.error {
                Text(error)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Color(red: 0.90, green: 0.28, blue: 0.30))
                    .multilineTextAlignment(.center)
            } else if mic.isLive {
                Text(String(format: "Level %.0f%% · %@", mic.level * 100, mic.input))
                    .font(.system(.caption, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var callSnippet: String {
        let colorLine = preset == .single
            ? "color: \(preset.codeName),"
            : "colors: \(preset.codeName),"
        return """
        import BezelGlow

        content
            .bezelGlowScreen(
                \(regionCode),
                level: level, // 0...1, you measure
                active: true,
                cornerRadius: 55,
                \(colorLine)
                composite: .light,
                intensity: \(format(intensity)),
                wave: \(wave),
                borderSize: \(format(borderSize)),
                fadeDepth: \(format(fadeDepth)),
                voiceColor: \(format(voiceColor)),
                fadeColor: \(format(fadeColor)),
                convexEnds: \(convexEnds),
                waveSpeed: \(format(waveSpeed)),
                waveAmplitude: \(format(waveAmplitude)),
                waveCount: \(format(waveCount)),
                endHeight: \(format(endHeight)),
                centralize: \(format(centralize))
            )
        """
    }

    private var regionCode: String {
        var parts: [String] = []
        if glowTop { parts.append(".top") }
        if glowBottom { parts.append(".bottom") }
        if glowLeading { parts.append(".leading") }
        if glowTrailing { parts.append(".trailing") }
        if parts.count == 4 { return ".all" }
        if parts.count == 1 { return parts[0] }
        if parts.isEmpty { return "[]" }
        return "[" + parts.joined(separator: ", ") + "]"
    }

    private func format(_ value: Double) -> String {
        if value == value.rounded() {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }

    private func shapeButton(_ title: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(.caption, design: .rounded).bold())
                .foregroundStyle(on ? .black : .white.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(on ? .white : .white.opacity(0.08), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func sliderRow<Control: View>(_ title: String, value: String, @ViewBuilder control: () -> Control) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(value).monospacedDigit()
            }
            .font(.system(.caption, design: .rounded).bold())
            .foregroundStyle(.white.opacity(0.7))
            control()
        }
    }

    private func edgeCheck(_ title: String, isOn: Binding<Bool>) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: isOn.wrappedValue ? "checkmark.square.fill" : "square")
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(.caption2, design: .rounded).bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isOn.wrappedValue ? .white : .white.opacity(0.45))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isOn.wrappedValue ? .white.opacity(0.16) : .clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
