# EstateView Autonomous Engineering Backlog

This backlog outlines 25 production sprints for continued autonomous evolution of the EstateView PropTech platform. Each sprint contains verifiable tasks with `[ ]` checkboxes.

---

## Phase I: Spatial AR LiDAR Mesh & Photogrammetry (Sprints 1-5)

### Sprint 01: LiDAR Depth API Bridge
- [x] Implement ARCore Depth API in `MainActivity.kt` using raw depth image buffers.
- [x] Implement ARKit Scene Depth API in `AppDelegate.swift` for LiDAR-equipped iOS devices.
- [x] Expose `streamDepthPoints` via EventChannel with normalized float array payloads.
- [x] Build 3D point cloud visualizer in Flutter using CustomPainter.

### Sprint 02: Real-time Wall Plane Reconstruction
- [x] Classify vertical and horizontal planes from spatial anchors in Kotlin/Swift.
- [x] Implement bounding polygon detection for walls, doors, and window openings.
- [x] Render 3D wireframe room enclosures in Flutter with dynamic perspective projection.
- [x] Add unit test verifying plane normal orientation math.

### Sprint 03: 3D Furniture Placement Engine
- [x] Add vector 3D asset bounding boxes for luxury furniture items.
- [x] Implement raycast collision detection against placed floor planes.
- [x] Add rotation and scale gesture manipulators in `SpatialViewportCanvas`.
- [x] Persist placed furniture configurations to SQLite database table `staged_furniture`.

### Sprint 04: USDZ & glTF 3D Floorplan Export
- [ ] Implement glTF 2.0 binary serializer in Dart for room meshes.
- [ ] Implement USDZ export pipeline for iOS Quick Look compatibility.
- [ ] Add share sheet action exporting room scans as interactive 3D archives.
- [ ] Add integration test verifying glTF node hierarchy and vertex counts.

### Sprint 05: Sunlight Ray-Tracing Simulator
- [ ] Integrate astronomical solar elevation and azimuth calculation library.
- [ ] Compute shadow projection onto room floorplans based on window placement and hour of day.
- [ ] Add interactive time-of-day slider animating sunbeam ingress through floorplan hotspots.
- [ ] Verify 800x360 landscape performance under 60 FPS animation.

---

## Phase II: Syndicate Portfolios & Escrow Ledger (Sprints 6-10)

### Sprint 06: Multi-Investor Portfolio Syndicates
- [ ] Design SQLite schema for `syndicates` and `syndicate_members`.
- [ ] Implement BLoC managing syndicate capital pools and ownership equity shares.
- [ ] Build syndicate overview dashboard with total pooled funds and target properties.
- [ ] Add unit tests verifying proportional equity distribution math.

### Sprint 07: Simulated Escrow & Earnest Money Vault
- [ ] Implement state machine for transaction lifecycle (Offer Submitted -> Escrow Locked -> Inspection Period -> Closing).
- [ ] Build secure earnest money deposit simulator with cryptographic receipt generation.
- [ ] Display transaction timeline cards in Portfolio Hub under new "Escrow" tab.
- [ ] Verify offline persistence across application cold restarts.

### Sprint 08: Capital Call & Distribution Engine
- [ ] Model recurring property maintenance capital calls and rental dividend distributions.
- [ ] Implement compound yield reinvestment calculator.
- [ ] Build distribution schedule table with monthly dividend projections.
- [ ] Test edge cases for negative cash flow periods and reserve fund replenishment.

### Sprint 09: Digital Legal Agreement Signer
- [ ] Build interactive SVG signature pad component with smoothing bezier curves.
- [ ] Generate cryptographic SHA-256 hash stamp for signed documents.
- [ ] Implement investor dossier PDF generation using native vector drawing.
- [ ] Store signature metadata and timestamp in SQLite.

### Sprint 10: Portfolio Stress-Testing Simulator
- [ ] Add macro-economic scenario modeling (interest rate shocks +100bps to +500bps, vacancy rate spikes).
- [ ] Build sensitivity tornado chart using `fl_chart`.
- [ ] Compute break-even occupancy and debt service coverage ratios (DSCR).
- [ ] Verify test suite passes with zero RenderFlex overflow on small viewports.

---

## Phase III: Geospatial Vector Caching & Mapbox Engine (Sprints 11-15)

### Sprint 11: Offline MBTiles Raster & Vector Tile Engine
- [ ] Integrate SQLite-backed MBTiles reader for zero-bandwidth offline map viewing.
- [ ] Pre-cache high-resolution satellite imagery for top 10 metropolitan centers.
- [ ] Implement LRU cache eviction policy for cached map tiles.
- [ ] Write widget test verifying map rendering without active network connectivity.

### Sprint 12: School District & Zoning Boundary Overlays
- [ ] Ingest GeoJSON polygons for municipal zoning and school attendance boundaries.
- [ ] Render semi-transparent polygon layers with interactive tap-to-inspect popups.
- [ ] Add school rating filter chip in `NeighborhoodExplorerView`.
- [ ] Validate polygon clipping against viewport bounds for smooth 60fps pans.

