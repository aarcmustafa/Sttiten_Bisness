import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'management_tab.dart'; // تأكد من مطابقة اسم ملف الواجهة

void main() async {
  // 1. ضروري لتهيئة الربط مع فلاتر قبل تشغيل التطبيق
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. تهيئة قاعدة بيانات Hive المحلية السريعة
  await Hive.initFlutter();
  
  // 3. فتح صناديق التخزين (Boxes) لتخزين البيانات بسلاسة
  await Hive.openBox('salesBox');
  await Hive.openBox('suppliersBox');
  await Hive.openBox('customersBox');
  await Hive.openBox('settingsBox');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sttiten Business',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const ManagementTab(),
    );
  }
}
