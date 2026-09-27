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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرمز القديم غير صحيح!')));
      return;
    }
    if (_newPinController.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرمز الجديد يجب أن يكون 4 أرقام!')));
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
      appBar: AppBar(title: const Text('الإعدادات والحماية')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('تغيير رمز الدخول (PIN)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextField(controller: _oldPinController, decoration: const InputDecoration(labelText: 'الرمز القديم (الافتراضي 1234)'), obscureText: true, maxLength: 4, keyboardType: TextInputType.number),
          TextField(controller: _newPinController, decoration: const InputDecoration(labelText: 'الرمز الجديد (4 أرقام)'), obscureText: true, maxLength: 4, keyboardType: TextInputType.number),
          ElevatedButton(onPressed: _changePin, child: const Text('حفظ الرمز الجديد')),
          
          const SizedBox(height: 40),
          const Divider(thickness: 2),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: const [
                Text('Stitten Stores', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text('الإصدار: v2.0'),
                SizedBox(height: 10),
                Text('تصميم وتطوير البرمجيات:', style: TextStyle(fontSize: 16)),
                Text('جلولي مصطفى', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                SizedBox(height: 10),
                Text('يتم حفظ جميع العمليات آلياً في ذاكرة الهاتف لضمان أمان البيانات.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
