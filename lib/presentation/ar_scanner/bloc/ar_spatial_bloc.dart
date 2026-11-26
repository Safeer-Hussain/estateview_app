import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/ar_spatial_service.dart';
import '../../../core/services/spatial_archive_export_service.dart';
import '../../../data/models/ar_measurement_model.dart';
import '../../../data/models/plane_reconstruction_model.dart';
import '../../../data/models/spatial_export_model.dart';
import '../../../data/models/staged_furniture_model.dart';
import '../../../data/repositories/ar_measurement_repository.dart';
import '../../../data/repositories/spatial_archive_repository.dart';

// EVENTS
abstract class ArSpatialEvent {
  const ArSpatialEvent();
}

class InitializeArSessionEvent extends ArSpatialEvent {
  const InitializeArSessionEvent();
}

class PlaceCornerAnchorEvent extends ArSpatialEvent {
  final Offset point;
  const PlaceCornerAnchorEvent(this.point);
}

class ComputeRoomPolygonEvent extends ArSpatialEvent {
  const ComputeRoomPolygonEvent();
}

class ResetSpatialAnchorsEvent extends ArSpatialEvent {
  const ResetSpatialAnchorsEvent();
}

class TelemetryPacketReceivedEvent extends ArSpatialEvent {
  final SpatialTelemetryPacket packet;
  const TelemetryPacketReceivedEvent(this.packet);
}

class SaveRoomScanEvent extends ArSpatialEvent {
  final String propertyId;
  final String roomName;
  const SaveRoomScanEvent({required this.propertyId, required this.roomName});
}

class LoadSavedScansEvent extends ArSpatialEvent {
  const LoadSavedScansEvent();
}

class ToggleLidarPointCloudEvent extends ArSpatialEvent {
  final bool enabled;
  const ToggleLidarPointCloudEvent(this.enabled);
}

class DepthPointsUpdatedEvent extends ArSpatialEvent {
  final DepthPointCloudPacket packet;
  const DepthPointsUpdatedEvent(this.packet);
}

class ToggleRoomEnclosureEvent extends ArSpatialEvent {
  final bool enabled;
  const ToggleRoomEnclosureEvent(this.enabled);
}

class ReconstructRoomEnclosureEvent extends ArSpatialEvent {
  final double ceilingHeight;
  const ReconstructRoomEnclosureEvent({this.ceilingHeight = 2.8});
}

class SelectWallPlaneEvent extends ArSpatialEvent {
  final WallPlaneModel? wall;
  const SelectWallPlaneEvent(this.wall);
}

class ExportRoomArchiveEvent extends ArSpatialEvent {
  final String propertyId;
  final String roomName;
  final SpatialArchiveFormat format;
  final double ceilingHeightMeters;
  final List<StagedFurnitureModel> stagedFurniture;
  final bool openNativeShareOrQuickLook;

  const ExportRoomArchiveEvent({
    required this.propertyId,
    required this.roomName,
    this.format = SpatialArchiveFormat.bundle,
    this.ceilingHeightMeters = 2.8,
    this.stagedFurniture = const [],
    this.openNativeShareOrQuickLook = false,
  });
}

class LoadExportedArchivesEvent extends ArSpatialEvent {
  const LoadExportedArchivesEvent();
}

// STATE
class ArSpatialState {
  final bool isSessionActive;
  final double trackingConfidence;
  final double ambientLux;
  final double compassAzimuth;
  final String solarExposureRating;
  final double raycastDistanceMeters;
  final List<Offset> anchors;
  final List<double> wallLengthsFt;
  final double areaSqFt;
  final double areaSqMeters;
  final double perimeterFt;
  final double perimeterMeters;
  final double paintCostEstimate;
  final double flooringCostEstimate;
  final bool isClosed;
  final bool isSaved;
  final bool isLidarActive;
  final DepthPointCloudPacket? latestPointCloud;
  final bool isEnclosureActive;
  final RoomEnclosureModel? roomEnclosure;
  final WallPlaneModel? selectedWall;
  final List<ArMeasurementModel> savedScans;
  final bool isExportingArchive;
  final SpatialExportRecord? lastExportRecord;
  final List<SpatialExportRecord> exportedArchives;
  final String? message;

