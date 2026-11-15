import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estate_view_app/core/di/injection.dart';
import 'package:estate_view_app/core/theme/app_theme.dart';
import 'package:estate_view_app/core/theme/theme_cubit.dart';
import 'package:estate_view_app/presentation/ai_concierge/bloc/ai_concierge_cubit.dart';
import 'package:estate_view_app/presentation/ar_scanner/bloc/ar_spatial_bloc.dart';
import 'package:estate_view_app/presentation/discovery/bloc/property_catalog_bloc.dart';
import 'package:estate_view_app/presentation/neighborhood/bloc/neighborhood_cubit.dart';
import 'package:estate_view_app/presentation/roi_analyzer/bloc/mortgage_roi_cubit.dart';
import 'package:estate_view_app/presentation/scaffold/adaptive_scaffold.dart';

import '../helpers/test_locator.dart';

Widget createTestApp() {
  return MultiBlocProvider(
    providers: [
      BlocProvider<ThemeCubit>.value(value: sl<ThemeCubit>()),
      BlocProvider<PropertyCatalogBloc>(
        create: (_) =>
            sl<PropertyCatalogBloc>()..add(const LoadPropertiesEvent()),
      ),
      BlocProvider<NeighborhoodCubit>(create: (_) => sl<NeighborhoodCubit>()),
      BlocProvider<ArSpatialBloc>(create: (_) => sl<ArSpatialBloc>()),
      BlocProvider<MortgageRoiCubit>(create: (_) => sl<MortgageRoiCubit>()),
      BlocProvider<AiConciergeCubit>(create: (_) => sl<AiConciergeCubit>()),
    ],
    child: BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: const AdaptiveScaffold(),
        );
      },
    ),
  );
}

void main() {
  setUp(() async {
    await setupTestLocator();
  });

  tearDown(() {
    sl.reset();
  });

  group('AdaptiveScaffold & Multi-Tab Widget Tests', () {
    testWidgets(
      '1. Renders multi-tab shell without any duplicate Hero tag exceptions',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Verify initial discovery screen rendered
        expect(find.byType(AdaptiveScaffold), findsOneWidget);
        expect(find.text('Curated Portfolios'), findsOneWidget);
        expect(find.byType(BottomNavigationBar), findsOneWidget);

        Finder navBarIcon(IconData icon) => find.descendant(
          of: find.byType(BottomNavigationBar),
          matching: find.byIcon(icon),
        );

        // Navigate to AR Scan Tab (Index 2)
        await tester.tap(navBarIcon(Icons.view_in_ar_outlined));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Native AR Spatial Studio'), findsOneWidget);

        // Navigate to ROI Cockpit Tab (Index 3)
        await tester.tap(navBarIcon(Icons.calculate_outlined));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Mortgage & ROI Cockpit'), findsOneWidget);

        // Navigate to AI Concierge Tab (Index 4)
        await tester.tap(navBarIcon(Icons.smart_toy_outlined));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('AI Property Concierge'), findsOneWidget);

        // Navigate to Portfolio Hub (Index 5)
        await tester.tap(navBarIcon(Icons.bookmark_outline));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Saved Portfolio Hub'), findsOneWidget);

        // Navigate to Settings (Index 6)
        await tester.tap(navBarIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Settings & Debug'), findsOneWidget);

        // Successfully traversed tabs with zero duplicate Hero tag crashes
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '2. Instant Dark / Light Theme Switching updates theme dynamically',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final themeCubit = sl<ThemeCubit>();
        expect(themeCubit.state, ThemeMode.dark);

        // Switch to Light Mode
        await themeCubit.setTheme(ThemeMode.light);
        await tester.pumpAndSettle();
        expect(themeCubit.state, ThemeMode.light);

        // Switch back to Dark Mode
        await themeCubit.toggleTheme();
        await tester.pumpAndSettle();
        expect(themeCubit.state, ThemeMode.dark);

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '3. Zero RenderFlex overflow errors on 800x360 landscape viewport',
      (tester) async {
        // Simulate physical 800x360 landscape mobile screen
        tester.view.physicalSize = const Size(800, 360);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // In landscape, bottom navigation bar is replaced by compact left NavigationRail
        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(BottomNavigationBar), findsNothing);

        // Verify that 800x360 landscape viewport has zero RenderFlex overflow stripes
        expect(tester.takeException(), isNull);

        // Switch to ROI Cockpit in landscape
        await tester.tap(find.byIcon(Icons.calculate_outlined));
        await tester.pumpAndSettle();
        expect(find.text('Mortgage & ROI Cockpit'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
