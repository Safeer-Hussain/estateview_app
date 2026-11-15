import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/utils/geo_math.dart';
import '../../../data/models/amenity_pin_model.dart';
import '../../../data/models/property_model.dart';

class NeighborhoodState {
  final PropertyModel? selectedProperty;
  final double searchRadiusKm;
  final Set<AmenityType> activeAmenityTypes;
  final List<AmenityPinModel> surroundingAmenities;
  final LatLng mapCenter;
  final double currentZoom;

  const NeighborhoodState({
    required this.selectedProperty,
    required this.searchRadiusKm,
    required this.activeAmenityTypes,
    required this.surroundingAmenities,
    required this.mapCenter,
    required this.currentZoom,
  });

  factory NeighborhoodState.initial() {
    return const NeighborhoodState(
      selectedProperty: null,
      searchRadiusKm: 5.0,
      activeAmenityTypes: {
        AmenityType.school,
        AmenityType.hospital,
        AmenityType.transit,
        AmenityType.park,
      },
      surroundingAmenities: [],
      mapCenter: LatLng(31.4720, 74.4390), // Lahore DHA
      currentZoom: 13.0,
    );
  }

  NeighborhoodState copyWith({
    PropertyModel? selectedProperty,
    double? searchRadiusKm,
    Set<AmenityType>? activeAmenityTypes,
    List<AmenityPinModel>? surroundingAmenities,
    LatLng? mapCenter,
    double? currentZoom,
  }) {
    return NeighborhoodState(
      selectedProperty: selectedProperty ?? this.selectedProperty,
      searchRadiusKm: searchRadiusKm ?? this.searchRadiusKm,
      activeAmenityTypes: activeAmenityTypes ?? this.activeAmenityTypes,
      surroundingAmenities: surroundingAmenities ?? this.surroundingAmenities,
      mapCenter: mapCenter ?? this.mapCenter,
      currentZoom: currentZoom ?? this.currentZoom,
    );
  }
}

class NeighborhoodCubit extends Cubit<NeighborhoodState> {
  NeighborhoodCubit() : super(NeighborhoodState.initial());

  // Comprehensive points of interest around major hubs
  static final List<AmenityPinModel> _masterAmenityCatalog = [
    // DHA Lahore Area Amenities
    const AmenityPinModel(
      id: 'sch-01',
      name: 'Lahore Grammar School Phase 5',
      type: AmenityType.school,
      position: LatLng(31.4740, 74.4120),
      address: 'Sector G, Phase 5, DHA',
    ),
    const AmenityPinModel(
      id: 'sch-02',
      name: 'LUMS (Lahore Univ of Management Sciences)',
      type: AmenityType.school,
      position: LatLng(31.4705, 74.4095),
      address: 'DHA Phase 5, Opposite Sector U',
    ),
    const AmenityPinModel(
      id: 'hosp-01',
      name: 'National Hospital & Medical Centre',
      type: AmenityType.hospital,
      position: LatLng(31.4820, 74.3980),
      address: 'L-Block, DHA Phase 1',
    ),
    const AmenityPinModel(
      id: 'hosp-02',
      name: 'Aga Khan University Medical Centre',
      type: AmenityType.hospital,
      position: LatLng(31.4710, 74.4420),
      address: 'Commercial Broadway, Phase 8',
    ),
    const AmenityPinModel(
      id: 'trans-01',
      name: 'Lahore Ring Road Interchange M-11',
      type: AmenityType.transit,
      position: LatLng(31.4650, 74.4550),
      address: 'Ring Road Phase 6 Entry',
    ),
    const AmenityPinModel(
      id: 'trans-02',
      name: 'Allama Iqbal International Airport Terminal',
      type: AmenityType.transit,
      position: LatLng(31.5210, 74.4030),
      address: 'Airport Access Road',
    ),
    const AmenityPinModel(
      id: 'park-01',
      name: 'DHA Country & Golf Club',
      type: AmenityType.park,
      position: LatLng(31.4580, 74.4480),
      address: 'Phase 6 Sector K, DHA',
    ),
    const AmenityPinModel(
      id: 'park-02',
      name: 'Sector J Central Botanical Park',
      type: AmenityType.park,
      position: LatLng(31.4750, 74.4360),
      address: 'Sector J, Phase 6, DHA',
    ),

    // Gulberg Area Amenities
    const AmenityPinModel(
      id: 'sch-03',
      name: 'Beaconhouse Liberty Campus',
      type: AmenityType.school,
      position: LatLng(31.5160, 74.3460),
      address: 'Gulberg III, Near Liberty',
    ),
    const AmenityPinModel(
      id: 'hosp-03',
      name: 'Doctors Hospital & Medical Centre',
      type: AmenityType.hospital,
      position: LatLng(31.5120, 74.3310),
      address: 'Canal Bank Road, Gulberg',
    ),
    const AmenityPinModel(
      id: 'trans-03',
      name: 'Kalma Chowk Metrobus Station',
      type: AmenityType.transit,
      position: LatLng(31.5030, 74.3330),
      address: 'Ferozepur Road Interchange',
    ),
    const AmenityPinModel(
      id: 'park-03',
      name: 'Lahore Gymkhana & Golf Grounds',
      type: AmenityType.park,
      position: LatLng(31.5240, 74.3590),
      address: 'Upper Mall / Gulberg Border',
    ),

    // Bahria Town Area Amenities
    const AmenityPinModel(
      id: 'sch-04',
      name: 'Mazhar Bard College Bahria',
      type: AmenityType.school,
      position: LatLng(31.3650, 74.1820),
      address: 'Sector C, Bahria Town',
    ),
    const AmenityPinModel(
      id: 'hosp-04',
      name: 'Bahria International Hospital',
      type: AmenityType.hospital,
      position: LatLng(31.3710, 74.1880),
      address: 'Takbeer Block, Sector B',
    ),
    const AmenityPinModel(
      id: 'park-04',
      name: 'Eiffel Tower Theme Park & Gardens',
      type: AmenityType.park,
      position: LatLng(31.3620, 74.1860),
      address: 'Sector C Plaza, Bahria Town',
    ),
  ];

  void selectProperty(PropertyModel property) {
    final center = LatLng(property.latitude, property.longitude);
    final filtered = _filterAmenities(
      center,
      state.searchRadiusKm,
      state.activeAmenityTypes,
    );
    emit(
      state.copyWith(
        selectedProperty: property,
        mapCenter: center,
        surroundingAmenities: filtered,
        currentZoom: 13.5,
      ),
    );
  }

  void setRadius(double radiusKm) {
    if (state.selectedProperty == null) {
      emit(state.copyWith(searchRadiusKm: radiusKm));
      return;
    }
    final center = LatLng(
      state.selectedProperty!.latitude,
      state.selectedProperty!.longitude,
    );
    final filtered = _filterAmenities(
      center,
      radiusKm,
      state.activeAmenityTypes,
    );
    emit(
      state.copyWith(searchRadiusKm: radiusKm, surroundingAmenities: filtered),
    );
  }

  void toggleAmenityLayer(AmenityType type) {
    final updated = Set<AmenityType>.from(state.activeAmenityTypes);
    if (updated.contains(type)) {
      if (updated.length > 1) {
        updated.remove(type);
      }
    } else {
      updated.add(type);
    }

    if (state.selectedProperty != null) {
      final center = LatLng(
        state.selectedProperty!.latitude,
        state.selectedProperty!.longitude,
      );
      final filtered = _filterAmenities(center, state.searchRadiusKm, updated);
      emit(
        state.copyWith(
          activeAmenityTypes: updated,
          surroundingAmenities: filtered,
        ),
      );
    } else {
      emit(state.copyWith(activeAmenityTypes: updated));
    }
  }

  List<AmenityPinModel> _filterAmenities(
    LatLng center,
    double radiusKm,
    Set<AmenityType> types,
  ) {
    final list = <AmenityPinModel>[];
    for (final item in _masterAmenityCatalog) {
      if (!types.contains(item.type)) continue;

      final dist = GeoMath.haversineDistanceKm(
        center.latitude,
        center.longitude,
        item.position.latitude,
        item.position.longitude,
      );

      if (dist <= radiusKm) {
        list.add(item.copyWithDistance(dist));
      }
    }
    list.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return list;
  }
}