  const ArSpatialState({
    required this.isSessionActive,
    required this.trackingConfidence,
    required this.ambientLux,
    required this.compassAzimuth,
    required this.solarExposureRating,
    required this.raycastDistanceMeters,
    required this.anchors,
    required this.wallLengthsFt,
    required this.areaSqFt,
    required this.areaSqMeters,
    required this.perimeterFt,
    required this.perimeterMeters,
    required this.paintCostEstimate,
    required this.flooringCostEstimate,
    required this.isClosed,
    required this.isSaved,
    required this.isLidarActive,
    this.latestPointCloud,
    required this.isEnclosureActive,
    this.roomEnclosure,
    this.selectedWall,
    required this.savedScans,
    this.isExportingArchive = false,
    this.lastExportRecord,
    this.exportedArchives = const [],
    this.message,
  });

  factory ArSpatialState.initial() {
    return const ArSpatialState(
      isSessionActive: false,
      trackingConfidence: 94.0,
      ambientLux: 480.0,
      compassAzimuth: 145.0,
      solarExposureRating: 'OPTIMAL_SOUTH_EXPOSURE',
      raycastDistanceMeters: 2.40,
      anchors: [],
      wallLengthsFt: [],
      areaSqFt: 0.0,
      areaSqMeters: 0.0,
      perimeterFt: 0.0,
      perimeterMeters: 0.0,
      paintCostEstimate: 0.0,
      flooringCostEstimate: 0.0,
      isClosed: false,
      isSaved: false,
      isLidarActive: false,
      latestPointCloud: null,
      isEnclosureActive: false,
      roomEnclosure: null,
      selectedWall: null,
      savedScans: [],
      isExportingArchive: false,
      lastExportRecord: null,
      exportedArchives: [],
      message: null,
    );
  }

  ArSpatialState copyWith({
    bool? isSessionActive,
    double? trackingConfidence,
    double? ambientLux,
    double? compassAzimuth,
    String? solarExposureRating,
    double? raycastDistanceMeters,
    List<Offset>? anchors,
    List<double>? wallLengthsFt,
    double? areaSqFt,
    double? areaSqMeters,
    double? perimeterFt,
    double? perimeterMeters,
    double? paintCostEstimate,
    double? flooringCostEstimate,
    bool? isClosed,
    bool? isSaved,
    bool? isLidarActive,
    DepthPointCloudPacket? latestPointCloud,
    bool? isEnclosureActive,
    RoomEnclosureModel? roomEnclosure,
    WallPlaneModel? selectedWall,
    List<ArMeasurementModel>? savedScans,
    bool? isExportingArchive,
    SpatialExportRecord? lastExportRecord,
    List<SpatialExportRecord>? exportedArchives,
    String? message,
  }) {
    return ArSpatialState(
      isSessionActive: isSessionActive ?? this.isSessionActive,
      trackingConfidence: trackingConfidence ?? this.trackingConfidence,
      ambientLux: ambientLux ?? this.ambientLux,
      compassAzimuth: compassAzimuth ?? this.compassAzimuth,
      solarExposureRating: solarExposureRating ?? this.solarExposureRating,
      raycastDistanceMeters:
          raycastDistanceMeters ?? this.raycastDistanceMeters,
      anchors: anchors ?? this.anchors,
      wallLengthsFt: wallLengthsFt ?? this.wallLengthsFt,
      areaSqFt: areaSqFt ?? this.areaSqFt,
      areaSqMeters: areaSqMeters ?? this.areaSqMeters,
      perimeterFt: perimeterFt ?? this.perimeterFt,
      perimeterMeters: perimeterMeters ?? this.perimeterMeters,
      paintCostEstimate: paintCostEstimate ?? this.paintCostEstimate,
      flooringCostEstimate: flooringCostEstimate ?? this.flooringCostEstimate,
      isClosed: isClosed ?? this.isClosed,
      isSaved: isSaved ?? this.isSaved,
      isLidarActive: isLidarActive ?? this.isLidarActive,
      latestPointCloud: latestPointCloud ?? this.latestPointCloud,
      isEnclosureActive: isEnclosureActive ?? this.isEnclosureActive,
      roomEnclosure: roomEnclosure ?? this.roomEnclosure,
      selectedWall: selectedWall ?? this.selectedWall,
      savedScans: savedScans ?? this.savedScans,
      isExportingArchive: isExportingArchive ?? this.isExportingArchive,
      lastExportRecord: lastExportRecord ?? this.lastExportRecord,
      exportedArchives: exportedArchives ?? this.exportedArchives,
      message: message,
    );
  }
}

