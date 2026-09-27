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

  Widget _buildResultRow(String label, double salesAmount, double costsAmount, bool isAnnual) {
    if (treasuryStartDate == null) return Text('$label: لم تحن بعد', style: const TextStyle(fontSize: 16));
    
    DateTime targetDate = isAnnual 
        ? DateTime(treasuryStartDate!.year + 1, treasuryStartDate!.month, treasuryStartDate!.day)
        : DateTime(treasuryStartDate!.year, treasuryStartDate!.month + 1, treasuryStartDate!.day);
        
    if (DateTime.now().isBefore(targetDate)) {
      return Text('$label: لم تحن بعد (تكتمل في ${DateFormat('yyyy-MM-dd').format(targetDate)})', style: const TextStyle(fontSize: 16));
    }

    double result = salesAmount - costsAmount;
    Color rColor = result > 0 ? Colors.green : Colors.red;
    String rText = result > 0 ? 'ربح' : 'خسارة / صفر';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label المبيعات: $salesAmount دج | التكلفة: $costsAmount دج'),
        Text('النتيجة: $result دج ($rText)', style: TextStyle(color: rColor, fontWeight: FontWeight.bold, fontSize: 18)),
        const Divider()
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الصندوق والتنبيهات')),
      body: RefreshIndicator(
        onRefresh: _calculateTreasury,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (alerts.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                color: Colors.red.shade100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('تنبيهات هامة:', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ...alerts.map((a) => Text('- $a', style: const TextStyle(color: Colors.red)))
                  ],
                ),
              ),
            const SizedBox(height: 20),
            const Text('حوصلة اليوم (نقداً + كريدي):', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('$todaySales دج', style: const TextStyle(fontSize: 22, color: Colors.blue, fontWeight: FontWeight.bold)),
            const Divider(thickness: 2),
            const SizedBox(height: 10),
            const Text('قسم الأرباح والخسائر:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListTile(
              title: Text(treasuryStartDate == null ? 'تحديد أول يوم للشهر' : 'تاريخ البداية: ${DateFormat('yyyy-MM-dd').format(treasuryStartDate!)}'),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                if (picked != null) {
                  setState(() => treasuryStartDate = picked);
                  _calculateTreasury();
                }
              },
            ),
            const SizedBox(height: 10),
            _buildResultRow('الحوصلة الشهرية', monthlySales, monthlyCosts, false),
            _buildResultRow('الحوصلة السنوية (12 شهر)', annualSales, annualCosts, true),
          ],
        ),
      ),
    );
  }
}
