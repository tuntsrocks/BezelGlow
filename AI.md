# BezelGlow — AI brief

Swift package. Product name `BezelGlow`. Module `import BezelGlow`. No external dependencies.

Repo: `https://github.com/tuntsrocks/BezelGlow.git`

Platforms: iOS 17+, macOS 14+. Shader is Metal. Xcode compiles the package `.metal`. `swift build` does not. Do not vendor the shader.

Xcode 26+ does not bundle the Metal compiler. If shader compilation fails with a missing Metal toolchain, the caller must run this once before building:

```sh
xcodebuild -downloadComponent MetalToolchain
```

Do not skip this when the host Xcode is 26 or newer and `MetalToolchain` is not already installed. Do not treat it as a package dependency.

## What it does

Draws an edge glow on a SwiftUI view. Caller supplies `level` in `0...1`. The package does not open the microphone, play audio, or use the network.

Two entry points:

- `.bezelGlowScreen(...)` — overlay, `.ignoresSafeArea()`. Full-screen bezel. Default `cornerRadius` 55.
- `.bezelGlow(...)` — overlay on the view bounds. Card or field. Default `cornerRadius` 28.

`level == 0` leaves a thin ribbon. Raising `level` pushes the fade inward. `intensity`, `voiceColor`, and `fadeColor` do not thicken the resting border.

Attack default `0.07`, release default `0.32`, applied inside `BezelGlow`. A jumpy meter still reads as light. Those two are on `BezelGlow.init` only, not on the `View` modifiers.

Hit testing is off. The glow is accessibility-hidden.

## Install

Xcode: File > Add Package Dependencies… > `https://github.com/tuntsrocks/BezelGlow.git` > product `BezelGlow`.

```swift
.package(url: "https://github.com/tuntsrocks/BezelGlow.git", from: "1.0.0")
```

`from:` requires a git tag. If none exists, use `branch: "main"`.

```swift
.package(url: "https://github.com/tuntsrocks/BezelGlow.git", branch: "main")
```

Target dependency: `"BezelGlow"`. Do not add `Example` as a dependency. SPM does not compile `Example/` into the host app.

Before the first build on Xcode 26+, if Metal shader compilation fails:

```sh
xcodebuild -downloadComponent MetalToolchain
```

## Call

Prefer the snippets in `Usage/`. Index: `Usage/README.md`.

| File | Use |
| --- | --- |
| `Usage/FullScreen.md` | `.bezelGlowScreen`, ignores safe area |
| `Usage/Card.md` | `.bezelGlow` on a rounded rect. Match `cornerRadius` |
| `Usage/Button.md` | `.bezelGlow` on the label, not on `Button` |
| `Usage/BottomEdge.md` | `.bottom` only. No diagonal cut |
| `Usage/CustomColor.md` | `color:` or `colors:` |
| `Usage/Wave.md` | `wave: true` plus speed, amplitude, count |
| `Usage/LightBackground.md` | `composite: .over`. Do not use `.light` on white |

Full-screen reference:

```swift
import BezelGlow
import SwiftUI

struct ListeningScreen: View {
    @State private var level = 0.0

    var body: some View {
        Color.black
            .ignoresSafeArea()
            .bezelGlowScreen(
                .all,
                level: level,
                active: true,
                cornerRadius: 55,
                colors: GlowColors.siri,
                composite: .light,
                intensity: 0.8,
                wave: true,
                borderSize: 8,
                fadeDepth: 64,
                voiceColor: 0.7,
                fadeColor: 0.85,
                waveSpeed: 0.9,
                waveAmplitude: 6,
                waveCount: 3
            )
    }
}
```

`level` is caller-owned, `0...1`. Black background: `composite: .light` (`plusLighter`). White or light background: `composite: .over`. `.light` is invisible on white. `.automatic` uses `.light` in dark mode and `.over` in light mode.

## Parameters on both modifiers

