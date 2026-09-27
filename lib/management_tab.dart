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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // تحميل الموردين وتنظيف الفواتير القديمة (أكثر من 60 يوم)
    List<Map<String, dynamic>> loadedSuppliers = (prefs.getStringList('suppliers_v2') ?? []).map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    DateTime twoMonthsAgo = DateTime.now().subtract(const Duration(days: 60));
    for (var sup in loadedSuppliers) {
      List invoices = sup['invoices'] ?? [];
      invoices.removeWhere((inv) {
        DateTime invDate = DateTime.parse(inv['date']);
        return invDate.isBefore(twoMonthsAgo);
      });
      sup['invoices'] = invoices;
    }
    suppliers = loadedSuppliers;
    
    sales = (prefs.getStringList('sales_v2') ?? []).map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    customers = (prefs.getStringList('customers_v2') ?? []).map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    
    _saveAllData(); // حفظ بعد التنظيف
    setState(() {});
  }

  Future<void> _saveAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('suppliers_v2', suppliers.map((e) => jsonEncode(e)).toList());
    await prefs.setStringList('sales_v2', sales.map((e) => jsonEncode(e)).toList());
    await prefs.setStringList('customers_v2', customers.map((e) => jsonEncode(e)).toList());
    setState(() {});
  }

  // --- قسم الموردين ---
  void _addSupplier() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('إضافة مورد جديد'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'الاسم الكامل')),
        TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'رقم الهاتف'), keyboardType: TextInputType.phone),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () {
          if (nameCtrl.text.isNotEmpty) {
            suppliers.add({'id': DateTime.now().millisecondsSinceEpoch.toString(), 'name': nameCtrl.text, 'phone': phoneCtrl.text, 'invoices': []});
            _saveAllData();
            Navigator.pop(ctx);
          }
        }, child: const Text('إضافة'))
      ],
    ));
  }

  void _manageSupplierInvoices(int index) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) {
      return StatefulBuilder(builder: (BuildContext context, StateSetter setModalState) {
        double totalDebt = 0;
        for (var inv in suppliers[index]['invoices']) {
          totalDebt += (inv['remaining'] ?? 0);
        }

        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 10, right: 10),
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              Text('فواتير: ${suppliers[index]['name']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text('مجموع الدين الباقي: $totalDebt دج', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: () {
                  final totalCtrl = TextEditingController();
                  final paidCtrl = TextEditingController();
                  showDialog(context: context, builder: (dCtx) => AlertDialog(
                    title: const Text('إضافة فاتورة جديدة'),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('التاريخ آليا: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}'),
                      TextField(controller: totalCtrl, decoration: const InputDecoration(labelText: 'قيمة الفاتورة الكلية'), keyboardType: TextInputType.number),
                      TextField(controller: paidCtrl, decoration: const InputDecoration(labelText: 'القيمة المدفوعة'), keyboardType: TextInputType.number),
                    ]),
                    actions: [
                      ElevatedButton(onPressed: () {
                        double total = double.tryParse(totalCtrl.text) ?? 0;
                        double paid = double.tryParse(paidCtrl.text) ?? 0;
                        double rem = total - paid;
                        setModalState(() {
                          suppliers[index]['invoices'].add({
                            'date': DateTime.now().toIso8601String(),
                            'total': total,
                            'paid': paid,
                            'remaining': rem,
                          });
                        });
                        _saveAllData();
                        Navigator.pop(dCtx);
                      }, child: const Text('حفظ الفاتورة'))
                    ],
                  ));
                }, 
                child: const Text('إضافة فاتورة جديدة')
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: suppliers[index]['invoices'].length,
                  itemBuilder: (c, i) {
                    var inv = suppliers[index]['invoices'][i];
                    bool isZero = inv['remaining'] == 0;
                    return Card(
                      color: isZero ? Colors.green.shade50 : Colors.red.shade50,
                      child: ListTile(
                        title: Text('التاريخ: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(inv['date']))}'),
                        subtitle: Text('الكلية: ${inv['total']} | المدفوع: ${inv['paid']} \nالباقي دينا: ${inv['remaining']} دج', style: TextStyle(color: isZero ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                        trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () {
                          setModalState(() => suppliers[index]['invoices'].removeAt(i));
                          _saveAllData();
                        }),
                      ),
                    );
                  }
                ),
              )
            ],
          ),
        );
      });
    });
  }

  // --- قسم المبيعات ---
  void _addDailySale() {
    final amountCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('مبيعات اليوم: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}'),
      content: TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'المبلغ نقداً'), keyboardType: TextInputType.number),
      actions: [
        ElevatedButton(onPressed: () {
          sales.add({
            'date': DateTime.now().toIso8601String(),
            'amount': double.tryParse(amountCtrl.text) ?? 0
          });
          _saveAllData();
          Navigator.pop(ctx);
        }, child: const Text('حفظ'))
      ],
    ));
  }

  // --- قسم الكريدي ---
  void _addCustomer(bool isEmployee) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    DateTime? startDate;
    
    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(isEmployee ? 'إضافة موظف' : 'إضافة زبون آخر'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'الاسم الكامل')),
          TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'رقم الهاتف'), keyboardType: TextInputType.phone),
          if (isEmployee)
            ListTile(
              title: Text(startDate == null ? 'اختر تاريخ بداية الشهر' : DateFormat('yyyy-MM-dd').format(startDate!)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                if (picked != null) setDialogState(() => startDate = picked);
              },
            )
        ]),
        actions: [
          ElevatedButton(onPressed: () {
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
          }, child: const Text('حفظ'))
        ],
      )
    ));
  }

  void _manageCustomer(int index) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) {
      return StatefulBuilder(builder: (BuildContext context, StateSetter setModalState) {
        double currentPurchases = 0;
        for (var p in customers[index]['purchases']) { currentPurchases += (p['amount'] ?? 0); }
        double totalOwed = currentPurchases + (customers[index]['rolledOverDebt'] ?? 0);

        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 10, right: 10),
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              Text('${customers[index]['name']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text('المجموع المستحق: $totalOwed دج', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(onPressed: () {
                    final pCtrl = TextEditingController();
                    showDialog(context: context, builder: (dCtx) => AlertDialog(
                      title: const Text('إضافة شراء'),
                      content: TextField(controller: pCtrl, keyboardType: TextInputType.number),
                      actions: [
                        ElevatedButton(onPressed: () {
                          setModalState(() {
                            customers[index]['purchases'].add({'date': DateTime.now().toIso8601String(), 'amount': double.tryParse(pCtrl.text) ?? 0});
                          });
                          _saveAllData();
                          Navigator.pop(dCtx);
                        }, child: const Text('حفظ'))
                      ],
                    ));
                  }, child: const Text('إضافة عملية شراء')),
                  
                  if (customers[index]['isEmployee'])
                    ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green), onPressed: () {
                      final payCtrl = TextEditingController();
                      showDialog(context: context, builder: (dCtx) => AlertDialog(
                        title: const Text('تخليص الشهر (الحوصلة)'),
                        content: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text('المستحق الكلي: $totalOwed دج'),
                          TextField(controller: payCtrl, decoration: const InputDecoration(labelText: 'قيمة السداد'), keyboardType: TextInputType.number),
                        ]),
                        actions: [
                          ElevatedButton(onPressed: () {
                            double paid = double.tryParse(payCtrl.text) ?? 0;
                            double remaining = totalOwed - paid;
                            setModalState(() {
                              customers[index]['purchases'] = []; // مسح مشتريات الشهر
                              customers[index]['rolledOverDebt'] = remaining; // ترحيل الباقي
                            });
                            _saveAllData();
                            Navigator.pop(dCtx);
                          }, child: const Text('تأكيد السداد وترحيل الباقي'))
                        ],
                      ));
                    }, child: const Text('حوصلة الشهر')),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: customers[index]['purchases'].length,
                  itemBuilder: (c, i) => ListTile(
                    title: Text(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(customers[index]['purchases'][i]['date']))),
                    trailing: Text('${customers[index]['purchases'][i]['amount']} دج', style: const TextStyle(fontWeight: FontWeight.bold)),
                  )
                ),
              )
            ],
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإدارة والمبيعات'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'الموردين'), Tab(text: 'المبيعات'), Tab(text: 'الكريدي')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. الموردين
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(onPressed: _addSupplier, icon: const Icon(Icons.add), label: const Text('إضافة مورد')),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: suppliers.length,
                  itemBuilder: (ctx, i) => Card(child: ListTile(
                    title: Text(suppliers[i]['name']),
                    subtitle: Text(suppliers[i]['phone']),
                    onTap: () => _manageSupplierInvoices(i),
                  ))
                ),
              )
            ],
          ),
          // 2. المبيعات
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(onPressed: _addDailySale, icon: const Icon(Icons.add), label: const Text('إضافة مبيعات نقدية لليوم')),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: sales.length,
                  itemBuilder: (ctx, i) => Card(child: ListTile(
                    title: Text(DateFormat('yyyy-MM-dd').format(DateTime.parse(sales[i]['date']))),
                    trailing: Text('${sales[i]['amount']} دج (نقداً)', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ))
                ),
              )
            ],
          ),
          // 3. الكريدي
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(onPressed: () => _addCustomer(true), child: const Text('إضافة موظف')),
                  ElevatedButton(onPressed: () => _addCustomer(false), child: const Text('إضافة زبون آخر')),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: customers.length,
                  itemBuilder: (ctx, i) => Card(child: ListTile(
                    title: Text('${customers[i]['name']} ${customers[i]['isEmployee'] ? "(موظف)" : ""}'),
                    subtitle: customers[i]['isEmployee'] && customers[i]['startDate'] != null 
                        ? Text('بداية الشهر: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(customers[i]['startDate']))}') 
                        : null,
                    onTap: () => _manageCustomer(i),
                  ))
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
