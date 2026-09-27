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
  
  List<Map<String, dynamic>> archiveSuppliers = [];
  List<Map<String, dynamic>> archiveSales = [];
  List<Map<String, dynamic>> archiveCustomers = [];

  String searchQuery = "";
  String customerFilter = "ALL";
  
  bool isManualMonthlyFilterEnabled = false;
  String selectedFilterMonth = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    DateTime sixtyDaysAgo = DateTime.now().subtract(const Duration(days: 60));
    DateTime seventyDaysAgo = DateTime.now().subtract(const Duration(days: 70));

    isManualMonthlyFilterEnabled = prefs.getBool('manual_monthly_filter') ?? false;
    selectedFilterMonth = prefs.getString('selected_filter_month') ?? DateFormat('yyyy-MM').format(DateTime.now());

    List<Map<String, dynamic>> loadedSuppliers = (prefs.getStringList('suppliers_v2') ?? [])
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
    for (var sup in loadedSuppliers) {
      List invoices = sup['invoices'] ?? [];
      invoices.removeWhere((inv) => DateTime.parse(inv['date']).isBefore(sixtyDaysAgo));
      sup['invoices'] = invoices;
    }
    suppliers = loadedSuppliers;

    sales = (prefs.getStringList('sales_v2') ?? []).map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    customers = (prefs.getStringList('customers_v2') ?? []).map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

    archiveSuppliers = (prefs.getStringList('archive_suppliers') ?? [])
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .where((item) => DateTime.parse(item['date']).isAfter(sixtyDaysAgo))
        .toList();

    archiveSales = (prefs.getStringList('archive_sales') ?? [])
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .where((item) => DateTime.parse(item['date']).isAfter(sixtyDaysAgo))
        .toList();

    archiveCustomers = (prefs.getStringList('archive_customers') ?? [])
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .where((item) => DateTime.parse(item['date']).isAfter(seventyDaysAgo))
        .toList();

    _saveAllData();
  }

  Future<void> _saveAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('manual_monthly_filter', isManualMonthlyFilterEnabled);
    await prefs.setString('selected_filter_month', selectedFilterMonth);
    
    await prefs.setStringList('suppliers_v2', suppliers.map((e) => jsonEncode(e)).toList());
    await prefs.setStringList('sales_v2', sales.map((e) => jsonEncode(e)).toList());
    await prefs.setStringList('customers_v2', customers.map((e) => jsonEncode(e)).toList());
    
    await prefs.setStringList('archive_suppliers', archiveSuppliers.map((e) => jsonEncode(e)).toList());
    await prefs.setStringList('archive_sales', archiveSales.map((e) => jsonEncode(e)).toList());
    await prefs.setStringList('archive_customers', archiveCustomers.map((e) => jsonEncode(e)).toList());
    setState(() {});
  }

  void _addArchiveEntry(String section, String title, String details, double amount) {
    var entry = {
      'title': title,
      'details': details,
      'amount': amount,
      'date': DateTime.now().toIso8601String(),
    };
    if (section == 'suppliers') archiveSuppliers.insert(0, entry);
    if (section == 'sales') archiveSales.insert(0, entry);
    if (section == 'customers') archiveCustomers.insert(0, entry);
  }

  double get _totalCustomersDebt {
    double total = 0;
    for (var c in customers) {
      for (var p in (c['purchases'] as List)) { total += (p['amount'] ?? 0); }
      total += (c['rolledOverDebt'] ?? 0);
    }
    return total;
  }

  double get _totalSalesCash {
    double total = 0;
    for (var s in sales) { 
      if (isManualMonthlyFilterEnabled) {
        if (s['date'].toString().startsWith(selectedFilterMonth)) {
          total += (s['amount'] ?? 0);
        }
      } else {
        total += (s['amount'] ?? 0);
      }
    }
    return total;
  }
    void _addSupplier() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إضافة مورد جديد', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, style: const TextStyle(color: Colors.black87), decoration: const InputDecoration(labelText: 'اسم المورد', prefixIcon: Icon(Icons.person, color: Color(0xFF1E3A8A)))),
            const SizedBox(height: 10),
            TextField(controller: phoneCtrl, style: const TextStyle(color: Colors.black87), decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone, color: Color(0xFF1E3A8A))), keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                suppliers.add({'id': DateTime.now().millisecondsSinceEpoch.toString(), 'name': nameCtrl.text, 'phone': phoneCtrl.text, 'invoices': []});
                _saveAllData();
                Navigator.pop(ctx);
              }
            },
            child: const Text('حفظ المورد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _manageSupplierInvoices(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(builder: (BuildContext context, StateSetter setModalState) {
          var invoices = suppliers[index]['invoices'] as List;
          var displayedInvoices = invoices.where((inv) {
            if (isManualMonthlyFilterEnabled) {
              return inv['date'].toString().startsWith(selectedFilterMonth);
            }
            return true;
          }).toList();

          double totalDebt = 0;
          for (var inv in invoices) { totalDebt += (inv['remaining'] ?? 0); }

          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 16, right: 16),
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 15),
                Text('فواتير المورد: ${suppliers[index]['name']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
                  child: Text('مجموع الدين المتبقي للمورد: $totalDebt دج', style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), padding: const EdgeInsets.symmetric(vertical: 12)),
                    icon: const Icon(Icons.receipt_long, color: Colors.white),
                    label: const Text('إضافة فاتورة جديدة للمورد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      final totalCtrl = TextEditingController();
                      final paidCtrl = TextEditingController();
                      showDialog(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          backgroundColor: Colors.white,
                          title: const Text('إضافة فاتورة جديدة', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('التاريخ: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              TextField(controller: totalCtrl, style: const TextStyle(color: Colors.black87), decoration: const InputDecoration(labelText: 'القيمة الكلية للفاتورة (دج)'), keyboardType: TextInputType.number),
                              const SizedBox(height: 10),
                              TextField(controller: paidCtrl, style: const TextStyle(color: Colors.black87), decoration: const InputDecoration(labelText: 'المبلغ المدفوع (دج)'), keyboardType: TextInputType.number),
                            ],
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
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
                                _addArchiveEntry('suppliers', 'فاتورة مورد', 'المورد: ${suppliers[index]['name']}', total);
                                _saveAllData();
                                Navigator.pop(dCtx);
                              },
                              child: const Text('حفظ الفاتورة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                    itemCount: displayedInvoices.length,
                    itemBuilder: (c, i) {
                      var inv = displayedInvoices[i];
                      bool isPaid = inv['remaining'] == 0;
                      return Card(
                        elevation: 1,
                        color: isPaid ? Colors.green.shade50 : Colors.red.shade50,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text('تاريخ الفاتورة: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(inv['date']))}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                          subtitle: Text('الإجمالي: ${inv['total']} دج | المدفوع: ${inv['paid']} دج\nالباقي ديناً: ${inv['remaining']} دج', style: const TextStyle(color: Colors.black87)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              setModalState(() => suppliers[index]['invoices'].remove(inv));
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

  void _addOrEditDailySale({Map<String, dynamic>? saleToEdit, int? editIndex}) {
    final amountCtrl = TextEditingController(text: saleToEdit != null ? saleToEdit['amount'].toString() : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(saleToEdit == null ? 'تسجيل مبيعات نقدية جديدة' : 'تعديل المبلغ النقدي', style: const TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold)),
        content: TextField(
          controller: amountCtrl,
          style: const TextStyle(color: Colors.black87),
          decoration: const InputDecoration(labelText: 'المبلغ النقدي المباشر (دج)', prefixIcon: Icon(Icons.money, color: Color(0xFF0D9488))),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
            onPressed: () {
              double amount = double.tryParse(amountCtrl.text) ?? 0;
              if (saleToEdit == null) {
                sales.add({'date': DateTime.now().toIso8601String(), 'amount': amount});
                _addArchiveEntry('sales', 'بيع نقدي', 'مبيعات يومية مباشرة', amount);
              } else {
                sales[editIndex!]['amount'] = amount;
              }
              _saveAllData();
              Navigator.pop(ctx);
            },
            child: Text(saleToEdit == null ? 'تسجيل' : 'تعديل', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEmployee ? 'إضافة موظف (حساب كريدي)' : 'إضافة زبون كريدي آخر', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, style: const TextStyle(color: Colors.black87), decoration: const InputDecoration(labelText: 'الاسم الكامل', prefixIcon: Icon(Icons.person, color: Color(0xFF1E3A8A)))),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, style: const TextStyle(color: Colors.black87), decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone, color: Color(0xFF1E3A8A))), keyboardType: TextInputType.phone),
              if (isEmployee) ...[
                const SizedBox(height: 15),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1E3A8A)),
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
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
              child: const Text('حفظ الحساب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(builder: (BuildContext context, StateSetter setModalState) {
          var purchases = customers[index]['purchases'] as List;
          var displayedPurchases = purchases.where((p) {
            if (isManualMonthlyFilterEnabled) {
              return p['date'].toString().startsWith(selectedFilterMonth);
            }
            return true;
          }).toList();

          double currentPurchases = 0;
          for (var p in purchases) { currentPurchases += (p['amount'] ?? 0); }
          double totalOwed = currentPurchases + (customers[index]['rolledOverDebt'] ?? 0);

          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 16, right: 16),
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 15),
                Text(customers[index]['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
                  child: Text('مجموع الكريدي المستحق: $totalOwed دج', style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
                        icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                        label: const Text('إضافة كريدي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          final pCtrl = TextEditingController();
                          showDialog(
                            context: context,
                            builder: (dCtx) => AlertDialog(
                              backgroundColor: Colors.white,
                              title: const Text('إضافة عملية شراء بالكريدي', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                              content: TextField(controller: pCtrl, style: const TextStyle(color: Colors.black87), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ (دج)')),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
                                  onPressed: () {
                                    double amount = double.tryParse(pCtrl.text) ?? 0;
                                    setModalState(() {
                                      customers[index]['purchases'].add({'date': DateTime.now().toIso8601String(), 'amount': amount});
                                    });
                                    _addArchiveEntry('customers', 'إضافة كريدي', 'الزبون: ${customers[index]['name']}', amount);
                                    _saveAllData();
                                    Navigator.pop(dCtx);
                                  },
                                  child: const Text('حفظ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
                        icon: const Icon(Icons.payment, color: Colors.white),
                        label: Text(customers[index]['isEmployee'] ? 'حوصلة/تسديد' : 'تسديد مبكر', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          final payCtrl = TextEditingController();
                          bool isManualFilter = false;
                          List<bool> selectedPurchases = List.generate(purchases.length, (_) => false);

                          showDialog(
                            context: context,
                            builder: (dCtx) => StatefulBuilder(
                              builder: (context, setDialogState) => AlertDialog(
                                backgroundColor: Colors.white,
                                title: const Text('تسديد وتصفية الديون', style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold, fontSize: 16)),
                                content: SizedBox(
                                  width: double.maxFinite,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('إجمالي الدين الحالي: $totalOwed دج', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 10),
                                        SwitchListTile(
                                          title: const Text('تصفية يدوية (اختيار عمليات محددة)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                          value: isManualFilter,
                                          activeColor: const Color(0xFF0D9488),
                                          onChanged: (val) {
                                            setDialogState(() => isManualFilter = val);
                                          },
                                        ),
                                        const SizedBox(height: 10),
                                        if (!isManualFilter) ...[
                                          TextField(
                                            controller: payCtrl,
                                            style: const TextStyle(color: Colors.black87),
                                            decoration: const InputDecoration(labelText: 'المبلغ المدفوع (دج)'),
                                            keyboardType: TextInputType.number,
                                          ),
                                        ] else ...[
                                          const Text('اختر العمليات المراد تصفيتها وتسديدها:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                          const SizedBox(height: 5),
                                          SizedBox(
                                            height: 150,
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              itemCount: purchases.length,
                                              itemBuilder: (context, pIndex) {
                                                var p = purchases[pIndex];
                                                return CheckboxListTile(
                                                  dense: true,
                                                  title: Text('${p['amount']} دج (${p['date'].toString().substring(0, 10)})', style: const TextStyle(fontSize: 13)),
                                                  value: selectedPurchases[pIndex],
                                                  onChanged: (val) {
                                                    setDialogState(() => selectedPurchases[pIndex] = val ?? false);
                                                  },
                                                );
                                              },
                                            ),
                                          )
                                        ]
                                      ],
                                    ),
                                  ),
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
                                    onPressed: () {
                                      setModalState(() {
                                        if (!isManualFilter) {
                                          double paid = double.tryParse(payCtrl.text) ?? 0;
                                          customers[index]['purchases'] = [];
                                          customers[index]['rolledOverDebt'] = totalOwed - paid;
                                          _addArchiveEntry('customers', 'تسديد مبكر آلي', 'الزبون: ${customers[index]['name']} (مدفوع: $paid دج)', paid);
                                        } else {
                                          double manualPaid = 0;
                                          List remainingPurchases = [];
                                          for (int i = 0; i < purchases.length; i++) {
                                            if (selectedPurchases[i]) {
                                              manualPaid += (purchases[i]['amount'] ?? 0);
                                            } else {
                                              remainingPurchases.add(purchases[i]);
                                            }
                                          }
                                          customers[index]['purchases'] = remainingPurchases;
                                          _addArchiveEntry('customers', 'تصفية يدوية مبكرة', 'الزبون: ${customers[index]['name']} (تمت تصفية: $manualPaid دج)', manualPaid);
                                        }
                                      });
                                      _saveAllData();
                                      Navigator.pop(dCtx);
                                    },
                                    child: const Text('تأكيد التسديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: ListView.builder(
                    itemCount: displayedPurchases.length,
                    itemBuilder: (c, i) => Card(
                      color: Colors.white,
                      child: ListTile(
                        title: Text(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(displayedPurchases[i]['date'])), style: const TextStyle(color: Colors.black87)),
                        trailing: Text('${displayedPurchases[i]['amount']} دج', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A))),
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
    void _openSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('إعدادات التصفية الشهرية للعمليات', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('تفعيل التصفية اليدوية الشهرية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('إلغاء التصفية التلقائية وعرض شهر محدد يدوياً لتخفيف زحمة الشاشة', style: TextStyle(fontSize: 12)),
                value: isManualMonthlyFilterEnabled,
                activeColor: const Color(0xFF1E3A8A),
                onChanged: (val) {
                  setDialogState(() => isManualMonthlyFilterEnabled = val);
                },
              ),
              const SizedBox(height: 15),
              if (isManualMonthlyFilterEnabled) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('اختر الشهر المستهدف:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    TextButton(
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.parse('$selectedFilterMonth-01'),
                          firstDate: DateTime(2023),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedFilterMonth = DateFormat('yyyy-MM').format(picked));
                        }
                      },
                      child: Text(selectedFilterMonth, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D9488), fontSize: 16)),
                    ),
                  ],
                )
              ]
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
              onPressed: () {
                _saveAllData();
                Navigator.pop(ctx);
              },
              child: const Text('حفظ التعديلات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
    }
    @override
  Widget build(BuildContext context) {
    var filteredSuppliers = suppliers.where((s) => s['name'].toString().contains(searchQuery)).toList();
    var filteredCustomers = customers.where((c) {
      bool matchesSearch = c['name'].toString().contains(searchQuery);
      if (customerFilter == "EMPLOYEES") return matchesSearch && c['isEmployee'] == true;
      if (customerFilter == "REGULAR") return matchesSearch && c['isEmployee'] != true;
      return matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('مركز الإدارة والمبيعات', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E3A8A),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            tooltip: 'إعدادات التصفية الشهرية',
            onPressed: _openSettingsDialog,
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'الموردين'),
            Tab(text: 'المبيعات النقدية'),
            Tab(text: 'حسابات الكريدي'),
            Tab(text: 'الأرشيف'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange.shade200)),
                    child: Column(
                      children: [
                        const Text('إجمالي الديون', style: TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold)),
                        Text('${_totalCustomersDebt.toStringAsFixed(0)} دج', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.teal.shade200)),
                    child: Column(
                      children: [
                        Text(isManualMonthlyFilterEnabled ? 'مبيعات شهر ($selectedFilterMonth)' : 'إجمالي المبيعات النقدية', style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold)),
                        Text('${_totalSalesCash.toStringAsFixed(0)} دج', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.teal.shade900)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (val) => setState(() => searchQuery = val),
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'بحث سريع بالاسم...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1E3A8A)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. الموردين
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), padding: const EdgeInsets.symmetric(vertical: 12)),
                          onPressed: _addSupplier,
                          icon: const Icon(Icons.business_rounded, color: Colors.white),
                          label: const Text('إضافة مورد جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: filteredSuppliers.length,
                        itemBuilder: (ctx, i) => Card(
                          color: Colors.white,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
                              child: const Icon(Icons.business, color: Color(0xFF1E3A8A)),
                            ),
                            title: Text(filteredSuppliers[i]['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                            subtitle: Text(filteredSuppliers[i]['phone'], style: const TextStyle(color: Colors.black54)),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            onTap: () => _manageSupplierInvoices(suppliers.indexOf(filteredSuppliers[i])),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // 2. المبيعات النقدية
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), padding: const EdgeInsets.symmetric(vertical: 12)),
                          onPressed: () => _addOrEditDailySale(),
                          icon: const Icon(Icons.add_card, color: Colors.white),
                          label: const Text('تسجيل مبيعات نقدية جديدة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: sales.where((s) => isManualMonthlyFilterEnabled ? s['date'].toString().startsWith(selectedFilterMonth) : true).length,
                        itemBuilder: (ctx, i) {
                          var displayedSales = sales.where((s) => isManualMonthlyFilterEnabled ? s['date'].toString().startsWith(selectedFilterMonth) : true).toList();
                          var sale = displayedSales[i];
                          int originalIndex = sales.indexOf(sale);
                          return Card(
                            color: Colors.white,
                            child: ListTile(
                              leading: const Icon(Icons.monetization_on_rounded, color: Colors.green, size: 30),
                              title: Text(DateFormat('yyyy-MM-dd').format(DateTime.parse(sale['date'])), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('${sale['amount']} دج', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                    onPressed: () => _addOrEditDailySale(saleToEdit: sale, editIndex: originalIndex),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        sales.removeAt(originalIndex);
                                        _saveAllData();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  ],
                ),
                // 3. حسابات الكريدي
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)), onPressed: () => _addCustomer(true), icon: const Icon(Icons.badge, color: Colors.white), label: const Text('إضافة موظف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)), onPressed: () => _addCustomer(false), icon: const Icon(Icons.person_add, color: Colors.white), label: const Text('إضافة زبون كريدي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          ChoiceChip(label: const Text('الكل'), selected: customerFilter == "ALL", onSelected: (s) => setState(() => customerFilter = "ALL")),
                          const SizedBox(width: 8),
                          ChoiceChip(label: const Text('الموظفين فقط'), selected: customerFilter == "EMPLOYEES", onSelected: (s) => setState(() => customerFilter = "EMPLOYEES")),
                          const SizedBox(width: 8),
                          ChoiceChip(label: const Text('الزبائن العاديين'), selected: customerFilter == "REGULAR", onSelected: (s) => setState(() => customerFilter = "REGULAR")),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: filteredCustomers.length,
                        itemBuilder: (ctx, i) {
                          var cust = filteredCustomers[i];
                          return Card(
                            color: Colors.white,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: cust['isEmployee'] ? Colors.orange.shade100 : Colors.blue.shade100,
                                child: Icon(cust['isEmployee'] ? Icons.badge : Icons.person, color: cust['isEmployee'] ? Colors.orange.shade800 : Colors.blue.shade800),
                              ),
                              title: Text(cust['name'] + (cust['isEmployee'] ? ' (موظف)' : ''), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                              subtitle: cust['isEmployee'] && cust['startDate'] != null 
                                  ? Text('بداية الشهر: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(cust['startDate']))}', style: const TextStyle(color: Colors.black54)) 
                                  : Text(cust['phone'], style: const TextStyle(color: Colors.black54)),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                              onTap: () => _manageCustomer(customers.indexOf(cust)),
                            ),
                          );
                        },
                      ),
                    )
                  ],
                ),
                // 4. الأرشيف مع الملاحظة
                DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Color(0xFF1E3A8A), size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'ملاحظة الصلاحية: يُحذف أرشيف الكريدي تلقائياً بعد 70 يوماً، بينما يحذف أرشيف الموردين والمبيعات بعد شهرين (60 يوماً).',
                                style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const TabBar(
                        labelColor: Color(0xFF1E3A8A),
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Color(0xFF1E3A8A),
                        tabs: [
                          Tab(text: 'الموردين'),
                          Tab(text: 'المبيعات'),
                          Tab(text: 'الكريدي (70 يوماً)'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            archiveSuppliers.isEmpty
                                ? const Center(child: Text('لا توجد عمليات مؤرشفة للموردين', style: TextStyle(color: Colors.grey)))
                                : ListView.builder(
                                    itemCount: archiveSuppliers.length,
                                    itemBuilder: (c, i) => Card(
                                      child: ListTile(
                                        title: Text(archiveSuppliers[i]['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text('${archiveSuppliers[i]['details']}\n${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(archiveSuppliers[i]['date']))}'),
                                        trailing: Text('${archiveSuppliers[i]['amount']} دج', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                                      ),
                                    ),
                                  ),
                            archiveSales.isEmpty
                                ? const Center(child: Text('لا توجد عمليات مؤرشفة للمبيعات', style: TextStyle(color: Colors.grey)))
                                : ListView.builder(
                                    itemCount: archiveSales.length,
                                    itemBuilder: (c, i) => Card(
                                      child: ListTile(
                                        title: Text(archiveSales[i]['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text('${archiveSales[i]['details']}\n${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(archiveSales[i]['date']))}'),
                                        trailing: Text('${archiveSales[i]['amount']} دج', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                      ),
                                    ),
                                  ),
                            archiveCustomers.isEmpty
                                ? const Center(child: Text('لا توجد عمليات مؤرشفة للكريدي', style: TextStyle(color: Colors.grey)))
                                : ListView.builder(
                                    itemCount: archiveCustomers.length,
                                    itemBuilder: (c, i) => Card(
                                      child: ListTile(
                                        title: Text(archiveCustomers[i]['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text('${archiveCustomers[i]['details']}\n${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(archiveCustomers[i]['date']))}'),
                                        trailing: Text('${archiveCustomers[i]['amount']} دج', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
          if (_tabController.index == 1) _addOrEditDailySale();
          if (_tabController.index == 2) _addCustomer(false);
        },
      ),
    );
  }
}
