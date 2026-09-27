import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class StatisticsTab extends StatefulWidget {
  const StatisticsTab({Key? key}) : super(key: key);

  @override
  _StatisticsTabState createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<StatisticsTab> {
  DateTime? treasuryStartDate;
  
  double todaySales = 0;
  double monthlySales = 0;
  double annualSales = 0;
  
  double monthlyCosts = 0;
  double annualCosts = 0;

  List<String> alerts = [];

  @override
  void initState() {
    super.initState();
    _calculateTreasury();
  }

  Future<void> _calculateTreasury() async {
    final prefs = await SharedPreferences.getInstance();
    
    List suppliers = (prefs.getStringList('suppliers_v2') ?? []).map((e) => jsonDecode(e)).toList();
    List sales = (prefs.getStringList('sales_v2') ?? []).map((e) => jsonDecode(e)).toList();
    List customers = (prefs.getStringList('customers_v2') ?? []).map((e) => jsonDecode(e)).toList();

    DateTime now = DateTime.now();
    double tSales = 0, mSales = 0, aSales = 0;
    double mCosts = 0, aCosts = 0;
    List<String> tempAlerts = [];

    DateTime? nextMonthDate;
    DateTime? nextYearDate;
    if (treasuryStartDate != null) {
      nextMonthDate = DateTime(treasuryStartDate!.year, treasuryStartDate!.month + 1, treasuryStartDate!.day);
      nextYearDate = DateTime(treasuryStartDate!.year + 1, treasuryStartDate!.month, treasuryStartDate!.day);
    }

    for (var cust in customers) {
      if (cust['isEmployee'] == true && cust['startDate'] != null) {
        DateTime sDate = DateTime.parse(cust['startDate']);
        DateTime deadline = DateTime(sDate.year, sDate.month + 1, sDate.day);
        
        if (now.isAfter(deadline) || now.isAtSameMomentAs(deadline)) {
          tempAlerts.add('حان موعد تخليص الموظف: ${cust['name']}');
        }
      }
    }

    for (var sale in sales) {
      DateTime sDate = DateTime.parse(sale['date']);
      if (sDate.year == now.year && sDate.month == now.month && sDate.day == now.day) tSales += sale['amount'];
      
      if (treasuryStartDate != null && nextMonthDate != null && nextYearDate != null) {
        if (sDate.isAfter(treasuryStartDate!) && sDate.isBefore(nextMonthDate)) mSales += sale['amount'];
        if (sDate.isAfter(treasuryStartDate!) && sDate.isBefore(nextYearDate)) aSales += sale['amount'];
      }
    }
    
    for(var cust in customers) {
      for(var pur in cust['purchases']) {
        DateTime pDate = DateTime.parse(pur['date']);
        if (pDate.year == now.year && pDate.month == now.month && pDate.day == now.day) tSales += pur['amount'];
        
        if (treasuryStartDate != null && nextMonthDate != null && nextYearDate != null) {
          if (pDate.isAfter(treasuryStartDate!) && pDate.isBefore(nextMonthDate)) mSales += pur['amount'];
          if (pDate.isAfter(treasuryStartDate!) && pDate.isBefore(nextYearDate)) aSales += pur['amount'];
        }
      }
    }

    if (treasuryStartDate != null && nextMonthDate != null && nextYearDate != null) {
      for (var sup in suppliers) {
        for (var inv in sup['invoices']) {
          DateTime iDate = DateTime.parse(inv['date']);
          if (iDate.isAfter(treasuryStartDate!) && iDate.isBefore(nextMonthDate)) mCosts += inv['total'];
          if (iDate.isAfter(treasuryStartDate!) && iDate.isBefore(nextYearDate)) aCosts += inv['total'];
        }
      }
    }

    setState(() {
      todaySales = tSales;
      monthlySales = mSales;
      annualSales = aSales;
      monthlyCosts = mCosts;
      annualCosts = aCosts;
      alerts = tempAlerts;
    });
  }

  Widget _buildResultCard(String label, double salesAmount, double costsAmount, bool isAnnual) {
    if (treasuryStartDate == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('$label: اختر تاريخ البداية لحساب الأرباح', style: const TextStyle(color: Colors.grey)),
        ),
      );
    }
    
    DateTime targetDate = isAnnual 
        ? DateTime(treasuryStartDate!.year + 1, treasuryStartDate!.month, treasuryStartDate!.day)
        : DateTime(treasuryStartDate!.year, treasuryStartDate!.month + 1, treasuryStartDate!.day);
        
    if (DateTime.now().isBefore(targetDate)) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('$label: قيد الحساب (تكتمل الرزنامة في ${DateFormat('yyyy-MM-dd').format(targetDate)})', style: const TextStyle(color: Colors.grey)),
        ),
      );
    }

    double result = salesAmount - costsAmount;
    bool isProfit = result > 0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('المبيعات: $salesAmount دج', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                Text('التكاليف: $costsAmount دج', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('النتيجة الصافية:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${result.abs()} دج (${isProfit ? "ربح صافي" : "خسارة"})', 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isProfit ? Colors.green.shade700 : Colors.red.shade700)),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الصندوق والإحصائيات')),
      body: RefreshIndicator(
        onRefresh: _calculateTreasury,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (alerts.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.shade200)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.red.shade700), const SizedBox(width: 8), Text('تنبيهات استحقاق الموظفين', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 16))]),
                    const SizedBox(height: 10),
                    ...alerts.map((a) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $a', style: TextStyle(color: Colors.red.shade800)))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // بطاقة مبيعات اليوم
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('حوصلة مبيعات اليوم (نقداً + كريدي)', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('$todaySales دج', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_month, color: Color(0xFF1E3A8A)),
                title: Text(treasuryStartDate == null ? 'حدد تاريخ بداية الصندوق المحاسبي' : 'تاريخ بداية الصندوق: ${DateFormat('yyyy-MM-dd').format(treasuryStartDate!)}'),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                  if (picked != null) {
                    setState(() => treasuryStartDate = picked);
                    _calculateTreasury();
                  }
                },
              ),
            ),
            const SizedBox(height: 15),
            _buildResultCard('الحوصلة الشهرية الصافية', monthlySales, monthlyCosts, false),
            const SizedBox(height: 10),
            _buildResultCard('الحوصلة السنوية الصافية', annualSales, annualCosts, true),
          ],
        ),
      ),
    );
  }
}
