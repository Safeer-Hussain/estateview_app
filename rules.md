# EstateView Engineering Rules & Architecture Guardrails

## Core Mandates
1. **Zero Hardcoded Colors**: Always use `Theme.of(context).colorScheme`.
2. **Unique Hero Tags**: Explicit `heroTag` on every `FloatingActionButton`.
3. **Landscape 360dp Height Viewport Safe**: Zero `RenderFlex` overflow errors on 800x360 landscape viewports.
4. **Android SDK 36**: Explicit `compileSdk = 36` and `targetSdk = 36` in `android/app/build.gradle.kts`.
5. **Anti-AI Code Hygiene**: Zero emojis in source code, commits, UI text, or logs. Zero `// TODO` stubs.
6. **Hardware Protection**: `io.flutter.embedding.android.EnableImpeller = false` in `AndroidManifest.xml`.
7. **Cross-SDK Analyzer Compatibility**: In `analysis_options.yaml`, `deprecated_member_use: ignore` is configured. Always run `flutter analyze --no-fatal-infos`.
8. **Automated Sprint Gatekeeper**: Enforce quality gates via `dart run tool/sprint_gate.dart`.
