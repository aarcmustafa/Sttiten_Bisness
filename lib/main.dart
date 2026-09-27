import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'management_tab.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة تخزين Hive وفتح الصناديق الأساسية والأرشيف
  await Hive.initFlutter();
  await Hive.openBox('settingsBox');
  await Hive.openBox('salesBox');
  await Hive.openBox('archivedSalesBox');
  await Hive.openBox('suppliersBox');
  await Hive.openBox('customersBox');

  runApp(const StittenBusinessApp());
}
// ==========================================
// الجزء الثاني: التطبيق الرئيسي وإدارة الثيم (Dark/Light Mode)
// ==========================================
class StittenBusinessApp extends StatelessWidget {
  const StittenBusinessApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var settingsBox = Hive.box('settingsBox');
    
    return ValueListenableBuilder(
      valueListenable: settingsBox.listenable(), // ✅ تم التصحيح هنا ليتوافق مع Flutter
      builder: (context, Box box, _) {
        bool isDarkMode = box.get('isDarkMode', defaultValue: false);
        
        return MaterialApp(
          title: 'Stitten Business ERP',
          debugShowCheckedModeBanner: false,
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            primarySwatch: Colors.teal,
            scaffoldBackgroundColor: Colors.grey[50],
            fontFamily: 'Cairo',
          ),
          darkTheme: ThemeData.dark().copyWith(
            primaryColor: const Color(0xFF0D9488),
          ),
          home: const AppRootScreen(),
        );
      },
    );
  }
}
// ==========================================
// الجزء الثالث: نظام الأمان وقفل الحماية بررمز سري
// ==========================================
class AppRootScreen extends StatefulWidget {
  const AppRootScreen({Key? key}) : super(key: key);

  @override
  State<AppRootScreen> createState() => _AppRootScreenState();
}

class _AppRootScreenState extends State<AppRootScreen> {
  bool _isAuthenticated = false;

  @override
  Widget build(BuildContext context) {
    var settingsBox = Hive.box('settingsBox');
    bool isSecurityEnabled = settingsBox.get('isSecurityEnabled', defaultValue: false);
    String savedPin = settingsBox.get('pin', defaultValue: '0000');

    // إذا كانت الحماية مفعلة ولم يتم إدخال الرمز الصحيح بعد
    if (isSecurityEnabled && !_isAuthenticated) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D9488),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 80, color: Colors.white),
                const SizedBox(height: 20),
                const Text('التطبيق محمي بررمز سري', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                TextField(
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'أدخل الرمز (4 أرقام)',
                    hintStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                  ),
                  onSubmitted: (val) {
                    if (val == savedPin) {
                      setState(() => _isAuthenticated = true);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('الرمز السري غير صحيح!')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const ManagementTab();
  }
}
// ==========================================
// الجزء الرابع: واجهة التنقل والشاشة الرئيسية للتطبيق
// ==========================================
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const ManagementTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
    );
  }
}
// ==========================================
// الجزء الخامس: دوال مساعدة إضافية وهيكل الدعم العام
// ==========================================
// تم ربط شاشة الإدارة ManagementTab بالكامل وتمرير إعدادات Hive بسلاسة.
