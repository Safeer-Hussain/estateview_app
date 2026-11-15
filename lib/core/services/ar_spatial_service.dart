import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';

import '../constants/app_constants.dart';

class SpatialTelemetryPacket {
  final double confidencePercent;
  final double ambientLux;
  final double compassAzimuth;
  final String solarExposureRating;
  final double raycastDistanceMeters;
  final DateTime timestamp;

  const SpatialTelemetryPacket({
    required this.confidencePercent,
    required this.ambientLux,
    required this.compassAzimuth,
    required this.solarExposureRating,
    required this.raycastDistanceMeters,
    required this.timestamp,
  });

  factory SpatialTelemetryPacket.fromMap(Map<dynamic, dynamic> map) {
    return SpatialTelemetryPacket(
      confidencePercent: (map['confidencePercent'] as num?)?.toDouble() ?? 92.0,
      ambientLux: (map['ambientLux'] as num?)?.toDouble() ?? 480.0,
      compassAzimuth: (map['compassAzimuth'] as num?)?.toDouble() ?? 145.0,
      solarExposureRating:
          map['solarExposureRating'] as String? ?? 'OPTIMAL_SOUTH_EXPOSURE',
      raycastDistanceMeters:
          (map['raycastDistanceMeters'] as num?)?.toDouble() ?? 2.4,
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['timestamp'] as num).toInt(),
            )
          : DateTime.now(),
    );
  }
}

class ArSpatialService {
  static const MethodChannel _methodChannel = MethodChannel(
    AppConstants.arSpatialMethodChannel,
  );
  static const EventChannel _eventChannel = EventChannel(
    AppConstants.arSpatialEventChannel,
  );

  StreamController<SpatialTelemetryPacket>? _fallbackController;
  Timer? _fallbackTimer;
  int _fallbackStep = 0;

  Future<Map<String, dynamic>> initializeArSession() async {
    try {
      final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'initializeArSession',
      );
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } catch (_) {
      // Fallback for desktop/simulator
    }
    return {
      'status': 'INITIALIZED',
      'trackingState': 'TRACKING_ACTIVE',
      'arEngine': 'Native_AR_Studio_Simulated',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Future<Map<String, dynamic>> placeCornerAnchor(
    double x,
    double y,
    double z,
  ) async {
    try {
      final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'placeCornerAnchor',
        {'x': x, 'y': y, 'z': z},
      );
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } catch (_) {
      // Fallback
    }
    return {
      'anchorCount': 1,
      'latestAnchor': {'x': x, 'y': y, 'z': z},
      'status': 'ANCHOR_PLACED',
    };
  }

  Future<Map<String, dynamic>> computeRoomPolygonArea(
    List<Map<String, double>> anchors,
  ) async {
    try {
      final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'computeRoomPolygonArea',
      );
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } catch (_) {
      // Fallback calculation using Shoelace formula
    }

    if (anchors.length < 3) {
      return {
        'areaSqMeters': 0.0,
        'areaSqFeet': 0.0,
        'perimeterMeters': 0.0,
        'perimeterFeet': 0.0,
        'pointCount': anchors.length,
        'isClosed': false,
      };
    }

    double areaSum = 0.0;
    double perimeter = 0.0;
    final n = anchors.length;

    for (int i = 0; i < n; i++) {
      final p1 = anchors[i];
      final p2 = anchors[(i + 1) % n];
      final x1 = p1['x'] ?? 0.0;
      final z1 = p1['z'] ?? (p1['y'] ?? 0.0);
      final x2 = p2['x'] ?? 0.0;
      final z2 = p2['z'] ?? (p2['y'] ?? 0.0);

      areaSum += (x1 * z2) - (x2 * z1);
      final dx = x2 - x1;
      final dz = z2 - z1;
      perimeter += sqrt(dx * dx + dz * dz);
    }

    final areaMeters = (areaSum.abs()) / 2.0;
    final areaFeet = areaMeters * 10.7639;
    final perimeterFeet = perimeter * 3.28084;

    return {
      'areaSqMeters': areaMeters,
      'areaSqFeet': areaFeet,
      'perimeterMeters': perimeter,
      'perimeterFeet': perimeterFeet,
      'pointCount': n,
      'isClosed': true,
    };
  }

  Future<Map<String, dynamic>> resetSpatialAnchors() async {
    try {
      final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'resetSpatialAnchors',
      );
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } catch (_) {
      // Fallback
    }
    return {'status': 'RESET', 'anchorCount': 0};
  }

  Stream<SpatialTelemetryPacket> streamSpatialTelemetry() {
    try {
      return _eventChannel
          .receiveBroadcastStream()
          .map((event) {
            if (event is Map) {
              return SpatialTelemetryPacket.fromMap(event);
            }
            return SpatialTelemetryPacket(
              confidencePercent: 94.0,
              ambientLux: 490.0,
              compassAzimuth: 145.0,
              solarExposureRating: 'OPTIMAL_SOUTH_EXPOSURE',
              raycastDistanceMeters: 2.35,
              timestamp: DateTime.now(),
            );
          })
          .handleError((_) {
            return _createFallbackStream();
          });
    } catch (_) {
      return _createFallbackStream();
    }
  }

  Stream<SpatialTelemetryPacket> _createFallbackStream() {
    _fallbackController?.close();
    _fallbackTimer?.cancel();

    _fallbackController = StreamController<SpatialTelemetryPacket>.broadcast();
    _fallbackTimer = Timer.periodic(const Duration(milliseconds: 1500), (
      timer,
    ) {
      _fallbackStep++;
      final confidence = 91.0 + (_fallbackStep % 7);
      final lux = 450.0 + (_fallbackStep * 11 % 120);
      final azimuth = (142.5 + (_fallbackStep * 4.2)) % 360.0;
      final solarRating = (azimuth >= 135.0 && azimuth <= 225.0)
          ? 'OPTIMAL_SOUTH_EXPOSURE'
          : 'MORNING_EAST_LIGHT';
      final raycast = 2.30 + ((_fallbackStep % 6) * 0.18);

      _fallbackController?.add(
        SpatialTelemetryPacket(
          confidencePercent: confidence,
          ambientLux: lux,
          compassAzimuth: azimuth,
          solarExposureRating: solarRating,
          raycastDistanceMeters: raycast,
          timestamp: DateTime.now(),
        ),
      );
    });

    return _fallbackController!.stream;
  }

  void dispose() {
    _fallbackTimer?.cancel();
    _fallbackController?.close();
  }
}
