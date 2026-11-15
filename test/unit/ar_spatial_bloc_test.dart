import 'package:flutter_test/flutter_test.dart';
import 'package:estate_view_app/core/services/ar_spatial_service.dart';
import 'package:estate_view_app/presentation/ar_scanner/bloc/ar_spatial_bloc.dart';

import '../helpers/mock_repositories.dart';

void main() {
  group('ArSpatialBloc Unit Tests', () {
    late ArSpatialService service;
    late MockArMeasurementRepository repository;
    late ArSpatialBloc bloc;

    setUp(() {
      service = ArSpatialService();
      repository = MockArMeasurementRepository();
      bloc = ArSpatialBloc(service, repository);
    });

    tearDown(() {
      bloc.close();
      service.dispose();
    });

    test('1. Initial state is inactive with zero anchors', () {
      expect(bloc.state.isSessionActive, isFalse);
      expect(bloc.state.anchors, isEmpty);
      expect(bloc.state.areaSqFt, 0.0);
      expect(bloc.state.isClosed, isFalse);
    });

    test(
      '2. Dropping 4 corner anchors computes closed polygon and area',
      () async {
        // 4 corners of a 20ft x 15ft rectangle in viewport space (scaled: 10px = 1ft)
        // (100, 100) -> (300, 100) -> (300, 250) -> (100, 250)
        bloc.add(const PlaceCornerAnchorEvent(Offset(100, 100)));
        await bloc.stream.first;

        bloc.add(const PlaceCornerAnchorEvent(Offset(300, 100)));
        await bloc.stream.first;

        bloc.add(const PlaceCornerAnchorEvent(Offset(300, 250)));
        await bloc.stream.first;

        bloc.add(const PlaceCornerAnchorEvent(Offset(100, 250)));
        final state = await bloc.stream.first;

        expect(state.anchors.length, 4);
        expect(state.isClosed, isTrue);
        // Area in sq.ft: 20 * 15 = 300 sq.ft
        expect(state.areaSqFt, closeTo(300.0, 1.0));
        // Perimeter: 20 + 15 + 20 + 15 = 70 ft
        expect(state.perimeterFt, closeTo(70.0, 1.0));

        // Paint estimate: 70ft perimeter * 10ft height * $1.50 = $1,050
        expect(state.paintCostEstimate, closeTo(1050.0, 5.0));
        // Flooring estimate: 300 sq.ft * $12 = $3,600
        expect(state.flooringCostEstimate, closeTo(3600.0, 10.0));
      },
    );

    test('3. ResetSpatialAnchorsEvent clears all points and metrics', () async {
      bloc.add(const PlaceCornerAnchorEvent(Offset(100, 100)));
      await bloc.stream.first;

      bloc.add(const ResetSpatialAnchorsEvent());
      final state = await bloc.stream.first;

      expect(state.anchors, isEmpty);
      expect(state.areaSqFt, 0.0);
      expect(state.isClosed, isFalse);
    });

    test(
      '4. TelemetryPacket updates compass azimuth and ambient lux',
      () async {
        final packet = SpatialTelemetryPacket(
          confidencePercent: 98.0,
          ambientLux: 520.0,
          compassAzimuth: 180.0,
          solarExposureRating: 'OPTIMAL_SOUTH_EXPOSURE',
          raycastDistanceMeters: 3.12,
          timestamp: DateTime.now(),
        );

        bloc.add(TelemetryPacketReceivedEvent(packet));
        final state = await bloc.stream.first;

        expect(state.compassAzimuth, 180.0);
        expect(state.ambientLux, 520.0);
        expect(state.trackingConfidence, 98.0);
        expect(state.raycastDistanceMeters, 3.12);
        expect(state.solarExposureRating, 'OPTIMAL_SOUTH_EXPOSURE');
      },
    );
  });
}
