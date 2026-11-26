import 'package:estate_view_app/core/di/injection.dart';
import 'package:estate_view_app/core/services/ar_spatial_service.dart';
import 'package:estate_view_app/core/services/connectivity_service.dart';
import 'package:estate_view_app/core/services/gltf_binary_serializer.dart';
import 'package:estate_view_app/core/services/preferences_service.dart';
import 'package:estate_view_app/core/services/spatial_archive_export_service.dart';
import 'package:estate_view_app/core/services/usdz_archive_serializer.dart';
import 'package:estate_view_app/core/theme/theme_cubit.dart';
import 'package:estate_view_app/data/repositories/ar_measurement_repository.dart';
import 'package:estate_view_app/data/repositories/property_repository.dart';
import 'package:estate_view_app/data/repositories/tour_repository.dart';
import 'package:estate_view_app/data/repositories/staged_furniture_repository.dart';
import 'package:estate_view_app/data/repositories/spatial_archive_repository.dart';
import 'package:estate_view_app/presentation/ai_concierge/bloc/ai_concierge_cubit.dart';
import 'package:estate_view_app/presentation/ar_scanner/bloc/ar_spatial_bloc.dart';
import 'package:estate_view_app/presentation/ar_scanner/bloc/furniture_staging_cubit.dart';
import 'package:estate_view_app/presentation/discovery/bloc/property_catalog_bloc.dart';
import 'package:estate_view_app/presentation/neighborhood/bloc/neighborhood_cubit.dart';
import 'package:estate_view_app/presentation/roi_analyzer/bloc/mortgage_roi_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mock_repositories.dart';

Future<void> setupTestLocator() async {
  await sl.reset();

  SharedPreferences.setMockInitialValues({
    'estateview_theme_mode': 'dark',
    'estateview_currency': 'USD',
  });
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  final mockPropRepo = MockPropertyRepository();
  final mockTourRepo = MockTourRepository();
  final mockArRepo = MockArMeasurementRepository();
  final mockFurnitureRepo = MockStagedFurnitureRepository();
  final mockArchiveRepo = MockSpatialArchiveRepository();
  final mockDb = MockAppDatabase();

  sl.registerSingleton<PropertyRepository>(mockPropRepo);
  sl.registerSingleton<TourRepository>(mockTourRepo);
  sl.registerSingleton<ArMeasurementRepository>(mockArRepo);
  sl.registerSingleton<StagedFurnitureRepository>(mockFurnitureRepo);
  sl.registerSingleton<SpatialArchiveRepository>(mockArchiveRepo);

  sl.registerLazySingleton<PreferencesService>(() => PreferencesService(sl()));
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  sl.registerLazySingleton<ArSpatialService>(() => ArSpatialService());
  sl.registerLazySingleton<GltfBinarySerializer>(() => GltfBinarySerializer());
  sl.registerLazySingleton<UsdzArchiveSerializer>(
    () => UsdzArchiveSerializer(),
  );
  sl.registerLazySingleton<SpatialArchiveExportService>(
    () => SpatialArchiveExportService(
      arService: sl(),
      glbSerializer: sl(),
      usdzSerializer: sl(),
    ),
  );

  sl.registerLazySingleton<ThemeCubit>(() => ThemeCubit(sl()));
  sl.registerFactory<PropertyCatalogBloc>(() => PropertyCatalogBloc(sl()));
  sl.registerFactory<NeighborhoodCubit>(() => NeighborhoodCubit());
  sl.registerFactory<ArSpatialBloc>(
    () =>
        ArSpatialBloc(sl(), sl(), exportService: sl(), archiveRepository: sl()),
  );
  sl.registerFactory<FurnitureStagingCubit>(() => FurnitureStagingCubit(sl()));
  sl.registerFactory<MortgageRoiCubit>(() => MortgageRoiCubit());
  sl.registerFactory<AiConciergeCubit>(
    () => AiConciergeCubit(mockDb, sl(), sl(), sl()),
  );
}
