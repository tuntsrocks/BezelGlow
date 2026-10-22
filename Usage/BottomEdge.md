# Bottom edge

One side. A corner is drawn only when both neighbors are on, so `.bottom` alone does not cut a diagonal into the screen.

```swift
import BezelGlow
import SwiftUI

struct VoiceBar: View {
    var level: Double
    var listening: Bool

    var body: some View {
        Color.black
            .ignoresSafeArea()
            .bezelGlowScreen(
                .bottom,
                level: level,
                active: listening,
                cornerRadius: 55,
                colors: GlowColors.sunset,
                composite: .light,
                borderSize: 10,
                fadeDepth: 72
            )
    }
}
```

`.voiceBottom` is the same as `.bottom`. `.voiceFrame` is bottom plus both sides.
