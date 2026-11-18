import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/staged_furniture_model.dart';
import '../../../data/repositories/staged_furniture_repository.dart';

class FurnitureStagingState {
  final bool isLoading;
  final String propertyId;
  final List<StagedFurnitureModel> placedItems;
  final String? selectedItemId;
  final bool hasCollisionWarning;
  final bool isOutOfBoundsWarning;
  final double totalStagingValueUsd;
  final String? message;

  const FurnitureStagingState({
    required this.isLoading,
    required this.propertyId,
    required this.placedItems,
    this.selectedItemId,
    required this.hasCollisionWarning,
    required this.isOutOfBoundsWarning,
    required this.totalStagingValueUsd,
    this.message,
  });

  factory FurnitureStagingState.initial() {
    return const FurnitureStagingState(
      isLoading: false,
      propertyId: 'prop-lahore-01',
      placedItems: [],
      selectedItemId: null,
      hasCollisionWarning: false,
      isOutOfBoundsWarning: false,
      totalStagingValueUsd: 0.0,
      message: null,
    );
  }

  StagedFurnitureModel? get selectedItem {
    if (selectedItemId == null) return null;
    try {
      return placedItems.firstWhere((item) => item.id == selectedItemId);
    } catch (_) {
      return null;
    }
  }

  FurnitureStagingState copyWith({
    bool? isLoading,
    String? propertyId,
    List<StagedFurnitureModel>? placedItems,
    String? selectedItemId,
    bool clearSelectedItem = false,
    bool? hasCollisionWarning,
    bool? isOutOfBoundsWarning,
    double? totalStagingValueUsd,
    String? message,
  }) {
    return FurnitureStagingState(
      isLoading: isLoading ?? this.isLoading,
      propertyId: propertyId ?? this.propertyId,
      placedItems: placedItems ?? this.placedItems,
      selectedItemId: clearSelectedItem
          ? null
          : (selectedItemId ?? this.selectedItemId),
      hasCollisionWarning: hasCollisionWarning ?? this.hasCollisionWarning,
      isOutOfBoundsWarning: isOutOfBoundsWarning ?? this.isOutOfBoundsWarning,
      totalStagingValueUsd: totalStagingValueUsd ?? this.totalStagingValueUsd,
      message: message,
    );
  }
}

class FurnitureStagingCubit extends Cubit<FurnitureStagingState> {
  final StagedFurnitureRepository _repository;
  static int _idCounter = 0;

  FurnitureStagingCubit(this._repository)
    : super(FurnitureStagingState.initial());

  Future<void> loadStagedFurniture(String propertyId) async {
    emit(state.copyWith(isLoading: true, propertyId: propertyId));
    try {
      final items = await _repository.getStagedFurniture(propertyId);
      final totalValue = items.fold<double>(
        0.0,
        (sum, item) => sum + item.priceUsd,
      );
      emit(
        state.copyWith(
          isLoading: false,
          placedItems: items,
          totalStagingValueUsd: totalValue,
          selectedItemId: items.isNotEmpty ? items.first.id : null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          message: 'Failed to load staged furniture: $e',
        ),
      );
    }
  }

  Future<void> placePresetItem(
    StagedFurnitureModel preset,
    Offset position, {
    List<Offset> floorPolygon = const [],
  }) async {
    _idCounter++;
    final newItem = preset.copyWith(
      id: 'furn-${DateTime.now().microsecondsSinceEpoch}-$_idCounter',
      propertyId: state.propertyId,
      posX: position.dx,
      posZ: position.dy,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    final updated = List<StagedFurnitureModel>.from(state.placedItems)
      ..add(newItem);
    await _repository.saveStagedFurniture(newItem);

    final (hasCollision, isOutOfBounds) = _auditCollisionsAndBounds(
      updated,
      newItem.id,
      floorPolygon,
    );

    final totalValue = updated.fold<double>(
      0.0,
      (sum, item) => sum + item.priceUsd,
    );

    emit(
      state.copyWith(
        placedItems: updated,
        selectedItemId: newItem.id,
        hasCollisionWarning: hasCollision,
        isOutOfBoundsWarning: isOutOfBounds,
        totalStagingValueUsd: totalValue,
        message: 'Placed ${newItem.name} on floorplan',
      ),
    );
  }

  Future<void> updateFurnitureTransform({
    required String id,
    Offset? position,
    double? rotationY,
    double? scale,
    List<Offset> floorPolygon = const [],
  }) async {
    final index = state.placedItems.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final current = state.placedItems[index];
    final updatedItem = current.copyWith(
      posX: position != null ? position.dx : current.posX,
      posZ: position != null ? position.dy : current.posZ,
      rotationY: rotationY ?? current.rotationY,
      scale: scale ?? current.scale,
    );

    final updatedList = List<StagedFurnitureModel>.from(state.placedItems);
    updatedList[index] = updatedItem;

    await _repository.saveStagedFurniture(updatedItem);

    final (hasCollision, isOutOfBounds) = _auditCollisionsAndBounds(
      updatedList,
      id,
      floorPolygon,
    );

    emit(
      state.copyWith(
        placedItems: updatedList,
        selectedItemId: id,
        hasCollisionWarning: hasCollision,
        isOutOfBoundsWarning: isOutOfBounds,
      ),
    );
  }

  void selectFurniture(String? id) {
    emit(state.copyWith(selectedItemId: id, clearSelectedItem: id == null));
  }

  Future<void> removeFurniture(String id) async {
    await _repository.removeStagedFurniture(id);
    final updated = state.placedItems.where((item) => item.id != id).toList();
    final totalValue = updated.fold<double>(
      0.0,
      (sum, item) => sum + item.priceUsd,
    );

    emit(
      state.copyWith(
        placedItems: updated,
        clearSelectedItem: state.selectedItemId == id,
        totalStagingValueUsd: totalValue,
        message: 'Removed furniture item from floorplan',
      ),
    );
  }

  Future<void> clearAllFurniture(String propertyId) async {
    await _repository.clearStagedFurniture(propertyId);
    emit(
      state.copyWith(
        placedItems: const [],
        clearSelectedItem: true,
        hasCollisionWarning: false,
        isOutOfBoundsWarning: false,
        totalStagingValueUsd: 0.0,
        message: 'Cleared all staged furniture items',
      ),
    );
  }

  (bool, bool) _auditCollisionsAndBounds(
    List<StagedFurnitureModel> items,
    String targetId,
    List<Offset> floorPolygon,
  ) {
    bool hasCollision = false;
    bool isOutOfBounds = false;

    try {
      final target = items.firstWhere((item) => item.id == targetId);

      // Check collision against all other items
      for (final other in items) {
        if (other.id == target.id) continue;
        if (target.collidesWith(other)) {
          hasCollision = true;
          break;
        }
      }

      // Check if inside room floor polygon
      if (floorPolygon.length >= 3) {
        isOutOfBounds = !target.isInsideFloorPolygon(floorPolygon);
      }
    } catch (_) {}

    return (hasCollision, isOutOfBounds);
  }
}
