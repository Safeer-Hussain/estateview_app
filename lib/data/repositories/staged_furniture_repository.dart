import '../../core/database/app_database.dart';
import '../models/staged_furniture_model.dart';

abstract class StagedFurnitureRepository {
  Future<List<StagedFurnitureModel>> getStagedFurniture(String propertyId);
  Future<void> saveStagedFurniture(StagedFurnitureModel item);
  Future<void> removeStagedFurniture(String id);
  Future<void> clearStagedFurniture(String propertyId);
}

class StagedFurnitureRepositoryImpl implements StagedFurnitureRepository {
  final AppDatabase _db;

  StagedFurnitureRepositoryImpl(this._db);

  @override
  Future<List<StagedFurnitureModel>> getStagedFurniture(String propertyId) {
    return _db.getStagedFurnitureByPropertyId(propertyId);
  }

  @override
  Future<void> saveStagedFurniture(StagedFurnitureModel item) async {
    await _db.saveStagedFurnitureItem(item);
  }

  @override
  Future<void> removeStagedFurniture(String id) async {
    await _db.deleteStagedFurnitureItem(id);
  }

  @override
  Future<void> clearStagedFurniture(String propertyId) async {
    await _db.clearStagedFurnitureForProperty(propertyId);
  }
}
