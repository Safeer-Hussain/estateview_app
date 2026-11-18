import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_constants.dart';
import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'presentation/ai_concierge/bloc/ai_concierge_cubit.dart';
import 'presentation/ar_scanner/bloc/ar_spatial_bloc.dart';
import 'presentation/ar_scanner/bloc/furniture_staging_cubit.dart';
import 'presentation/discovery/bloc/property_catalog_bloc.dart';
import 'presentation/neighborhood/bloc/neighborhood_cubit.dart';
import 'presentation/roi_analyzer/bloc/mortgage_roi_cubit.dart';
import 'presentation/splash/splash_view.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint('EstateView FlutterError: ${details.exceptionAsString()}');
      };

      try {
        // Minimal defensive pre-runApp setup
        await setupLocator();
      } catch (e, stack) {
        debugPrint('EstateView setupLocator initialization error: $e\n$stack');
      }

      runApp(const EstateViewApp());
    },
    (error, stackTrace) {
      debugPrint('EstateView Unhandled Zone Error: $error\n$stackTrace');
    },
  );
}

class EstateViewApp extends StatelessWidget {
  const EstateViewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: sl<ThemeCubit>()),
        BlocProvider<PropertyCatalogBloc>(
          create: (_) =>
              sl<PropertyCatalogBloc>()..add(const LoadPropertiesEvent()),
        ),
        BlocProvider<NeighborhoodCubit>(create: (_) => sl<NeighborhoodCubit>()),
        BlocProvider<ArSpatialBloc>(create: (_) => sl<ArSpatialBloc>()),
        BlocProvider<FurnitureStagingCubit>(
          create: (_) => sl<FurnitureStagingCubit>(),
        ),
        BlocProvider<MortgageRoiCubit>(create: (_) => sl<MortgageRoiCubit>()),
        BlocProvider<AiConciergeCubit>(create: (_) => sl<AiConciergeCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: const SplashView(),
          );
        },
      ),
    );
  }
}
