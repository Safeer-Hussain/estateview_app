import '../../core/database/app_database.dart';
import '../models/tour_booking_model.dart';

class TourRepository {
  final AppDatabase _db;

  TourRepository(this._db);

  Future<void> bookTour(TourBookingModel tour) async {
    await _db.insertTour(tour);
  }

  Future<List<TourBookingModel>> getTours() async {
    return await _db.getAllTours();
  }
}
