import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ManagementTab extends StatefulWidget {
  const ManagementTab({Key? key}) : super(key: key);

  @override
  State<ManagementTab> createState() => _ManagementTabState();
}

class _ManagementTabState extends State<ManagementTab> {
  // إعدادات البداية للحوصلات (تلقائي أو تاريخ مخصص)
  bool isManualStartDate = false;
  String manualStartDateStr = "2026-01-01";

  // دالة عامة لتأكيد الحذف
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
                Hive.box('salesBox').add({
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

  // --- نافذة تعديل مبيعات نقدية ---
  void _editDailySaleDialog(int index, Map item) {
    final amountCtrl = TextEditingController(text: item['amount'].toString());
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل المبيعات النقدية', style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold)),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'المبلغ النقدي الجديد (دج)', prefixIcon: Icon(Icons.money, color: Color(0xFF0D9488))),
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
                Hive.box('salesBox').putAt(index, {
                  'amount': double.parse(amountCtrl.text),
                  'date': item['date'],
                });
                setState(() {});
                Navigator.pop(ctx);
              }
            },
            child: const Text('تحديث', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        title: const Text('إضافة فاتورة توريد / للمورد', style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold)),
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
                decoration: const InputDecoration(labelText: 'قيمة التوريد/الفاتورة (دج)', prefixIcon: Icon(Icons.receipt, color: Color(0xFF0D9488))),
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

  // --- نافذة تعديل الموردين ---
  void _editSupplierDialog(int index, Map item) {
    final nameCtrl = TextEditingController(text: item['name']);
    final amountCtrl = TextEditingController(text: item['amount'].toString());
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل بيانات المورد / التوريد', style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold)),
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
                decoration: const InputDecoration(labelText: 'قيمة التوريد/الفاتورة (دج)', prefixIcon: Icon(Icons.receipt, color: Color(0xFF0D9488))),
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
                Hive.box('suppliersBox').putAt(index, {
                  'name': nameCtrl.text.trim(),
                  'amount': double.parse(amountCtrl.text),
                  'date': item['date'],
                });
                setState(() {});
                Navigator.pop(ctx);
              }
            },
            child: const Text('تحديث', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- نافذة إضافة كريدي ---
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

  // --- نافذة تعديل الكريدي ---
  void _editCreditDialog(int index, Map item) {
    String type = item['type'] ?? 'زبون';
    final nameCtrl = TextEditingController(text: item['name']);
    final amountCtrl = TextEditingController(text: item['amount'].toString());
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تعديل حساب الكريدي', style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold)),
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
                  Hive.box('customersBox').putAt(index, {
                    'type': type,
                    'name': nameCtrl.text.trim(),
                    'amount': double.parse(amountCtrl.text),
                    'date': item['date'],
                  });
                  setState(() {});
                  Navigator.pop(ctx);
                }
              },
              child: const Text('تحديث', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // --- نافذة إعدادات نقطة البداية للحوصلات ---
  void _showSettingsDialog() {
    final dateCtrl = TextEditingController(text: manualStartDateStr);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إعدادات حساب الحوصلة', style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('تحديد تاريخ بداية يدوي'),
                subtitle: Text(isManualStartDate ? 'الاعتماد على التاريخ المخصص' : 'تلقائي (من أول عملية)'),
                value: isManualStartDate,
                activeColor: const Color(0xFF0D9488),
                onChanged: (val) {
                  setDialogState(() => isManualStartDate = val);
                  setState(() {});
                },
              ),
              if (isManualStartDate) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: dateCtrl,
                  decoration: const InputDecoration(labelText: 'تاريخ البداية (YYYY-MM-DD)', prefixIcon: Icon(Icons.date_range)),
                  onChanged: (val) => manualStartDateStr = val,
                ),
              ]
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
              onPressed: () {
                setState(() {});
                Navigator.pop(ctx);
              },
              child: const Text('تم', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
    // --- مكون الحوصلة المالية الشهرية والسنوية ---
  Widget buildFinancialSummaryCard() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        Hive.box('salesBox').listenable(),
        Hive.box('suppliersBox').listenable(),
      ]),
      builder: (context, _) {
        final salesBox = Hive.box('salesBox');
        final suppliersBox = Hive.box('suppliersBox');

        String currentMonth = DateTime.now().toString().substring(0, 7);
        String currentYear = DateTime.now().toString().substring(0, 4);

        double monthlySales = 0.0;
        double monthlyCost = 0.0;
        double yearlySales = 0.0;
        double yearlyCost = 0.0;

        for (var i = 0; i < salesBox.length; i++) {
          var item = salesBox.getAt(i);
          String date = item['date'] ?? '';
          if (date.startsWith(currentMonth)) {
            monthlySales += (item['amount'] ?? 0.0);
          }
          if (date.startsWith(currentYear)) {
            yearlySales += (item['amount'] ?? 0.0);
          }
        }

        for (var i = 0; i < suppliersBox.length; i++) {
          var item = suppliersBox.getAt(i);
          String date = item['date'] ?? '';
          if (date.startsWith(currentMonth)) {
            monthlyCost += (item['amount'] ?? 0.0);
          }
          if (date.startsWith(currentYear)) {
            yearlyCost += (item['amount'] ?? 0.0);
          }
        }

        double monthlyNet = monthlySales - monthlyCost;
        double yearlyNet = yearlySales - yearlyCost;

        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF0D9488), width: 1.5),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.between,
                children: [
                  const Text('الحوصلة المالية (مبيعات - توريد)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0D9488))),
                  IconButton(icon: const Icon(Icons.settings, size: 20, color: Colors.grey), onPressed: _showSettingsDialog)
                ],
              ),
              const Divider(),
              const SizedBox(height: 5),
              // الحوصلة الشهرية
              Row(
                mainAxisAlignment: MainAxisAlignment.between,
                children: [
                  const Text('الشهر الحالي:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    'ربح/خسارة: ${monthlyNet.toStringAsFixed(2)} دج',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: monthlyNet >= 0 ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ],
              ),
              Text('المبيعات: $monthlySales دج | التوريد: $monthlyCost دج', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 12),
              // الحوصلة السنوية
              Row(
                mainAxisAlignment: MainAxisAlignment.between,
                children: [
                  const Text('السنة الحالية:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    'ربح/خسارة: ${yearlyNet.toStringAsFixed(2)} دج',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: yearlyNet >= 0 ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ],
              ),
              Text('المبيعات: $yearlySales دج | التوريد: $yearlyCost دج', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }
    @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D9488),
          title: const Text('Stitten Business - إدارة المتجر'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.point_of_sale), text: 'المبيعات والحوصلة'),
              Tab(icon: Icon(Icons.local_shipping), text: 'الموردين'),
              Tab(icon: Icon(Icons.people), text: 'الكريدي'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- تبويب المبيعات والحوصلة ---
            Column(
              children: [
                buildFinancialSummaryCard(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), minimumSize: const Size.fromHeight(45)),
                    onPressed: _addDailySaleDialog,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('تسجيل مبيعات نقدية جديدة', style: TextStyle(color: Colors.white)),
                  ),
                ),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: Hive.box('salesBox').listenable(),
                    builder: (context, Box box, _) {
                      if (box.isEmpty) {
                        return const Center(child: Text('لا توجد مبيعات مسجلة', style: TextStyle(color: Colors.grey)));
                      }
                      return ListView.builder(
                        itemCount: box.length,
                        itemBuilder: (context, index) {
                          final item = box.getAt(index);
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: ListTile(
                              leading: const CircleAvatar(backgroundColor: Color(0xFF0D9488), child: Icon(Icons.attach_money, color: Colors.white)),
                              title: Text('المبلغ: ${item['amount']} دج', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('التاريخ: ${item['date'].toString().substring(0, 16)}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    tooltip: 'تعديل',
                                    onPressed: () => _editDailySaleDialog(index, item),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'حذف',
                                    onPressed: () => showDeleteConfirmation(context, () => box.deleteAt(index)),
                                  ),
                                ],
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

            // --- تبويب الموردين والتوريد ---
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), minimumSize: const Size.fromHeight(45)),
                    onPressed: _addSupplierDialog,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('إضافة فاتورة مورد / توريد جديد', style: TextStyle(color: Colors.white)),
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
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: ListTile(
                              leading: const CircleAvatar(backgroundColor: Colors.blueGrey, child: Icon(Icons.store, color: Colors.white)),
                              title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('قيمة التوريد: ${item['amount']} دج | التاريخ: ${item['date'].toString().substring(0, 10)}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    tooltip: 'تعديل',
                                    onPressed: () => _editSupplierDialog(index, item),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'حذف',
                                    onPressed: () => showDeleteConfirmation(context, () => box.deleteAt(index)),
                                  ),
                                ],
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
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), minimumSize: const Size.fromHeight(45)),
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
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: item['type'] == 'موظف' ? Colors.orange : Colors.indigo,
                                child: Icon(item['type'] == 'موظف' ? Icons.badge : Icons.person, color: Colors.white),
                              ),
                              title: Text('${item['name']} (${item['type']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('المبلغ: ${item['amount']} دج'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    tooltip: 'تعديل',
                                    onPressed: () => _editCreditDialog(index, item),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'حذف',
                                    onPressed: () => showDeleteConfirmation(context, () => box.deleteAt(index)),
                                  ),
                                ],
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
