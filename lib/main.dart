import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickNav App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class SectionData {
  final String id;
  final String title;
  final IconData icon;
  final String svgString;
  final Color themeColor;
  final List<String> items;

  const SectionData({
    required this.id,
    required this.title,
    required this.icon,
    required this.svgString,
    required this.themeColor,
    required this.items,
  });
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // رسمة SVG للـ Vector Icon
  static const String _sampleSvgLogo = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <circle cx="50" cy="50" r="45" fill="#1E88E5" />
  <path d="M30 50 L45 65 L70 35" stroke="white" stroke-width="8" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
</svg>
''';

  // هيكل البيانات المحسن
  static final List<SectionData> _sections = [
    SectionData(
      id: 'dashboard',
      title: 'الرئيسية',
      icon: Icons.dashboard_rounded,
      svgString: _sampleSvgLogo,
      themeColor: const Color(0xFF1E88E5),
      items: List.generate(20, (i) => 'بيانات قسم الرئيسية - عنصر ${i + 1}'),
    ),
    SectionData(
      id: 'analytics',
      title: 'التحليلات',
      icon: Icons.analytics_rounded,
      svgString: _sampleSvgLogo,
      themeColor: const Color(0xFF43A047),
      items: List.generate(20, (i) => 'بيانات قسم التحليلات - عنصر ${i + 1}'),
    ),
    SectionData(
      id: 'archive',
      title: 'الأرشيف',
      icon: Icons.inventory_2_rounded,
      svgString: _sampleSvgLogo,
      themeColor: const Color(0xFFFB8C00),
      items: List.generate(20, (i) => 'بيانات قسم الأرشيف - عنصر ${i + 1}'),
    ),
    SectionData(
      id: 'settings',
      title: 'الإعدادات',
      icon: Icons.settings_rounded,
      svgString: _sampleSvgLogo,
      themeColor: const Color(0xFF8E24AA),
      items: List.generate(20, (i) => 'إعدادات النظام - خيار ${i + 1}'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentSection = _sections[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(currentSection.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: currentSection.themeColor,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SvgPicture.string(_sampleSvgLogo, width: 32, height: 32),
          ),
        ],
      ),
      // IndexedStack يمنع تحريك الشاشة لسحب الصورة ويضمن تنقل فوري دون إعادة بناء
      body: IndexedStack(
        index: _selectedIndex,
        children: _sections.map((sec) => SectionContentView(section: sec)).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: _sections.map((sec) {
          return NavigationDestination(
            icon: Icon(sec.icon),
            label: sec.title,
          );
        }).toList(),
      ),
    );
  }
}

class SectionContentView extends StatelessWidget {
  final SectionData section;

  const SectionContentView({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // رأس ثابت لكل قسم (بدون قابلية للسحب أو التحريك)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          color: section.themeColor.withOpacity(0.1),
          child: Row(
            children: [
              SvgPicture.string(section.svgString, width: 40, height: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAlignment.start,
                  children: [
                    Text(
                      'قسم: ${section.title}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: section.themeColor),
                    ),
                    const Text('معالجة فورية وسريعة للبيانات في الذاكرة', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
        // عرض البيانات باستخدام ListView.builder لأفضل أداء للملايين من العناصر
        Expanded(
          child: ListView.builder(
            itemCount: section.items.length,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: section.themeColor.withOpacity(0.2),
                    child: Text('${index + 1}', style: TextStyle(color: section.themeColor)),
                  ),
                  title: Text(section.items[index]),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
