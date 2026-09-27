import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManagementTab extends StatefulWidget {
  const ManagementTab({Key? key}) : super(key: key);

  @override
  _ManagementTabState createState() => _ManagementTabState();
}

class _ManagementTabState extends State<ManagementTab> {
  List<Map<String, dynamic>> suppliers = [];
  List<Map<String, dynamic>> customers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      suppliers = (prefs.getStringList('suppliers_list') ?? []).map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
      customers = (prefs.getStringList('customers_list') ?? []).map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('suppliers_list', suppliers.map((e) => jsonEncode(e)).toList());
    await prefs.setStringList('customers_list', customers.map((e) => jsonEncode(e)).toList());
    setState(() {});
  }

  void _showAddEditSupplierDialog({Map<String, dynamic>? supplier, int? index}) {
    final nameController = TextEditingController(text: supplier?['name'] ?? '');
    final phoneController = TextEditingController(text: supplier?['phone'] ?? '');
    final debtController = TextEditingController(text: supplier?['debt']?.toString() ?? '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(supplier == null ? 'إضافة مورد جديد' : 'تعديل المورد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم المورد')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
            TextField(controller: debtController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'مبلغ الدين')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              final data = {
                'name': nameController.text,
                'phone': phoneController.text,
                'debt': double.tryParse(debtController.text) ?? 0.0,
              };
              if (index == null) {
                suppliers.add(data);
              } else {
                suppliers[index] = data;
              }
              _saveData();
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showAddEditCustomerDialog({Map<String, dynamic>? customer, int? index}) {
    final nameController = TextEditingController(text: customer?['name'] ?? '');
    final amountController = TextEditingController(text: customer?['amount']?.toString() ?? '0');
    bool isEmp = customer?['isEmp'] ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(customer == null ? 'إضافة زبون / كريدي' : 'تعديل الحساب'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الزبون أو الموظف')),
              TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'مبلغ الدين (دج)')),
              CheckboxListTile(
                title: const Text('هل هو موظف (لتخليص الشهر)؟'),
                value: isEmp,
                onChanged: (val) => setDialogState(() => isEmp = val ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty) return;
                final data = {
                  'name': nameController.text,
                  'amount': double.tryParse(amountController.text) ?? 0.0,
                  'isEmp': isEmp,
                };
                if (index == null) {
                  customers.add(data);
                } else {
                  customers[index] = data;
                }
                _saveData();
                Navigator.pop(context);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الموردين والزبائن'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الموردين والفواتير', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(onPressed: () => _showAddEditSupplierDialog(), icon: const Icon(Icons.add, size: 18), label: const Text('مورد')),
            ],
          ),
          ...suppliers.asMap().entries.map((entry) => Card(
            child: ListTile(
              title: Text(entry.value['name']),
              subtitle: Text('الهاتف: ${entry.value['phone']} - الدين: ${entry.value['debt']} دج'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showAddEditSupplierDialog(supplier: entry.value, index: entry.key)),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () { setState(() => suppliers.removeAt(entry.key)); _saveData(); }),
                ],
              ),
            ),
          )),
          const Divider(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الزبائن والكريدي والموظفين', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(onPressed: () => _showAddEditCustomerDialog(), icon: const Icon(Icons.add, size: 18), label: const Text('زبون')),
            ],
          ),
          ...customers.asMap().entries.map((entry) => Card(
            child: ListTile(
              title: Text('${entry.value['name']} ${entry.value['isEmp'] ? '(موظف)' : ''}'),
              subtitle: Text('الدين: ${entry.value['amount']} دج'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showAddEditCustomerDialog(customer: entry.value, index: entry.key)),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () { setState(() => customers.removeAt(entry.key)); _saveData(); }),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}
