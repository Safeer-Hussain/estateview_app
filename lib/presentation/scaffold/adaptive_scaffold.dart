import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/di/injection.dart';
import '../../core/services/connectivity_service.dart';
import '../ai_concierge/views/ai_concierge_view.dart';
import '../ar_scanner/views/ar_scanner_view.dart';
import '../discovery/views/property_catalog_view.dart';
import '../neighborhood/views/neighborhood_explorer_view.dart';
import '../portfolio/views/portfolio_hub_view.dart';
import '../roi_analyzer/views/mortgage_roi_view.dart';
import '../settings/views/settings_view.dart';

class AdaptiveScaffold extends StatefulWidget {
  const AdaptiveScaffold({super.key});

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  int _currentIndex = 0;
  bool _isOnline = true;

  final List<Widget> _destinations = const [
    PropertyCatalogView(),
    NeighborhoodExplorerView(),
    ArScannerView(),
    MortgageRoiView(),
    AiConciergeView(),
    PortfolioHubView(),
    SettingsView(),
  ];

  final List<String> _titles = const [
    'Curated Portfolios',
    'Neighborhood & Amenities',
    'Native AR Spatial Studio',
    'Mortgage & ROI Cockpit',
    'AI Property Concierge',
    'Saved Portfolio Hub',
    'Settings & Debug',
  ];

  @override
  void initState() {
    super.initState();
    final connService = sl<ConnectivityService>();
    _isOnline = connService.isOnline;
    connService.onConnectivityChanged.listen((online) {
      if (mounted) setState(() => _isOnline = online);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return GestureDetector(
      // Tap outside to unfocus software keyboard anywhere in the app
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: isLandscape ? 36 : kToolbarHeight,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  _titles[_currentIndex],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isLandscape ? 13 : 18,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (!_isOnline)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'OFFLINE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Image.asset(
                AppConstants.iconApp,
                width: isLandscape ? 22 : 28,
                height: isLandscape ? 22 : 28,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.apartment, size: 20, color: colors.primary),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Animated Offline Banner
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _isOnline ? 0 : 34,
              color: colors.secondaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _isOnline
                  ? const SizedBox.shrink()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_off_outlined,
                          size: 16,
                          color: colors.onSecondaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Offline Portfolio Mode - Serving Cached Property Listings, Floorplans & Saved Scans',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colors.onSecondaryContainer,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),

            // Main Content Area (Landscape with NavigationRail vs Portrait with BottomNav)
            Expanded(
              child: isLandscape
                  ? Row(
                      children: [
                        // Compact Left NavigationRail wrapped in SingleChildScrollView + IntrinsicHeight
                        SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: IntrinsicHeight(
                            child: NavigationRail(
                              minWidth: 56,
                              selectedIndex: _currentIndex,
                              labelType: NavigationRailLabelType.none,
                              backgroundColor: colors.surfaceContainer,
                              onDestinationSelected: (index) {
                                setState(() => _currentIndex = index);
                              },
                              destinations: const [
                                NavigationRailDestination(
                                  icon: Icon(Icons.explore_outlined, size: 20),
                                  selectedIcon: Icon(Icons.explore, size: 20),
                                  label: Text('Discover'),
                                ),
                                NavigationRailDestination(
                                  icon: Icon(Icons.map_outlined, size: 20),
                                  selectedIcon: Icon(Icons.map, size: 20),
                                  label: Text('Neighborhood'),
                                ),
                                NavigationRailDestination(
                                  icon: Icon(
                                    Icons.view_in_ar_outlined,
                                    size: 20,
                                  ),
                                  selectedIcon: Icon(
                                    Icons.view_in_ar,
                                    size: 20,
                                  ),
                                  label: Text('AR Studio'),
                                ),
                                NavigationRailDestination(
                                  icon: Icon(
                                    Icons.calculate_outlined,
                                    size: 20,
                                  ),
                                  selectedIcon: Icon(Icons.calculate, size: 20),
                                  label: Text('ROI'),
                                ),
                                NavigationRailDestination(
                                  icon: Icon(
                                    Icons.smart_toy_outlined,
                                    size: 20,
                                  ),
                                  selectedIcon: Icon(Icons.smart_toy, size: 20),
                                  label: Text('AI Concierge'),
                                ),
                                NavigationRailDestination(
                                  icon: Icon(Icons.bookmark_outline, size: 20),
                                  selectedIcon: Icon(Icons.bookmark, size: 20),
                                  label: Text('Portfolio'),
                                ),
                                NavigationRailDestination(
                                  icon: Icon(Icons.settings_outlined, size: 20),
                                  selectedIcon: Icon(Icons.settings, size: 20),
                                  label: Text('Settings'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(child: _destinations[_currentIndex]),
                      ],
                    )
                  : _destinations[_currentIndex],
            ),
          ],
        ),
        bottomNavigationBar: isLandscape
            ? null
            : BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                type: BottomNavigationBarType.fixed,
                selectedFontSize: 11,
                unselectedFontSize: 10,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.explore_outlined),
                    activeIcon: Icon(Icons.explore),
                    label: 'Discover',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.map_outlined),
                    activeIcon: Icon(Icons.map),
                    label: 'Explore',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.view_in_ar_outlined),
                    activeIcon: Icon(Icons.view_in_ar),
                    label: 'AR Scan',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.calculate_outlined),
                    activeIcon: Icon(Icons.calculate),
                    label: 'ROI',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.smart_toy_outlined),
                    activeIcon: Icon(Icons.smart_toy),
                    label: 'Concierge',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.bookmark_outline),
                    activeIcon: Icon(Icons.bookmark),
                    label: 'Portfolio',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings_outlined),
                    activeIcon: Icon(Icons.settings),
                    label: 'Settings',
                  ),
                ],
              ),
      ),
    );
  }
}
