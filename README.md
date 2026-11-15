# EstateView: Flagship PropTech Platform

[![CI Quality Gate](https://github.com/Safeer-Hussain/estateview/actions/workflows/ci.yml/badge.svg)](https://github.com/Safeer-Hussain/estateview/actions/workflows/ci.yml)
[![Flutter SDK](https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter)](https://flutter.dev)
[![Dart SDK](https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart)](https://dart.dev)
[![Android Target](https://img.shields.io/badge/Android-SDK%2036-3DDC84?logo=android)](https://developer.android.com)
[![Platform Support](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Desktop%20%7C%20Web-4285F4)](#)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

EstateView is an enterprise-grade PropTech real estate platform built in Flutter. It combines luxury property cataloging, interactive vector blueprint rendering, native ARCore/ARKit spatial room measurement, mortgage amortization and rental yield modeling, and an on-device token-streaming AI property advisory engine.

Designed for complete autonomy and resilience, EstateView runs fully offline without recurring cloud vendor subscriptions, relying on local SQLite persistence, mock network fault injection, and native platform channels.

---

## Architectural Highlights

- **Strict Feature-First Clean Architecture + MVVM/BLoC**: Unidirectional data flow using `flutter_bloc` paired with the `get_it` service locator.
- **Native AR Spatial Telemetry Bridge**: Bidirectional platform channels (`MethodChannel` and `EventChannel`) streaming real-time planar tracking confidence, ambient lux lighting, solar azimuth, and live distance raycasts.
- **100% Theme Parity & Zero Hardcoded Colors**: Instant runtime switching between Obsidian Architectural Dark and Crisp Gallery Light palettes via `ThemeCubit` and `Theme.of(context).colorScheme`.
- **Landscape Viewport Safety (360dp Height Safe)**: Tested and verified on ultra-compact 800x360 landscape viewports with compact NavigationRail, independent multi-pane scrolling, and zero `RenderFlex` overflow errors.
- **Physical Device & Impeller Protection**: Tailored for Android SDK 36 with Vulkan Impeller fallbacks in `AndroidManifest.xml` to prevent GPU crashes on MediaTek and Mali chipsets.
- **Anti-AI Code Hygiene**: Zero emojis in source code, UI strings, logs, or git commits. Zero tutorial comments or `// TODO` placeholders.

---

## Functional Modules

```
                    +------------------------------------+
                    |       AdaptiveScaffold             |
                    |  (NavigationRail / BottomNavBar)   |
                    +-----------------+------------------+
                                      |
         +----------------------------+----------------------------+
         |              |             |              |             |
   +-----+----+   +-----+----+  +-----+----+   +-----+----+  +-----+----+
   | Module 1 |   | Module 2 |  | Module 3 |   | Module 4 |  | Module 5 |
   | Catalog  |   | Radar    |  | AR Studio|   | ROI Calc |  | AI Chat  |
   | & Vector |   | (GeoOSM) |  | (ARCore/ |   | (Yield & |   | (Stream  |
   | Blueprint|   |          |  |  ARKit)  |   |  Amort)  |   |  Engine) |
   +----------+   +----------+  +----------+   +----------+  +----------+
```

### 1. Luxury Property Catalog & Vector Blueprint Studio
- Filterable catalog by Listing Type (`Buy`, `Rent`, `Lease`), Property Type (`Penthouse`, `Villa`, `Commercial`, `Townhouse`), minimum bedrooms, and price thresholds.
- Dynamic valuation conversion between USD ($) and PKR (Lac / Cr).
- Interactive vector blueprint canvas (`RoomHotspotCanvas`) rendered via `CustomPainter`, supporting touch inspection of dimensions, ceiling clearance, and solar orientation.
- Schedule Private Viewing modal with inline form validation, date/time pickers, and instant SQLite persistence.
- Shareable Investor Dossier sheet detailing cap rates and key metrics.

### 2. Geospatial Neighborhood Radar
- OpenStreetMap integration via `flutter_map` centered on property coordinates.
- Interactive radius slider (1 km to 25 km) filtering surrounding urban amenities using the Haversine distance formula.
- Toggleable amenity layers: Metro & Transit, Dining & Lifestyle, Top Private Schools, and Healthcare.

### 3. Native AR Room Measurement Studio
- Platform channel integration with Android ARCore and iOS ARKit.
- Real-time planar corner anchor placement and dynamic wall boundary rendering.
- Live Shoelace polygon area calculation in square feet and square meters.
- Circular vector solar azimuth compass gauge indicating daylight exposure.

### 4. Mortgage & Rental Yield ROI Cockpit
- Real-time loan amortization calculation with synchronized property price, down payment, interest rate, and loan term sliders.
- Comprehensive investor metrics: Gross Rental Yield, Net Rental Yield, Cash-on-Cash Return, and Capital Appreciation forecasts over 5, 10, and 20 years.
- Edge-to-edge loan amortization balance decline chart powered by `fl_chart`.

### 5. On-Device AI Property Concierge
- Token-by-token streaming natural language property assistant simulating LLM token generation (18ms token intervals).
- Asynchronous stream lifecycle strictly guarded in `try ... finally` to prevent hanging UI spinners.
- Intelligent context triggers for financial debt service audits, room scan interpretation, and neighborhood amenity queries.

---

## Mathematical Formulations

### 1. Shoelace Polygon Area Formula
Used by the AR Spatial Studio to compute room floor areas from corner coordinates:
$$\text{Area} = \frac{1}{2} \left| \sum_{i=1}^{n-1} (x_i y_{i+1} - x_{i+1} y_i) + (x_n y_1 - x_1 y_n) \right|$$

### 2. Haversine Great-Circle Distance
Used by the Geospatial Neighborhood Radar to filter points of interest within an active radius:
$$d = 2 R \arcsin\left(\sqrt{\sin^2\left(\frac{\Delta\phi}{2}\right) + \cos(\phi_1)\cos(\phi_2)\sin^2\left(\frac{\Delta\lambda}{2}\right)}\right)$$
Where $R = 6371\text{ km}$, $\phi$ is latitude, and $\lambda$ is longitude.

### 3. Loan Amortization (Equated Monthly Installment - EMI)
$$\text{EMI} = P \times \frac{r(1 + r)^n}{(1 + r)^n - 1}$$
Where $P$ is principal loan balance, $r$ is monthly interest rate ($\text{annual rate} / 12 / 100$), and $n$ is total loan tenure in months.

### 4. Real Estate Investment Yield Metrics
$$\text{Gross Rental Yield} = \left(\frac{\text{Annual Gross Rental Income}}{\text{Property Purchase Price}}\right) \times 100$$

$$\text{Net Rental Yield} = \left(\frac{\text{Annual Gross Rent} - \text{Annual Operating Expenses}}{\text{Property Purchase Price}}\right) \times 100$$

$$\text{Cash-on-Cash ROI} = \left(\frac{\text{Annual Pre-Tax Cash Flow}}{\text{Total Cash Invested (Down Payment + Closing Costs)}}\right) \times 100$$

---

## Native AR Spatial Bridge Architecture

```
Flutter Engine                     Android (Kotlin) / iOS (Swift)
      |                                          |
      |--- MethodChannel: initializeArSession -->| Start ARCore / ARKit Session
      |<-- MethodChannel Response: OK -----------|
      |                                          |
      |--- MethodChannel: placeCornerAnchor ---->| Raycast & Register Anchor
      |<-- MethodChannel Response: {x, y, z} ----|
      |                                          |
      |<== EventChannel: spatial_telemetry ======| Stream Telemetry Packet (every 1.5s):
      |    - Tracking Confidence %               |   - planeTrackingConfidence
      |    - Ambient Lux                         |   - ambientLux
      |    - Compass Azimuth Degrees             |   - compassAzimuthDegrees
      |    - Solar Exposure Rating               |   - solarExposureRating
      |    - Distance Raycast Meters             |   - liveDistanceRaycastMeters
```

---

## Directory Structure

```
estateview/
├── .github/
│   └── workflows/
│       └── ci.yml               # GitHub Actions CI workflow
├── android/
│   ├── app/
│   │   ├── build.gradle.kts     # SDK 36, targetSdk 36, minSdk 21
│   │   └── src/main/
│   │       ├── AndroidManifest.xml # Permissions & Impeller guard
│   │       └── kotlin/.../MainActivity.kt # AR Spatial Method & Event Channels
├── assets/
│   ├── icons/app_icon.png       # Luxury PropTech app emblem
│   └── images/                  # Architectural renders & blueprint overlays
├── docs/
│   ├── PRD.md                   # Complete Product Requirements Document
│   └── AUTONOMOUS_BACKLOG.md    # 25-sprint autonomous engineering roadmap
├── ios/Runner/
│   └── AppDelegate.swift        # iOS ARKit Spatial Method & Event Channels
├── lib/
│   ├── core/                    # Constants, DB, DI, Network, Theme, Utils
│   ├── data/                    # Models & Repositories
│   ├── presentation/            # Discovery, Radar, AR Studio, ROI, AI Concierge
│   └── main.dart                # runZonedGuarded entry point & DI bootstrap
├── test/
│   ├── helpers/                 # Test locator & mock repositories
│   ├── unit/                    # BLoC, Cubit, and Math unit tests
│   └── widget/                  # Landscape 800x360 & theme widget tests
└── tool/
    ├── generate_assets.dart     # Procedural asset synthesis tool
    └── sprint_gate.dart         # Autonomous Sprint Gatekeeper script
```

---

## Getting Started

### Prerequisites
- Flutter SDK 3.47 or later
- Dart SDK 3.13 or later
- Java 17 Development Kit (for Android builds)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/Safeer-Hussain/estateview.git
   cd estateview
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the Autonomous Sprint Gatekeeper (checks format, analysis, and tests):
   ```bash
   dart run tool/sprint_gate.dart
   ```

4. Launch the application:
   ```bash
   flutter run
   ```

---

## Verification & Testing Suite

EstateView includes an automated unit and widget test suite covering BLoC state transitions, financial calculations, AR Shoelace area computation, token streaming cleanup, theme switching, and landscape viewport rendering.

Execute the test suite with:
```bash
flutter test
```

Execute static analysis with:
```bash
flutter analyze --no-fatal-infos
```

---

## License & Clean-Room Notice

This project is licensed under the [MIT License](LICENSE).

**Clean-Room Non-Disclosure Notice**: EstateView is developed entirely from clean-room original code, synthetic datasets, procedural assets, and mathematical formulations. It does not contain proprietary code, private company assets, or customer data from any commercial real estate entity.
