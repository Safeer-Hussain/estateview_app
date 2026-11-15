import 'package:flutter_test/flutter_test.dart';
import 'package:estate_view_app/presentation/discovery/bloc/property_catalog_bloc.dart';

import '../helpers/mock_repositories.dart';

void main() {
  group('PropertyCatalogBloc Unit Tests', () {
    late MockPropertyRepository repository;
    late PropertyCatalogBloc bloc;

    setUp(() {
      repository = MockPropertyRepository();
      bloc = PropertyCatalogBloc(repository);
    });

    tearDown(() {
      bloc.close();
    });

    test(
      '1. Initial state is correct with default filters and loading true',
      () {
        expect(bloc.state.isLoading, isTrue);
        expect(bloc.state.selectedListingType, 'all');
        expect(bloc.state.selectedPropertyType, 'All Types');
        expect(bloc.state.properties, isEmpty);
      },
    );

    test('2. LoadPropertiesEvent loads all properties into state', () async {
      bloc.add(const LoadPropertiesEvent());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<PropertyCatalogState>(
            (s) => s.isLoading && s.properties.isEmpty,
          ),
          predicate<PropertyCatalogState>(
            (s) =>
                !s.isLoading &&
                s.properties.length == 3 &&
                s.allUnfilteredProperties.length == 3,
          ),
        ]),
      );
    });

    test('3. Filter by listing type (buy vs rent) filters correctly', () async {
      bloc.add(const LoadPropertiesEvent());
      await bloc.stream.firstWhere((s) => !s.isLoading);

      bloc.add(const FilterPropertiesEvent(listingType: 'rent'));
      final state = await bloc.stream.first;
      expect(state.properties.length, 1);
      expect(state.properties.first.listingType, 'rent');
      expect(state.properties.first.title, contains('Studio Loft'));
    });

    test('4. Filter by property type filters correctly', () async {
      bloc.add(const LoadPropertiesEvent());
      await bloc.stream.firstWhere((s) => !s.isLoading);

      bloc.add(const FilterPropertiesEvent(propertyType: 'Penthouse'));
      final state = await bloc.stream.first;
      expect(state.properties.length, 1);
      expect(state.properties.first.propertyType, 'Penthouse');
    });

    test(
      '5. Instant shortlist bookmark toggle updates UI immediately',
      () async {
        bloc.add(const LoadPropertiesEvent());
        await bloc.stream.firstWhere((s) => !s.isLoading);

        // Property 'test-prop-02' currently has isShortlisted: false
        expect(
          bloc.state.properties
              .firstWhere((p) => p.id == 'test-prop-02')
              .isShortlisted,
          isFalse,
        );

        bloc.add(const ToggleShortlistEvent('test-prop-02'));
        final state = await bloc.stream.first;

        final updated = state.properties.firstWhere(
          (p) => p.id == 'test-prop-02',
        );
        expect(updated.isShortlisted, isTrue);
        expect(state.shortlistCount, 2);
      },
    );

    test('6. Search query correctly matches address and title', () async {
      bloc.add(const LoadPropertiesEvent());
      await bloc.stream.firstWhere((s) => !s.isLoading);

      bloc.add(const FilterPropertiesEvent(query: 'Sector J'));
      final state = await bloc.stream.first;
      expect(state.properties.length, 1);
      expect(state.properties.first.title, contains('Cantilever'));
    });
  });
}