// BLOC
class ArSpatialBloc extends Bloc<ArSpatialEvent, ArSpatialState> {
  final ArSpatialService _service;
  final ArMeasurementRepository _repository;
  final SpatialArchiveExportService _exportService;
  final SpatialArchiveRepository? archiveRepository;
  StreamSubscription<SpatialTelemetryPacket>? _telemetrySub;
  StreamSubscription<DepthPointCloudPacket>? _depthSub;

  ArSpatialBloc(
    this._service,
    this._repository, {
    SpatialArchiveExportService? exportService,
    this.archiveRepository,
  }) : _exportService =
           exportService ?? SpatialArchiveExportService(arService: _service),
       super(ArSpatialState.initial()) {
    on<InitializeArSessionEvent>(_onInitializeArSession);
    on<PlaceCornerAnchorEvent>(_onPlaceCornerAnchor);
    on<ComputeRoomPolygonEvent>(_onComputeRoomPolygon);
    on<ResetSpatialAnchorsEvent>(_onResetSpatialAnchors);
    on<TelemetryPacketReceivedEvent>(_onTelemetryPacketReceived);
    on<SaveRoomScanEvent>(_onSaveRoomScan);
    on<LoadSavedScansEvent>(_onLoadSavedScans);
    on<ToggleLidarPointCloudEvent>(_onToggleLidarPointCloud);
    on<DepthPointsUpdatedEvent>(_onDepthPointsUpdated);
    on<ToggleRoomEnclosureEvent>(_onToggleRoomEnclosure);
    on<ReconstructRoomEnclosureEvent>(_onReconstructRoomEnclosure);
    on<SelectWallPlaneEvent>(_onSelectWallPlane);
    on<ExportRoomArchiveEvent>(_onExportRoomArchive);
    on<LoadExportedArchivesEvent>(_onLoadExportedArchives);
  }

  void _onToggleLidarPointCloud(
    ToggleLidarPointCloudEvent event,
    Emitter<ArSpatialState> emit,
  ) {
    if (event.enabled) {
      _depthSub?.cancel();
      _depthSub = _service.streamDepthPoints().listen((packet) {
        add(DepthPointsUpdatedEvent(packet));
      });
      emit(
        state.copyWith(
          isLidarActive: true,
          message: '3D LiDAR Depth Stream Active (Point Cloud Ingestion)',
        ),
      );
    } else {
      _depthSub?.cancel();
      _depthSub = null;
      emit(
        state.copyWith(
          isLidarActive: false,
          message: 'Switched to 2D Planar Hotspot Studio',
        ),
      );
    }
  }

  void _onDepthPointsUpdated(
    DepthPointsUpdatedEvent event,
    Emitter<ArSpatialState> emit,
  ) {
    emit(state.copyWith(latestPointCloud: event.packet));
  }

  void _onToggleRoomEnclosure(
    ToggleRoomEnclosureEvent event,
    Emitter<ArSpatialState> emit,
  ) {
    emit(
      state.copyWith(
        isEnclosureActive: event.enabled,
        message: event.enabled
            ? '3D Wireframe Room Enclosure Active'
            : 'Switched Viewport',
      ),
    );
    if (event.enabled &&
        state.anchors.length >= 3 &&
        state.roomEnclosure == null) {
      add(const ReconstructRoomEnclosureEvent());
    }
  }

  Future<void> _onReconstructRoomEnclosure(
    ReconstructRoomEnclosureEvent event,
    Emitter<ArSpatialState> emit,
  ) async {
    final anchorMaps = state.anchors
        .map((a) => {'x': a.dx / 100.0, 'z': a.dy / 100.0})
        .toList();

    final enclosure = await _service.reconstructWallPlanes(
      anchorMaps,
      ceilingHeight: event.ceilingHeight,
    );

    emit(
      state.copyWith(
        roomEnclosure: enclosure,
        selectedWall: enclosure.walls.isNotEmpty ? enclosure.walls.first : null,
        message:
            'Reconstructed ${enclosure.walls.length} 3D Wall Planes with Openings',
      ),
    );
  }

