import 'package:flutter/material.dart';
import 'screens/lock_screen.dart';

void main() {
  runApp(const StittenStoresApp());
}

class StittenStoresApp extends StatelessWidget {
  const StittenStoresApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stitten Stores',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LockScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({Key? key}) : super(key: key);

  @override
  _LockScreenState createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController _pinController = TextEditingController();
  String _savedPin = "1234";

  @override
  void initState() {
    super.initState();
    _loadPin();
  }

  Future<void> _loadPin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedPin = prefs.getString('app_pin') ?? "1234";
    });
  }

  void _verifyPin() {
    if (_pinController.text == _savedPin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رمز الحماية غير صحيح! (الافتراضي: 1234)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('قفل الحماية الآمن', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 10),
                  const Text('أدخل رمز الـ PIN الخاص بك'),
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(hintText: '****'),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: _verifyPin,
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(45)),
                    child: const Text('فتح التطبيق'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
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
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatisticsTab extends StatefulWidget {
  const StatisticsTab({Key? key}) : super(key: key);

  @override
  _StatisticsTabState createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<StatisticsTab> {
  double totalCustomersDebt = 0;
  double totalSuppliersDebt = 0;
  int employeeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    
    final customersData = prefs.getStringList('customers_list') ?? [];
    double custDebt = 0;
    int empCount = 0;
    for (var item in customersData) {
      final Map<String, dynamic> data = jsonDecode(item);
      custDebt += (data['amount'] ?? 0.0);
      if (data['isEmp'] == true) empCount++;
    }

    final suppliersData = prefs.getStringList('suppliers_list') ?? [];
    double supDebt = 0;
    for (var item in suppliersData) {
      final Map<String, dynamic> data = jsonDecode(item);
      supDebt += (data['debt'] ?? 0.0);
    }

    setState(() {
      totalCustomersDebt = custDebt;
      totalSuppliersDebt = supDebt;
      employeeCount = empCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة الإحصائيات المتقدمة'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (employeeCount > 0)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade200)),
                child: Text(
                  'تنبيه: لديك حسابات لـ $employeeCount موظف تحتاج للمراجعة وتخليص الشهر!',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            const Text('ملخص الأداء المالي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildStatCard('إجمالي ديون الزبائن والكريدي', '$totalCustomersDebt دج', Colors.blue),
            _buildStatCard('إجمالي ديون الموردين', '$totalSuppliersDebt دج', Colors.orange),
            _buildStatCard('صافي الحركة المالية', '${totalCustomersDebt - totalSuppliersDebt} دج', Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManagementTab extends StatefulWidget {
  const ManagementTab({Key? key}) : super(key: key);

  @override
  _ManagementTabState createState() => _ManagementTabState();
}

class _ManagementTabState extends State<ManagementTab> {
  List<Map<String, dynamic>> suppliers = [];
  List<Map<String, dynamic>> customers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      suppliers = (prefs.getStringList('suppliers_list') ?? []).map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
      customers = (prefs.getStringList('customers_list') ?? []).map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('suppliers_list', suppliers.map((e) => jsonEncode(e)).toList());
    await prefs.setStringList('customers_list', customers.map((e) => jsonEncode(e)).toList());
    setState(() {});
  }

  void _showAddEditSupplierDialog({Map<String, dynamic>? supplier, int? index}) {
    final nameController = TextEditingController(text: supplier?['name'] ?? '');
    final phoneController = TextEditingController(text: supplier?['phone'] ?? '');
    final debtController = TextEditingController(text: supplier?['debt']?.toString() ?? '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(supplier == null ? 'إضافة مورد جديد' : 'تعديل المورد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم المورد')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
            TextField(controller: debtController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'مبلغ الدين')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              final data = {
                'name': nameController.text,
                'phone': phoneController.text,
                'debt': double.tryParse(debtController.text) ?? 0.0,
              };
              if (index == null) {
                suppliers.add(data);
              } else {
                suppliers[index] = data;
              }
              _saveData();
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showAddEditCustomerDialog({Map<String, dynamic>? customer, int? index}) {
    final nameController = TextEditingController(text: customer?['name'] ?? '');
    final amountController = TextEditingController(text: customer?['amount']?.toString() ?? '0');
    bool isEmp = customer?['isEmp'] ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(customer == null ? 'إضافة زبون / كريدي' : 'تعديل الحساب'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الزبون أو الموظف')),
              TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'مبلغ الدين (دج)')),
              CheckboxListTile(
                title: const Text('هل هو موظف (لتخليص الشهر)؟'),
                value: isEmp,
                onChanged: (val) => setDialogState(() => isEmp = val ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty) return;
                final data = {
                  'name': nameController.text,
                  'amount': double.tryParse(amountController.text) ?? 0.0,
                  'isEmp': isEmp,
                };
                if (index == null) {
                  customers.add(data);
                } else {
                  customers[index] = data;
                }
                _saveData();
                Navigator.pop(context);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الموردين والزبائن'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الموردين والفواتير', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(onPressed: () => _showAddEditSupplierDialog(), icon: const Icon(Icons.add, size: 18), label: const Text('مورد')),
            ],
          ),
          ...suppliers.asMap().entries.map((entry) => Card(
            child: ListTile(
              title: Text(entry.value['name']),
              subtitle: Text('الهاتف: ${entry.value['phone']} - الدين: ${entry.value['debt']} دج'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showAddEditSupplierDialog(supplier: entry.value, index: entry.key)),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () { setState(() => suppliers.removeAt(entry.key)); _saveData(); }),
                ],
              ),
            ),
          )),
          const Divider(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الزبائن والكريدي والموظفين', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(onPressed: () => _showAddEditCustomerDialog(), icon: const Icon(Icons.add, size: 18), label: const Text('زبون')),
            ],
          ),
          ...customers.asMap().entries.map((entry) => Card(
            child: ListTile(
              title: Text('${entry.value['name']} ${entry.value['isEmp'] ? '(موظف)' : ''}'),
              subtitle: Text('الدين: ${entry.value['amount']} دج'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showAddEditCustomerDialog(customer: entry.value, index: entry.key)),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () { setState(() => customers.removeAt(entry.key)); _saveData(); }),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}
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
