import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({Key? key}) : super(key: key);

  @override
  _SettingsTabState createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final TextEditingController _oldPinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();

  Future<void> _changePin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('app_pin') ?? "1234";

    if (_oldPinController.text != savedPin) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رمز الـ PIN القديم غير صحيح')));
      return;
    }
    if (_newPinController.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرمز الجديد يجب أن يكون 4 أرقام')));
      return;
    }

    await prefs.setString('app_pin', _newPinController.text);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تغيير رمز القفل بنجاح!')));
    _oldPinController.clear();
    _newPinController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات وحول التطبيق'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('تغيير رمز الحماية (PIN)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextField(controller: _oldPinController, decoration: const InputDecoration(labelText: 'الرمز القديم'), obscureText: true, maxLength: 4),
          TextField(controller: _newPinController, decoration: const InputDecoration(labelText: 'الرمز الجديد (4 أرقام)'), obscureText: true, maxLength: 4),
          ElevatedButton(onPressed: _changePin, child: const Text('تحديث الرمز')),
          const Divider(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                const Text('Stitten Stores', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Text('الإصدار: v2.0.0'),
                const SizedBox(height: 10),
                const Text('تصميم وتطوير البرمجيات:'),
                const Text('جلولي مصطفى', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 10),
                const Text('جميع الحقوق محفوظة © 2026', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
