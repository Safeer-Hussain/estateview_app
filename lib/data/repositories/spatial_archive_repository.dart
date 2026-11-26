import '../../core/database/app_database.dart';
import '../../data/models/spatial_export_model.dart';

abstract class SpatialArchiveRepository {
  Future<void> saveExportRecord(SpatialExportRecord record);
  Future<List<SpatialExportRecord>> getExportRecords({String? propertyId});
}

class SpatialArchiveRepositoryImpl implements SpatialArchiveRepository {
  final AppDatabase _db;

  SpatialArchiveRepositoryImpl(this._db);

  @override
  Future<void> saveExportRecord(SpatialExportRecord record) async {
    await _db.insertExportRecord(record);
  }

  @override
  Future<List<SpatialExportRecord>> getExportRecords({
    String? propertyId,
  }) async {
    if (propertyId != null && propertyId.isNotEmpty) {
      return await _db.getExportRecordsByPropertyId(propertyId);
    }
    return await _db.getAllExportRecords();
  }
}
