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
