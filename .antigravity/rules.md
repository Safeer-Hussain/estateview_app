# EstateView Antigravity AI Engineering Rules

## 1. Zero-Regression Architectural Principles
1. **Clean Architecture & SOLID**:
   - Strict separation across `core/`, `data/`, `domain/`, and `presentation/`.
   - State management: `flutter_bloc` (`Bloc` / `Cubit`).
   - Dependency injection: `get_it`.
   - Offline-first: On-device `sqflite` and `shared_preferences`.

2. **Zero Hardcoded Colors**:
   - Never use `Colors.black`, `Colors.white`, or raw `Color(0xFF...)` in presentation widgets.
   - Resolve all colors dynamically via `Theme.of(context).colorScheme` (`surface`, `surfaceContainer`, `onSurface`, `primary`, `secondary`, `outlineVariant`).
   - Support instant runtime switching between Obsidian Dark and Gallery Light palettes.

3. **Unique Hero Tags**:
   - Every `FloatingActionButton` MUST define an explicit, unique `heroTag` string (e.g., `fabPropertyScheduleTour`, `fabMapRecenter`, `fabArMeasurePoint`, `fabRoiExportDossier`, `fabAiConciergeClear`, `fabArReset`, `fabArSaveScan`).

4. **Landscape Viewport Safety (360dp Height Safe)**:
   - When `Orientation.landscape` is active:
     - NavigationRail with `minWidth: 56` and `labelType: NavigationRailLabelType.none`, wrapped in `SingleChildScrollView(physics: ClampingScrollPhysics())` + `IntrinsicHeight`.
     - Compact AppBar with `toolbarHeight: 36`.
     - Independent scrolling on both left and right panes in master-detail layouts.
     - Never use large `childAspectRatio` in `GridView`; use explicit `mainAxisExtent`.
     - All charts (`fl_chart`) must set `reservedSize: 0` on hidden axes and span edge-to-edge.

5. **Anti-AI Code Hygiene**:
   - NEVER use emojis in code, UI strings, logs, or commit messages. Use vector Material / Cupertino symbols exclusively.
   - NEVER write tutorial comments or `// TODO` stubs. Every feature must be 100% functional.

6. **Android SDK 36 & Hardware Protection**:
   - Maintain `compileSdk = 36`, `targetSdk = 36`, and `minSdk = 21` in `android/app/build.gradle.kts`.
   - Disable Impeller Vulkan crashes on MediaTek/Mali physical devices:
     `<meta-data android:name="io.flutter.embedding.android.EnableImpeller" android:value="false"/>`
   - Wrap `main()` initialization defensively in `runZonedGuarded`.

## 2. Autonomous 6-Phase Sprint Execution Lifecycle
1. **Phase 1: Discovery & Workspace Inspection**:
   - Audit git state, branches, remotes, and existing files before authoring changes.
2. **Phase 2: Architectural Modeling**:
   - Define immutable models, repository contracts, and BLoC events/states prior to UI implementation.
3. **Phase 3: Implementation**:
   - Implement functional components adhering to zero hardcoded colors and landscape rules.
4. **Phase 4: Automated Verification**:
   - Run `flutter analyze --no-fatal-infos` (must return "No issues found!").
   - Run `flutter test` (must pass 100% of unit and widget tests).
5. **Phase 5: Gatekeeping Script Execution**:
   - Execute `dart run tool/sprint_gate.dart`.
6. **Phase 6: Mainline Synchronization**:
   - Commit changes using clean conventional commits without emojis.
   - Push to `origin main` and ensure `git log origin/main..HEAD` is empty.
