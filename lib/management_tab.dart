import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ManagementTab extends StatefulWidget {
  const ManagementTab({Key? key}) : super(key: key);

  @override
  State<ManagementTab> createState() => _ManagementTabState();
}

class _ManagementTabState extends State<ManagementTab> {
  bool isManualFilter = false;
  String selectedMonth = "2026-09";

  // دالة عامة لتأكيد الحذف قبل التنفيذ نهائياً
  void showDeleteConfirmation(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text('هل أنت متأكد من رغبتك في حذف هذا العنصر نهائياً؟', style: TextStyle(color: Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
    // --- نافذة إضافة مبيعات نقدية ---
  void _addDailySaleDialog() {
    final amountCtrl = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل مبيعات نقدية جديدة', style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold)),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'المبلغ النقدي (دج)', prefixIcon: Icon(Icons.money, color: Color(0xFF0D9488))),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'يرجى إدخال المبلغ';
              if (double.tryParse(value) == null || double.parse(value) <= 0) return 'أدخل رقماً صالحاً أكبر من الصفر';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                double amount = double.parse(amountCtrl.text);
                Hive.box('salesBox').add({
                  'amount': amount,
                  'date': DateTime.now().toIso8601String(),
                });
                setState(() {});
                Navigator.pop(ctx);
              }
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
    // --- نافذة إضافة مورد وفاتورة ---
  void _addSupplierDialog() {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة مورد وفاتورة جديدة', style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold)),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'اسم المورد', prefixIcon: Icon(Icons.person, color: Color(0xFF0D9488))),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'اسم المورد مطلوب' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'قيمة الفاتورة/الدين (دج)', prefixIcon: Icon(Icons.receipt, color: Color(0xFF0D9488))),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'المبلغ مطلوب';
                  if (double.tryParse(value) == null || double.parse(value) < 0) return 'أدخل مبلغاً صالحاً';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Hive.box('suppliersBox').add({
                  'name': nameCtrl.text.trim(),
                  'amount': double.parse(amountCtrl.text),
                  'date': DateTime.now().toIso8601String(),
                });
                setState(() {});
                Navigator.pop(ctx);
              }
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
    // --- نافذة إضافة كريدي / زبون أو موظف ---
  void _addCreditDialog() {
    String type = 'زبون';
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تسجيل حساب كريدي جديد', style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold)),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: type,
                  items: const [
                    DropdownMenuItem(value: 'زبون', child: Text('زبون عادي')),
                    DropdownMenuItem(value: 'موظف', child: Text('موظف')),
                  ],
                  onChanged: (val) => setDialogState(() => type = val!),
                  decoration: const InputDecoration(labelText: 'نوع الحساب'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'الاسم الكريم', prefixIcon: Icon(Icons.badge, color: Color(0xFF0D9488))),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'الاسم مطلوب' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'مبلغ الكريدي الإجمالي (دج)', prefixIcon: Icon(Icons.money_off, color: Color(0xFF0D9488))),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'المبلغ مطلوب';
                    if (double.tryParse(value) == null || double.parse(value) <= 0) return 'أدخل رقماً صالحاً أكبر من الصفر';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Hive.box('customersBox').add({
                    'type': type,
                    'name': nameCtrl.text.trim(),
                    'amount': double.parse(amountCtrl.text),
                    'date': DateTime.now().toIso8601String(),
                  });
                  setState(() {});
                  Navigator.pop(ctx);
                }
              },
              child: const Text('حفظ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
    @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D9488),
          title: Text(isManualFilter ? 'إدارة المتجر (شهر: $selectedMonth)' : 'إدارة المتجر والمبيعات اليومية'),
          actions: [
            IconButton(
              icon: Icon(isManualFilter ? Icons.filter_alt : Icons.filter_alt_off),
              tooltip: 'تبديل وضع التصفية (تلقائي / يدوي)',
              onPressed: () => setState(() => isManualFilter = !isManualFilter),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.point_of_sale), text: 'المبيعات'),
              Tab(icon: Icon(Icons.local_shipping), text: 'الموردين'),
              Tab(icon: Icon(Icons.people), text: 'الكريدي'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- تبويب المبيعات النقدية ---
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
                    onPressed: _addDailySaleDialog,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('إضافة مبيعات نقدية جديدة', style: TextStyle(color: Colors.white)),
                  ),
                ),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: Hive.box('salesBox').listenable(),
                    builder: (context, Box box, _) {
                      if (box.isEmpty) {
                        return const Center(child: Text('لا توجد مبيعات مسجلة حالياً', style: TextStyle(color: Colors.grey)));
                      }
                      return ListView.builder(
                        itemCount: box.length,
                        itemBuilder: (context, index) {
                          final item = box.getAt(index);
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            child: ListTile(
                              leading: const CircleAvatar(backgroundColor: Color(0xFF0D9488), child: Icon(Icons.attach_money, color: Colors.white)),
                              title: Text('المبلغ: ${item['amount']} دج', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('التاريخ: ${item['date'].toString().substring(0, 10)}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => showDeleteConfirmation(context, () => box.deleteAt(index)),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),

            // --- تبويب الموردين ---
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
                    onPressed: _addSupplierDialog,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('إضافة مورد جديد', style: TextStyle(color: Colors.white)),
                  ),
                ),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: Hive.box('suppliersBox').listenable(),
                    builder: (context, Box box, _) {
                      if (box.isEmpty) {
                        return const Center(child: Text('لا يوجد موردون مسجلون', style: TextStyle(color: Colors.grey)));
                      }
                      return ListView.builder(
                        itemCount: box.length,
                        itemBuilder: (context, index) {
                          final item = box.getAt(index);
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            child: ListTile(
                              leading: const CircleAvatar(backgroundColor: Colors.blueGrey, child: Icon(Icons.store, color: Colors.white)),
                              title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('الدين المتبقي: ${item['amount']} دج'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => showDeleteConfirmation(context, () => box.deleteAt(index)),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),

            // --- تبويب الكريدي (الزبائن والموظفين) ---
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
                    onPressed: _addCreditDialog,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('تسجيل كريدي جديد', style: TextStyle(color: Colors.white)),
                  ),
                ),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: Hive.box('customersBox').listenable(),
                    builder: (context, Box box, _) {
                      if (box.isEmpty) {
                        return const Center(child: Text('لا توجد سجلات كريدي نشطة', style: TextStyle(color: Colors.grey)));
                      }
                      return ListView.builder(
                        itemCount: box.length,
                        itemBuilder: (context, index) {
                          final item = box.getAt(index);
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: item['type'] == 'موظف' ? Colors.orange : Colors.indigo,
                                child: Icon(item['type'] == 'موظف' ? Icons.badge : Icons.person, color: Colors.white),
                              ),
                              title: Text('${item['name']} (${item['type']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('المبلغ: ${item['amount']} دج'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => showDeleteConfirmation(context, () => box.deleteAt(index)),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
