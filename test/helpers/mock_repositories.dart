import 'package:flutter_test/flutter_test.dart';
import 'package:estate_view_app/core/constants/app_constants.dart';
import 'package:estate_view_app/core/database/app_database.dart';
import 'package:estate_view_app/data/models/ai_message_model.dart';
import 'package:estate_view_app/data/models/floorplan_model.dart';
import 'package:estate_view_app/data/models/property_model.dart';
import 'package:estate_view_app/data/models/tour_booking_model.dart';
import 'package:estate_view_app/data/models/ar_measurement_model.dart';
import 'package:estate_view_app/data/models/staged_furniture_model.dart';
import 'package:estate_view_app/data/repositories/property_repository.dart';
import 'package:estate_view_app/data/repositories/tour_repository.dart';
import 'package:estate_view_app/data/repositories/ar_measurement_repository.dart';
import 'package:estate_view_app/data/repositories/staged_furniture_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockAppDatabase extends Mock implements AppDatabase {
  final List<AiMessageModel> _messages = [];

  @override
  Future<List<AiMessageModel>> getAiMessages() async => _messages;

  @override
  Future<int> insertAiMessage(AiMessageModel msg) async {
    _messages.add(msg);
    return 1;
  }

  @override
  Future<void> clearAiMessages() async {
    _messages.clear();
  }
}

final testMockProperties = [
  const PropertyModel(
    id: 'test-prop-01',
    title: 'The Cantilever Courtyard Villa',
    subtitle: 'Modernist Brutalist Pavilion',
    priceUsd: 890000.0,
    pricePkr: 248000000.0,
    address: 'Sector J, Phase 6, DHA',
    city: 'Lahore',
    latitude: 31.4720,
    longitude: 74.4390,
    bedrooms: 5,
    bathrooms: 6,
    areaSqFt: 6200.0,
    propertyType: 'Villa',
    listingType: 'buy',
    isShortlisted: true,
    imageAsset: AppConstants.imgVillaCourtyard,
    amenities: ['Geothermal Cooling', 'Solar Array'],
    floorplan: FloorplanData(
      blueprintId: 'fp-01',
      totalAreaSqFt: 6200.0,
      rooms: [
        RoomHotspot(
          id: 'rm-01',
          name: 'Master Suite',
          widthFt: 24.0,
          lengthFt: 20.0,
          areaSqFt: 480.0,
          flooringType: 'Oak Parquet',
          sunOrientation: 'South-West',
          relativePosition: Offset(0.7, 0.3),
          description: 'Spacious suite with spa bath.',
        ),
      ],
    ),
    advisorName: 'Sarah Chen',
    advisorRole: 'Senior Partner',
    advisorAvatar: AppConstants.imgAdvisorSarah,
    advisorPhone: '+92 300 8472911',
    createdAt: 1700000000000,
  ),
  const PropertyModel(
    id: 'test-prop-02',
    title: 'The Sky Atrium Penthouse',
    subtitle: 'Double-Height Duplex Loft',
    priceUsd: 650000.0,
    pricePkr: 181000000.0,
    address: 'Main Boulevard, Gulberg III',
    city: 'Lahore',
    latitude: 31.5120,
    longitude: 74.3480,
    bedrooms: 4,
    bathrooms: 5,
    areaSqFt: 4800.0,
    propertyType: 'Penthouse',
    listingType: 'buy',
    isShortlisted: false,
    imageAsset: AppConstants.imgPenthouseLoft,
    amenities: ['Private Elevator', 'Wrap-around Terrace'],
    floorplan: FloorplanData(
      blueprintId: 'fp-02',
      totalAreaSqFt: 4800.0,
      rooms: [],
    ),
    advisorName: 'Omar Hayat',
    advisorRole: 'Executive Director',
    advisorAvatar: AppConstants.imgAdvisorOmar,
    advisorPhone: '+92 321 9541200',
    createdAt: 1700000100000,
  ),
  const PropertyModel(
    id: 'test-prop-03',
    title: 'Urban Smart Studio Loft',
    subtitle: 'Turnkey Luxury Rental',
    priceUsd: 2200.0,
    pricePkr: 610000.0,
    address: 'MM Alam Road, Gulberg III',
    city: 'Lahore',
    latitude: 31.5150,
    longitude: 74.3510,
    bedrooms: 1,
    bathrooms: 2,
    areaSqFt: 1450.0,
    propertyType: 'Apartment',
    listingType: 'rent',
    isShortlisted: false,
    imageAsset: AppConstants.imgSmartTownhouse,
    amenities: ['1Gbps Fiber', 'Herman Miller Desk'],
    floorplan: FloorplanData(
      blueprintId: 'fp-03',
      totalAreaSqFt: 1450.0,
      rooms: [],
    ),
    advisorName: 'Elena Rostova',
    advisorRole: 'Portfolio Specialist',
    advisorAvatar: AppConstants.imgAdvisorElena,
    advisorPhone: '+92 304 7710922',
    createdAt: 1700000200000,
  ),
];

