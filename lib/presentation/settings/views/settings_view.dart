import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/utils/app_feedback.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _prefsService = sl<PreferencesService>();
  late bool _isPkr;
  late int _latency;
  late bool _simulate503;

  @override
  void initState() {
    super.initState();
    _isPkr = _prefsService.isPkrCurrency;
    _latency = _prefsService.simulatedLatency;
    _simulate503 = _prefsService.simulateHttp503;
  }

  void _showRecruiterDebugDrawer() {
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colors.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colors.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.bug_report_outlined,
                              color: colors.onSecondaryContainer,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recruiter Engineering Debug Console',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: colors.onSurface,
                                  ),
                                ),
                                Text(
                                  'Simulate network faults, latencies, and price drop triggers',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(),
                      const SizedBox(height: 10),

                      // Simulated Latency Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Simulated Dio Network Latency',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface,
                            ),
                          ),
                          Text(
                            '${_latency}ms',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _latency.toDouble(),
                        min: 100,
                        max: 2000,
                        divisions: 19,
                        activeColor: colors.primary,
                        onChanged: (val) {
                          final newVal = val.round();
                          setModalState(() => _latency = newVal);
                          setState(() => _latency = newVal);
                          _prefsService.setSimulatedLatency(newVal);
                        },
                      ),
                      const SizedBox(height: 10),

                      // Simulate HTTP 503 Fault
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Force HTTP 503 Fault Interception',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          'Tests Dio mock interceptor error boundaries and retry UI',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        value: _simulate503,
                        activeColor: colors.error,
                        onChanged: (val) {
                          setModalState(() => _simulate503 = val);
                          setState(() => _simulate503 = val);
                          _prefsService.setSimulateHttp503(val);
                          AppFeedback.showWarning(
                            context,
                            val
                                ? 'Simulated HTTP 503 fault ACTIVE'
                                : 'HTTP 503 fault cleared',
                          );
                        },
                      ),
                      const SizedBox(height: 10),

                      // Trigger Simulated Price Drop Alert
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.surfaceContainerHighest,
                          foregroundColor: colors.onSurface,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          AppFeedback.showSuccess(
                            context,
                            'SIMULATED ALERT: The Cantilever Courtyard Villa price dropped by 4.5% (\$850,000)!',
                          );
                        },
                        icon: const Icon(
                          Icons.notifications_active_outlined,
                          size: 18,
                        ),
                        label: const Text('Inject Simulated Price-Drop Alert'),
                      ),
                      const SizedBox(height: 8),

                      // Database Statistics Button
                      OutlinedButton.icon(
                        onPressed: () async {
                          final db = await AppDatabase.instance.database;
                          final propCount =
                              Sqflite.firstIntValue(
                                await db.rawQuery(
                                  'SELECT COUNT(*) FROM properties',
                                ),
                              ) ??
                              0;
                          final tourCount =
                              Sqflite.firstIntValue(
                                await db.rawQuery('SELECT COUNT(*) FROM tours'),
                              ) ??
                              0;
                          final scanCount =
                              Sqflite.firstIntValue(
                                await db.rawQuery(
                                  'SELECT COUNT(*) FROM ar_measurements',
                                ),
                              ) ??
                              0;

                          if (context.mounted) {
                            Navigator.of(context).pop();
                            AppFeedback.showInfo(
                              context,
                              'SQLite DB Stats: $propCount Properties, $tourCount Scheduled Tours, $scanCount AR Room Scans.',
                            );
                          }
                        },
                        icon: const Icon(Icons.storage_outlined, size: 18),
                        label: const Text(
                          'Inspect Live SQLite Database Statistics',
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Settings & Preferences',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          // Appearance & Theme Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.palette_outlined,
                      size: 18,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Architectural Theme',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                BlocBuilder<ThemeCubit, ThemeMode>(
                  builder: (context, themeMode) {
                    final isDark = themeMode == ThemeMode.dark;
                    return Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('Obsidian Dark'),
                              ),
                            ),
                            selected: isDark,
                            selectedColor: colors.primaryContainer,
                            labelStyle: TextStyle(
                              color: isDark
                                  ? colors.onPrimaryContainer
                                  : colors.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                context.read<ThemeCubit>().setTheme(
                                  ThemeMode.dark,
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('Gallery Light'),
                              ),
                            ),
                            selected: !isDark,
                            selectedColor: colors.primaryContainer,
                            labelStyle: TextStyle(
                              color: !isDark
                                  ? colors.onPrimaryContainer
                                  : colors.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                context.read<ThemeCubit>().setTheme(
                                  ThemeMode.light,
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Currency Preference Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.currency_exchange,
                      size: 18,
                      color: colors.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Valuation Currency',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('USD (\$)'),
                          ),
                        ),
                        selected: !_isPkr,
                        selectedColor: colors.primaryContainer,
                        labelStyle: TextStyle(
                          color: !_isPkr
                              ? colors.onPrimaryContainer
                              : colors.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _isPkr = false);
                            _prefsService.setCurrency(false);
                            AppFeedback.showSuccess(
                              context,
                              'Valuation currency set to USD (\$).',
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('PKR (Rs)'),
                          ),
                        ),
                        selected: _isPkr,
                        selectedColor: colors.primaryContainer,
                        labelStyle: TextStyle(
                          color: _isPkr
                              ? colors.onPrimaryContainer
                              : colors.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _isPkr = true);
                            _prefsService.setCurrency(true);
                            AppFeedback.showSuccess(
                              context,
                              'Valuation currency set to PKR (Lac/Cr).',
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Native AR Platform Status Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.view_in_ar, size: 18, color: colors.tertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Spatial Native Bridge Status',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'MethodChannel: com.safeer.estateview/ar_spatial\n'
                  'EventChannel: com.safeer.estateview/spatial_telemetry\n'
                  'Target Engine: ARCore v2.4 (Android) / ARKit 6.0 (iOS)\n'
                  'Tracking: Plane Detection + Solar Azimuth Telemetry',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    height: 1.5,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // App Version & Recruiter Secret Drawer Trigger
          Center(
            child: InkWell(
              onLongPress: () {
                _showRecruiterDebugDrawer();
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    Text(
                      AppConstants.appName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${AppConstants.appVersion} • (Long press for Recruiter Console)',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
