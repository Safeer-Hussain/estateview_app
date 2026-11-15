# EstateView - Product Requirements Document (PRD)

## 1. Executive Summary
**EstateView** is a flagship PropTech mobile application built with Flutter, establishing a gold standard for luxury real estate discovery, interactive architectural spatial analysis, native AR room measurement, mortgage debt service & ROI yield modeling, and on-device AI property advisory.

The application eliminates third-party dependencies and cloud SaaS vendor lock-in by executing all geospatial filtering, geometric floorplan rendering, spatial telemetry emulation, financial mathematics, and natural language advisory offline via on-device SQLite, SharedPreferences, and reactive BLoC state management.

---

## 2. Platform Architecture & Technology Stack

### 2.1 Core Stack
- **Framework**: Flutter SDK 3.47+ / Dart 3.13+
- **Target Platforms**: Android (SDK 36, AndroidX 1.18+), iOS (iOS 16+), Windows, macOS, Linux, Web.
- **State Management**: `flutter_bloc` (Bloc, Cubit, BlocProvider, MultiBlocProvider, BlocBuilder, BlocConsumer).
- **Dependency Injection**: `get_it` Service Locator.
- **Local Persistence**: `sqflite` (SQLite 3.5+) paired with `shared_preferences`.
- **Networking**: `dio` with configured Mock Latency & Fault Interceptor (400ms-850ms latency, simulated HTTP 503 outage toggle).
- **Geospatial Mapping**: `flutter_map` with OpenStreetMap CartoDB dark/light tile layers and Haversine distance computations.
- **Financial Visualizations**: `fl_chart` for edge-to-edge loan amortization and capital growth trajectories.

### 2.2 Clean Architecture Layers
```
lib/
├── core/
│   ├── constants/       # Hero tags, channel names, asset paths
│   ├── database/        # SQLite database singleton & initial seed data
│   ├── di/              # Service locator container (get_it)
│   ├── network/         # Dio API client & mock fault interceptor
│   ├── services/        # AR bridge, connectivity, and preferences services
│   ├── theme/           # Obsidian Dark and Gallery Light palettes & Cubit
│   └── utils/           # SnackBar feedback, currency formatters, GeoMath
├── data/
│   ├── models/          # Immutable domain-mapped data entities
│   └── repositories/    # Abstract & concrete data repositories
└── presentation/
    ├── ai_concierge/    # Module 5: Token-streaming AI property advisor
    ├── ar_scanner/      # Module 3: Native ARCore/ARKit spatial studio
    ├── discovery/       # Module 1: Catalog, interactive floorplan, viewing modal
    ├── neighborhood/    # Module 2: Geospatial interactive amenity radar
    ├── portfolio/       # Saved shortlist, viewing appointments, AR scans
    ├── roi_analyzer/    # Module 4: Mortgage amortization & ROI cockpit
    ├── scaffold/        # AdaptiveScaffold (NavigationRail in landscape, BottomNav in portrait)
    ├── settings/        # Theme switcher, currency toggle, recruiter debug console
    └── splash/          # Animated branded splash with deferred initialization
```

---

## 3. Detailed Functional Modules

### 3.1 Module 1: Luxury Property Catalog & Vector Blueprint Studio
- **Curated Property Catalog**:
  - Filterable by Listing Type (`Buy`, `Rent`, `Lease`), Property Type (`Penthouse`, `Villa`, `Commercial`, `Townhouse`), minimum bedrooms, and price thresholds.
  - Multi-attribute cards displaying price, square footage, bed/bath count, verified badge, and instant reactive bookmark toggles.
  - Real-time conversion between USD ($) and PKR (Lac / Cr).
- **Interactive Vector Floorplan Canvas (`RoomHotspotCanvas`)**:
  - Custom vector blueprint renderer with dimensional room labels, architectural boundaries, and interactive hotspot targets.
  - Room metadata inspection detailing dimensions, ceiling height, and daylight orientation.
- **Schedule Viewing Modal**:
  - Complete reservation flow with inline form validation, date/time pickers, tour type selection (`In-Person VIP Tour` vs. `Live 4K Spatial Walkthrough`), and instant SQLite persistence.
- **Shareable Investor Dossier**:
  - Modal bottom sheet displaying property investment highlights, cap rates, geospatial coordinates, and simulated export capabilities.

