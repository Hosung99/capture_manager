import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../platform/permission_handler.dart';
import '../capture_feed/capture_feed_screen.dart';
import '../category_browser/category_browser_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Request Android permissions on first launch (no-op on macOS)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppPermissionHandler.requestAll(context);
    });
  }

  static const _screens = [
    CaptureFeedScreen(),
    CategoryBrowserScreen(),
    SettingsScreen(),
  ];

  static const _labels = ['피드', '브라우저', '설정'];
  static const _icons = [Icons.photo_library, Icons.grid_view, Icons.settings];

  @override
  Widget build(BuildContext context) {
    if (Platform.isMacOS) {
      return _buildMacOsLayout();
    }
    return _buildAndroidLayout();
  }

  Widget _buildMacOsLayout() {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (var i = 0; i < _labels.length; i++)
                NavigationRailDestination(
                  icon: Icon(_icons[i]),
                  label: Text(_labels[i]),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }

  Widget _buildAndroidLayout() {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: [
          for (var i = 0; i < _labels.length; i++)
            BottomNavigationBarItem(
              icon: Icon(_icons[i]),
              label: _labels[i],
            ),
        ],
      ),
    );
  }
}
