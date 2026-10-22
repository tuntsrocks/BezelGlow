# Button

Put `.bezelGlow` on the button label, not on the `Button` itself, so the glow matches the capsule. The glow does not take taps.

```swift
import BezelGlow
import SwiftUI

struct GlowButton: View {
    var level: Double
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Talk")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(.black, in: Capsule())
                .bezelGlow(
                    .all,
                    level: level,
                    cornerRadius: 24,
                    color: GlowColor(hex: 0x5EC8FF),
                    composite: .light,
                    borderSize: 4,
                    fadeDepth: 16
                )
        }
        .buttonStyle(.plain)
    }
}
```
