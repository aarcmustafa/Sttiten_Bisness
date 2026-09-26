import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => StoreProvider()..cleanOldInvoices(),
      child: const StittenStoresApp(),
    ),
  );
}

class StittenStoresApp extends StatelessWidget {
  const StittenStoresApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stitten Stores 2.0',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Arial',
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        )
      ),
      // لدعم اللغة العربية من اليمين لليسار
      locale: const Locale('ar', 'AE'),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const HomeScreen(),
    );
  }
}

// ==========================================
// 1. MODELS (هيكلة البيانات)
// ==========================================
class Supplier {
  String id;
  String name;
  String phone;
  DateTime startDate;
  List<Invoice> invoices = [];
  Supplier({required this.id, required this.name, required this.phone, required this.startDate});
}

class Invoice {
  String id;
  DateTime date;
  double totalAmount;
  double paidAmount;
  Invoice({required this.id, required this.date, required this.totalAmount, required this.paidAmount});
  double get remainingDebt => totalAmount - paidAmount;
}

class DailySale {
  DateTime date;
  double cashAmount;
  DailySale({required this.date, required this.cashAmount});
}

class Customer {
  String id;
  String name;
  String phone;
  bool isEmployee;
  DateTime? monthStartDate;
  List<Purchase> purchases = [];
  Customer({required this.id, required this.name, required this.phone, required this.isEmployee, this.monthStartDate});
}

class Purchase {
  DateTime date;
  double amount;
  Purchase({required this.date, required this.amount});
}

// ==========================================
// 2. STATE MANAGEMENT (المنطق والعمليات الحسابية)
// ==========================================
class StoreProvider with ChangeNotifier {
  List<Supplier> suppliers = [];
  List<DailySale> sales = [];
  List<Customer> customers = [];
  
  // أول يوم من الشهر لعمليات الصندوق
  DateTime boxStartDate = DateTime(DateTime.now().year, DateTime.now().month, 1); 

  // --- قسم الموردين ---
  void addSupplier(String name, String phone) {
    suppliers.add(Supplier(id: DateTime.now().toString(), name: name, phone: phone, startDate: DateTime.now()));
    notifyListeners();
  }

  void addInvoiceToSupplier(String supplierId, double total, double paid) {
    var supplier = suppliers.firstWhere((s) => s.id == supplierId);
    supplier.invoices.add(Invoice(id: DateTime.now().toString(), date: DateTime.now(), totalAmount: total, paidAmount: paid));
    notifyListeners();
  }

  void cleanOldInvoices() {
    // حذف يدوياً وتلقائياً للفواتير التي تجاوزت شهرين
    final twoMonthsAgo = DateTime.now().subtract(const Duration(days: 60));
    for (var supplier in suppliers) {
      supplier.invoices.removeWhere((inv) => inv.date.isBefore(twoMonthsAgo));
    }
    notifyListeners();
  }

  // --- قسم المبيعات ---
  void addDailySale(double amount) {
    sales.add(DailySale(date: DateTime.now(), cashAmount: amount));
    notifyListeners();
  }

  double getTodayCashSales() {
    DateTime today = DateTime.now();
    return sales.where((s) => isSameDay(s.date, today)).fold(0, (sum, item) => sum + item.cashAmount);
  }

  double getTodayCreditSales() {
    DateTime today = DateTime.now();
    double credit = 0;
    for (var c in customers) {
      credit += c.purchases.where((p) => isSameDay(p.date, today)).fold(0, (sum, item) => sum + item.amount);
    }
    return credit;
  }

  // --- قسم الكريدي ---
  void addCustomer(String name, String phone, bool isEmployee, DateTime? startDate) {
    customers.add(Customer(id: DateTime.now().toString(), name: name, phone: phone, isEmployee: isEmployee, monthStartDate: startDate));
    notifyListeners();
  }

  void addPurchaseToCustomer(String customerId, double amount) {
    var customer = customers.firstWhere((c) => c.id == customerId);
    customer.purchases.add(Purchase(date: DateTime.now(), amount: amount));
    notifyListeners();
  }

  void settleMonthlyCustomer(String customerId, double paidAmount) {
    var customer = customers.firstWhere((c) => c.id == customerId);
    double totalPurchases = customer.purchases.fold(0, (sum, item) => sum + item.amount);
    double remaining = totalPurchases - paidAmount;
    
    // تصفير المشتريات السابقة
    customer.purchases.clear();
    // ترحيل الباقي للشهر الجديد
    if (remaining > 0) {
      customer.purchases.add(Purchase(date: DateTime.now(), amount: remaining));
    }
    notifyListeners();
  }

