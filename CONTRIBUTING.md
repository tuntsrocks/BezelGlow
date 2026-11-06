# Contributing to BezelGlow

Use [GitHub issues](https://github.com/tuntsrocks/BezelGlow/issues) for bugs,
questions, and feature proposals. Jouy ([@CosmicSnow](https://github.com/CosmicSnow))
is the original author. Keep project discussions in the repository so other
contributors can follow them. For vulnerabilities, use the private route in
[SECURITY.md](SECURITY.md).

## Build and test

You need macOS and Xcode. The library targets iOS 17+ and macOS 14+.
CI uses Xcode 26.3 on macOS 15. The example project uses newer Xcode project
settings, so use Xcode 26.3 or later when working on the example.

On Xcode 26+, install the Metal compiler once:

```sh
xcodebuild -downloadComponent MetalToolchain
```

From the repository root, run the package tests:

```sh
xcodebuild test \
  -scheme BezelGlow \
  -destination 'platform=macOS' \
  -derivedDataPath /tmp/BezelGlow-tests \
  CODE_SIGNING_ALLOWED=NO
```

Build the example without signing:

```sh
xcodebuild build \
  -project Example/GlowExample.xcodeproj \
  -scheme GlowExample \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/BezelGlow-example \
  CODE_SIGNING_ALLOWED=NO
```

Use Xcode for these checks. Command-line `swift build` does not compile the
package's Metal shader and is not a substitute for validating the rendered glow.

For interactive testing, open `Example/GlowExample.xcodeproj`. Choose an iPhone
Simulator, or select your own development team under **Signing & Capabilities**
for a physical iPhone. The project does not include a signing team or credentials.
Manual mode works without microphone access.

## Make a change

Fork the repository and create a branch for your change. Keep pull requests
focused, explain the problem, and list the checks you ran. Add or update tests
when behavior changes. Update the README and `Usage/` snippets if the public API changes.

For visual changes, include screenshots or a short video. Check dark and light
backgrounds, a single edge and the full perimeter, and Reduce Motion. State which
simulator or physical device you used; do not describe simulator testing as device testing.

Keep microphone access, audio processing, and network integrations outside the
library. The glow takes a caller-owned `level` from 0 to 1. Do not add signing
identities, provisioning profiles, secrets, private endpoints, or personal files.

Only contribute code and assets you have permission to share under the
repository's [existing license](LICENSE). Identify any third-party material and
its license in the pull request. Do not copy code or assets from Apple or another
project without the necessary permission and notices.

Participation follows [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
