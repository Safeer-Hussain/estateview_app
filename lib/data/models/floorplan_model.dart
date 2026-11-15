import 'dart:convert';

import 'package:flutter/material.dart';

class RoomHotspot {
  final String id;
  final String name;
  final double widthFt;
  final double lengthFt;
  final double areaSqFt;
  final String flooringType;
  final String sunOrientation;
  final Offset relativePosition; // (0.0 to 1.0 within floorplan canvas)
  final String description;

  const RoomHotspot({
    required this.id,
    required this.name,
    required this.widthFt,
    required this.lengthFt,
    required this.areaSqFt,
    required this.flooringType,
    required this.sunOrientation,
    required this.relativePosition,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'widthFt': widthFt,
      'lengthFt': lengthFt,
      'areaSqFt': areaSqFt,
      'flooringType': flooringType,
      'sunOrientation': sunOrientation,
      'dx': relativePosition.dx,
      'dy': relativePosition.dy,
      'description': description,
    };
  }

  factory RoomHotspot.fromMap(Map<String, dynamic> map) {
    return RoomHotspot(
      id: map['id'] as String,
      name: map['name'] as String,
      widthFt: (map['widthFt'] as num).toDouble(),
      lengthFt: (map['lengthFt'] as num).toDouble(),
      areaSqFt: (map['areaSqFt'] as num).toDouble(),
      flooringType: map['flooringType'] as String,
      sunOrientation: map['sunOrientation'] as String,
      relativePosition: Offset(
        (map['dx'] as num).toDouble(),
        (map['dy'] as num).toDouble(),
      ),
      description: map['description'] as String,
    );
  }
}

class FloorplanData {
  final String blueprintId;
  final double totalAreaSqFt;
  final List<RoomHotspot> rooms;

  const FloorplanData({
    required this.blueprintId,
    required this.totalAreaSqFt,
    required this.rooms,
  });

  Map<String, dynamic> toMap() {
    return {
      'blueprintId': blueprintId,
      'totalAreaSqFt': totalAreaSqFt,
      'rooms': rooms.map((r) => r.toMap()).toList(),
    };
  }

  factory FloorplanData.fromMap(Map<String, dynamic> map) {
    return FloorplanData(
      blueprintId: map['blueprintId'] as String,
      totalAreaSqFt: (map['totalAreaSqFt'] as num).toDouble(),
      rooms: (map['rooms'] as List<dynamic>)
          .map((r) => RoomHotspot.fromMap(r as Map<String, dynamic>))
          .toList(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory FloorplanData.fromJson(String source) =>
      FloorplanData.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