  // التنبيهات: الموظفون الذين حان أجل تخليصهم (مر شهر)
  List<Customer> get alertCustomers {
    return customers.where((c) {
      if (!c.isEmployee || c.monthStartDate == null) return false;
      return DateTime.now().difference(c.monthStartDate!).inDays >= 30;
    }).toList();
  }

  // --- قسم الصندوق (الأرباح والخسائر) ---
  void setBoxStartDate(DateTime date) {
    boxStartDate = date;
    notifyListeners();
  }

  double get totalMonthlySales {
    // جمع مبيعات الشهر بناء على تاريخ بداية الصندوق
    return sales.where((s) => s.date.isAfter(boxStartDate) || isSameDay(s.date, boxStartDate)).fold(0, (sum, item) => sum + item.cashAmount);
  }

  double get totalMonthlyCosts {
    // جمع تكاليف الموردين
    double cost = 0;
    for (var s in suppliers) {
      cost += s.invoices.where((inv) => inv.date.isAfter(boxStartDate) || isSameDay(inv.date, boxStartDate)).fold(0, (sum, item) => sum + item.paidAmount);
    }
    return cost;
  }

  bool isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }
}

// ==========================================
// 3. UI SCREENS (الواجهات)
// ==========================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var alerts = context.watch<StoreProvider>().alertCustomers;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Stitten Stores 2.0')),
      body: Column(
        children: [
          if (alerts.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade100,
              child: Text(
                'تنبيه: يوجد ${alerts.length} موظف حان وقت تخليصهم!', 
                textAlign: TextAlign.center, 
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)
              ),
            ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildMenuBtn(context, 'الموردين', const SuppliersScreen(), Icons.local_shipping),
                _buildMenuBtn(context, 'المبيعات', const SalesScreen(), Icons.point_of_sale),
                _buildMenuBtn(context, 'الكريدي والزبائن', const CreditScreen(), Icons.people),
                _buildMenuBtn(context, 'الصندوق (أرباح)', const BoxScreen(), Icons.account_balance_wallet),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuBtn(BuildContext ctx, String title, Widget screen, IconData icon) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
      ),
      onPressed: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => screen)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40), 
          const SizedBox(height: 10), 
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center)
        ],
      ),
    );
  }
}

// ------------------------------------------
// شاشة الموردين
// ------------------------------------------
class SuppliersScreen extends StatelessWidget {
  const SuppliersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var provider = context.watch<StoreProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('الموردين')),
      body: ListView.builder(
        itemCount: provider.suppliers.length,
        itemBuilder: (ctx, i) {
          var s = provider.suppliers[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(s.phone),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SupplierDetailsScreen(supplier: s))),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSupplierDialog(context),
        label: const Text('إضافة مورد'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showAddSupplierDialog(BuildContext context) {
    String name = '', phone = '';
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('إضافة مورد جديد'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(decoration: const InputDecoration(labelText: 'الاسم الكامل'), onChanged: (v) => name = v),
          TextField(decoration: const InputDecoration(labelText: 'رقم الهاتف'), keyboardType: TextInputType.phone, onChanged: (v) => phone = v),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () {
          if(name.isNotEmpty) {
            context.read<StoreProvider>().addSupplier(name, phone);
            Navigator.pop(ctx);
          }
        }, child: const Text('إضافة'))
      ],
    ));
  }
}

