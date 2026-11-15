import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/property_model.dart';
import '../../../data/repositories/property_repository.dart';

// EVENTS
abstract class PropertyCatalogEvent {
  const PropertyCatalogEvent();
}

class LoadPropertiesEvent extends PropertyCatalogEvent {
  const LoadPropertiesEvent();
}

class FilterPropertiesEvent extends PropertyCatalogEvent {
  final String? query;
  final String? propertyType;
  final String? listingType;
  final double? maxPriceUsd;
  final int? minBedrooms;

  const FilterPropertiesEvent({
    this.query,
    this.propertyType,
    this.listingType,
    this.maxPriceUsd,
    this.minBedrooms,
  });
}

class ToggleShortlistEvent extends PropertyCatalogEvent {
  final String propertyId;
  const ToggleShortlistEvent(this.propertyId);
}

// STATE
class PropertyCatalogState {
  final bool isLoading;
  final List<PropertyModel> properties;
  final List<PropertyModel> allUnfilteredProperties;
  final String selectedListingType; // 'all', 'buy', 'rent'
  final String selectedPropertyType; // 'All Types', 'Villa', 'Penthouse', 'Townhouse', 'Commercial', 'Apartment'
  final String searchQuery;
  final int minBedrooms;
  final double maxPriceUsd;
  final String? errorMessage;

  const PropertyCatalogState({
    required this.isLoading,
    required this.properties,
    required this.allUnfilteredProperties,
    required this.selectedListingType,
    required this.selectedPropertyType,
    required this.searchQuery,
    required this.minBedrooms,
    required this.maxPriceUsd,
    this.errorMessage,
  });

  List<PropertyModel> get shortlistedProperties =>
      allUnfilteredProperties.where((p) => p.isShortlisted).toList();

  int get shortlistCount => shortlistedProperties.length;

  factory PropertyCatalogState.initial() {
    return const PropertyCatalogState(
      isLoading: true,
      properties: [],
      allUnfilteredProperties: [],
      selectedListingType: 'all',
      selectedPropertyType: 'All Types',
      searchQuery: '',
      minBedrooms: 0,
      maxPriceUsd: 10000000.0,
      errorMessage: null,
    );
  }

  PropertyCatalogState copyWith({
    bool? isLoading,
    List<PropertyModel>? properties,
    List<PropertyModel>? allUnfilteredProperties,
    String? selectedListingType,
    String? selectedPropertyType,
    String? searchQuery,
    int? minBedrooms,
    double? maxPriceUsd,
    String? errorMessage,
  }) {
    return PropertyCatalogState(
      isLoading: isLoading ?? this.isLoading,
      properties: properties ?? this.properties,
      allUnfilteredProperties:
          allUnfilteredProperties ?? this.allUnfilteredProperties,
      selectedListingType: selectedListingType ?? this.selectedListingType,
      selectedPropertyType: selectedPropertyType ?? this.selectedPropertyType,
      searchQuery: searchQuery ?? this.searchQuery,
      minBedrooms: minBedrooms ?? this.minBedrooms,
      maxPriceUsd: maxPriceUsd ?? this.maxPriceUsd,
      errorMessage: errorMessage,
    );
  }
}

// BLOC
class PropertyCatalogBloc
    extends Bloc<PropertyCatalogEvent, PropertyCatalogState> {
  final PropertyRepository _repository;

  PropertyCatalogBloc(this._repository)
    : super(PropertyCatalogState.initial()) {
    on<LoadPropertiesEvent>(_onLoadProperties);
    on<FilterPropertiesEvent>(_onFilterProperties);
    on<ToggleShortlistEvent>(_onToggleShortlist);
  }

  Future<void> _onLoadProperties(
    LoadPropertiesEvent event,
    Emitter<PropertyCatalogState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final all = await _repository.getProperties();
      final filtered = _applyFilters(
        all,
        state.selectedListingType,
        state.selectedPropertyType,
        state.searchQuery,
        state.minBedrooms,
        state.maxPriceUsd,
      );
      emit(
        state.copyWith(
          isLoading: false,
          properties: filtered,
          allUnfilteredProperties: all,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load properties: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onFilterProperties(
    FilterPropertiesEvent event,
    Emitter<PropertyCatalogState> emit,
  ) async {
    final newListing = event.listingType ?? state.selectedListingType;
    final newType = event.propertyType ?? state.selectedPropertyType;
    final newQuery = event.query ?? state.searchQuery;
    final newBeds = event.minBedrooms ?? state.minBedrooms;
    final newPrice = event.maxPriceUsd ?? state.maxPriceUsd;

    final filtered = _applyFilters(
      state.allUnfilteredProperties,
      newListing,
      newType,
      newQuery,
      newBeds,
      newPrice,
    );

    emit(
      state.copyWith(
        properties: filtered,
        selectedListingType: newListing,
        selectedPropertyType: newType,
        searchQuery: newQuery,
        minBedrooms: newBeds,
        maxPriceUsd: newPrice,
      ),
    );
  }

  Future<void> _onToggleShortlist(
    ToggleShortlistEvent event,
    Emitter<PropertyCatalogState> emit,
  ) async {
    // 1. Instant immutable update so UI reflects on the very first tap
    final updatedAll = state.allUnfilteredProperties.map((p) {
      if (p.id == event.propertyId) {
        return p.copyWith(isShortlisted: !p.isShortlisted);
      }
      return p;
    }).toList();

    final updatedFiltered = state.properties.map((p) {
      if (p.id == event.propertyId) {
        return p.copyWith(isShortlisted: !p.isShortlisted);
      }
      return p;
    }).toList();

    emit(
      state.copyWith(
        properties: updatedFiltered,
        allUnfilteredProperties: updatedAll,
      ),
    );

    // 2. Persist to sqflite
    final target = updatedAll.firstWhere((p) => p.id == event.propertyId);
    await _repository.toggleShortlist(event.propertyId, target.isShortlisted);
  }

  List<PropertyModel> _applyFilters(
    List<PropertyModel> items,
    String listingType,
    String propertyType,
    String query,
    int minBeds,
    double maxPrice,
  ) {
    return items.where((p) {
      if (listingType != 'all' &&
          p.listingType.toLowerCase() != listingType.toLowerCase()) {
        return false;
      }
      if (propertyType != 'All Types' &&
          p.propertyType.toLowerCase() != propertyType.toLowerCase()) {
        return false;
      }
      if (minBeds > 0 && p.bedrooms < minBeds) {
        return false;
      }
      if (p.priceUsd > maxPrice) {
        return false;
      }
      if (query.trim().isNotEmpty) {
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
}
