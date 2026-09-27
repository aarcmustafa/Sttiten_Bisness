import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'management_tab.dart'; // تأكد أن اسم ملف واجهة الإدارة يطابق هذا الاسم

void main() async {
  // 1. ضمان تهيئة بيئة فلاتر قبل ربط أي مكتبات أصلية
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. تهيئة قاعدة بيانات Hive المحلية السريعة
  await Hive.initFlutter();
  
  // 3. فتح صناديق التخزين (Boxes) لضمان جاهزيتها للقراءة والكتابة فور بدء التطبيق
  await Hive.openBox('salesBox');
  await Hive.openBox('suppliersBox');
  await Hive.openBox('customersBox');

  // 4. تشغيل التطبيق
  runApp(const StittenBusinessApp());
}

class StittenBusinessApp extends StatelessWidget {
  const StittenBusinessApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stitten Business',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[100],
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D9488),
          primary: const Color(0xFF0D9488),
        ),
      ),
      // تشغيل واجهة الإدارة والحوصلات التي قمنا ببنائها مباشرة
      home: const ManagementTab(),
    );
  }
}