// ------------------------------------------
// تفاصيل المورد (الفواتير)
// ------------------------------------------
class SupplierDetailsScreen extends StatelessWidget {
  final Supplier supplier;
  const SupplierDetailsScreen({Key? key, required this.supplier}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // نعيد قراءة بيانات المورد لضمان التحديث اللحظي
    var provider = context.watch<StoreProvider>();
    var currentSupplier = provider.suppliers.firstWhere((s) => s.id == supplier.id);
    
    double totalDebt = currentSupplier.invoices.fold(0, (sum, inv) => sum + inv.remainingDebt);

    return Scaffold(
      appBar: AppBar(title: Text('فواتير: ${currentSupplier.name}')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade200,
            child: Column(
              children: [
                const Text('إجمالي الدين الباقي على التاجر', style: TextStyle(fontSize: 16)),
                Text(
                  totalDebt.toStringAsFixed(2), 
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: totalDebt > 0 ? Colors.red : Colors.green)
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: currentSupplier.invoices.length,
              itemBuilder: (ctx, i) {
                var inv = currentSupplier.invoices[i];
                Color numColor = inv.remainingDebt <= 0 ? Colors.green : Colors.red;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text('التاريخ: ${inv.date.toString().substring(0,10)}'),
                    subtitle: Text('الكلية: ${inv.totalAmount} | المدفوعة: ${inv.paidAmount}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('الباقي'),
                        Text('${inv.remainingDebt}', style: TextStyle(color: numColor, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddInvoiceDialog(context),
        label: const Text('إضافة فاتورة'),
        icon: const Icon(Icons.receipt),
      ),
    );
  }

  void _showAddInvoiceDialog(BuildContext context) {
    double total = 0, paid = 0;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('فاتورة جديدة'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('يسجل التاريخ آلياً', style: TextStyle(color: Colors.grey, fontSize: 12)),
          TextField(decoration: const InputDecoration(labelText: 'قيمة الفاتورة الكلية'), keyboardType: TextInputType.number, onChanged: (v) => total = double.tryParse(v) ?? 0),
          TextField(decoration: const InputDecoration(labelText: 'القيمة المدفوعة'), keyboardType: TextInputType.number, onChanged: (v) => paid = double.tryParse(v) ?? 0),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () {
          context.read<StoreProvider>().addInvoiceToSupplier(supplier.id, total, paid);
          Navigator.pop(ctx);
        }, child: const Text('حفظ'))
      ],
    ));
  }
}

// ------------------------------------------
// شاشة المبيعات
// ------------------------------------------
class SalesScreen extends StatelessWidget {
  const SalesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var provider = context.watch<StoreProvider>();
    double todayCash = provider.getTodayCashSales();
    double todayCredit = provider.getTodayCreditSales();
    double totalToday = todayCash + todayCredit;

    return Scaffold(
      appBar: AppBar(title: const Text('المبيعات اليومية')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('حوصلة مبيعات اليوم', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    Text('نقداً: $todayCash'),
                    Text('بالكريدي: $todayCredit'),
                    const SizedBox(height: 10),
                    Text('المجموع الكلي: $totalToday', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              onPressed: () => _showAddCashSaleDialog(context),
              icon: const Icon(Icons.attach_money),
              label: const Text('إضافة مبيعات نقداً (يسجل التاريخ آلياً)', style: TextStyle(fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }

  void _showAddCashSaleDialog(BuildContext context) {
    double amount = 0;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('إضافة مبيعات نقدية'),
      content: TextField(
        decoration: const InputDecoration(labelText: 'القيمة'),
        keyboardType: TextInputType.number,
        onChanged: (v) => amount = double.tryParse(v) ?? 0,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () {
          if(amount > 0) {
            context.read<StoreProvider>().addDailySale(amount);
            Navigator.pop(ctx);
          }
        }, child: const Text('إضافة'))
      ],
    ));
  }
}

// ------------------------------------------
// شاشة الكريدي والزبائن (مع الرزنامة)
// ------------------------------------------
class CreditScreen extends StatelessWidget {
  const CreditScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var provider = context.watch<StoreProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('الكريدي والزبائن')),
      body: ListView.builder(
        itemCount: provider.customers.length,
        itemBuilder: (ctx, i) {
          var c = provider.customers[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              leading: Icon(c.isEmployee ? Icons.badge : Icons.person),
              title: Text('${c.name} ${c.isEmployee ? "(موظف)" : "(آخرون)"}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(c.phone),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerDetailsScreen(customer: c))),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCustomerDialog(context),
        label: const Text('إضافة زبون'),
        icon: const Icon(Icons.person_add),
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    String name = '', phone = '';
    bool isEmployee = false;
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('إضافة زبون جديد'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: isEmployee ? Colors.blue : Colors.grey.shade400),
                        onPressed: () => setState(() => isEmployee = true),
                        child: const Text('موظف'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: !isEmployee ? Colors.blue : Colors.grey.shade400),
                        onPressed: () => setState(() {
                          isEmployee = false;
                          selectedDate = null;
                        }),
                        child: const Text('آخرون'),
                      ),
                    ],
                  ),
                  TextField(decoration: const InputDecoration(labelText: 'الاسم الكامل'), onChanged: (v) => name = v),
                  TextField(decoration: const InputDecoration(labelText: 'رقم الهاتف'), keyboardType: TextInputType.phone, onChanged: (v) => phone = v),
                  const SizedBox(height: 15),
                  // إظهار الرزنامة فقط للموظف
                  if (isEmployee)
                    OutlinedButton.icon(
                      icon:
