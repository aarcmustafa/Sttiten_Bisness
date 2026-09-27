import 'package:flutter/material.dart';
import 'statistics_tab.dart';
import 'management_tab.dart';
import 'settings_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const StatisticsTab(),
    const ManagementTab(),
    const SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'الإحصائيات'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'الإدارة والكريدي'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات وحول'),
        ],
      ),
    );
  }
}
