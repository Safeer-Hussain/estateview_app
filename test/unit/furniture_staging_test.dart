import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:estate_view_app/data/models/staged_furniture_model.dart';
import 'package:estate_view_app/presentation/ar_scanner/bloc/furniture_staging_cubit.dart';

import '../helpers/mock_repositories.dart';

void main() {
  group('StagedFurnitureModel Math & Collision Tests', () {
    test('Oriented Bounding Box corners calculation without rotation', () {
      const item = StagedFurnitureModel(
        id: 'item-1',
        propertyId: 'prop-1',
        presetId: 'preset-1',
        name: 'Desk',
        category: 'Tables',
        widthMeters: 2.0,
        depthMeters: 1.0,
        heightMeters: 0.8,
        posX: 5.0,
        posZ: 10.0,
        rotationY: 0.0,
        scale: 1.0,
        colorHex: '#000000',
        priceUsd: 1200.0,
        createdAt: 0,
      );

      final corners = item.getBoundingBoxCorners();
      expect(corners.length, equals(4));

      // (-1, -0.5), (1, -0.5), (1, 0.5), (-1, 0.5) shifted by (5, 10)
      expect(corners[0].dx, closeTo(4.0, 0.001));
      expect(corners[0].dy, closeTo(9.5, 0.001));
      expect(corners[1].dx, closeTo(6.0, 0.001));
      expect(corners[1].dy, closeTo(9.5, 0.001));
      expect(corners[2].dx, closeTo(6.0, 0.001));
      expect(corners[2].dy, closeTo(10.5, 0.001));
      expect(corners[3].dx, closeTo(4.0, 0.001));
      expect(corners[3].dy, closeTo(10.5, 0.001));
    });

    test('SAT collision detection detects overlap between intersecting bounding boxes', () {
      const itemA = StagedFurnitureModel(
        id: 'item-a',
        propertyId: 'prop-1',
        presetId: 'p-1',
        name: 'Item A',
        category: 'Seating',
        widthMeters: 2.0,
        depthMeters: 2.0,
        heightMeters: 1.0,
        posX: 0.0,
        posZ: 0.0,
        colorHex: '#111111',
        priceUsd: 1000.0,
        createdAt: 0,
      );

      const itemB = StagedFurnitureModel(
        id: 'item-b',
        propertyId: 'prop-1',
        presetId: 'p-2',
        name: 'Item B',
        category: 'Seating',
        widthMeters: 2.0,
        depthMeters: 2.0,
        heightMeters: 1.0,
        posX: 1.5, // Center is at 1.5, edges reach 0.5 to 2.5 -> overlaps with A (edge at 1.0)
        posZ: 0.0,
        colorHex: '#222222',
        priceUsd: 1200.0,
        createdAt: 0,
      );

      expect(itemA.collidesWith(itemB), isTrue);
      expect(itemB.collidesWith(itemA), isTrue);
    });

    test('SAT collision detection confirms no collision when separated', () {
      const itemA = StagedFurnitureModel(
        id: 'item-a',
        propertyId: 'prop-1',
        presetId: 'p-1',
        name: 'Item A',
        category: 'Seating',
        widthMeters: 2.0,
        depthMeters: 2.0,
        heightMeters: 1.0,
        posX: 0.0,
        posZ: 0.0,
        colorHex: '#111111',
        priceUsd: 1000.0,
        createdAt: 0,
      );

      const itemDisjoint = StagedFurnitureModel(
        id: 'item-c',
        propertyId: 'prop-1',
        presetId: 'p-3',
        name: 'Item C',
        category: 'Seating',
        widthMeters: 2.0,
        depthMeters: 2.0,
        heightMeters: 1.0,
        posX: 5.0, // Far away
        posZ: 5.0,
        colorHex: '#333333',
        priceUsd: 800.0,
        createdAt: 0,
      );

      expect(itemA.collidesWith(itemDisjoint), isFalse);
      expect(itemDisjoint.collidesWith(itemA), isFalse);
    });

    test('Point-in-polygon raycast containment inside floor anchors', () {
      final roomFloor = [
        const Offset(-5, -5),
        const Offset(5, -5),
        const Offset(5, 5),
        const Offset(-5, 5),
      ];

      const insideItem = StagedFurnitureModel(
        id: 'inside-1',
        propertyId: 'prop-1',
        presetId: 'p-1',
        name: 'Inside Chair',
        category: 'Seating',
        widthMeters: 1.0,
        depthMeters: 1.0,
        heightMeters: 0.8,
        posX: 0.0,
        posZ: 0.0,
        colorHex: '#444444',
        priceUsd: 500.0,
        createdAt: 0,
      );

      const outsideItem = StagedFurnitureModel(
        id: 'outside-1',
        propertyId: 'prop-1',
        presetId: 'p-2',
        name: 'Outside Chair',
        category: 'Seating',
        widthMeters: 1.0,
        depthMeters: 1.0,
        heightMeters: 0.8,
        posX: 10.0,
        posZ: 10.0,
        colorHex: '#555555',
        priceUsd: 500.0,
        createdAt: 0,
      );

      expect(insideItem.isInsideFloorPolygon(roomFloor), isTrue);
      expect(outsideItem.isInsideFloorPolygon(roomFloor), isFalse);
    });
  });

  group('FurnitureStagingCubit Operations', () {
    late MockStagedFurnitureRepository mockRepo;
    late FurnitureStagingCubit cubit;

    setUp(() {
      mockRepo = MockStagedFurnitureRepository();
      cubit = FurnitureStagingCubit(mockRepo);
    });

    tearDown(() {
      cubit.close();
    });

    test(
      'placePresetItem saves to repository and updates total valuation',
      () async {
        final preset = FurniturePresets.catalog.first;

        await cubit.placePresetItem(preset, const Offset(1.0, 2.0));

        expect(cubit.state.placedItems.length, equals(1));
        expect(cubit.state.placedItems.first.name, equals(preset.name));
        expect(cubit.state.placedItems.first.posX, equals(1.0));
        expect(cubit.state.placedItems.first.posZ, equals(2.0));
        expect(cubit.state.totalStagingValueUsd, equals(preset.priceUsd));
        expect(cubit.state.hasCollisionWarning, isFalse);
      },
    );

    test('detects collision warning when placing overlapping items', () async {
      final preset = FurniturePresets.catalog.first;

      // Place first item at (0, 0)
      await cubit.placePresetItem(preset, const Offset(0.0, 0.0));
      // Place second item overlapping at (0.2, 0.2)
      await cubit.placePresetItem(preset, const Offset(0.2, 0.2));

      expect(cubit.state.placedItems.length, equals(2));
      expect(cubit.state.hasCollisionWarning, isTrue);
    });

    test('updateFurnitureTransform updates position and rotation', () async {
      final preset = FurniturePresets.catalog.first;
      await cubit.placePresetItem(preset, const Offset(0.0, 0.0));
      final placedId = cubit.state.placedItems.first.id;

      await cubit.updateFurnitureTransform(
        id: placedId,
        position: const Offset(3.0, 4.0),
        rotationY: pi / 2,
        scale: 1.5,
      );

      final updated = cubit.state.placedItems.first;
      expect(updated.posX, equals(3.0));
      expect(updated.posZ, equals(4.0));
      expect(updated.rotationY, equals(pi / 2));
      expect(updated.scale, equals(1.5));
    });

    test(
      'removeFurniture and clearAllFurniture correctly updates state and repo',
      () async {
        const presets = FurniturePresets.catalog;
        await cubit.placePresetItem(presets[0], const Offset(0, 0));
        await cubit.placePresetItem(presets[1], const Offset(5, 5));

        expect(cubit.state.placedItems.length, equals(2));
        final firstId = cubit.state.placedItems.first.id;

        await cubit.removeFurniture(firstId);
        expect(cubit.state.placedItems.length, equals(1));
        expect(cubit.state.placedItems.first.id, isNot(equals(firstId)));

        await cubit.clearAllFurniture(cubit.state.propertyId);
        expect(cubit.state.placedItems.isEmpty, isTrue);
        expect(cubit.state.totalStagingValueUsd, equals(0.0));
      },
    );
  });
}
