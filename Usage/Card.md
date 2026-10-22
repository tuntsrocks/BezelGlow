# Card

`.bezelGlow` stays on the card. Match `cornerRadius` to the card shape. It does not ignore the safe area.

```swift
import BezelGlow
import SwiftUI

struct GlowCard: View {
    var level: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Now playing")
                .font(.headline)
            Text("The glow follows the card, not the screen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.black, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .bezelGlow(
            .all,
            level: level,
            cornerRadius: 28,
            colors: GlowColors.blues,
            composite: .light,
            borderSize: 6,
            fadeDepth: 28
        )
        .padding()
    }
}
```
