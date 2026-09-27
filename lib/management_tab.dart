import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'settings_page.dart'; // استيراد صفحة الإعدادات المنفصلة

class ManagementTab extends StatefulWidget {
  const ManagementTab({Key? key}) : super(key: key);

  @override
  State<ManagementTab> createState() => _ManagementTabState();
}

class _ManagementTabState extends State<ManagementTab> {
  // متغيرات النظام والإعدادات
  bool isSecurityEnabled = false;
  String securityPin = "1234";
  bool isDarkMode = false;
  bool isManualStartDate = false;
  String manualStartDateStr = "2026-01-01";

  // متغيرات البحث والفلترة
  String salesSearchQuery = "";
  String suppliersSearchQuery = "";
  String creditSearchQuery = "";
  String creditTypeFilter = "الكل";

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

  void _archiveDailySales(Box salesBox) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تصفية وأرشفة مبيعات اليوم', style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold)),
        content: const Text('هل تريد تصفية قائمة المبيعات للبدء من جديد؟ (ملاحظة: الحوصلة الشهرية والسنوية ستتذكر كل هذه العمليات ولن تأثر أبداً).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800]),
            onPressed: () async {
              var archiveBox = await Hive.openBox('archivedSalesBox');
              for (var i = 0; i < salesBox.length; i++) {
                archiveBox.add(salesBox.getAt(i));
              }
              await salesBox.clear();
              setState(() {});
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تمت أرشفة مبيعات اليوم وتصفية القائمة بنجاح')),
              );
            },
            child: const Text('تأكيد التصفية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
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
        title: const Text('إضافة فاتورة مورد / للمورد', style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold)),
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