| Name | Type | Default (screen / view) | Effect |
| --- | --- | --- | --- |
| `region` | `GlowRegion` | `.all` | Edges. OptionSet. |
| `level` | `Double` | `0` | 0...1. Caller-owned meter. |
| `active` | `Bool` | `true` | `false` fades the effect out. |
| `mood` | `GlowMood` | `.listening` | Silent floor only. Does not change wave speed. |
| `cornerRadius` | `CGFloat` | `55` / `28` | Match the host corner. |
| `palette` | `GlowPalette` | `.siri` | Fallback when `colors` is empty and `color` is nil. |
| `colors` | `[GlowColor]` | `[]` | Several stops, in travel order. |
| `color` | `GlowColor?` | `nil` | One color for the whole rim. Wins over `colors`. |
| `composite` | `GlowComposite` | `.automatic` | `.light`, `.over`, `.automatic`. |
| `intensity` | `Double` | `1` | How hard `level` pushes the fade inward. |
| `wave` | `Bool` | `false` | Traveling wave on ribbon and fade. Off when Reduce Motion is on. |
| `borderSize` | `CGFloat` | `18` | Ribbon thickness, points. |
| `fadeDepth` | `CGFloat` | `42` | Inward fade reach when `level` > 0, points. |
| `voiceColor` | `Double` | `0.7` | Color flare with level. Clamped 0...1. |
| `fadeColor` | `Double` | `0.85` | Color strength in the fade band. Clamped 0...1. |
| `convexEnds` | `Bool` | `true` | `true` peak in the middle. `false` valley. |
| `waveSpeed` | `Double` | `1` | Wave speed. |
| `waveAmplitude` | `CGFloat` | `10` | Wave height, points. Clamped 0...40. |
| `waveCount` | `Double` | `2` | Waves around the perimeter. Minimum 1. |
| `endHeight` | `Double` | `1` | 0 ends on its own side. 1 reaches the neighbor. Clamped 0...1. |
| `centralize` | `Double` | `0` | 0 spills onto the neighbor. 1 stays centered. Clamped 0...1. |

## Regions

`GlowRegion`: `.top`, `.trailing`, `.bottom`, `.leading`. Combine with array syntax.

Presets: `.all`, `.horizontal`, `.vertical`, `.screen` (same as `.all`), `.voiceBottom` (same as `.bottom`), `.voiceFrame` (`[.bottom, .leading, .trailing]`).

A corner is drawn only when both neighboring sides are on. A lone edge does not cut on a diagonal. Leading/trailing follow layout direction.

## Colors

`GlowColors.siri`, `.blues`, `.ocean`, `.sunset`, `.aurora`. `.single` is one `GlowColor`, hex `0x5EC8FF`.

```swift
.bezelGlowScreen(.all, level: level, colors: GlowColors.blues)
.bezelGlowScreen(.all, level: level, color: GlowColor(hex: 0x5EC8FF))
```

`GlowPalette` is the four-stop fallback (`.siri`, `.pastel`, `.ocean`, `.sunset`). Prefer `colors:` / `color:` at call sites.

## Mood floors

Used only when `level` is below the floor and `active` is true.

- `.listening` — 0
- `.thinking` — 0.46
- `.responding` — 0.20
- `.idle` — 0.18

## Do not

- Do not open the mic inside the package. Measure outside and pass `level`.
- Do not use `.light` on a white background.
- Do not import `Example` or copy `ExampleMic` into the host app. The example is a local lab: `Example/GlowExample.xcodeproj`. Tune there, copy the generated call, paste it.
- Do not add `Usage/` as a target. Those files are snippets, not a module.
- Do not invent parameters. `bandWidth` and `glowReach` are not in the public API.
- Do not claim this is Siri or a system API.

## License

Use and customize, including commercial apps. Copying the code into an app and modifying it there does not require the notice. The notice applies only when redistributing the package itself as a package. Then name the source: BezelGlow, `https://github.com/tuntsrocks/BezelGlow`. Credit in an app is optional, not required. If the user wants to credit it, a link to that URL is enough. Do not add a credit unless the user asks. See `LICENSE`.
