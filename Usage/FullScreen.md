# Full screen

`.bezelGlowScreen` draws past the safe area. Pass a 0...1 level you already measured. `composite: .light` is additive, so this wants a dark screen.

```swift
import BezelGlow
import SwiftUI

struct ListeningScreen: View {
    @State private var level = 0.0

    var body: some View {
        Color.black
            .ignoresSafeArea()
            .overlay(alignment: .bottom) {
                Text("Listening")
                    .foregroundStyle(.white)
                    .padding(.bottom, 48)
            }
            .bezelGlowScreen(
                .all,
                level: level,
                active: true,
                cornerRadius: 55,
                colors: GlowColors.siri,
                composite: .light,
                borderSize: 8,
                fadeDepth: 64
            )
    }
}
```
