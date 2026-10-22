# Wave

`wave: true` moves the ribbon and the fade together. Reduce Motion turns the wave off. `waveAmplitude` is clamped to 40 points.

```swift
import BezelGlow
import SwiftUI

struct WavyRim: View {
    var level: Double

    var body: some View {
        Color.black
            .ignoresSafeArea()
            .bezelGlowScreen(
                .all,
                level: level,
                cornerRadius: 55,
                colors: GlowColors.aurora,
                composite: .light,
                wave: true,
                borderSize: 8,
                fadeDepth: 40,
                waveSpeed: 0.92,
                waveAmplitude: 8,
                waveCount: 3
            )
    }
}
```