  void _onSelectWallPlane(
    SelectWallPlaneEvent event,
    Emitter<ArSpatialState> emit,
  ) {
    emit(state.copyWith(selectedWall: event.wall));
  }

  Future<void> _onInitializeArSession(
    InitializeArSessionEvent event,
    Emitter<ArSpatialState> emit,
  ) async {
    await _service.initializeArSession();
    _telemetrySub?.cancel();
    _telemetrySub = _service.streamSpatialTelemetry().listen((packet) {
      add(TelemetryPacketReceivedEvent(packet));
    });

    final scans = await _repository.getMeasurements();

    emit(
      state.copyWith(
        isSessionActive: true,
        savedScans: scans,
        message: 'Native AR Spatial Bridge Active (ARCore/ARKit)',
      ),
    );
  }

  Future<void> _onPlaceCornerAnchor(
    PlaceCornerAnchorEvent event,
    Emitter<ArSpatialState> emit,
  ) async {
    final updatedAnchors = List<Offset>.from(state.anchors)..add(event.point);
    // Compute wall lengths & polygon immediately so rapid consecutive taps never drop anchors
    _recomputePolygonAndMetrics(updatedAnchors, emit);
    await _service.placeCornerAnchor(event.point.dx, event.point.dy, 0.0);
  }

  Future<void> _onComputeRoomPolygon(
    ComputeRoomPolygonEvent event,
    Emitter<ArSpatialState> emit,
  ) async {
    _recomputePolygonAndMetrics(state.anchors, emit);
  }

  void _recomputePolygonAndMetrics(
    List<Offset> anchors,
    Emitter<ArSpatialState> emit,
  ) {
    if (anchors.isEmpty) {
      emit(state.copyWith(anchors: []));
      return;
    }

    final n = anchors.length;
    final wallLengths = <double>[];
    double perimeterPx = 0.0;

    for (int i = 0; i < n; i++) {
      final p1 = anchors[i];
      final p2 = anchors[(i + 1) % n];
      final dist = (p2 - p1).distance;
      // Scale: 10 pixels = ~1.0 foot in viewport space
      final distFt = dist / 10.0;
      wallLengths.add(distFt);
      perimeterPx += dist;
    }

    if (n >= 3) {
      // Shoelace formula
      double areaPx = 0.0;
      for (int i = 0; i < n; i++) {
        final p1 = anchors[i];
        final p2 = anchors[(i + 1) % n];
        areaPx += (p1.dx * p2.dy) - (p2.dx * p1.dy);
      }
      final areaSqFt = (areaPx.abs() / 2.0) / 100.0;
      final areaSqM = areaSqFt / 10.7639;
      final perimeterFt = perimeterPx / 10.0;
      final perimeterM = perimeterFt / 3.28084;

      // Cost estimates: Paint @ $1.50/sq.ft wall area (approx 10ft ceiling height), Flooring @ $12/sq.ft
      final wallAreaSqFt = perimeterFt * 10.0;
      final paintCost = wallAreaSqFt * 1.5;
      final flooringCost = areaSqFt * 12.0;

      emit(
        state.copyWith(
          anchors: anchors,
          wallLengthsFt: wallLengths,
          areaSqFt: areaSqFt,
          areaSqMeters: areaSqM,
          perimeterFt: perimeterFt,
          perimeterMeters: perimeterM,
          paintCostEstimate: paintCost,
          flooringCostEstimate: flooringCost,
          isClosed: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          anchors: anchors,
          wallLengthsFt: wallLengths,
          areaSqFt: 0.0,
          areaSqMeters: 0.0,
          perimeterFt: 0.0,
          perimeterMeters: 0.0,
          isClosed: false,
        ),
      );
    }
  }

  Future<void> _onResetSpatialAnchors(
    ResetSpatialAnchorsEvent event,
    Emitter<ArSpatialState> emit,
  ) async {
    await _service.resetSpatialAnchors();
    emit(
      state.copyWith(
        anchors: [],
        wallLengthsFt: [],
        areaSqFt: 0.0,
        areaSqMeters: 0.0,
        perimeterFt: 0.0,
        perimeterMeters: 0.0,
        paintCostEstimate: 0.0,
        flooringCostEstimate: 0.0,
        isClosed: false,
        isSaved: false,
        isEnclosureActive: false,
        roomEnclosure: null,
        selectedWall: null,
        message: 'Spatial anchors cleared.',
      ),
    );
  }

