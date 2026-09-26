import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  // تهيئة نظام Flutter وقاعدة البيانات المحلية Hive
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  // فتح صناديق التخزين (Boxes) لكل قسم لحفظ البيانات بشكل منفصل
  await Hive.openBox('sales_box');
  await Hive.openBox('customers_box');
  await Hive.openBox('purchases_box');
  await Hive.openBox('suppliers_box');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'محلات استيتن',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class SectionConfig {
  final String id;
  final String title;
  final IconData icon;
  final String boxName;
  final Color themeColor;

  const SectionConfig({
    required this.id,
    required this.title,
    required this.icon,
    required this.boxName,
    required this.themeColor,
  });
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  static const String _sampleSvgLogo = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <circle cx="50" cy="50" r="45" fill="#1E88E5" />
  <path d="M30 50 L45 65 L70 35" stroke="white" stroke-width="8" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
</svg>
''';

  final List<SectionConfig> _sections = [
    const SectionConfig(id: 'sales', title: 'المبيعات', icon: Icons.dashboard_rounded, boxName: 'sales_box', themeColor: Color(0xFF1E88E5)),
    const SectionConfig(id: 'customers', title: 'ديون الزبائن', icon: Icons.people_rounded, boxName: 'customers_box', themeColor: Color(0xFF43A047)),
    const SectionConfig(id: 'purchases', title: 'المشتريات', icon: Icons.receipt_long_rounded, boxName: 'purchases_box', themeColor: Color(0xFFFB8C00)),
    const SectionConfig(id: 'suppliers', title: 'الموردون', icon: Icons.local_shipping_rounded, boxName: 'suppliers_box', themeColor: Color(0xFF8E24AA)),
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
      // IndexedStack يحافظ على حالة الشاشات ويمنع السحب الأفقي
      body: IndexedStack(
        index: _selectedIndex,
        children: _sections.map((sec) => SectionView(config: sec)).toList(),
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

class SectionView extends StatelessWidget {
  final SectionConfig config;

  const SectionView({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box(config.boxName).listenable(),
      builder: (context, Box box, _) {
        final items = box.values.toList();

        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              color: config.themeColor.withOpacity(0.1),
              child: Row(
                children: [
                  SvgPicture.string('''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <circle cx="50" cy="50" r="45" fill="${_colorToHex(config.themeColor)}" />
  <path d="M30 50 L45 65 L70 35" stroke="white" stroke-width="8" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
</svg>
''', width: 40, height: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('قسم: ${config.title}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: config.themeColor)),
                        Text('إجمالي العناصر المحفوظة: ${items.length}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _addNewItemDialog(context, box),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('إضافة جديد'),
                    style: ElevatedButton.styleFrom(backgroundColor: config.themeColor, foregroundColor: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('لا توجد بيانات محفوظة حالياً. اضغط على إضافة جديد.'))
                  : ListView.builder(
                      itemCount: items.length,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: config.themeColor.withOpacity(0.2),
                              child: Text('${index + 1}', style: TextStyle(color: config.themeColor)),
                            ),
                            title: Text(items[index].toString()),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => box.deleteAt(index), // حذف العنصر نهائياً من الذاكرة المحلية
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _addNewItemDialog(BuildContext context, Box box) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: FlutterLogo().runtimeType == 0 ? context : context, // Simple Dialog wrapper
      builder: (context) => AlertDialog(
        title: Text('إضافة بيانات جديدة لـ ${config.title}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'اكتب تفاصيل البيانات هنا...'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                box.add(controller.text.trim()); // حفظ البيانات محلياً بشكل دائم
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}
