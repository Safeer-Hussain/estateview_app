import 'dart:convert';

import 'floorplan_model.dart';

class PropertyModel {
  final String id;
  final String title;
  final String subtitle;
  final double priceUsd;
  final double pricePkr;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final int bedrooms;
  final int bathrooms;
  final double areaSqFt;
  final String
  propertyType; // Villa, Penthouse, Townhouse, Commercial, Apartment
  final String listingType; // buy, rent
  final bool isShortlisted;
  final String imageAsset;
  final List<String> amenities;
  final FloorplanData floorplan;
  final String advisorName;
  final String advisorRole;
  final String advisorAvatar;
  final String advisorPhone;
  final int createdAt;

  const PropertyModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.priceUsd,
    required this.pricePkr,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.bedrooms,
    required this.bathrooms,
    required this.areaSqFt,
    required this.propertyType,
    required this.listingType,
    required this.isShortlisted,
    required this.imageAsset,
    required this.amenities,
    required this.floorplan,
    required this.advisorName,
    required this.advisorRole,
    required this.advisorAvatar,
    required this.advisorPhone,
    required this.createdAt,
  });

  PropertyModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    double? priceUsd,
    double? pricePkr,
    String? address,
    String? city,
    double? latitude,
    double? longitude,
    int? bedrooms,
    int? bathrooms,
    double? areaSqFt,
    String? propertyType,
    String? listingType,
    bool? isShortlisted,
    String? imageAsset,
    List<String>? amenities,
    FloorplanData? floorplan,
    String? advisorName,
    String? advisorRole,
    String? advisorAvatar,
    String? advisorPhone,
    int? createdAt,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      priceUsd: priceUsd ?? this.priceUsd,
      pricePkr: pricePkr ?? this.pricePkr,
      address: address ?? this.address,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      areaSqFt: areaSqFt ?? this.areaSqFt,
      propertyType: propertyType ?? this.propertyType,
      listingType: listingType ?? this.listingType,
      isShortlisted: isShortlisted ?? this.isShortlisted,
      imageAsset: imageAsset ?? this.imageAsset,
      amenities: amenities ?? this.amenities,
      floorplan: floorplan ?? this.floorplan,
      advisorName: advisorName ?? this.advisorName,
      advisorRole: advisorRole ?? this.advisorRole,
      advisorAvatar: advisorAvatar ?? this.advisorAvatar,
      advisorPhone: advisorPhone ?? this.advisorPhone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'price_usd': priceUsd,
      'price_pkr': pricePkr,
      'address': address,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area_sq_ft': areaSqFt,
      'property_type': propertyType,
      'listing_type': listingType,
      'is_shortlisted': isShortlisted ? 1 : 0,
      'image_asset': imageAsset,
      'amenities_json': jsonEncode(amenities),
      'floorplan_json': floorplan.toJson(),
      'advisor_json': jsonEncode({
        'name': advisorName,
        'role': advisorRole,
        'avatar': advisorAvatar,
        'phone': advisorPhone,
      }),
      'created_at': createdAt,
    };
  }

  factory PropertyModel.fromMap(Map<String, dynamic> map) {
    final advisorMap = map['advisor_json'] is String
        ? jsonDecode(map['advisor_json'] as String) as Map<String, dynamic>
        : (map['advisor_json'] as Map<String, dynamic>? ?? {});

    final amenitiesList = map['amenities_json'] is String
        ? (jsonDecode(map['amenities_json'] as String) as List<dynamic>)
              .cast<String>()
        : (map['amenities_json'] as List<dynamic>? ?? []).cast<String>();

    final floorplanObj = map['floorplan_json'] is String
        ? FloorplanData.fromJson(map['floorplan_json'] as String)
        : FloorplanData.fromMap(map['floorplan_json'] as Map<String, dynamic>);

    return PropertyModel(
      id: map['id'] as String,
      title: map['title'] as String,
      subtitle: map['subtitle'] as String,
      priceUsd: (map['price_usd'] as num).toDouble(),
      pricePkr: (map['price_pkr'] as num).toDouble(),
      address: map['address'] as String,
      city: map['city'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      bedrooms: map['bedrooms'] as int,
      bathrooms: map['bathrooms'] as int,
      areaSqFt: (map['area_sq_ft'] as num).toDouble(),
      propertyType: map['property_type'] as String,
      listingType: map['listing_type'] as String,
      isShortlisted: (map['is_shortlisted'] as int) == 1,
      imageAsset: map['image_asset'] as String,
      amenities: amenitiesList,
      floorplan: floorplanObj,
      advisorName: advisorMap['name'] as String? ?? 'Sarah Chen',
      advisorRole: advisorMap['role'] as String? ?? 'Principal Advisor',
      advisorAvatar:
          advisorMap['avatar'] as String? ?? 'assets/images/advisor_sarah.png',
      advisorPhone: advisorMap['phone'] as String? ?? '+92 300 8472911',
      createdAt:
          map['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}
