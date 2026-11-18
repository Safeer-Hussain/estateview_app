import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../data/models/property_model.dart';
import '../../data/models/floorplan_model.dart';
import '../../data/models/tour_booking_model.dart';
import '../../data/models/ar_measurement_model.dart';
import '../../data/models/ai_message_model.dart';
import '../../data/models/staged_furniture_model.dart';
import '../constants/app_constants.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('estateview_v2.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE properties (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        subtitle TEXT NOT NULL,
        price_usd REAL NOT NULL,
        price_pkr REAL NOT NULL,
        address TEXT NOT NULL,
        city TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        bedrooms INTEGER NOT NULL,
        bathrooms INTEGER NOT NULL,
        area_sq_ft REAL NOT NULL,
        property_type TEXT NOT NULL,
        listing_type TEXT NOT NULL,
        is_shortlisted INTEGER NOT NULL DEFAULT 0,
        image_asset TEXT NOT NULL,
        amenities_json TEXT NOT NULL,
        floorplan_json TEXT NOT NULL,
        advisor_json TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tours (
        id TEXT PRIMARY KEY,
        property_id TEXT NOT NULL,
        property_title TEXT NOT NULL,
        date TEXT NOT NULL,
        time_slot TEXT NOT NULL,
        tour_type TEXT NOT NULL,
        contact_name TEXT NOT NULL,
        contact_email TEXT NOT NULL,
        contact_phone TEXT NOT NULL,
        notes TEXT,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ar_measurements (
        id TEXT PRIMARY KEY,
        property_id TEXT NOT NULL,
        room_name TEXT NOT NULL,
        points_json TEXT NOT NULL,
        wall_lengths_json TEXT NOT NULL,
        area_sq_ft REAL NOT NULL,
        area_sq_meters REAL NOT NULL,
        perimeter_ft REAL NOT NULL,
        perimeter_meters REAL NOT NULL,
        paint_cost_estimate REAL NOT NULL,
        flooring_cost_estimate REAL NOT NULL,
        solar_exposure TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ai_concierge_messages (
        id TEXT PRIMARY KEY,
        sender TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    await _ensureStagedFurnitureTable(db);
  }

  Future<void> _ensureStagedFurnitureTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS staged_furniture (
        id TEXT PRIMARY KEY,
        property_id TEXT NOT NULL,
        preset_id TEXT NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        width_meters REAL NOT NULL,
        depth_meters REAL NOT NULL,
        height_meters REAL NOT NULL,
        pos_x REAL NOT NULL,
        pos_z REAL NOT NULL,
        rotation_y REAL NOT NULL,
        scale REAL NOT NULL,
        color_hex TEXT NOT NULL,
        price_usd REAL NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  // --- SEEDING METHOD CALLED POST-FRAME IN SPLASH ---
  Future<void> seedInitialDataIfEmpty() async {
    final db = await database;
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM properties',
    );
    final count = Sqflite.firstIntValue(countResult) ?? 0;

    if (count == 0) {
      final batch = db.batch();
      for (final prop in _seedProperties) {
        batch.insert('properties', prop.toMap());
      }
      for (final tour in _seedTours) {
        batch.insert('tours', tour.toMap());
      }
      for (final scan in _seedScans) {
        batch.insert('ar_measurements', scan.toMap());
      }
      await batch.commit(noResult: true);
    }
  }

  // --- PROPERTY QUERIES ---
  Future<List<PropertyModel>> getAllProperties() async {
    final db = await database;
    final maps = await db.query('properties', orderBy: 'created_at DESC');
    return maps.map((m) => PropertyModel.fromMap(m)).toList();
  }

  Future<PropertyModel?> getPropertyById(String id) async {
    final db = await database;
    final maps = await db.query('properties', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return PropertyModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> togglePropertyShortlist(String id, bool isShortlisted) async {
    final db = await database;
    return await db.update(
      'properties',
      {'is_shortlisted': isShortlisted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<PropertyModel>> getShortlistedProperties() async {
    final db = await database;
    final maps = await db.query(
      'properties',
      where: 'is_shortlisted = ?',
      whereArgs: [1],
    );
    return maps.map((m) => PropertyModel.fromMap(m)).toList();
  }

  // --- TOUR QUERIES ---
  Future<int> insertTour(TourBookingModel tour) async {
    final db = await database;
    return await db.insert(
      'tours',
      tour.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TourBookingModel>> getAllTours() async {
    final db = await database;
    final maps = await db.query('tours', orderBy: 'created_at DESC');
    return maps.map((m) => TourBookingModel.fromMap(m)).toList();
  }

  // --- AR MEASUREMENT QUERIES ---
  Future<int> insertArMeasurement(ArMeasurementModel measurement) async {
    final db = await database;
    return await db.insert(
      'ar_measurements',
      measurement.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ArMeasurementModel>> getAllArMeasurements() async {
    final db = await database;
    final maps = await db.query('ar_measurements', orderBy: 'created_at DESC');
    return maps.map((m) => ArMeasurementModel.fromMap(m)).toList();
  }

  // --- AI CONCIERGE MESSAGES ---
  Future<int> insertAiMessage(AiMessageModel msg) async {
    final db = await database;
    return await db.insert(
      'ai_concierge_messages',
      msg.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<AiMessageModel>> getAiMessages() async {
    final db = await database;
    final maps = await db.query(
      'ai_concierge_messages',
      orderBy: 'timestamp ASC',
    );
    return maps.map((m) => AiMessageModel.fromMap(m)).toList();
  }

  Future<void> clearAiMessages() async {
    final db = await database;
    await db.delete('ai_concierge_messages');
  }

  // --- STAGED 3D FURNITURE QUERIES ---
  Future<List<StagedFurnitureModel>> getStagedFurnitureByPropertyId(
    String propertyId,
  ) async {
    final db = await database;
    await _ensureStagedFurnitureTable(db);
    final maps = await db.query(
      'staged_furniture',
      where: 'property_id = ?',
      whereArgs: [propertyId],
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => StagedFurnitureModel.fromMap(m)).toList();
  }

  Future<int> saveStagedFurnitureItem(StagedFurnitureModel item) async {
    final db = await database;
    await _ensureStagedFurnitureTable(db);
    return await db.insert(
      'staged_furniture',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteStagedFurnitureItem(String id) async {
    final db = await database;
    await _ensureStagedFurnitureTable(db);
    return await db.delete(
      'staged_furniture',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearStagedFurnitureForProperty(String propertyId) async {
    final db = await database;
    await _ensureStagedFurnitureTable(db);
    return await db.delete(
      'staged_furniture',
      where: 'property_id = ?',
      whereArgs: [propertyId],
    );
  }

  // --- SEED DATA (22 PROPERTIES ACROSS DHA LAHORE, GULBERG, BAHRIA & GLOBAL HUBS) ---
  static final List<PropertyModel> _seedProperties = [
    PropertyModel(
      id: 'prop-lahore-01',
      title: 'The Cantilever Courtyard Villa',
      subtitle: 'Modernist Brutalist Pavilion with Reflecting Pool',
      priceUsd: 890000.0,
      pricePkr: 248000000.0, // 24.8 Cr
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
      amenities: [
        'Geothermal Heating & Cooling',
        'Private 50ft Lap Pool',
        'Smart Lutron Lighting Matrix',
        '3-Car EV Charging Garage',
        'Solar Roof 25kW Array',
        'Double-Height Living Atrium',
      ],
      floorplan: const FloorplanData(
        blueprintId: 'fp-lahore-01',
        totalAreaSqFt: 6200.0,
        rooms: [
          RoomHotspot(
            id: 'rm-01',
            name: 'Master Suite Sanctuary',
            widthFt: 24.0,
            lengthFt: 20.0,
            areaSqFt: 480.0,
            flooringType: 'Hand-scraped Oak Chevron Parquet',
            sunOrientation: 'South-West Optimal Afternoon Light',
            relativePosition: Offset(0.72, 0.28),
            description: 'En-suite spa bath, walk-in Italian dressing gallery, and direct terrace access.',
          ),
          RoomHotspot(
            id: 'rm-02',
            name: 'Double-Height Living Atrium',
            widthFt: 36.0,
            lengthFt: 28.0,
            areaSqFt: 1008.0,
            flooringType: 'Polished Honed Basalt Slabs',
            sunOrientation: 'South Exposure Daylight Well',
            relativePosition: Offset(0.35, 0.32),
            description: '22-foot cantilevered ceiling with floor-to-ceiling acoustic glass facing courtyard pool.',
          ),
          RoomHotspot(
            id: 'rm-03',
            name: 'Gourmet Chef Kitchen & Dining',
            widthFt: 22.0,
            lengthFt: 18.0,
            areaSqFt: 396.0,
            flooringType: 'Monolithic Terrazzo Seamless Stone',
            sunOrientation: 'East Morning Horizon Light',
            relativePosition: Offset(0.32, 0.74),
            description: 'Sub-Zero & Wolf appliances, quartzite prep island, walk-in butler pantry.',
          ),
          RoomHotspot(
            id: 'rm-04',
            name: 'Terrace & Pool Deck Lounge',
            widthFt: 30.0,
            lengthFt: 22.0,
            areaSqFt: 660.0,
            flooringType: 'Thermal Treated Teak Decking',
            sunOrientation: 'Open Sky Solar Exposure',
            relativePosition: Offset(0.75, 0.72),
            description: 'Outdoor barbecue galley, sunken firepit, flush overflow perimeter pool.',
          ),
        ],
      ),
      advisorName: 'Sarah Chen',
      advisorRole: 'Senior Architectural Portfolio Partner',
      advisorAvatar: AppConstants.imgAdvisorSarah,
      advisorPhone: '+92 300 8472911',
      createdAt: DateTime.now().millisecondsSinceEpoch - 100000,
    ),
    PropertyModel(
      id: 'prop-lahore-02',
      title: 'The Sky Atrium Penthouse',
      subtitle: 'Double-Height Duplex Loft with Panoramic City Horizon',
      priceUsd: 650000.0,
      pricePkr: 181000000.0, // 18.1 Cr
      address: 'Main Boulevard, Gulberg III',
      city: 'Lahore',
      latitude: 31.5120,
      longitude: 74.3480,
      bedrooms: 4,
      bathrooms: 5,
      areaSqFt: 4800.0,
      propertyType: 'Penthouse',
      listingType: 'buy',
      isShortlisted: true,
      imageAsset: AppConstants.imgPenthouseLoft,
      amenities: [
        'Private High-Speed Keycard Elevator',
        'Wrap-Around Observation Terrace',
        'Sonos Architectural Sound Grid',
        '24/7 White-Glove Concierge',
        'Dedicated Heated Wine Cellar',
        'Panoramic City Skyline Views',
      ],
      floorplan: const FloorplanData(
        blueprintId: 'fp-lahore-02',
        totalAreaSqFt: 4800.0,
        rooms: [
          RoomHotspot(
            id: 'rm-p1',
            name: 'Sky Lounge & Grand Salon',
            widthFt: 32.0,
            lengthFt: 24.0,
            areaSqFt: 768.0,
            flooringType: 'Calacatta Gold Marble Slab',
            sunOrientation: 'Panoramic 270-Degree Skyline Exposure',
            relativePosition: Offset(0.40, 0.35),
            description: 'Curtain-wall structural glazing overlooking Gulberg Central Park and city skyline.',
          ),
          RoomHotspot(
            id: 'rm-p2',
            name: 'Primary Penthouse Suite',
            widthFt: 22.0,
            lengthFt: 20.0,
            areaSqFt: 440.0,
            flooringType: 'Natural Smoked Walnut Plank',
            sunOrientation: 'West Sunset Horizon View',
            relativePosition: Offset(0.76, 0.30),
            description: 'Custom acoustic dampening, steam shower sanctuary, dual custom cedar closets.',
          ),
          RoomHotspot(
            id: 'rm-p3',
            name: 'Bespoke Bar & Cigar Lounge',
            widthFt: 18.0,
            lengthFt: 16.0,
            areaSqFt: 288.0,
            flooringType: 'Brushed Brass Inlaid Marble',
            sunOrientation: 'North-East Diffused Ambient Light',
            relativePosition: Offset(0.35, 0.72),
            description: 'Sub-zero undercounter dual wine refrigeration, onyx illuminated bar top.',
          ),
          RoomHotspot(
            id: 'rm-p4',
            name: 'Sky Deck Jacuzzi Terrace',
            widthFt: 26.0,
            lengthFt: 16.0,
            areaSqFt: 416.0,
            flooringType: 'Anti-Slip Basalt Architectural Tile',
            sunOrientation: 'Unobstructed Open Azimuth',
            relativePosition: Offset(0.74, 0.75),
            description: 'Heated infinity hydro-spa with automated perimeter louvered pergola.',
          ),
        ],
      ),
      advisorName: 'Omar Hayat',
      advisorRole: 'Executive Director, Prime Assets',
      advisorAvatar: AppConstants.imgAdvisorOmar,
      advisorPhone: '+92 321 9541200',
      createdAt: DateTime.now().millisecondsSinceEpoch - 200000,
    ),
    PropertyModel(
      id: 'prop-lahore-03',
      title: 'Signature Commercial Tech Hub',
      subtitle: 'LEED Platinum Glass Office Floor with Sky Garden',
      priceUsd: 1450000.0,
      pricePkr: 405000000.0, // 40.5 Cr
      address: 'Sir Syed Road, Gulberg II',
      city: 'Lahore',
      latitude: 31.5280,
      longitude: 74.3540,
      bedrooms: 0,
      bathrooms: 8,
      areaSqFt: 9500.0,
      propertyType: 'Commercial',
      listingType: 'buy',
      isShortlisted: false,
      imageAsset: AppConstants.imgCommercialHub,
      amenities: [
        'Dedicated 10Gbps Fiber Backbone',
        'Tier-3 Server Room Redundancy',
        'Outdoor Landscaped Breakout Terrace',
        'Multi-Zone VRF Clean Air HVAC',
        '18 Reserved Basement Parking Bays',
        'Full Biometric Access System',
      ],
      floorplan: const FloorplanData(
        blueprintId: 'fp-lahore-03',
        totalAreaSqFt: 9500.0,
        rooms: [
          RoomHotspot(
            id: 'rm-c1',
            name: 'Open Collaboration Studio',
            widthFt: 60.0,
            lengthFt: 45.0,
            areaSqFt: 2700.0,
            flooringType: 'Acoustic Raised Floor System with Carpet Tiles',
            sunOrientation: 'North-Facing Glare-Free Ambient Light',
            relativePosition: Offset(0.38, 0.35),
            description: 'Capacity for 80 engineer workstations with integrated underfloor power drops.',
          ),
          RoomHotspot(
            id: 'rm-c2',
            name: 'Boardroom & Immersive Presentation Theater',
            widthFt: 30.0,
            lengthFt: 22.0,
            areaSqFt: 660.0,
            flooringType: 'Sound-absorbent Solid Walnut Inlay',
            sunOrientation: 'East Morning Sunlight with Motorized Shades',
            relativePosition: Offset(0.75, 0.30),
            description: '24-seat conference suite with dual 98-inch 4K displays and beamforming mics.',
          ),
          RoomHotspot(
            id: 'rm-c3',
            name: 'Executive Leadership Suites',
            widthFt: 28.0,
            lengthFt: 20.0,
            areaSqFt: 560.0,
            flooringType: 'Handmade Wool Carpet over Hardwood',
            sunOrientation: 'South-East Natural Luminescence',
            relativePosition: Offset(0.35, 0.72),
            description: 'Private meeting corner, en-suite washroom, and direct terrace access.',
          ),
          RoomHotspot(
            id: 'rm-c4',
            name: 'Rooftop Sky Garden Cafe',
            widthFt: 40.0,
            lengthFt: 25.0,
            areaSqFt: 1000.0,
            flooringType: 'Engineered Weatherproof Porcelain Pavers',
            sunOrientation: 'Full Solar Day Exposure',
            relativePosition: Offset(0.72, 0.72),
            description: 'Barista counter, vertical green wall, and outdoor breakout booths.',
          ),
        ],
      ),
      advisorName: 'Elena Rostova',
      advisorRole: 'Commercial Investment Specialist',
      advisorAvatar: AppConstants.imgAdvisorElena,
      advisorPhone: '+92 304 7710922',
      createdAt: DateTime.now().millisecondsSinceEpoch - 300000,
    ),
    PropertyModel(
      id: 'prop-lahore-04',
      title: 'Nordic Monolith Smart Townhouse',
      subtitle: 'Carbon-Neutral Architectural Residence with Timber Louvers',
      priceUsd: 420000.0,
      pricePkr: 117000000.0, // 11.7 Cr
      address: 'Sector C, Bahria Town',
      city: 'Lahore',
      latitude: 31.3680,
      longitude: 74.1850,
      bedrooms: 4,
      bathrooms: 4,
      areaSqFt: 3800.0,
      propertyType: 'Townhouse',
      listingType: 'buy',
      isShortlisted: false,
      imageAsset: AppConstants.imgSmartTownhouse,
      amenities: [
        'Passive Solar Envelope Design',
        'Smart Triple Glazed Low-E Windows',
        'Rainwater Harvesting Filtration',
        'Integrated Tesla Powerwall 2',
        'Rooftop Herb & Zen Garden',
        'Keyless NFC Entry System',
      ],
      floorplan: const FloorplanData(
        blueprintId: 'fp-lahore-04',
        totalAreaSqFt: 3800.0,
        rooms: [
          RoomHotspot(
            id: 'rm-t1',
            name: 'Nordic Living Room & Hearth',
            widthFt: 24.0,
            lengthFt: 18.0,
            areaSqFt: 432.0,
            flooringType: 'Bleached Scandinavian Ash Hardwood',
            sunOrientation: 'South Morning Warmth',
            relativePosition: Offset(0.35, 0.32),
            description: 'Suspended bioethanol hearth and integrated floor-to-ceiling library.',
          ),
          RoomHotspot(
            id: 'rm-t2',
            name: 'Minimalist Dining & Open Kitchen',
            widthFt: 20.0,
            lengthFt: 16.0,
            areaSqFt: 320.0,
            flooringType: 'Micro-cement Light Grey Coating',
            sunOrientation: 'East Light Channel',
            relativePosition: Offset(0.72, 0.32),
            description: 'Corian seamless countertops with flush induction cooking surface.',
          ),
          RoomHotspot(
            id: 'rm-t3',
            name: 'Primary Bedroom Suite',
            widthFt: 20.0,
            lengthFt: 16.0,
            areaSqFt: 320.0,
            flooringType: 'Warm Oak Plank',
            sunOrientation: 'West Afternoon Glow',
            relativePosition: Offset(0.35, 0.72),
            description: 'Custom slatted timber headboard and walk-in dressing wardrobe.',
          ),
          RoomHotspot(
            id: 'rm-t4',
            name: 'Zen Atrium Patio',
            widthFt: 18.0,
            lengthFt: 14.0,
            areaSqFt: 252.0,
            flooringType: 'River Pebble Inlaid Stone',
            sunOrientation: 'Direct Overhead Skylight',
            relativePosition: Offset(0.72, 0.72),
            description:
                'Indoor Japanese maple tree with automated drip irrigation.',
          ),
        ],
      ),
      advisorName: 'Sarah Chen',
      advisorRole: 'Senior Architectural Portfolio Partner',
      advisorAvatar: AppConstants.imgAdvisorSarah,
      advisorPhone: '+92 300 8472911',
      createdAt: DateTime.now().millisecondsSinceEpoch - 400000,
    ),
    PropertyModel(
      id: 'prop-lahore-05',
      title: 'Minimalist Courtyard Villa Phase 8',
      subtitle: 'Limestone Pavilion with Internal Reflective Water Courtyard',
      priceUsd: 780000.0,
      pricePkr: 217000000.0, // 21.7 Cr
      address: 'Sector Y, Phase 8, DHA',
      city: 'Lahore',
      latitude: 31.4920,
      longitude: 74.4720,
      bedrooms: 5,
      bathrooms: 6,
      areaSqFt: 5500.0,
      propertyType: 'Villa',
      listingType: 'buy',
      isShortlisted: false,
      imageAsset: AppConstants.imgVillaCourtyard,
      amenities: [
        'Central Zen Courtyard with Fountain',
        'Private Cinema Room with 4K Laser',
        'Full Smart KNX Home Automation',
        '4-Vehicle Shaded Motorcourt',
        'Commercial Chef Prep Kitchen',
        'High-Security Perimeter Barrier',
      ],
      floorplan: const FloorplanData(
        blueprintId: 'fp-lahore-05',
        totalAreaSqFt: 5500.0,
        rooms: [
          RoomHotspot(
            id: 'rm-y1',
            name: 'Courtyard Living Salon',
            widthFt: 30.0,
            lengthFt: 24.0,
            areaSqFt: 720.0,
            flooringType: 'Travertine Navona Slab',
            sunOrientation: 'South Exposure Internal Courtyard View',
            relativePosition: Offset(0.38, 0.35),
            description: 'Frameless glass pivot doors opening completely into water courtyard.',
          ),
          RoomHotspot(
            id: 'rm-y2',
            name: 'Grand Dining Pavilion',
            widthFt: 24.0,
            lengthFt: 18.0,
            areaSqFt: 432.0,
            flooringType: 'Travertine Navona Slab',
            sunOrientation: 'East Light Atrium',
            relativePosition: Offset(0.75, 0.32),
            description: 'Custom 14-person bronze inlay dining table setting.',
          ),
          RoomHotspot(
            id: 'rm-y3',
            name: 'Owner Penthouse Wing',
            widthFt: 26.0,
            lengthFt: 20.0,
            areaSqFt: 520.0,
            flooringType: 'Smoked European Walnut',
            sunOrientation: 'South-West Optimal Sunset',
            relativePosition: Offset(0.35, 0.72),
            description:
                'Private salon, dual dressing rooms, freestanding soaking tub.',
          ),
          RoomHotspot(
            id: 'rm-y4',
            name: 'Acoustic Cinema Theater',
            widthFt: 22.0,
            lengthFt: 18.0,
            areaSqFt: 396.0,
            flooringType: 'High-Density Wool Acoustic Carpet',
            sunOrientation: 'Zero Light Bleed Black Box',
            relativePosition: Offset(0.72, 0.72),
            description: '150-inch microperforated acoustic screen with Dolby Atmos 9.4.4 surround.',
          ),
        ],
      ),
      advisorName: 'Omar Hayat',
      advisorRole: 'Executive Director, Prime Assets',
      advisorAvatar: AppConstants.imgAdvisorOmar,
      advisorPhone: '+92 321 9541200',
      createdAt: DateTime.now().millisecondsSinceEpoch - 500000,
    ),
    PropertyModel(
      id: 'prop-lahore-06',
      title: 'Gulberg Glass Pavilion Executive Suite',
      subtitle: 'Ultra-Luxury Rental Residence overlooking Golf Course',
      priceUsd: 3800.0, // Monthly Rent
      pricePkr: 1050000.0, // 10.5 Lac / Month
      address: 'Kasuri Road, Gulberg III',
      city: 'Lahore',
      latitude: 31.5050,
      longitude: 74.3490,
      bedrooms: 3,
      bathrooms: 4,
      areaSqFt: 3100.0,
      propertyType: 'Apartment',
      listingType: 'rent',
      isShortlisted: false,
      imageAsset: AppConstants.imgPenthouseLoft,
      amenities: [
        'Fully Furnished by Molteni&C',
        'Daily Housekeeping Included',
        'Infinity Pool & Steam Spa Access',
        'Complimentary Valet Parking',
        'High-Speed Enterprise Internet',
        'Private Residents Lounge',
      ],
      floorplan: const FloorplanData(
        blueprintId: 'fp-lahore-06',
        totalAreaSqFt: 3100.0,
        rooms: [
          RoomHotspot(
            id: 'rm-g1',
            name: 'Panoramic Living Gallery',
            widthFt: 26.0,
            lengthFt: 20.0,
            areaSqFt: 520.0,
            flooringType: 'Crema Marfil Polished Marble',
            sunOrientation: 'North-East Morning Horizon',
            relativePosition: Offset(0.35, 0.35),
            description: 'Continuous glass curtain wall overlooking Lahore Gymkhana fairway.',
          ),
          RoomHotspot(
            id: 'rm-g2',
            name: 'Executive Suite 01',
            widthFt: 18.0,
            lengthFt: 16.0,
            areaSqFt: 288.0,
            flooringType: 'Natural White Oak',
            sunOrientation: 'East Morning Light',
            relativePosition: Offset(0.72, 0.35),
            description: 'En-suite rain shower, workstation desk, custom acoustic glazing.',
          ),
          RoomHotspot(
            id: 'rm-g3',
            name: 'Open Island Bar & Kitchen',
            widthFt: 20.0,
            lengthFt: 14.0,
            areaSqFt: 280.0,
            flooringType: 'Grey Pietra Stone',
            sunOrientation: 'Ambient Diffused',
            relativePosition: Offset(0.35, 0.72),
            description: 'Miele integrated coffee machine, wine cooler, gas + induction.',
          ),
          RoomHotspot(
            id: 'rm-g4',
            name: 'Balcony Sundeck',
            widthFt: 22.0,
            lengthFt: 10.0,
            areaSqFt: 220.0,
            flooringType: 'Composite Teak Decking',
            sunOrientation: 'Golf Course Breezeway',
            relativePosition: Offset(0.72, 0.72),
            description: 'Lounge seating for four with glass railing for uninterrupted fairway views.',
          ),
        ],
      ),
      advisorName: 'Elena Rostova',
      advisorRole: 'Commercial & Rental Portfolio Specialist',
      advisorAvatar: AppConstants.imgAdvisorElena,
      advisorPhone: '+92 304 7710922',
      createdAt: DateTime.now().millisecondsSinceEpoch - 600000,
    ),
    PropertyModel(
      id: 'prop-lahore-07',
      title: 'The Orchard Modernist Sanctuary',
      subtitle: '1-Acre Estate with Olive Grove & Glass Tea Pavilion',
      priceUsd: 1150000.0,
      pricePkr: 320000000.0, // 32 Cr
      address: 'Main Boulevard, Bahria Orchard',
      city: 'Lahore',
      latitude: 31.3250,
      longitude: 74.1950,
      bedrooms: 6,
      bathrooms: 7,
      areaSqFt: 8500.0,
      propertyType: 'Villa',
      listingType: 'buy',
      isShortlisted: false,
      imageAsset: AppConstants.imgVillaCourtyard,
      amenities: [
        'Private 1-Acre Gated Compound',
        'Olympic Size 25m Swimming Pool',
        'Independent Guest Glass Pavilion',
        'Commercial Organic Kitchen Garden',
        'Full Solar Microgrid with Battery Bank',
        'Private Tennis & Pickleball Court',
      ],
      floorplan: const FloorplanData(
        blueprintId: 'fp-lahore-07',
        totalAreaSqFt: 8500.0,
        rooms: [
          RoomHotspot(
            id: 'rm-o1',
            name: 'Grand Living Atrium',
            widthFt: 40.0,
            lengthFt: 30.0,
            areaSqFt: 1200.0,
            flooringType: 'Brushed Italian Pietra Grey Stone',
            sunOrientation: 'South Courtyard All-Day Luminescence',
            relativePosition: Offset(0.38, 0.35),
            description: 'Triple-height ceiling with exposed laminated timber glulam beams.',
          ),
          RoomHotspot(
            id: 'rm-o2',
            name: 'Garden Dining Conservatory',
            widthFt: 28.0,
            lengthFt: 20.0,
            areaSqFt: 560.0,
            flooringType: 'Brushed Italian Pietra Grey Stone',
            sunOrientation: 'East Light with Orchard Vistas',
            relativePosition: Offset(0.75, 0.32),
            description:
                'Glass-enclosed conservatory with motorized roof louvers.',
          ),
          RoomHotspot(
            id: 'rm-o3',
            name: 'Primary Estate Suite',
            widthFt: 30.0,
            lengthFt: 22.0,
            areaSqFt: 660.0,
            flooringType: 'Smoked European Oak',
            sunOrientation: 'South-West Sunset Horizon',
            relativePosition: Offset(0.35, 0.72),
            description: 'Private terrace overlooking olive orchard, outdoor stone shower.',
          ),
          RoomHotspot(
            id: 'rm-o4',
            name: 'Wellness Spa & Sauna Chamber',
            widthFt: 24.0,
            lengthFt: 18.0,
            areaSqFt: 432.0,
            flooringType: 'Finnish Thermo-Aspen & Granite',
            sunOrientation: 'Diffused Soft Spa Light',
            relativePosition: Offset(0.72, 0.72),
            description: 'Custom Finnish dry sauna, cold plunge basin, and steam shower.',
          ),
        ],
      ),
      advisorName: 'Sarah Chen',
      advisorRole: 'Senior Architectural Portfolio Partner',
      advisorAvatar: AppConstants.imgAdvisorSarah,
      advisorPhone: '+92 300 8472911',
      createdAt: DateTime.now().millisecondsSinceEpoch - 700000,
    ),
    PropertyModel(
      id: 'prop-dubai-01',
      title: 'Burj Canal Duplex Sky Villa',
      subtitle: 'Waterfront Penthouse overlooking Burj Khalifa & Canal',
      priceUsd: 3200000.0,
      pricePkr: 890000000.0, // 89 Cr
      address: 'Marasi Marina, Business Bay',
      city: 'Dubai',
      latitude: 25.1880,
      longitude: 55.2720,
      bedrooms: 4,
      bathrooms: 5,
      areaSqFt: 5800.0,
      propertyType: 'Penthouse',
      listingType: 'buy',
      isShortlisted: true,
      imageAsset: AppConstants.imgPenthouseLoft,
      amenities: [
        'Private Yacht Mooring Berth',
        'Private Rooftop Infinity Lap Pool',
        'Panoramic Burj Khalifa Downtown Views',
        'Rolls Royce Chauffeur Service',
        'Private Cinema & Sound Studio',
        'Direct Marina Boardwalk Access',
      ],
      floorplan: const FloorplanData(
        blueprintId: 'fp-dubai-01',
        totalAreaSqFt: 5800.0,
        rooms: [
          RoomHotspot(
            id: 'rm-d1',
            name: 'Waterfront Grand Salon',
            widthFt: 36.0,
            lengthFt: 26.0,
            areaSqFt: 936.0,
            flooringType: 'Bookmatched Statuario Venato Marble',
            sunOrientation: 'Burj Khalifa North-West Sunset Angle',
            relativePosition: Offset(0.38, 0.35),
            description: 'Double-volume ceilings with floor-to-ceiling glass facing Dubai Canal.',
          ),
          RoomHotspot(
            id: 'rm-d2',
            name: 'Owner Royal Suite',
            widthFt: 26.0,
            lengthFt: 22.0,
            areaSqFt: 572.0,
            flooringType: 'Handmade Silk Carpet & Wenge Wood',
            sunOrientation: 'Downtown Skyline View',
            relativePosition: Offset(0.74, 0.32),
            description: 'Dual marble en-suites, bespoke Poliform walk-in closets, private terrace.',
          ),
          RoomHotspot(
            id: 'rm-d3',
            name: 'Show Kitchen & Champagne Bar',
            widthFt: 22.0,
            lengthFt: 18.0,
            areaSqFt: 396.0,
            flooringType: 'Bookmatched Statuario Venato Marble',
            sunOrientation: 'Ambient Indirect Light',
            relativePosition: Offset(0.35, 0.72),
            description: 'Custom Boffi kitchen cabinetry with Gaggenau 400 series appliances.',
          ),
          RoomHotspot(
            id: 'rm-d4',
            name: 'Marina Horizon Pool Terrace',
            widthFt: 32.0,
            lengthFt: 18.0,
            areaSqFt: 576.0,
            flooringType: 'Travertine Thermal Paver',
            sunOrientation: 'Direct Skyline Sun Exposure',
            relativePosition: Offset(0.72, 0.72),
            description: 'Glass-bottom cantilevered pool hanging over Dubai Canal promenade.',
          ),
        ],
      ),
      advisorName: 'Omar Hayat',
      advisorRole: 'Executive Director, Prime Assets',
      advisorAvatar: AppConstants.imgAdvisorOmar,
      advisorPhone: '+92 321 9541200',
      createdAt: DateTime.now().millisecondsSinceEpoch - 800000,
    ),
    PropertyModel(
      id: 'prop-dubai-02',
      title: 'Palm Jumeirah Cantilever Beachfront Villa',
      subtitle: 'Private Beachfront Access with Glass Courtyard',
      priceUsd: 7800000.0,
      pricePkr: 2170000000.0, // 217 Cr
      address: 'Frond N, Palm Jumeirah',
      city: 'Dubai',
      latitude: 25.1200,
      longitude: 55.1380,
      bedrooms: 6,
      bathrooms: 8,
      areaSqFt: 11200.0,
      propertyType: 'Villa',
      listingType: 'buy',
      isShortlisted: false,
      imageAsset: AppConstants.imgVillaCourtyard,
      amenities: [
        '100ft Private White Sand Beachfront',
        'Private 60ft Infinity Pool to Sea',
        'Submerged Glass Basement Spa',
        'Air-Conditioned 6-Supercar Garage',
        'Rooftop Sunset Lounge & Bar',
        'Private Resident Security Guardhouse',
      ],
      floorplan: const FloorplanData(
        blueprintId: 'fp-dubai-02',
        totalAreaSqFt: 11200.0,
        rooms: [
          RoomHotspot(
            id: 'rm-p1',
            name: 'Beachfront Living Pavilion',
            widthFt: 48.0,
            lengthFt: 32.0,
            areaSqFt: 1536.0,
            flooringType: 'Greek Thassos White Marble',
            sunOrientation: 'Arabian Gulf Sea Horizon',
            relativePosition: Offset(0.38, 0.35),
            description: 'Disappearing sliding glass pockets framing Arabian Gulf horizon.',
          ),
          RoomHotspot(
            id: 'rm-p2',
            name: 'Presidential Master Wing',
            widthFt: 32.0,
            lengthFt: 24.0,
            areaSqFt: 768.0,
            flooringType: 'Natural Smoked French Oak',
            sunOrientation: 'Direct Sea Sunset Horizon',
            relativePosition: Offset(0.75, 0.30),
            description:
                'Direct walkout to beachfront sundeck and private plunge pool.',
          ),
          RoomHotspot(
            id: 'rm-p3',
            name: 'Submerged Aquarium Lounge',
            widthFt: 28.0,
            lengthFt: 20.0,
            areaSqFt: 560.0,
            flooringType: 'Honed Black Granite Slab',
            sunOrientation: 'Under-Pool Natural Ambient Glow',
            relativePosition: Offset(0.35, 0.72),
            description: 'Submerged below the main pool with transparent underwater viewing glass.',
          ),
          RoomHotspot(
            id: 'rm-p4',
            name: 'Private Beach Deck & Cabana',
            widthFt: 40.0,
            lengthFt: 24.0,
            areaSqFt: 960.0,
            flooringType: 'Indonesian Ipe Wood Decking',
            sunOrientation: 'All-Day Sea Breeze & Sun',
            relativePosition: Offset(0.72, 0.72),
            description: 'Private shaded cabana with outdoor shower and direct beach steps.',
          ),
        ],
      ),
      advisorName: 'Omar Hayat',
      advisorRole: 'Executive Director, Prime Assets',
      advisorAvatar: AppConstants.imgAdvisorOmar,
      advisorPhone: '+92 321 9541200',
      createdAt: DateTime.now().millisecondsSinceEpoch - 900000,
    ),
    PropertyModel(
      id: 'prop-nyc-01',
      title: 'Tribeca Cast-Iron Architectural Loft',
      subtitle: 'Historic 1890 Building Reimagined with Modern Concrete Core',
      priceUsd: 4950000.0,
      pricePkr: 1380000000.0,
      address: 'Franklin Street, Tribeca',
      city: 'New York',
      latitude: 40.7180,
      longitude: -74.0080,
      bedrooms: 3,
      bathrooms: 4,
      areaSqFt: 4200.0,
      propertyType: 'Penthouse',
      listingType: 'buy',
      isShortlisted: false,
      imageAsset: AppConstants.imgPenthouseLoft,
      amenities: [
        'Direct Keyed Freight & Passenger Elevator',
        'Original Restored Timber Beams & Columns',
        'Custom Boffi Monolithic Steel Island',
        'Private 1200 SqFt Rooftop Terrace',
        'Acoustically Isolated Music Studio',
        'Radiant Heated Polished Concrete',
      ],
      floorplan: const FloorplanData(
        blueprintId: 'fp-nyc-01',
        totalAreaSqFt: 4200.0,
        rooms: [
          RoomHotspot(
            id: 'rm-n1',
            name: 'Grand Great Room & Gallery',
            widthFt: 42.0,
            lengthFt: 28.0,
            areaSqFt: 1176.0,
            flooringType: 'Polished Architectural Concrete',
            sunOrientation: 'South-Facing Historic Cast-Iron Windows',
            relativePosition: Offset(0.38, 0.35),
            description: 'Exposed 14-foot yellow pine timber ceilings and cast-iron Corinthian capitals.',
          ),
          RoomHotspot(
            id: 'rm-n2',
            name: 'Primary Suite Sanctuary',
            widthFt: 24.0,
            lengthFt: 20.0,
            areaSqFt: 480.0,
            flooringType: 'Reclaimed Wide Plank Heart Pine',
            sunOrientation: 'Quiet North Courtyard Light',
            relativePosition: Offset(0.74, 0.32),
            description: 'Custom steel and fluted glass partitions with monolithic soaking tub.',
          ),
          RoomHotspot(
            id: 'rm-n3',
            name: 'Culinary Steel Laboratory',
            widthFt: 22.0,
            lengthFt: 18.0,
            areaSqFt: 396.0,
            flooringType: 'Polished Architectural Concrete',
            sunOrientation: 'Ambient Diffused',
            relativePosition: Offset(0.35, 0.72),
            description: 'Seamless stainless steel island and custom charcoal oak cabinetry.',
          ),
          RoomHotspot(
            id: 'rm-n4',
            name: 'Private Tribeca Roof Oasis',
            widthFt: 30.0,
            lengthFt: 20.0,
            areaSqFt: 600.0,
            flooringType: 'Bluestone Paver Tiles',
            sunOrientation: '360-Degree Open Sky Exposure',
            relativePosition: Offset(0.72, 0.72),
            description: 'Irrigated birch trees, outdoor kitchen, outdoor gas fireplace.',
          ),
        ],
      ),
      advisorName: 'Elena Rostova',
      advisorRole: 'Commercial & Global Prime Assets',
      advisorAvatar: AppConstants.imgAdvisorElena,
      advisorPhone: '+92 304 7710922',
      createdAt: DateTime.now().millisecondsSinceEpoch - 1000000,
    ),
    PropertyModel(
      id: 'prop-london-01',
      title: 'Kensington Mews Glass-Atrium Residence',
      subtitle:
          'Victorian Facade with Light-Filled Subterranean Wellness Suite',
      priceUsd: 6200000.0,
      pricePkr: 1720000000.0,
      address: 'Kensignton Park Gardens Mews',
      city: 'London',
      latitude: 51.5090,
      longitude: -0.1980,
      bedrooms: 4,
      bathrooms: 5,
      areaSqFt: 4600.0,
      propertyType: 'Townhouse',
      listingType: 'buy',
      isShortlisted: false,
      imageAsset: AppConstants.imgSmartTownhouse,
      amenities: [
        'Basement Swimming Pool with Glass Floor',
        'Automated Turntable Car Lift',
        'Private Wine Cellar Tasting Vault',
        'Full Smart Crestron Integration',
        'Access to Private Kensington Communal Gardens',
        'Integrated Air Purification System',
      ],
      floorplan: const FloorplanData(
        blueprintId: 'fp-london-01',
        totalAreaSqFt: 4600.0,
        rooms: [
          RoomHotspot(
            id: 'rm-l1',
            name: 'Mews Double Reception Room',
            widthFt: 28.0,
            lengthFt: 22.0,
            areaSqFt: 616.0,
            flooringType: 'Smoked Chevron European Oak',
            sunOrientation: 'South Daylight Well',
            relativePosition: Offset(0.38, 0.35),
            description: 'Central multi-storey glass lightwell penetrating down to subterranean pool.',
          ),
          RoomHotspot(
            id: 'rm-l2',
            name: 'Principal Bedroom Floor',
            widthFt: 24.0,
            lengthFt: 18.0,
            areaSqFt: 432.0,
            flooringType: 'Natural Silk Velvet Carpet',
            sunOrientation: 'Mews Front Morning Glow',
            relativePosition: Offset(0.74, 0.32),
            description: 'Full-floor suite with bookmatched marble bathroom and walk-in dressing hall.',
          ),
          RoomHotspot(
            id: 'rm-l3',
            name: 'Kitchen & Family Snug',
            widthFt: 22.0,
            lengthFt: 16.0,
            areaSqFt: 352.0,
            flooringType: 'Portland Stone Flagstones',
            sunOrientation: 'Lightwell Skylight',
            relativePosition: Offset(0.35, 0.72),
            description: 'Bespoke hand-crafted British joinery and natural quartzite countertops.',
          ),
          RoomHotspot(
            id: 'rm-l4',
            name: 'Subterranean Pool & Gym Sanctuary',
            widthFt: 30.0,
            lengthFt: 20.0,
            areaSqFt: 600.0,
            flooringType: 'Textured Flamed Granite',
            sunOrientation: 'Overhead Glass Lightwell',
            relativePosition: Offset(0.72, 0.72),
            description: '10m vitality pool, steam chamber, and dedicated Pilates studio.',
          ),
        ],
      ),
      advisorName: 'Sarah Chen',
      advisorRole: 'Senior Architectural Portfolio Partner',
      advisorAvatar: AppConstants.imgAdvisorSarah,
      advisorPhone: '+92 300 8472911',
      createdAt: DateTime.now().millisecondsSinceEpoch - 1100000,
    ),
    PropertyModel(
      id: 'prop-islamabad-01',
      title: 'Margalla Ridge Brutalist Villa',
      subtitle: 'Board-Formed Concrete Residence with Margalla Hills Panorama',
      priceUsd: 1350000.0,
      pricePkr: 376000000.0,
      address: 'Sector E-7, Hill View Enclave',
      city: 'Islamabad',
      latitude: 33.7290,
      longitude: 73.0450,
      bedrooms: 5,
      bathrooms: 6,
      areaSqFt: 7800.0,
      propertyType: 'Villa',
      listingType: 'buy',
      isShortlisted: false,
      imageAsset: AppConstants.imgVillaCourtyard,
      amenities: [
        'Panoramic Margalla Hills Viewpoints',
        'Board-Formed Exposed Architectural Concrete',
        'Infinity Edge Mountain Cantilever Pool',
        'Private Guard Garrison & Gatehouse',
        'Solar Generation 30kW with Storage',
        'Dedicated Home Cinema & Billiards Hall',
      ],
      floorplan: const FloorplanData(
        blueprintId: 'fp-isb-01',
        totalAreaSqFt: 7800.0,
        rooms: [
          RoomHotspot(
            id: 'rm-m1',
            name: 'Mountain Vista Living Pavilion',
            widthFt: 38.0,
            lengthFt: 26.0,
            areaSqFt: 988.0,
            flooringType: 'Polished Terrazzo with Local River Stone',
            sunOrientation: 'North-East Mountain Horizon',
            relativePosition: Offset(0.38, 0.35),
            description: 'Frameless glass curtain wall looking directly onto the protected Margalla National Park.',
          ),
          RoomHotspot(
            id: 'rm-m2',
            name: 'Master Suite Panoramic Sanctuary',
            widthFt: 28.0,
            lengthFt: 22.0,
            areaSqFt: 616.0,
            flooringType: 'Bleached Himalayan Walnut',
            sunOrientation: 'Morning Sunrise over Margallas',
            relativePosition: Offset(0.74, 0.32),
            description: 'Cantilevered balcony overlooking forest ravine, sunken marble tub.',
          ),
          RoomHotspot(
            id: 'rm-m3',
            name: 'Chef Kitchen & Courtyard Dining',
            widthFt: 24.0,
            lengthFt: 20.0,
            areaSqFt: 480.0,
            flooringType: 'Polished Terrazzo',
            sunOrientation: 'East Light Channel',
            relativePosition: Offset(0.35, 0.72),
            description:
                'Open granite island with separate secondary wet kitchen.',
          ),
          RoomHotspot(
            id: 'rm-m4',
            name: 'Cliffside Infinity Pool & Deck',
            widthFt: 34.0,
            lengthFt: 20.0,
            areaSqFt: 680.0,
            flooringType: 'Natural Slate Pavers',
            sunOrientation: 'Full Natural Sun Exposure',
            relativePosition: Offset(0.72, 0.72),
            description:
                'Cantilevered over the ridge with zero-edge water reflection.',
          ),
        ],
      ),
      advisorName: 'Omar Hayat',
      advisorRole: 'Executive Director, Prime Assets',
      advisorAvatar: AppConstants.imgAdvisorOmar,
      advisorPhone: '+92 321 9541200',
      createdAt: DateTime.now().millisecondsSinceEpoch - 1200000,
    ),
    PropertyModel(
      id: 'prop-karachi-01',
      title: 'Clifton Horizon Seafront Sky Loft',
      subtitle: 'Arabian Sea Panoramic Duplex with Wrap-around Terrace',
      priceUsd: 820000.0,
      pricePkr: 228000000.0,
      address: 'Block 4, Marine Promenade, Clifton',
      city: 'Karachi',
      latitude: 24.8150,
      longitude: 67.0280,
      bedrooms: 4,
      bathrooms: 5,
      areaSqFt: 5100.0,
      propertyType: 'Penthouse',
      listingType: 'buy',
      isShortlisted: false,
      imageAsset: AppConstants.imgPenthouseLoft,
      amenities: [
        'Unobstructed Arabian Sea Ocean Views',
        'Private Keycard Elevator Vestibule',
        'Marine-Grade Anti-Corrosion Materials',
        'Full 100% Backed Generator Power',
        'Private Temperature-Controlled Pool',
        '24/7 Armed Security & Concierge',
      ],
      floorplan: const FloorplanData(
        blueprintId: 'fp-khi-01',
        totalAreaSqFt: 5100.0,
        rooms: [
          RoomHotspot(
            id: 'rm-k1',
            name: 'Oceanfront Grand Salon',
            widthFt: 34.0,
            lengthFt: 24.0,
            areaSqFt: 816.0,
            flooringType: 'Polished Italian Botticino Marble',
            sunOrientation: 'Direct South-West Ocean Sunset',
            relativePosition: Offset(0.38, 0.35),
            description: 'Double-glazed tempered glass resisting marine salt spray and acoustic waves.',
          ),
          RoomHotspot(
            id: 'rm-k2',
            name: 'Master Suite Seaside Wing',
            widthFt: 24.0,
            lengthFt: 20.0,
            areaSqFt: 480.0,
            flooringType: 'Teak Plank Hardwood',
            sunOrientation: 'Ocean Breeze & Sunset Angle',
            relativePosition: Offset(0.74, 0.32),
            description: 'Private oceanfront balcony, dual dressing suites, and Jacuzzi spa.',
          ),
          RoomHotspot(
            id: 'rm-k3',
            name: 'Seafront Breakfast Gallery & Bar',
            widthFt: 22.0,
            lengthFt: 16.0,
            areaSqFt: 352.0,
            flooringType: 'Polished Botticino Marble',
            sunOrientation: 'East Morning Horizon',
            relativePosition: Offset(0.35, 0.72),
            description:
                'Waterfall edge granite breakfast bar seating 8 comfortably.',
          ),
          RoomHotspot(
            id: 'rm-k4',
            name: 'Seaside Sun Deck & Terrace',
            widthFt: 30.0,
            lengthFt: 18.0,
            areaSqFt: 540.0,
            flooringType: 'Anti-Slip Sea Stone Tile',
            sunOrientation: 'All-Day Sea Breeze',
            relativePosition: Offset(0.72, 0.72),
            description: 'Glass-panel parapet with built-in outdoor lounge and gas fireplace.',
          ),
        ],
      ),
      advisorName: 'Elena Rostova',
      advisorRole: 'Commercial & Global Prime Assets',
      advisorAvatar: AppConstants.imgAdvisorElena,
      advisorPhone: '+92 304 7710922',
      createdAt: DateTime.now().millisecondsSinceEpoch - 1300000,
    ),
    PropertyModel(
      id: 'prop-lahore-08',
      title: 'DHA Phase 5 Mid-Century Modern Villa',
      subtitle: 'Restored 1970s Architectural Masterpiece with Courtyard',
      priceUsd: 590000.0,
      pricePkr: 164000000.0,
      address: 'Sector C, Phase 5, DHA',
      city: 'Lahore',
      latitude: 31.4680,
      longitude: 74.3980,
      bedrooms: 4,
      bathrooms: 5,
      areaSqFt: 4500.0,
      propertyType: 'Villa',
      listingType: 'buy',
      isShortlisted: false,
      imageAsset: AppConstants.imgVillaCourtyard,
      amenities: [
        'Mid-Century Clinker Brick Walls',
        'Restored Teak & Terrazzo Finishes',
        'Sunken Living Conversation Pit',
        'Internal Courtyard with Lemon Trees',
        'Full Smart Lighting Conversion',
        '2-Car Underground Port',
      ],
      floorplan: const FloorplanData(
        blueprintId: 'fp-lhr-08',
        totalAreaSqFt: 4500.0,
        rooms: [
          RoomHotspot(
            id: 'rm-mc1',
            name: 'Sunken Conversation Pit & Salon',
            widthFt: 28.0,
            lengthFt: 22.0,
            areaSqFt: 616.0,
            flooringType: 'Mid-Century Emerald Terrazzo',
            sunOrientation: 'South Courtyard Diffused Light',
            relativePosition: Offset(0.38, 0.35),
            description: 'Original 1970s sunken seating pit with central copper hood fireplace.',
          ),
          RoomHotspot(
            id: 'rm-mc2',
            name: 'Primary Courtyard Bedroom',
            widthFt: 22.0,
            lengthFt: 18.0,
            areaSqFt: 396.0,
            flooringType: 'Natural Teak Parquet',
            sunOrientation: 'Morning Lemon Grove Light',
            relativePosition: Offset(0.74, 0.32),
            description:
                'Sliding teak louvers opening into private walled garden.',
          ),
          RoomHotspot(
            id: 'rm-mc3',
            name: 'Open Dining & Teak Bar',
            widthFt: 20.0,
            lengthFt: 16.0,
            areaSqFt: 320.0,
            flooringType: 'Emerald Terrazzo',
            sunOrientation: 'East Light Well',
            relativePosition: Offset(0.35, 0.72),
            description: 'Seamless integration with outdoor courtyard patio.',
          ),
          RoomHotspot(
            id: 'rm-mc4',
            name: 'Courtyard Reflection Pool Patio',
            widthFt: 24.0,
            lengthFt: 18.0,
            areaSqFt: 432.0,
            flooringType: 'Natural Red Clay Pavers',
            sunOrientation: 'Open Overhead Sunlight',
            relativePosition: Offset(0.72, 0.72),
            description: 'Handcrafted ceramic tile water fountain and mature lemon grove.',
          ),
        ],
      ),
      advisorName: 'Sarah Chen',
      advisorRole: 'Senior Architectural Portfolio Partner',
      advisorAvatar: AppConstants.imgAdvisorSarah,
      advisorPhone: '+92 300 8472911',
      createdAt: DateTime.now().millisecondsSinceEpoch - 1400000,
    ),
    PropertyModel(
      id: 'prop-lahore-09',
      title: 'Gulberg Urban Smart Studio Loft',
      subtitle: 'Turnkey Luxury Rental for Tech Executives & Founders',
      priceUsd: 1950.0, // Rent
      pricePkr: 540000.0, // 5.4 Lac / Month
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
      amenities: [
        'High-Speed 1Gbps Dedicated Fiber',
        'Bespoke Herman Miller Workstation',
        'Smart Apple HomeKit Automated Blinds',
        'Gym & Heated Rooftop Pool',
        'Walking Distance to MM Alam Cafes',
        'Biometric Secure Elevator',
      ],
      floorplan: const FloorplanData(
        blueprintId: 'fp-lhr-09',
        totalAreaSqFt: 1450.0,
        rooms: [
          RoomHotspot(
            id: 'rm-st1',
            name: 'Executive Studio & Salon',
            widthFt: 24.0,
            lengthFt: 20.0,
            areaSqFt: 480.0,
            flooringType: 'Brushed Light Oak',
            sunOrientation: 'North-East Diffused Office Light',
            relativePosition: Offset(0.38, 0.35),
            description: 'Integrated dual-monitor desk setup and modular designer seating.',
          ),
          RoomHotspot(
            id: 'rm-st2',
            name: 'Sleeping Sanctuary Alcove',
            widthFt: 16.0,
            lengthFt: 14.0,
            areaSqFt: 224.0,
            flooringType: 'Brushed Light Oak',
            sunOrientation: 'Quiet Ambient',
            relativePosition: Offset(0.74, 0.32),
            description:
                'Acoustic fluted felt sliding doors for complete privacy.',
          ),
          RoomHotspot(
            id: 'rm-st3',
            name: 'Linear Kitchenette & Espresso Bar',
            widthFt: 18.0,
            lengthFt: 10.0,
            areaSqFt: 180.0,
            flooringType: 'Matte Grey Porcelain',
            sunOrientation: 'Ambient',
            relativePosition: Offset(0.35, 0.72),
            description:
                'Integrated compact dishwasher, La Marzocco espresso machine.',
          ),
          RoomHotspot(
            id: 'rm-st4',
            name: 'Sunset Balcony Terrace',
            widthFt: 16.0,
            lengthFt: 8.0,
            areaSqFt: 128.0,
            flooringType: 'Porcelain Paver',
            sunOrientation: 'West Sunset City Lights',
            relativePosition: Offset(0.72, 0.72),
            description:
                'High-top bistro table overlooking vibrant MM Alam skyline.',
          ),
        ],
      ),
      advisorName: 'Omar Hayat',
      advisorRole: 'Executive Director, Prime Assets',
      advisorAvatar: AppConstants.imgAdvisorOmar,
      advisorPhone: '+92 321 9541200',
      createdAt: DateTime.now().millisecondsSinceEpoch - 1500000,
    ),
    PropertyModel(
      id: 'prop-lahore-10',
      title: 'Prism Architectural Prototype Residence',
      subtitle: 'Zero-Energy Net Positive Experimental Pavilion',
      priceUsd: 920000.0,
      pricePkr: 256000000.0,
      address: 'Zone 1, Phase 9 Prism, DHA',
      city: 'Lahore',
      latitude: 31.4250,
      longitude: 74.4550,
      bedrooms: 5,
      bathrooms: 6,
      areaSqFt: 6800.0,
      propertyType: 'Villa',
      listingType: 'buy',
      isShortlisted: false,
      imageAsset: AppConstants.imgVillaCourtyard,
      amenities: [
        'Net-Positive 35kW Bifacial Solar Canopy',
        'Geothermal Earth Tubes for Cooling',
        'Aerated Autoclaved Concrete Insulation',
        'Rainwater Cistern with Mineralization',
        'Smart AI Energy Management Hub',
        'Autonomous Robotic Garden Mower',
      ],
      floorplan: const FloorplanData(
        blueprintId: 'fp-lhr-10',
        totalAreaSqFt: 6800.0,
        rooms: [
          RoomHotspot(
            id: 'rm-pr1',
            name: 'Solar-Passive Living Gallery',
            widthFt: 36.0,
            lengthFt: 24.0,
            areaSqFt: 864.0,
            flooringType: 'Polished Recycled Agglomerate Stone',
            sunOrientation: 'South Solar Heat Sink Slabs',
            relativePosition: Offset(0.38, 0.35),
            description: 'Deep architectural roof overhangs calculating exact solar angles across all four seasons.',
          ),
          RoomHotspot(
            id: 'rm-pr2',
            name: 'Passive Suite Wing',
            widthFt: 24.0,
            lengthFt: 20.0,
            areaSqFt: 480.0,
            flooringType: 'Locally Harvested Kikar Hardwood',
            sunOrientation: 'Morning East Awakening',
            relativePosition: Offset(0.74, 0.32),
            description: 'Natural cross-ventilation ventilation flues maintaining optimal airflow.',
          ),
          RoomHotspot(
            id: 'rm-pr3',
            name: 'Hydronic Clean Kitchen',
            widthFt: 22.0,
            lengthFt: 18.0,
            areaSqFt: 396.0,
            flooringType: 'Polished Recycled Stone',
            sunOrientation: 'North Ambient Diffuse',
            relativePosition: Offset(0.35, 0.72),
            description: 'Induction surfaces powered directly from daytime rooftop solar generation.',
          ),
          RoomHotspot(
            id: 'rm-pr4',
            name: 'Biotop Eco-Swimming Pond',
            widthFt: 32.0,
            lengthFt: 22.0,
            areaSqFt: 704.0,
            flooringType: 'River Sandstone & Wetland Shingle',
            sunOrientation: 'Open Daylight',
            relativePosition: Offset(0.72, 0.72),
            description: 'Chemical-free natural biological filtration pool with aquatic plants.',
          ),
        ],
      ),
      advisorName: 'Sarah Chen',
      advisorRole: 'Senior Architectural Portfolio Partner',
      advisorAvatar: AppConstants.imgAdvisorSarah,
      advisorPhone: '+92 300 8472911',
      createdAt: DateTime.now().millisecondsSinceEpoch - 1600000,
    ),
  ];

  static final List<TourBookingModel> _seedTours = [
    TourBookingModel(
      id: 'tour-01',
      propertyId: 'prop-lahore-01',
      propertyTitle: 'The Cantilever Courtyard Villa',
      date: '2026-11-20',
      timeSlot: '03:00 PM - 04:00 PM',
      tourType: 'In-Person VIP Tour',
      contactName: 'Safeer Hussain',
      contactEmail: 'safeer@estateview.io',
      contactPhone: '+92 300 1234567',
      notes: 'Focus on solar roof capacity, geothermal HVAC inspection, and courtyard structural load.',
      status: 'CONFIRMED',
      createdAt: DateTime.now().millisecondsSinceEpoch - 86400000,
    ),
    TourBookingModel(
      id: 'tour-02',
      propertyId: 'prop-lahore-02',
      propertyTitle: 'The Sky Atrium Penthouse',
      date: '2026-11-22',
      timeSlot: '11:00 AM - 12:00 PM',
      tourType: 'Live 4K Spatial Walkthrough',
      contactName: 'Safeer Hussain',
      contactEmail: 'safeer@estateview.io',
      contactPhone: '+92 300 1234567',
      notes: 'Review sound isolation on double-height glass and elevator keycard protocols.',
      status: 'CONFIRMED',
      createdAt: DateTime.now().millisecondsSinceEpoch - 43200000,
    ),
  ];

  static final List<ArMeasurementModel> _seedScans = [
    ArMeasurementModel(
      id: 'scan-01',
      propertyId: 'prop-lahore-01',
      roomName: 'Master Suite Sanctuary',
      points: const [
        Offset(60, 60),
        Offset(240, 60),
        Offset(240, 200),
        Offset(60, 200),
      ],
      wallLengthsFt: const [24.0, 20.0, 24.0, 20.0],
      areaSqFt: 480.0,
      areaSqMeters: 44.59,
      perimeterFt: 88.0,
      perimeterMeters: 26.82,
      paintCostEstimate: 720.0,
      flooringCostEstimate: 5760.0,
      solarExposure: 'OPTIMAL_SOUTH_WEST',
      createdAt: DateTime.now().millisecondsSinceEpoch - 120000000,
    ),
  ];
}