### Sprint 13: 3D Building Extrusions & Skyline Visualizer
- [ ] Parse building height attributes from OpenStreetMap vector layers.
- [ ] Implement isometric 2.5D building extrusion painter.
- [ ] Add camera pitch and tilt controls with dual-finger drag gestures.
- [ ] Ensure full dark and light architectural palette parity.

### Sprint 14: WalkScore & Transit Accessibility Isochrones
- [ ] Implement travel-time isochrone generator (5-min, 10-min, 15-min walking polygons).
- [ ] Display composite Walkability, Transit, and Bike scores for every property listing.
- [ ] Store calculated isochrone geometries in SQLite.
- [ ] Add automated unit tests for isochrone radius interpolation.

### Sprint 15: Environmental & Flood Hazard Overlays
- [ ] Integrate FEMA flood zone classification polygons.
- [ ] Display wildfire, air quality, and coastal sea-level rise hazard indicators.
- [ ] Add insurance premium impact estimator in `MortgageRoiView`.
- [ ] Verify zero emoji rule in all hazard label typography.

---

## Phase IV: AI Voice Concierge & Multimodal Ingestion (Sprints 16-20)

### Sprint 16: On-Device Speech-to-Text Audio Pipeline
- [ ] Integrate native Android `SpeechRecognizer` and iOS `SFSpeechRecognizer` via MethodChannel.
- [ ] Build pulsing microphone FAB with audio waveform visualizer.
- [ ] Stream real-time transcribed text directly into `AiConciergeCubit`.
- [ ] Verify speech permission handling and defensive fallback UI.

### Sprint 17: Voice-Guided Spatial Tour Narrator
- [ ] Integrate Flutter text-to-speech engine with luxury concierge voice profile.
- [ ] Implement automatic audio narration when user taps floorplan hotspots.
- [ ] Add audio playback controls (play, pause, skip, rate adjustment).
- [ ] Ensure audio session pauses gracefully on phone call interruptions.

### Sprint 18: Multimodal Blueprint Image Ingestion
- [ ] Implement on-device computer vision edge detection for user-uploaded blueprint photos.
- [ ] Detect room boundary contours and auto-generate vector `FloorplanHotspot` points.
- [ ] Extract dimension text strings using on-device OCR.
- [ ] Persist extracted blueprints into SQLite `floorplans` table.

### Sprint 19: Comparative Market Analysis (CMA) Engine
- [ ] Implement k-Nearest Neighbors (k-NN) algorithm to find comparable sold properties.
- [ ] Compute automated valuation model (AVM) estimate with 90% confidence bands.
- [ ] Render comparative price-per-square-foot scatter plot.
- [ ] Write unit tests validating k-NN distance metrics.

### Sprint 20: AI Natural Language Filter Parser
- [ ] Implement intent parser in `AiConciergeCubit` converting queries into catalog filter states.
- [ ] Add one-tap "Apply Filters to Catalog" action in chat messages.
- [ ] Support complex compound queries ("Modernist villas with at least 4 beds under \$3M near private schools").
- [ ] Verify stream cleanup and error handling in edge cases.

---

## Phase V: Fractional Ownership & Global Tax Engine (Sprints 21-25)

### Sprint 21: Fractional Tokenized Equity Modeler
- [ ] Model 1/8th to 1/100th fractional property share ownership structures.
- [ ] Implement calendar co-ownership scheduling algorithm for owner stay-nights.
- [ ] Calculate secondary marketplace liquidity discount and trading yield.
- [ ] Persist fractional equity allocations to SQLite.

### Sprint 22: Global Cross-Border Real Estate Tax Engine
- [ ] Support jurisdictional tax modules (US 1031 Exchange, UK Stamp Duty Land Tax, UAE 4% DLD fee).
- [ ] Implement capital gains tax calculator with holding-period sliding scales.
- [ ] Display net post-tax ROI figures side-by-side in `MortgageRoiView`.
- [ ] Write test suite validating multi-jurisdiction tax bracket math.

### Sprint 23: Currency FX Hedging & Real-Time Rates
- [ ] Add multi-currency support for EUR, GBP, AED, SGD, and JPY alongside USD and PKR.
- [ ] Implement currency fluctuation sensitivity simulation on rental yield.
- [ ] Add historical FX volatility chart using `fl_chart`.
- [ ] Ensure currency toggle propagates across all cards, modals, and sheets.

### Sprint 24: Commercial Lease Analysis (Triple Net / NNN)
- [ ] Support commercial lease structures (Gross, Modified Gross, Triple Net NNN).
- [ ] Model tenant CAM (Common Area Maintenance) expense pass-throughs.
- [ ] Compute Weighted Average Unexpired Lease Term (WAULT).
- [ ] Add commercial metrics tab to `MortgageRoiView`.

### Sprint 25: Master Automated CI/CD & Binary Release Engine
- [ ] Configure Fastlane release pipelines for Android App Bundle (`.aab`) and iOS (`.ipa`).
- [ ] Automate Google Play Internal App Sharing and TestFlight distributions.
- [ ] Add strict zero-regression gate verifying 100% test pass rate and 0 analyzer issues.
- [ ] Generate signed release build provenance hashes.
