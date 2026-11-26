# Changelog

All notable changes to the EstateView PropTech platform are documented in this file.

## [1.4.4+3] - 2026-11-26

### Added
- USDZ and glTF 2.0 Binary (.glb) 3D Floorplan Export pipeline (Sprint 04).
- Pure-Dart Khronos glTF 2.0 binary serializer (`GltfBinarySerializer`) supporting hierarchical room nodes, floor and ceiling ear-clipping triangulation, wall quads, door/window portals, and staged furniture volumes with PBR materials and accessor bounds.
- Apple Quick Look compatible USDZ exporter (`UsdzArchiveSerializer`) producing 64-byte aligned, uncompressed STORE ZIP archives wrapping Pixar USDA 1.0 scenes with `UsdPreviewSurface` shaders.
- Disk archival, metadata inspection, and SQLite persistence (`exported_3d_archives` table) managed via `SpatialArchiveExportService`, `SpatialArchiveRepository`, and `ArSpatialBloc`.
- Native platform channel hooks in `AppDelegate.swift` (`QLPreviewController` Quick Look preview and `UIActivityViewController`) and `MainActivity.kt` (`Intent.ACTION_SEND` archive sharing).
- Interactive `SpatialArchiveShareSheet` featuring format switching (`.glb`, `.usdz`, dual bundle), extrusion height controls, live vertex/triangle diagnostics, node tree / USDA schema inspector, and 800x360 landscape safety, wired into `ArScannerView`, `PortfolioHubView`, and `ShareDossierSheet`.
- Comprehensive unit, widget, and integration tests verifying glTF 2.0 node hierarchy, exact vertex/triangle counts, USDZ 64-byte boundary alignment, and 800x360 responsive layout parity.

## [1.4.3+2] - 2026-11-18

### Added
- 3D Furniture Placement Engine in Native AR Spatial Studio (Sprint 03).
- Oriented Bounding Box (OBB) geometric projection and corner calculation math in `StagedFurnitureModel`.
- Separating Axis Theorem (SAT) collision detection algorithm preventing overlapping furniture placement.
- Point-in-polygon raycast containment auditing ensuring placed furniture remains within room floorplan boundaries.
- Interactive gesture manipulators: drag to translate position on floorplan, rotation slider, and scale controls.
- Curated luxury architectural furniture catalog sheet featuring 6 designer presets (Eames Lounge Chair, Barcelona Daybed, Noguchi Coffee Table, Flos Arco Floor Lamp, Solid Walnut Dining Table, Platform Bed).
- SQLite persistence table `staged_furniture` with automated CRUD queries and repository layer.
- Viewport mode selector supporting seamless toggling between 2D Planar, 3D LiDAR, 3D Enclosure, and 3D Staging.
- Automated release workflow in `.github/workflows/release.yml` building and publishing `app-release.apk`.
- Comprehensive unit and widget tests for OBB collision math, containment auditing, and 800x360 landscape safety.

## [1.4.2+1] - 2026-11-17

### Added
- Real-time Wall Plane Reconstruction and 3D wireframe room enclosures (Sprint 02).
- Perspective projection rendering of vertical wall boundaries, door portals, and window openings.
- Automated wall plane normal classification and gross room area analytics.

## [1.4.1+1] - 2026-11-16

### Added
- Native ARCore and ARKit LiDAR Depth API bridge (Sprint 01).
- 3D point cloud streaming visualizer via event channels.
- Ambient illumination and solar exposure tracking HUD.

## [1.0.0+1] - 2026-11-15

### Added
- Flagship PropTech application launch with Clean Architecture and BLoC state management.
- Multi-tab adaptive navigation with 800x360 landscape viewport compliance.
- Interactive vector floorplan studio and financial ROI amortization calculators.
- On-device AI property concierge with streaming query engine.
