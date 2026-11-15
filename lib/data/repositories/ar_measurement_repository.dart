import '../../core/database/app_database.dart';
import '../models/ar_measurement_model.dart';

class ArMeasurementRepository {
  final AppDatabase _db;

  ArMeasurementRepository(this._db);

  Future<void> saveMeasurement(ArMeasurementModel measurement) async {
    await _db.insertArMeasurement(measurement);
  }

  Future<List<ArMeasurementModel>> getMeasurements() async {
    return await _db.getAllArMeasurements();
  }
}
