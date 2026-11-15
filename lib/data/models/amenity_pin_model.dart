import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum AmenityType { school, hospital, transit, park }

class AmenityPinModel {
  final String id;
  final String name;
  final AmenityType type;
  final LatLng position;
  final String address;
  final double distanceKm;

  const AmenityPinModel({
    required this.id,
    required this.name,
    required this.type,
    required this.position,
    required this.address,
    this.distanceKm = 0.0,
  });

  AmenityPinModel copyWithDistance(double dist) {
    return AmenityPinModel(
      id: id,
      name: name,
      type: type,
      position: position,
      address: address,
      distanceKm: dist,
    );
  }

  IconData get icon {
    switch (type) {
      case AmenityType.school:
        return Icons.school_outlined;
      case AmenityType.hospital:
        return Icons.local_hospital_outlined;
      case AmenityType.transit:
        return Icons.directions_subway_outlined;
      case AmenityType.park:
        return Icons.park_outlined;
    }
  }

  String get typeLabel {
    switch (type) {
      case AmenityType.school:
        return 'School & University';
      case AmenityType.hospital:
        return 'Medical & Hospital';
      case AmenityType.transit:
        return 'Metro & Transit';
      case AmenityType.park:
        return 'Park & Country Club';
    }
  }
}