  // الانتقال إلى صفحة الإعدادات المنفصلة
  void _openSettingsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsPage(
          initialSecurityEnabled: isSecurityEnabled,
          initialPin: securityPin,
          initialDarkMode: isDarkMode,
          initialManualStartDate: isManualStartDate,
          initialStartDateStr: manualStartDateStr,
          onSave: (secEnabled, pin, darkMode, manualStart, startDate) {
            setState(() {
              isSecurityEnabled = secEnabled;
              securityPin = pin;
              isDarkMode = darkMode;
              isManualStartDate = manualStart;
              manualStartDateStr = startDate;
            });
          },
        ),
      ),
    );
  }
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
          if (date.startsWith(currentMonth)) monthlySales += (item['amount'] ?? 0.0);
          if (date.startsWith(currentYear)) yearlySales += (item['amount'] ?? 0.0);
        }

        if (Hive.isBoxOpen('archivedSalesBox')) {
          var archiveBox = Hive.box('archivedSalesBox');
          for (var i = 0; i < archiveBox.length; i++) {
            var item = archiveBox.getAt(i);
            String date = item['date'] ?? '';
            if (date.startsWith(currentMonth)) monthlySales += (item['amount'] ?? 0.0);
            if (date.startsWith(currentYear)) yearlySales += (item['amount'] ?? 0.0);
          }
        }

        for (var i = 0; i < suppliersBox.length; i++) {
          var item = suppliersBox.getAt(i);
          String date = item['date'] ?? '';
          if (date.startsWith(currentMonth)) monthlyCost += (item['amount'] ?? 0.0);
          if (date.startsWith(currentYear)) yearlyCost += (item['amount'] ?? 0.0);
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('الحوصلة المالية الشاملة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0D9488))),
                  IconButton(
                    icon: const Icon(Icons.settings, size: 20, color: Colors.grey), 
                    onPressed: _openSettingsPage, // يفتح صفحة الإعدادات الجديدة
                  )
                ],
              ),
              const Divider(),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('الشهر الحالي:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    'ربح/خسارة: ${monthlyNet.toStringAsFixed(2)} دج',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: monthlyNet >= 0 ? Colors.green[700] : Colors.red[700]),
                  ),
                ],
              ),
              Text('المبيعات: $monthlySales دج | التوريد: $monthlyCost دج', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('السنة الحالية:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    'ربح/خسارة: ${yearlyNet.toStringAsFixed(2)} دج',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: yearlyNet >= 0 ? Colors.green[700] : Colors.red[700]),
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
    final now = DateTime.now();
    final sixtyDaysAgo = now.subtract(const Duration(days: 60));
    final seventyDaysAgo = now.subtract(const Duration(days: 70));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D9488),
          title: const Text('Stitten Business - إدارة المتجر', style: TextStyle(color: Colors.white)),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.point_of_sale), text: 'المبيعات'),
              Tab(icon: Icon(Icons.local_shipping), text: 'الموردين'),
              Tab(icon: Icon(Icons.people), text: 'الكريدي'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- 1. تبويب المبيعات ---
            Column(
              children: [
                buildFinancialSummaryCard(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), minimumSize: const Size.fromHeight(42)),
                          onPressed: _addDailySaleDialog,
                          icon: const Icon(Icons.add, color: Colors.white, size: 18),
                          label: const Text('إضافة مبيعات', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], minimumSize: const Size.fromHeight(42)),
                          onPressed: () => _archiveDailySales(Hive.box('salesBox')),
                          icon: const Icon(Icons.archive, color: Colors.white, size: 18),
                          label: const Text('تصفية وأرشفة يومية', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: Hive.box('salesBox').listenable(),
                    builder: (context, Box box, _) {
                      if (box.isEmpty) {
                        return const Center(child: Text('قائمة مبيعات اليوم فارغة (تمت تصفيتها أو أُضيفت حديثاً)', style: TextStyle(color: Colors.grey)));
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

            // --- 2. تبويب الموردين (مع البحث وأرشيف 60 يوماً) ---
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), minimumSize: const Size.fromHeight(45)),
                        onPressed: _addSupplierDialog,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('إضافة فاتورة مورد / توريد جديد', style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'البحث عن مورد بالاسم...',
                          prefixIcon: Icon(Icons.search, color: Color(0xFF0D9488)),
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) => setState(() => suppliersSearchQuery = val.trim()),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: Hive.box('suppliersBox').listenable(),
                    builder: (context, Box box, _) {
                      List<int> validIndices = [];
                      for (int i = 0; i < box.length; i++) {
                        var item = box.getAt(i);
                        DateTime itemDate = DateTime.parse(item['date'] ?? now.toIso8601String());
                        String name = item['name'] ?? '';
                        if (itemDate.isAfter(sixtyDaysAgo) && name.contains(suppliersSearchQuery)) {
                          validIndices.add(i);
                        }
                      }

                      if (validIndices.isEmpty) {
                        return const Center(child: Text('لا توجد نتائج مطابقة في أرشيف الموردين (60 يوم)', style: TextStyle(color: Colors.grey)));
                      }
                      return ListView.builder(
                        itemCount: validIndices.length,
                        itemBuilder: (context, idx) {
                          int index = validIndices[idx];
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

            // --- 3. تبويب الكريدي (مع البحث، الفلترة، وأرشيف 70 يوماً) ---
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), minimumSize: const Size.fromHeight(45)),
                        onPressed: _addCreditDialog,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('تسجيل كريدي جديد', style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'بحث بالاسم...',
                                prefixIcon: Icon(Icons.search, color: Color(0xFF0D9488)),
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (val) => setState(() => creditSearchQuery = val.trim()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              value: creditTypeFilter,
                              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'الكل', child: Text('الكل')),
                                DropdownMenuItem(value: 'زبون', child: Text('زبون')),
                                DropdownMenuItem(value: 'موظف', child: Text('موظف')),
                              ],
                              onChanged: (val) => setState(() => creditTypeFilter = val!),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: Hive.box('customersBox').listenable(),
                    builder: (context, Box box, _) {
                      List<int> validIndices = [];
                      for (int i = 0; i < box.length; i++) {
                        var item = box.getAt(i);
                        DateTime itemDate = DateTime.parse(item['date'] ?? now.toIso8601String());
                        String name = item['name'] ?? '';
                        String type = item['type'] ?? 'زبون';

                        bool matchesType = (creditTypeFilter == 'الكل' || type == creditTypeFilter);
                        bool matchesSearch = name.contains(creditSearchQuery);
                        if (itemDate.isAfter(seventyDaysAgo) && matchesType && matchesSearch) {
                          validIndices.add(i);
                        }
                      }

                      if (validIndices.isEmpty) {
                        return const Center(child: Text('لا توجد سجلات كريدي مطابقة في أرشيف 70 يوماً', style: TextStyle(color: Colors.grey)));
                      }
                      return ListView.builder(
                        itemCount: validIndices.length,
                        itemBuilder: (context, idx) {
                          int index = validIndices[idx];
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
