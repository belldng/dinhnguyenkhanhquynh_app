import 'package:flutter/material.dart';
import '../app_rules_and_focus/app_rules_and_focus_tab.dart';
import '../location_tracking/live_map_screen.dart';
import '../parent_dashboard/child_overview_tab.dart';
import '../sensor_monitoring/sensor_monitoring_tab.dart';
import 'parent_settings_tab.dart';

class ParentMainScaffold extends StatefulWidget {
  const ParentMainScaffold({super.key});

  @override
  State<ParentMainScaffold> createState() => _ParentMainScaffoldState();
}

class _ParentMainScaffoldState extends State<ParentMainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ChildOverviewTab(),
    LiveMapScreen(),
    AppRulesAndFocusTab(),
    SensorMonitoringTab(),
    ParentSettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Tổng quan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_rounded),
            label: 'Vị trí GPS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.rule_folder_rounded),
            label: 'Quy tắc',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sensors_rounded),
            label: 'Cảm biến',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}
