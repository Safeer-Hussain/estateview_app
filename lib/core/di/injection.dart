import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../network/api_client.dart';
import '../services/ar_spatial_service.dart';
import '../services/connectivity_service.dart';
import '../services/gltf_binary_serializer.dart';
import '../services/preferences_service.dart';
import '../services/spatial_archive_export_service.dart';
import '../services/usdz_archive_serializer.dart';
import '../theme/theme_cubit.dart';
import '../../data/repositories/property_repository.dart';
import '../../data/repositories/tour_repository.dart';
import '../../data/repositories/ar_measurement_repository.dart';
import '../../data/repositories/staged_furniture_repository.dart';
import '../../data/repositories/spatial_archive_repository.dart';
import '../../presentation/discovery/bloc/property_catalog_bloc.dart';
import '../../presentation/neighborhood/bloc/neighborhood_cubit.dart';
import '../../presentation/ar_scanner/bloc/ar_spatial_bloc.dart';
import '../../presentation/ar_scanner/bloc/furniture_staging_cubit.dart';
import '../../presentation/roi_analyzer/bloc/mortgage_roi_cubit.dart';
import '../../presentation/ai_concierge/bloc/ai_concierge_cubit.dart';

final sl = GetIt.instance;

Future<void> setupLocator() async {
  // SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  // App Database
  final db = AppDatabase.instance;
  sl.registerSingleton<AppDatabase>(db);

  // Core Services
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
  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl(), sl()));

  // Repositories
  sl.registerLazySingleton<PropertyRepository>(() => PropertyRepository(sl()));
  sl.registerLazySingleton<TourRepository>(() => TourRepository(sl()));
  sl.registerLazySingleton<ArMeasurementRepository>(
    () => ArMeasurementRepository(sl()),
  );
  sl.registerLazySingleton<StagedFurnitureRepository>(
    () => StagedFurnitureRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<SpatialArchiveRepository>(
    () => SpatialArchiveRepositoryImpl(sl()),
  );

  // State Management (Theme, BLoCs, Cubits)
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
    () => AiConciergeCubit(sl(), sl(), sl(), sl()),
  );
}