  void _onTelemetryPacketReceived(
    TelemetryPacketReceivedEvent event,
    Emitter<ArSpatialState> emit,
  ) {
    emit(
      state.copyWith(
        trackingConfidence: event.packet.confidencePercent,
        ambientLux: event.packet.ambientLux,
        compassAzimuth: event.packet.compassAzimuth,
        solarExposureRating: event.packet.solarExposureRating,
        raycastDistanceMeters: event.packet.raycastDistanceMeters,
      ),
    );
  }

  Future<void> _onSaveRoomScan(
    SaveRoomScanEvent event,
    Emitter<ArSpatialState> emit,
  ) async {
    if (state.anchors.length < 3) return;

    final scan = ArMeasurementModel(
      id: 'scan-${DateTime.now().millisecondsSinceEpoch}',
      propertyId: event.propertyId,
      roomName: event.roomName,
      points: state.anchors,
      wallLengthsFt: state.wallLengthsFt,
      areaSqFt: state.areaSqFt,
      areaSqMeters: state.areaSqMeters,
      perimeterFt: state.perimeterFt,
      perimeterMeters: state.perimeterMeters,
      paintCostEstimate: state.paintCostEstimate,
      flooringCostEstimate: state.flooringCostEstimate,
      solarExposure: state.solarExposureRating,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _repository.saveMeasurement(scan);
    final updatedScans = await _repository.getMeasurements();

    emit(
      state.copyWith(
        isSaved: true,
        savedScans: updatedScans,
        message: 'Floorplan scan saved successfully!',
      ),
    );
  }

  Future<void> _onLoadSavedScans(
    LoadSavedScansEvent event,
    Emitter<ArSpatialState> emit,
  ) async {
    final scans = await _repository.getMeasurements();
    final archives = archiveRepository != null
        ? await archiveRepository!.getExportRecords()
        : state.exportedArchives;
    emit(state.copyWith(savedScans: scans, exportedArchives: archives));
  }

  Future<void> _onLoadExportedArchives(
    LoadExportedArchivesEvent event,
    Emitter<ArSpatialState> emit,
  ) async {
    if (archiveRepository == null) return;
    final archives = await archiveRepository!.getExportRecords();
    emit(state.copyWith(exportedArchives: archives));
  }

  Future<void> _onExportRoomArchive(
    ExportRoomArchiveEvent event,
    Emitter<ArSpatialState> emit,
  ) async {
    emit(state.copyWith(isExportingArchive: true));
    try {
      final bundle = await _exportService.exportRoomArchive(
        propertyId: event.propertyId,
        roomName: event.roomName,
        viewportAnchors: state.anchors,
        existingEnclosure: state.roomEnclosure,
        ceilingHeightMeters: event.ceilingHeightMeters,
        stagedFurniture: event.stagedFurniture,
        format: event.format,
      );

      if (archiveRepository != null) {
        await archiveRepository!.saveExportRecord(bundle.record);
      }

      if (event.openNativeShareOrQuickLook) {
        if (bundle.record.usdzPath != null &&
            event.format == SpatialArchiveFormat.usdz) {
          await _exportService.previewUsdzQuickLook(bundle.record.usdzPath!);
        } else {
          final paths = <String>[
            if (bundle.record.glbPath != null) bundle.record.glbPath!,
            if (bundle.record.usdzPath != null) bundle.record.usdzPath!,
          ];
          await _exportService.shareSpatialArchive(
            filePaths: paths,
            title: '${event.roomName} 3D Archive',
          );
        }
      }

      final updatedArchives = archiveRepository != null
          ? await archiveRepository!.getExportRecords()
          : [bundle.record, ...state.exportedArchives];

      emit(
        state.copyWith(
          isExportingArchive: false,
          lastExportRecord: bundle.record,
          exportedArchives: updatedArchives,
          message:
              'Exported ${event.roomName} (${bundle.record.vertexCount} vertices, ${bundle.record.triangleCount} triangles)',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isExportingArchive: false,
          message: 'Failed to export 3D archive: $e',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _telemetrySub?.cancel();
    _depthSub?.cancel();
    return super.close();
  }
}
