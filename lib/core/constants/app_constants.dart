class AppConstants {
  static const String appName = 'EstateView';
  static const String appTagline = 'Architectural PropTech & Spatial Studio';
  static const String appVersion = 'v1.4.2-flagship';

  // Navigation Keys & Hero Tags
  static const String fabPropertyScheduleTour = 'fab_property_schedule_tour';
  static const String fabMapRecenter = 'fab_map_recenter';
  static const String fabArMeasurePoint = 'fab_ar_measure_point';
  static const String fabRoiExportDossier = 'fab_roi_export_dossier';
  static const String fabAiConciergeClear = 'fab_ai_concierge_clear';
  static const String fabArReset = 'fab_ar_reset';
  static const String fabArSaveScan = 'fab_ar_save_scan';
  static const String fabArToggleLidar = 'fab_ar_toggle_lidar';
  static const String fabArToggleEnclosure = 'fab_ar_toggle_enclosure';

  // Method Channels
  static const String arSpatialMethodChannel =
      'com.safeer.estateview/ar_spatial';
  static const String arSpatialEventChannel =
      'com.safeer.estateview/spatial_telemetry';
  static const String arLidarDepthEventChannel =
      'com.safeer.estateview/depth_point_cloud';

  // SharedPreferences Keys
  static const String prefThemeMode = 'estateview_theme_mode';
  static const String prefCurrency = 'estateview_currency';
  static const String prefSimulatedLatency = 'estateview_simulated_latency';
  static const String prefSimulateHttp503 = 'estateview_simulate_http_503';

  // Asset Paths
  static const String iconApp = 'assets/icons/app_icon.png';
  static const String imgVillaCourtyard = 'assets/images/villa_courtyard.png';
  static const String imgPenthouseLoft = 'assets/images/penthouse_loft.png';
  static const String imgCommercialHub = 'assets/images/commercial_hub.png';
  static const String imgSmartTownhouse = 'assets/images/smart_townhouse.png';
  static const String imgBlueprintFloorplan =
      'assets/images/blueprint_floorplan.png';
  static const String imgAdvisorSarah = 'assets/images/advisor_sarah.png';
  static const String imgAdvisorOmar = 'assets/images/advisor_omar.png';
  static const String imgAdvisorElena = 'assets/images/advisor_elena.png';

  // Financial Modeling Defaults
  static const double defaultPriceUsd = 850000.0;
  static const double defaultDownPaymentPercent = 25.0;
  static const double defaultInterestRate = 6.5;
  static const int defaultTenureYears = 20;
  static const double defaultMonthlyRentalIncome = 4800.0;
}
