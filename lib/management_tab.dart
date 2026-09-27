import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ManagementTab extends StatefulWidget {
  const ManagementTab({Key? key}) : super(key: key);

  @override
  State<ManagementTab> createState() => _ManagementTabState();
}

class _ManagementTabState extends State<ManagementTab> {
  // متغيرات التصفية الشهرية واليومية
  bool isManualFilter = false;
  String selectedMonth = "2026-08"; // الشهر الافتراضي الحالي

  // دالة عامة لتأكيد الحذف (متاحة لكل الأقسام)
  void showDeleteConfirmation(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.red)),
        content: const Text('هل أنت متأكد من رغبتك في حذف هذا العنصر نهائياً؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المتجر والمبيعات'),
        actions: [
          IconButton(
            icon: Icon(isManualFilter ? Icons.filter_alt : Icons.filter_alt_off),
            onPressed: () {
              setState(() {
                isManualFilter = !isManualFilter;
              });
            },
          )
        ],
      ),
      body: const Center(child: Text('محتوى الأقسام أدناه...')),
    );
  }
}
  // نافذة إضافة مبيعات نقدية مع Validator والتخزين في Hive
  void _addDailySaleDialog() {
    final amountCtrl = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل مبيعات نقدية'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: amountCtrl,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'المبلغ (دج)'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'يرجى إدخال المبلغ';
              if (double.tryParse(value) == null || double.parse(value) <= 0) return 'أدخل رقماً صالحاً أكبر من الصفر';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                double amount = double.parse(amountCtrl.text);
                var box = Hive.box('salesBox');
                box.add({
                  'amount': amount,
                  'date': DateTime.now().toIso8601String(),
                });
                setState(() {});
                Navigator.pop(ctx);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  // زر الحذف الخاص بعنصر مبيعات مع استدعاء نافذة التأكيد
  Widget buildSaleItemWidget(int index, Map saleData) {
    return ListTile(
      title: Text('المبلغ: ${saleData['amount']} دج'),
      subtitle: Text('التاريخ: ${saleData['date'].toString().substring(0, 10)}'),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () {
          showDeleteConfirmation(context, () {
            setState(() {
              Hive.box('salesBox').deleteAt(index);
            });
          });
        },
      ),
    );
  }
  void _addSupplierDialog() {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة مورد جديد'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'اسم المورد'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'اسم المورد مطلوب' : null,
              ),
              TextFormField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'قيمة الفاتورة / الدين'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'المبلغ مطلوب';
                  if (double.tryParse(value) == null) return 'أدخل رقماً صحيحاً';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                var box = Hive.box('suppliersBox');
                box.add({
                  'name': nameCtrl.text.trim(),
                  'amount': double.parse(amountCtrl.text),
                  'date': DateTime.now().toIso8601String(),
                });
                setState(() {});
                Navigator.pop(ctx);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Widget buildSupplierItemWidget(int index, Map supplierData) {
    return ListTile(
      title: Text(supplierData['name']),
      subtitle: Text('الدين: ${supplierData['amount']} دج'),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () {
          showDeleteConfirmation(context, () {
            setState(() {
              Hive.box('suppliersBox').deleteAt(index);
            });
          });
        },
      ),
    );
  }
  void _addCreditDialog() {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل دين كريدي جديد'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'اسم الزبون / الموظف'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'الاسم مطلوب' : null,
              ),
              TextFormField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'مبلغ الكريدي'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'المبلغ مطلوب';
                  if (double.tryParse(value) == null || double.parse(value) <= 0) return 'أدخل مبلغاً صالحاً';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                var box = Hive.box('customersBox');
                box.add({
                  'name': nameCtrl.text.trim(),
                  'amount': double.parse(amountCtrl.text),
                  'date': DateTime.now().toIso8601String(),
                });
                setState(() {});
                Navigator.pop(ctx);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Widget buildCreditItemWidget(int index, Map creditData) {
    return ListTile(
      title: Text(creditData['name']),
      subtitle: Text('المبلغ المتبقي: ${creditData['amount']} دج'),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () {
          showDeleteConfirmation(context, () {
            setState(() {
              Hive.box('customersBox').deleteAt(index);
            });
          });
        },
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة المتجر الذكية'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'المبيعات'),
              Tab(text: 'الموردين'),
              Tab(text: 'الكريدي'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // تبويب المبيعات
            Column(
              children: [
                ElevatedButton(onPressed: _addDailySaleDialog, child: const Text('إضافة مبيعات نقدية')),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: Hive.box('salesBox').listenable(),
                    builder: (context, Box box, _) {
                      if (box.isEmpty) return const Center(child: Text('لا توجد مبيعات مسجلة'));
                      return ListView.builder(
                        itemCount: box.length,
                        itemBuilder: (context, index) => buildSaleItemWidget(index, box.getAt(index)),
                      );
                    },
                  ),
                ),
              ],
            ),
            // تبويب الموردين
            Column(
              children: [
                ElevatedButton(onPressed: _addSupplierDialog, child: const Text('إضافة مورد جديد')),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: Hive.box('suppliersBox').listenable(),
                    builder: (context, Box box, _) {
                      if (box.isEmpty) return const Center(child: Text('لا يوجد موردون مسجلون'));
                      return ListView.builder(
                        itemCount: box.length,
                        itemBuilder: (context, index) => buildSupplierItemWidget(index, box.getAt(index)),
                      );
                    },
                  ),
                ),
              ],
            ),
            // تبويب الكريدي
            Column(
              children: [
                ElevatedButton(onPressed: _addCreditDialog, child: const Text('إضافة كريدي جديد')),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: Hive.box('customersBox').listenable(),
                    builder: (context, Box box, _) {
                      if (box.isEmpty) return const Center(child: Text('لا توجد سجلات كريدي'));
                      return ListView.builder(
                        itemCount: box.length,
                        itemBuilder: (context, index) => buildCreditItemWidget(index, box.getAt(index)),
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
