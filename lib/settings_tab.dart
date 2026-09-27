import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({Key? key}) : super(key: key);

  @override
  _SettingsTabState createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool _isPinEnabled = false;
  final TextEditingController _oldPinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPinSettings();
  }

  Future<void> _loadPinSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isPinEnabled = prefs.getBool('is_pin_enabled') ?? false;
    });
  }

  Future<void> _togglePin(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    if (value) {
      // إذا أراد تفعيل القفل، نطلب منه تعيين رمز جديد أولاً
      _showSetPinDialog(prefs);
    } else {
      // إيقاف القفل المباشر
      await prefs.setBool('is_pin_enabled', false);
      setState(() {
        _isPinEnabled = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إلغاء تفعيل قفل التطبيق')),
      );
    }
  }

  void _showSetPinDialog(SharedPreferences prefs) {
    final pinCtrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تعيين رمز قفل جديد', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('أدخل رمز PIN مكون من 4 أرقام لحماية تطبيقك:'),
            const SizedBox(height: 15),
            TextField(
              controller: pinCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '• • • •',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
            onPressed: () async {
              if (pinCtrl.text.length == 4) {
                await prefs.setString('app_pin', pinCtrl.text);
                await prefs.setBool('is_pin_enabled', true);
                setState(() {
                  _isPinEnabled = true;
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تفعيل قفل التطبيق بنجاح!'), backgroundColor: Colors.green),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى إدخال 4 أرقام كاملة')),
                );
              }
            },
            child: const Text('تفعيل القفل', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _changePin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('app_pin') ?? "";

    if (_oldPinController.text != savedPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('الرمز القديم غير صحيح!'), backgroundColor: Colors.red.shade700),
      );
      return;
    }
    if (_newPinController.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرمز الجديد يجب أن يتكون من 4 أرقام!')),
      );
      return;
    }

    await prefs.setString('app_pin', _newPinController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تغيير رمز الحماية بنجاح!'), backgroundColor: Colors.green),
    );
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    activeColor: const Color(0xFF1E3A8A),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('تفعيل قفل التطبيق (PIN)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    subtitle: Text(_isPinEnabled ? 'مفعل (يطلب الرمز عند فتح التطبيق)' : 'معطل (دخول مباشر للتطبيق)'),
                    value: _isPinEnabled,
                    onChanged: _togglePin,
                  ),
                  if (_isPinEnabled) ...[
                    const Divider(height: 30),
                    const Text('تغيير رمز PIN الحالي', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _oldPinController,
                      decoration: const InputDecoration(labelText: 'الرمز القديم', prefixIcon: Icon(Icons.lock_outline)),
                      obscureText: true,
                      maxLength: 4,
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: _newPinController,
                      decoration: const InputDecoration(labelText: 'الرمز الجديد (4 أرقام)', prefixIcon: Icon(Icons.lock_reset)),
                      obscureText: true,
                      maxLength: 4,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
                        onPressed: _changePin,
                        child: const Text('تحديث الرمز', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: const [
                  Icon(Icons.storefront_rounded, size: 40, color: Color(0xFF1E3A8A)),
                  SizedBox(height: 8),
                  Text('Stitten Stores', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  Text('الإصدار الاحترافي v2.0'),
                  Divider(height: 20),
                  Text('تطوير وتصميم البرمجيات:', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 4),
                  Text('جلولي مصطفى', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
