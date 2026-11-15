import 'dart:convert';

import 'package:flutter/material.dart';

class ArMeasurementModel {
  final String id;
  final String propertyId;
  final String roomName;
  final List<Offset> points; // 2D points in viewport space
  final List<double> wallLengthsFt;
  final double areaSqFt;
  final double areaSqMeters;
  final double perimeterFt;
  final double perimeterMeters;
  final double paintCostEstimate;
  final double flooringCostEstimate;
  final String solarExposure;
  final int createdAt;

  const ArMeasurementModel({
    required this.id,
    required this.propertyId,
    required this.roomName,
    required this.points,
    required this.wallLengthsFt,
    required this.areaSqFt,
    required this.areaSqMeters,
    required this.perimeterFt,
    required this.perimeterMeters,
    required this.paintCostEstimate,
    required this.flooringCostEstimate,
    required this.solarExposure,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'property_id': propertyId,
      'room_name': roomName,
      'points_json': jsonEncode(
        points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
      ),
      'wall_lengths_json': jsonEncode(wallLengthsFt),
      'area_sq_ft': areaSqFt,
      'area_sq_meters': areaSqMeters,
      'perimeter_ft': perimeterFt,
      'perimeter_meters': perimeterMeters,
      'paint_cost_estimate': paintCostEstimate,
      'flooring_cost_estimate': flooringCostEstimate,
      'solar_exposure': solarExposure,
      'created_at': createdAt,
    };
  }

  factory ArMeasurementModel.fromMap(Map<String, dynamic> map) {
    final pointsList = map['points_json'] is String
        ? (jsonDecode(map['points_json'] as String) as List<dynamic>)
              .map(
                (p) => Offset(
                  (p['dx'] as num).toDouble(),
                  (p['dy'] as num).toDouble(),
                ),
              )
              .toList()
        : <Offset>[];

    final wallList = map['wall_lengths_json'] is String
        ? (jsonDecode(map['wall_lengths_json'] as String) as List<dynamic>)
              .map((w) => (w as num).toDouble())
              .toList()
        : <double>[];

    return ArMeasurementModel(
      id: map['id'] as String,
      propertyId: map['property_id'] as String,
      roomName: map['room_name'] as String,
      points: pointsList,
      wallLengthsFt: wallList,
      areaSqFt: (map['area_sq_ft'] as num).toDouble(),
      areaSqMeters: (map['area_sq_meters'] as num).toDouble(),
      perimeterFt: (map['perimeter_ft'] as num).toDouble(),
      perimeterMeters: (map['perimeter_meters'] as num).toDouble(),
      paintCostEstimate: (map['paint_cost_estimate'] as num).toDouble(),
      flooringCostEstimate: (map['flooring_cost_estimate'] as num).toDouble(),
      solarExposure: map['solar_exposure'] as String,
      createdAt: map['created_at'] as int,
    );
  }
}