### 3.2 Module 2: Geospatial Neighborhood Radar
- **OpenStreetMap Integration**:
  - High-performance vector tile rendering centered on curated luxury properties.
  - Interactive radius filter slider (1 km to 25 km).
- **Haversine Distance Filter**:
  $$\text{distance} = 2 R \arcsin\left(\sqrt{\sin^2\left(\frac{\Delta\phi}{2}\right) + \cos(\phi_1)\cos(\phi_2)\sin^2\left(\frac{\Delta\lambda}{2}\right)}\right)$$
- **Layer Toggles**:
  - Metro & Transit Hubs.
  - Michelin Dining & Lifestyle.
  - Top-Tier Private Schools.
  - Healthcare & Wellness Centers.

### 3.3 Module 3: Native AR Room Measurement Studio
- **Platform Bridge Channels**:
  - `MethodChannel('com.safeer.estateview/ar_spatial')`: Invokes native platform methods (`initializeArSession`, `placeCornerAnchor`, `computeRoomPolygonArea`, `resetSpatialAnchors`).
  - `EventChannel('com.safeer.estateview/spatial_telemetry')`: Streams live spatial telemetry packets every 1.5 seconds (tracking confidence, ambient lux, compass azimuth, solar exposure, live distance).
- **Shoelace Polygon Formula for Area Calculation**:
  $$\text{Area} = \frac{1}{2} \left| \sum_{i=1}^{n-1} (x_i y_{i+1} - x_{i+1} y_i) + (x_n y_1 - x_1 y_n) \right|$$
- **Real-time Spatial Viewport**:
  - Interactive canvas allowing the user to place corner anchors, visualize wall boundaries, inspect live perimeter calculations, and save room measurements to SQLite.
- **Solar Azimuth Compass Gauge**:
  - Circular vector gauge visualizing heading degrees, cardinal directions, and dynamic sunlight exposure rating.

### 3.4 Module 4: Mortgage & Rental Yield ROI Cockpit
- **Standard Amortization Formula (Equated Monthly Installment - EMI)**:
  $$\text{EMI} = P \times \frac{r(1 + r)^n}{(1 + r)^n - 1}$$
  Where $P$ is principal loan amount, $r$ is monthly interest rate, and $n$ is total payments in months.
- **Financial Metrics Calculated**:
  - Gross Rental Yield: $\frac{\text{Annual Rent}}{\text{Property Price}} \times 100$
  - Net Rental Yield: $\frac{\text{Annual Rent} - \text{Annual Expenses}}{\text{Property Price}} \times 100$
  - Cash-on-Cash Return: $\frac{\text{Net Annual Cash Flow}}{\text{Total Cash Invested}} \times 100$
  - Capital Appreciation Forecast over 5, 10, and 20 years.
- **Edge-to-Edge Amortization Visualizer**:
  - `fl_chart` line chart rendering loan balance decline over the amortization schedule.

### 3.5 Module 5: On-Device AI Property Concierge
- **Token-Streaming Conversational Engine**:
  - Reactive `AiConciergeCubit` streaming responses character-by-character (18ms delays) simulating LLM token generation.
  - Guarded in `try ... finally` ensuring `isStreaming: false` is strictly emitted upon stream completion or error.
- **Context-Aware Property Queries**:
  - Recognizes property valuation queries, mortgage calculations, spatial scan questions, and neighborhood suitability.
  - Direct prompt shortcut pills for rapid discovery.

---

## 4. Non-Functional & Safety Requirements
1. **Zero Hardcoded Colors**: Full parity between Obsidian Dark and Gallery Light palettes via `Theme.of(context).colorScheme`.
2. **Hero Tag Uniqueness**: All FloatingActionButtons define explicit, unique Hero tags.
3. **Landscape Viewport Safety**: Zero `RenderFlex` overflow exceptions on 800x360 landscape viewports.
4. **Android SDK 36 Compatibility**: `compileSdk = 36`, `targetSdk = 36`, `minSdk = 21` configured with Impeller Vulkan disabled on Android to prevent physical device crashes.
5. **Anti-AI Code Hygiene**: Zero emojis in source code, UI strings, logs, or git commits. Zero tutorial comments or `// TODO` stubs.
