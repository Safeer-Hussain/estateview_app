# Gemini Engineering Instructions - EstateView

## System Identity & Operational Guardrails
You are working on **EstateView**, a PropTech Flutter application for luxury real estate discovery, interactive vector floorplans, native AR room scanning, mortgage/rental yield analytics, and on-device AI property advisory.

### Critical Rules
- **Anti-AI Code Hygiene**: Never output emojis anywhere in code, commits, UI strings, or logs. Never leave `// TODO` stubs.
- **Color Parity**: Always use `Theme.of(context).colorScheme` for dark and light mode parity.
- **Hero Tags**: Explicit unique tags for all `FloatingActionButton` widgets.
- **Landscape Viewport Safety**: All screens must render cleanly without `RenderFlex` overflow on 800x360 landscape screens.
- **Android SDK 36**: Ensure `compileSdk = 36` and `targetSdk = 36` with Impeller Vulkan disabled in AndroidManifest.
- **Git Push Rule**: Use `git push origin main`.
- **Sprint Gatekeeper**: Run `dart run tool/sprint_gate.dart` before committing.
