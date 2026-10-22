# Light background

`.light` is `plusLighter`. It disappears on white. Use `.over` when the host is light. `.automatic` picks `.light` in dark mode and `.over` in light mode.

```swift
import BezelGlow
import SwiftUI

struct LightCard: View {
    var level: Double

    var body: some View {
        Text("On white")
            .font(.headline)
            .padding(24)
            .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .bezelGlow(
                .all,
                level: level,
                cornerRadius: 20,
                colors: GlowColors.ocean,
                composite: .over,
                borderSize: 5,
                fadeDepth: 18
            )
            .padding()
            .background(Color.white)
    }
}
```
