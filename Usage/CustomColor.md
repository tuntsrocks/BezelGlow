# Custom color

`color:` paints the whole rim with one stop. `colors:` walks the border in the order you pass. `GlowColor` components are 0...1, or use `hex:`.

```swift
import BezelGlow
import SwiftUI

struct PaintedRim: View {
    var level: Double

    var body: some View {
        Color.black
            .ignoresSafeArea()
            .bezelGlowScreen(
                .all,
                level: level,
                cornerRadius: 55,
                colors: [
                    GlowColor(hex: 0x7EB6FF),
                    GlowColor(hex: 0x8EE7FF),
                    GlowColor(hex: 0xB7C6FF),
                ],
                composite: .light
            )
    }
}
```

Built in: `GlowColors.siri`, `.blues`, `.ocean`, `.sunset`, `.aurora`. `.single` is one color, `GlowColor(hex: 0x5EC8FF)`.