class MockPropertyRepository implements PropertyRepository {
  List<PropertyModel> properties = List.from(testMockProperties);

  @override
  Future<List<PropertyModel>> getProperties({
    String? query,
    String? propertyType,
    String? listingType,
    double? maxPriceUsd,
    int? minBedrooms,
  }) async {
    return properties.where((p) {
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

  @override
  Future<PropertyModel?> getPropertyById(String id) async {
    final matches = properties.where((p) => p.id == id);
    return matches.isNotEmpty ? matches.first : null;
  }

  @override
  Future<void> toggleShortlist(String id, bool isShortlisted) async {
    final index = properties.indexWhere((p) => p.id == id);
    if (index >= 0) {
      properties[index] = properties[index].copyWith(
        isShortlisted: isShortlisted,
      );
    }
  }

  @override
  Future<List<PropertyModel>> getShortlistedProperties() async {
    return properties.where((p) => p.isShortlisted).toList();
  }
}

class MockTourRepository implements TourRepository {
  List<TourBookingModel> tours = [
    const TourBookingModel(
      id: 'mock-tour-1',
      propertyId: 'test-prop-01',
      propertyTitle: 'The Cantilever Courtyard Villa',
      date: '2026-11-20',
      timeSlot: '03:00 PM - 04:00 PM',
      tourType: 'In-Person VIP Tour',
      contactName: 'Safeer Hussain',
      contactEmail: 'safeer@estateview.io',
      contactPhone: '+92 300 8472911',
      notes: 'Solar and HVAC review',
      status: 'CONFIRMED',
      createdAt: 1700000000000,
    ),
  ];

  @override
  Future<void> bookTour(TourBookingModel tour) async {
    tours.add(tour);
  }

  @override
  Future<List<TourBookingModel>> getTours() async {
    return tours;
  }
}

class MockArMeasurementRepository implements ArMeasurementRepository {
  List<ArMeasurementModel> measurements = [
    const ArMeasurementModel(
      id: 'mock-scan-1',
      propertyId: 'test-prop-01',
      roomName: 'Master Suite',
      points: [Offset(0, 0), Offset(20, 0), Offset(20, 15), Offset(0, 15)],
      wallLengthsFt: [20.0, 15.0, 20.0, 15.0],
      areaSqFt: 300.0,
      areaSqMeters: 27.87,
      perimeterFt: 70.0,
      perimeterMeters: 21.33,
      paintCostEstimate: 450.0,
      flooringCostEstimate: 3600.0,
      solarExposure: 'OPTIMAL_SOUTH_WEST',
      createdAt: 1700000000000,
    ),
  ];

  @override
  Future<void> saveMeasurement(ArMeasurementModel measurement) async {
    measurements.add(measurement);
  }

  @override
  Future<List<ArMeasurementModel>> getMeasurements() async {
    return measurements;
  }
}

class MockStagedFurnitureRepository implements StagedFurnitureRepository {
  List<StagedFurnitureModel> stagedItems = [];

  @override
  Future<List<StagedFurnitureModel>> getStagedFurniture(
    String propertyId,
  ) async {
    return stagedItems.where((i) => i.propertyId == propertyId).toList();
  }

  @override
  Future<void> saveStagedFurniture(StagedFurnitureModel item) async {
    final index = stagedItems.indexWhere((i) => i.id == item.id);
    if (index >= 0) {
      stagedItems[index] = item;
    } else {
      stagedItems.add(item);
    }
  }

  @override
  Future<void> removeStagedFurniture(String id) async {
    stagedItems.removeWhere((i) => i.id == id);
  }

  @override
  Future<void> clearStagedFurniture(String propertyId) async {
    stagedItems.removeWhere((i) => i.propertyId == propertyId);
  }
}
