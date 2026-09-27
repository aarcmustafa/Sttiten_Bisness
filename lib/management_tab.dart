import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ManagementTab extends StatefulWidget {
  const ManagementTab({Key? key}) : super(key: key);

  @override
  _ManagementTabState createState() => _ManagementTabState();
}

class _ManagementTabState extends State<ManagementTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> suppliers = [];
  List<Map<String, dynamic>> sales = [];
  List<Map<String, dynamic>> customers = [];

  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> loadedSuppliers = (prefs.getStringList('suppliers_v2') ?? [])
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
    DateTime twoMonthsAgo = DateTime.now().subtract(const Duration(days: 60));
    for (var sup in loadedSuppliers) {
      List invoices = sup['invoices'] ?? [];
      invoices.removeWhere((inv) => DateTime.parse(inv['date']).isBefore(twoMonthsAgo));
      sup['invoices'] = invoices;
    }
    suppliers = loadedSuppliers;
    sales = (prefs.getStringList('sales_v2') ?? []).map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    customers = (prefs.getStringList('customers_v2') ?? []).map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    
    _saveAllData();
    setState(() {});
  }

  Future<void> _saveAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('suppliers_v2', suppliers.map((e) => jsonEncode(e)).toList());
    await prefs.setStringList('sales_v2', sales.map((e) => jsonEncode(e)).toList());
    await prefs.setStringList('customers_v2', customers.map((e) => jsonEncode(e)).toList());
    setState(() {});
  }

  void _addSupplier() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إضافة مورد جديد', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم المورد', prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 10),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                suppliers.add({'id': DateTime.now().millisecondsSinceEpoch.toString(), 'name': nameCtrl.text, 'phone': phoneCtrl.text, 'invoices': []});
                _saveAllData();
                Navigator.pop(ctx);
              }
            },
            child: const Text('حفظ المورد', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _manageSupplierInvoices(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(builder: (BuildContext context, StateSetter setModalState) {
          double totalDebt = 0;
          for (var inv in suppliers[index]['invoices']) { totalDebt += (inv['remaining'] ?? 0); }

          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 16, right: 16),
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 15),
                Text('فواتير المورد: ${suppliers[index]['name']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Text('مجموع الدين المتبقي للمورد: $totalDebt دج', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), padding: const EdgeInsets.symmetric(vertical: 12)),
                    icon: const Icon(Icons.receipt_long, color: Colors.white),
                    label: const Text('إضافة فاتورة جديدة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      final totalCtrl = TextEditingController();
                      final paidCtrl = TextEditingController();
                      showDialog(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          title: const Text('إضافة فاتورة جديدة'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('التاريخ آلياً: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}', style: const TextStyle(color: Colors.grey)),
                              TextField(controller: totalCtrl, decoration: const InputDecoration(labelText: 'القيمة الكلية للفاتورة (دج)'), keyboardType: TextInputType.number),
                              TextField(controller: paidCtrl, decoration: const InputDecoration(labelText: 'المبلغ المدفوع (دج)'), keyboardType: TextInputType.number),
                            ],
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('إلغاء')),
                            ElevatedButton(
                              onPressed: () {
                                double total = double.tryParse(totalCtrl.text) ?? 0;
                                double paid = double.tryParse(paidCtrl.text) ?? 0;
                                setModalState(() {
                                  suppliers[index]['invoices'].add({
                                    'date': DateTime.now().toIso8601String(),
                                    'total': total,
                                    'paid': paid,
                                    'remaining': total - paid,
                                  });
                                });
                                _saveAllData();
                                Navigator.pop(dCtx);
                              },
                              child: const Text('حفظ الفاتورة'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: ListView.builder(
                    itemCount: suppliers[index]['invoices'].length,
                    itemBuilder: (c, i) {
                      var inv = suppliers[index]['invoices'][i];
                      bool isPaid = inv['remaining'] == 0;
                      return Card(
                        elevation: 1,
                        color: isPaid ? Colors.green.shade50 : Colors.red.shade50,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text('تاريخ الفاتورة: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(inv['date']))}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('الإجمالي: ${inv['total']} دج | المدفوع: ${inv['paid']} دج\nالباقي ديناً: ${inv['remaining']} دج'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              setModalState(() => suppliers[index]['invoices'].removeAt(i));
                              _saveAllData();
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
    void _addDailySale() {
    final amountCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('مبيعات اليوم النقدي (${DateFormat('yyyy-MM-dd').format(DateTime.now())})'),
        content: TextField(
          controller: amountCtrl,
          decoration: const InputDecoration(labelText: 'المبلغ النقدي المباشر (دج)', prefixIcon: Icon(Icons.money)),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
            onPressed: () {
              sales.add({'date': DateTime.now().toIso8601String(), 'amount': double.tryParse(amountCtrl.text) ?? 0});
              _saveAllData();
              Navigator.pop(ctx);
            },
            child: const Text('تسجيل المبيعات', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _addCustomer(bool isEmployee) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    DateTime? startDate;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEmployee ? 'إضافة موظف (حساب كريدي)' : 'إضافة زبون كريدي آخر', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'الاسم الكامل', prefixIcon: Icon(Icons.person))),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
              if (isEmployee) ...[
                const SizedBox(height: 15),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: Text(startDate == null ? 'اختر تاريخ بداية الشهر' : 'البداية: ${DateFormat('yyyy-MM-dd').format(startDate!)}'),
                  onPressed: () async {
                    DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                    if (picked != null) setDialogState(() => startDate = picked);
                  },
                )
              ]
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  customers.add({
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'name': nameCtrl.text,
                    'phone': phoneCtrl.text,
                    'isEmployee': isEmployee,
                    'startDate': startDate?.toIso8601String(),
                    'purchases': [],
                    'rolledOverDebt': 0.0
                  });
                  _saveAllData();
                  Navigator.pop(ctx);
                }
              },
              child: const Text('حفظ الحساب', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _manageCustomer(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(builder: (BuildContext context, StateSetter setModalState) {
          double currentPurchases = 0;
          for (var p in customers[index]['purchases']) { currentPurchases += (p['amount'] ?? 0); }
          double totalOwed = currentPurchases + (customers[index]['rolledOverDebt'] ?? 0);

          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 16, right: 16),
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 15),
                Text(customers[index]['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Text('مجموع الكريدي المستحق: $totalOwed دج', style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
                        icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                        label: const Text('إضافة كريدي', style: TextStyle(color: Colors.white)),
                        onPressed: () {
                          final pCtrl = TextEditingController();
                          showDialog(
                            context: context,
                            builder: (dCtx) => AlertDialog(
                              title: const Text('إضافة عملية شراء بالكريدي'),
                              content: TextField(controller: pCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ (دج)')),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('إلغاء')),
                                ElevatedButton(
                                  onPressed: () {
                                    setModalState(() {
                                      customers[index]['purchases'].add({'date': DateTime.now().toIso8601String(), 'amount': double.tryParse(pCtrl.text) ?? 0});
                                    });
                                    _saveAllData();
                                    Navigator.pop(dCtx);
                                  },
                                  child: const Text('حفظ'),
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    if (customers[index]['isEmployee']) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
                          icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                          label: const Text('حوصلة الشهر', style: TextStyle(color: Colors.white)),
                          onPressed: () {
                            final payCtrl = TextEditingController();
                            showDialog(
                              context: context,
                              builder: (dCtx) => AlertDialog(
                                title: const Text('تسديد وحوصلة الشهر'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('مجموع الكريدي المستحق: $totalOwed دج'),
                                    TextField(controller: payCtrl, decoration: const InputDecoration(labelText: 'المبلغ المدفوع (دج)'), keyboardType: TextInputType.number),
                                  ],
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('إلغاء')),
                                  ElevatedButton(
                                    onPressed: () {
                                      double paid = double.tryParse(payCtrl.text) ?? 0;
                                      setModalState(() {
                                        customers[index]['purchases'] = [];
                                        customers[index]['rolledOverDebt'] = totalOwed - paid;
                                      });
                                      _saveAllData();
                                      Navigator.pop(dCtx);
                                    },
                                    child: const Text('حفظ وترحيل المتبقي'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: ListView.builder(
                    itemCount: customers[index]['purchases'].length,
                    itemBuilder: (c, i) => Card(
                      child: ListTile(
                        title: Text(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(customers[index]['purchases'][i]['date']))),
                        trailing: Text('${customers[index]['purchases'][i]['amount']} دج', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ),
                )
              ],
            ),
          );
        });
      },
    );
  }
    @override
  Widget build(BuildContext context) {
    var filteredSuppliers = suppliers.where((s) => s['name'].toString().contains(searchQuery)).toList();
    var filteredCustomers = customers.where((c) => c['name'].toString().contains(searchQuery)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('مركز الإدارة والمبيعات'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: const [
            Tab(text: 'الموردين'),
            Tab(text: 'المبيعات النقدية'),
            Tab(text: 'حسابات الكريدي'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (val) => setState(() => searchQuery = val),
              decoration: InputDecoration(
                hintText: 'بحث سريع بالاسم...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // الموردين
                ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filteredSuppliers.length,
                  itemBuilder: (ctx, i) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
                        child: const Icon(Icons.business, color: Color(0xFF1E3A8A)),
                      ),
                      title: Text(filteredSuppliers[i]['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(filteredSuppliers[i]['phone']),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _manageSupplierInvoices(suppliers.indexOf(filteredSuppliers[i])),
                    ),
                  ),
                ),
                // المبيعات النقدية
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D9488),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _addDailySale,
                          icon: const Icon(Icons.add_card, color: Colors.white),
                          label: const Text('تسجيل مبيعات نقدية جديدة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: sales.length,
                        itemBuilder: (ctx, i) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.monetization_on_rounded, color: Colors.green, size: 30),
                            title: Text(DateFormat('yyyy-MM-dd').format(DateTime.parse(sales[i]['date']))),
                            trailing: Text('${sales[i]['amount']} دج', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                // الكريدي
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
                          onPressed: () => _addCustomer(true),
                          icon: const Icon(Icons.badge, color: Colors.white),
                          label: const Text('إضافة موظف', style: TextStyle(color: Colors.white)),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
                          onPressed: () => _addCustomer(false),
                          icon: const Icon(Icons.person_add, color: Colors.white),
                          label: const Text('إضافة زبون كريدي', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: filteredCustomers.length,
                        itemBuilder: (ctx, i) {
                          var cust = filteredCustomers[i];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: cust['isEmployee'] ? Colors.orange.shade100 : Colors.blue.shade100,
                                child: Icon(
                                  cust['isEmployee'] ? Icons.badge : Icons.person,
                                  color: cust['isEmployee'] ? Colors.orange.shade800 : Colors.blue.shade800,
                                ),
                              ),
                              title: Text(cust['name'] + (cust['isEmployee'] ? ' (موظف)' : ''), style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: cust['isEmployee'] && cust['startDate'] != null 
                                  ? Text('بداية الشهر: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(cust['startDate']))}') 
                                  : Text(cust['phone']),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => _manageCustomer(customers.indexOf(cust)),
                            ),
                          );
                        },
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1E3A8A),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          if (_tabController.index == 0) _addSupplier();
          if (_tabController.index == 1) _addDailySale();
          if (_tabController.index == 2) _addCustomer(false);
        },
      ),
    );
  }
}

