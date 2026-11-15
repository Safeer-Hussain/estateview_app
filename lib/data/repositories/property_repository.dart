import '../../core/database/app_database.dart';
import '../models/property_model.dart';

class PropertyRepository {
  final AppDatabase _db;

  PropertyRepository(this._db);

  Future<List<PropertyModel>> getProperties({
    String? query,
    String? propertyType,
    String? listingType,
    double? maxPriceUsd,
    int? minBedrooms,
  }) async {
    final all = await _db.getAllProperties();
    return all.where((p) {
      if (listingType != null &&
          listingType.isNotEmpty &&
          listingType != 'all') {
        if (p.listingType.toLowerCase() != listingType.toLowerCase()) {
          return false;
        }
      }
      if (propertyType != null &&
          propertyType.isNotEmpty &&
          propertyType != 'All Types') {
        if (p.propertyType.toLowerCase() != propertyType.toLowerCase()) {
          return false;
        }
      }
      if (minBedrooms != null && minBedrooms > 0) {
        if (p.bedrooms < minBedrooms) return false;
      }
      if (maxPriceUsd != null && maxPriceUsd > 0) {
        if (p.priceUsd > maxPriceUsd) return false;
      }
      if (query != null && query.trim().isNotEmpty) {
        final q = query.toLowerCase().trim();
        final match =
            p.title.toLowerCase().contains(q) ||
            p.subtitle.toLowerCase().contains(q) ||
            p.address.toLowerCase().contains(q) ||
            p.city.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  Future<PropertyModel?> getPropertyById(String id) async {
    return await _db.getPropertyById(id);
  }

  Future<void> toggleShortlist(String id, bool isShortlisted) async {
    await _db.togglePropertyShortlist(id, isShortlisted);
  }

  Future<List<PropertyModel>> getShortlistedProperties() async {
    return await _db.getShortlistedProperties();
  }
}
