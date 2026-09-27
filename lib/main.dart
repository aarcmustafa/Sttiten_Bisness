import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Arial',
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.blueAccent,
        )
      ),
      locale: const Locale('ar', 'AE'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'AE'),
      ],
      home: const LockScreen(), // يبدأ بشاشة قفل الحماية (الخطوة 5)
    );
  }
}

// ==========================================
// MODELS (هيكلة البيانات)
// ==========================================
class Supplier {
  String id;
  String name;
  String phone;
  DateTime startDate;
  List<Invoice> invoices = [];
  Supplier({required this.id, required this.name, required this.phone, required this.startDate});

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'phone': phone, 'startDate': startDate.toIso8601String(),
    'invoices': invoices.map((i) => i.toJson()).toList()
  };

  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
    id: json['id'], name: json['name'], phone: json['phone'], startDate: DateTime.parse(json['startDate'])
  )..invoices = (json['invoices'] as List).map((i) => Invoice.fromJson(i)).toList();
}

class Invoice {
  String id;
  DateTime date;
  double totalAmount;
  double paidAmount;
  Invoice({required this.id, required this.date, required this.totalAmount, required this.paidAmount});
  double get remainingDebt => totalAmount - paidAmount;

  Map<String, dynamic> toJson() => {'id': id, 'date': date.toIso8601String(), 'totalAmount': totalAmount, 'paidAmount': paidAmount};
  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(id: json['id'], date: DateTime.parse(json['date']), totalAmount: json['totalAmount'], paidAmount: json['paidAmount']);
}

class DailySale {
  DateTime date;
  double cashAmount;
  DailySale({required this.date, required this.cashAmount});

  Map<String, dynamic> toJson() => {'date': date.toIso8601String(), 'cashAmount': cashAmount};
  factory DailySale.fromJson(Map<String, dynamic> json) => DailySale(date: DateTime.parse(json['date']), cashAmount: json['cashAmount']);
}

class Customer {
  String id;
  String name;
  String phone;
  bool isEmployee;
  DateTime? monthStartDate;
  List<Purchase> purchases = [];
  Customer({required this.id, required this.name, required this.phone, required this.isEmployee, this.monthStartDate});

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'phone': phone, 'isEmployee': isEmployee,
    'monthStartDate': monthStartDate?.toIso8601String(),
    'purchases': purchases.map((p) => p.toJson()).toList()
  };

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json['id'], name: json['name'], phone: json['phone'], isEmployee: json['isEmployee'],
    monthStartDate: json['monthStartDate'] != null ? DateTime.parse(json['monthStartDate']) : null
  )..purchases = (json['purchases'] as List).map((p) => Purchase.fromJson(p)).toList();
}

class Purchase {
  DateTime date;
  double amount;
  Purchase({required this.date, required this.amount});

  Map<String, dynamic> toJson() => {'date': date.toIso8601String(), 'amount': amount};
  factory Purchase.fromJson(Map<String, dynamic> json) => Purchase(date: DateTime.parse(json['date']), amount: json['amount']);
}

// ==========================================
// STATE MANAGEMENT (المنطق، العمليات، والنسخ الاحتياطي - الخطوة 3)
// ==========================================
class StoreProvider with ChangeNotifier {
  List<Supplier> suppliers = [];
  List<DailySale> sales = [];
  List<Customer> customers = [];
  
  DateTime boxStartDate = DateTime(DateTime.now().year, DateTime.now().month, 1); 

  // ميزة تصدير البيانات (نسخ احتياطي)
  String exportDataToJson() {
    final Map<String, dynamic> data = {
      'boxStartDate': boxStartDate.toIso8601String(),
      'suppliers': suppliers.map((s) => s.toJson()).toList(),
      'sales': sales.map((s) => s.toJson()).toList(),
      'customers': customers.map((c) => c.toJson()).toList(),
    };
    return jsonEncode(data);
  }

  // ميزة استعادة البيانات
  bool importDataFromJson(String jsonString) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      boxStartDate = DateTime.parse(data['boxStartDate']);
      suppliers = (data['suppliers'] as List).map((s) => Supplier.fromJson(s)).toList();
      sales = (data['sales'] as List).map((s) => DailySale.fromJson(s)).toList();
      customers = (data['customers'] as List).map((c) => Customer.fromJson(c)).toList();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  void addSupplier(String name, String phone) {
    suppliers.add(Supplier(id: DateTime.now().toString(), name: name, phone: phone, startDate: DateTime.now()));
    notifyListeners();
  }

  void updateSupplier(String id, String name, String phone) {
    var supplier = suppliers.firstWhere((s) => s.id == id);
    supplier.name = name;
    supplier.phone = phone;
    notifyListeners();
  }

  void deleteSupplier(String id) {
    suppliers.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  void addInvoiceToSupplier(String supplierId, double total, double paid) {
    var supplier = suppliers.firstWhere((s) => s.id == supplierId);
    supplier.invoices.add(Invoice(id: DateTime.now().toString(), date: DateTime.now(), totalAmount: total, paidAmount: paid));
    notifyListeners();
  }

  void cleanOldInvoices() {
    final twoMonthsAgo = DateTime.now().subtract(const Duration(days: 60));
    for (var supplier in suppliers) {
      supplier.invoices.removeWhere((inv) => inv.date.isBefore(twoMonthsAgo));
    }
    notifyListeners();
  }

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

  void addCustomer(String name, String phone, bool isEmployee, DateTime? startDate) {
    customers.add(Customer(id: DateTime.now().toString(), name: name, phone: phone, isEmployee: isEmployee, monthStartDate: startDate));
    notifyListeners();
  }

  void updateCustomer(String id, String name, String phone, bool isEmployee, DateTime? startDate) {
    var customer = customers.firstWhere((c) => c.id == id);
    customer.name = name;
    customer.phone = phone;
    customer.isEmployee = isEmployee;
    customer.monthStartDate = startDate;
    notifyListeners();
  }

  void deleteCustomer(String id) {
    customers.removeWhere((c) => c.id == id);
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
    
    customer.purchases.clear();
    if (remaining > 0) {
      customer.purchases.add(Purchase(date: DateTime.now(), amount: remaining));
    }
    notifyListeners();
  }

  List<Customer> get alertCustomers {
    return customers.where((c) {
      if (!c.isEmployee || c.monthStartDate == null) return false;
      return DateTime.now().difference(c.monthStartDate!).inDays >= 30;
    }).toList();
  }

  void setBoxStartDate(DateTime date) {
    boxStartDate = date;
    notifyListeners();
  }

  double get totalMonthlySales {
    return sales.where((s) => s.date.isAfter(boxStartDate) || isSameDay(s.date, boxStartDate)).fold(0, (sum, item) => sum + item.cashAmount);
  }

  double get totalMonthlyCosts {
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

Route smoothNavigate(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 0.05);
      const end = Offset.zero;
      const curve = Curves.easeInOut;
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var fadeTween = Tween<double>(begin: 0.0, end: 1.0);
      
      return SlideTransition(
        position: animation.drive(tween),
        child: FadeTransition(
          opacity: animation.drive(fadeTween),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}
// ------------------------------------------
// شاشة قفل الحماية برمز PIN (الخطوة 5)
// ------------------------------------------
class LockScreen extends StatefulWidget {
  const LockScreen({Key? key}) : super(key: key);

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final String correctPin = '1234'; // الرمز الافتراضي (يمكن للتاجر تغييره لاحقاً)
  String enteredPin = '';

  void _onNumberTap(String number) {
    if (enteredPin.length < 4) {
      setState(() {
        enteredPin += number;
      });
      if (enteredPin.length == 4) {
        if (enteredPin == correctPin) {
          Navigator.pushReplacement(context, smoothNavigate(const HomeScreen()));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('الرمز خطأ! حاول مجدداً (الرمز الافتراضي: 1234)'), backgroundColor: Colors.red),
          );
          setState(() {
            enteredPin = '';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            const Text('أدخل رمز الحماية لفتح التطبيق', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < enteredPin.length ? Colors.white : Colors.white.withOpacity(0.4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 40),
            for (var row in [['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9'], ['', '0', 'del']])
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row.map((item) {
                  if (item.isEmpty) return Container(width: 70, height: 70, margin: const EdgeInsets.all(10));
                  return Container(
                    width: 70,
                    height: 70,
                    margin: const EdgeInsets.all(10),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: Colors.white.withOpacity(0.2),
                        elevation: 0,
                      ),
                      onPressed: () {
                        if (item == 'del') {
                          if (enteredPin.isNotEmpty) {
                            setState(() {
                              enteredPin = enteredPin.substring(0, enteredPin.length - 1);
                            });
                          }
                        } else {
                          _onNumberTap(item);
                        }
                      },
                      child: item == 'del'
                          ? const Icon(Icons.backspace, color: Colors.white)
                          : Text(item, style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------
// الواجهة الرئيسية وحول التطبيق
// ------------------------------------------
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var alerts = context.watch<StoreProvider>().alertCustomers;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.storefront, size: 28),
            SizedBox(width: 8),
            Text('Stitten Stores 2.0'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_backup_restore),
            tooltip: 'النسخ الاحتياطي',
            onPressed: () => _showBackupDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAboutDialog(context),
          ),
        ],
      ),
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
                _buildMenuBtn(context, 'المبيعات والتقارير', const SalesScreen(), Icons.point_of_sale),
                _buildMenuBtn(context, 'الكريدي والزبائن', const CreditScreen(), Icons.people),
                _buildMenuBtn(context, 'الصندوق والأرباح', const BoxScreen(), Icons.account_balance_wallet),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12.0),
            alignment: Alignment.center,
            child: const Text(
              'تطوير وتصميم: جلولي مصطفى',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog(BuildContext context) {
    final provider = context.read<StoreProvider>();
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('النسخ الاحتياطي والاستعادة (الخطوة 3)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('قم بنسخ الكود أدناه واحتفظ به، أو الصقه للاستعادة:'),
            const SizedBox(height: 10),
            TextField(
              controller: controller..text = provider.exportDataToJson(),
              maxLines: 4,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              bool success = provider.importDataFromJson(controller.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(success ? 'تمت استعادة البيانات بنجاح' : 'فشل الاستعادة، الكود غير صحيح'), backgroundColor: success ? Colors.green : Colors.red),
              );
            },
            child: const Text('استعادة البيانات'),
          ),
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حول التطبيق'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Stitten Stores 2.0', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            Text('الإصدار: 2.0.0'),
            SizedBox(height: 8),
            Text('المصمم والمطور: جلولي مصطفى'),
            SizedBox(height: 12),
            Text('تطبيق متكامل لإدارة المتاجر، الموردين، المبيعات، والكريدي بكل احترافية مع حماية كاملة.'),
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  Widget _buildMenuBtn(BuildContext ctx, String title, Widget screen, IconData icon) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => Navigator.push(ctx, smoothNavigate(screen)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 45, color: Colors.blueAccent), 
            const SizedBox(height: 12), 
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center)
          ],
        ),
      ),
    );
  }
}

// شاشة الموردين
class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({Key? key}) : super(key: key);

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    var provider = context.watch<StoreProvider>();
    var filteredSuppliers = provider.suppliers.where((s) => s.name.contains(searchQuery) || s.phone.contains(searchQuery)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('الموردين')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(labelText: 'بحث عن مورد...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
              onChanged: (v) => setState(() => searchQuery = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredSuppliers.length,
              itemBuilder: (ctx, i) {
                var s = filteredSuppliers[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(s.phone),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showEditSupplierDialog(context, s)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDeleteSupplier(context, s.id)),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                    onTap: () => Navigator.push(context, smoothNavigate(SupplierDetailsScreen(supplier: s))),
                  ),
                );
              },
            ),
          ),
        ],
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
        ElevatedButton(onPressed: () { if(name.isNotEmpty) { context.read<StoreProvider>().addSupplier(name, phone); Navigator.pop(ctx); } }, child: const Text('إضافة'))
      ],
    ));
  }

  void _showEditSupplierDialog(BuildContext context, Supplier supplier) {
    String name = supplier.name, phone = supplier.phone;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('تعديل بيانات المورد'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: TextEditingController(text: name), decoration: const InputDecoration(labelText: 'الاسم الكامل'), onChanged: (v) => name = v),
          TextField(controller: TextEditingController(text: phone), decoration: const InputDecoration(labelText: 'رقم الهاتف'), keyboardType: TextInputType.phone, onChanged: (v) => phone = v),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () { if(name.isNotEmpty) { context.read<StoreProvider>().updateSupplier(supplier.id, name, phone); Navigator.pop(ctx); } }, child: const Text('تحديث'))
      ],
    ));
  }

  void _confirmDeleteSupplier(BuildContext context, String id) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('تأكيد الحذف'),
      content: const Text('هل أنت متأكد من حذف هذا المورد؟'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () { context.read<StoreProvider>().deleteSupplier(id); Navigator.pop(ctx); }, child: const Text('حذف'))
      ],
    ));
  }
}

class SupplierDetailsScreen extends StatelessWidget {
  final Supplier supplier;
  const SupplierDetailsScreen({Key? key, required this.supplier}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var provider = context.watch<StoreProvider>();
    var currentSupplier = provider.suppliers.firstWhere((s) => s.id == supplier.id, orElse: () => supplier);
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
                Text(totalDebt.toStringAsFixed(2), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: totalDebt > 0 ? Colors.red : Colors.green)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: currentSupplier.invoices.length,
              itemBuilder: (ctx, i) {
                var inv = currentSupplier.invoices[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text('التاريخ: ${inv.date.toString().substring(0,10)}'),
                    subtitle: Text('الكلية: ${inv.totalAmount} | المدفوعة: ${inv.paidAmount}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('الباقي'),
                        Text('${inv.remainingDebt}', style: TextStyle(color: inv.remainingDebt <= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
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
          TextField(decoration: const InputDecoration(labelText: 'قيمة الفاتورة الكلية'), keyboardType: TextInputType.number, onChanged: (v) => total = double.tryParse(v) ?? 0),
          TextField(decoration: const InputDecoration(labelText: 'القيمة المدفوعة'), keyboardType: TextInputType.number, onChanged: (v) => paid = double.tryParse(v) ?? 0),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () { context.read<StoreProvider>().addInvoiceToSupplier(supplier.id, total, paid); Navigator.pop(ctx); }, child: const Text('حفظ'))
      ],
    ));
  }
}
// ------------------------------------------
// شاشة المبيعات والتقارير المتقدمة (الخطوة 4)
// ------------------------------------------
class SalesScreen extends StatelessWidget {
  const SalesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var provider = context.watch<StoreProvider>();
    double todayCash = provider.getTodayCashSales();
    double todayCredit = provider.getTodayCreditSales();
    double totalToday = todayCash + todayCredit;

    // حساب إجمالي مبيعات الشهر الحالي مقارنة بالعامة
    double monthlySales = provider.totalMonthlySales;

    return Scaffold(
      appBar: AppBar(title: const Text('المبيعات والتقارير المتقدمة')),
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
                    Text('نقداً: $todayCash دج'),
                    Text('بالكريدي: $todayCredit دج'),
                    const SizedBox(height: 10),
                    Text('المجموع الكلي اليوم: $totalToday دج', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('تقارير الأداء المتقدمة (الخطوة 4)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Divider(),
                    Text('إجمالي المبيعات منذ بداية الصندوق: $monthlySales دج', style: const TextStyle(fontSize: 15, color: Colors.green)),
                    const SizedBox(height: 5),
                    const Text('يعتمد التقرير على تصفية الحسابات والتواريخ المسجلة بدقة.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              onPressed: () => _showAddCashSaleDialog(context),
              icon: const Icon(Icons.attach_money),
              label: const Text('إضافة مبيعات نقداً', style: TextStyle(fontSize: 16)),
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
        ElevatedButton(onPressed: () { if(amount > 0) { context.read<StoreProvider>().addDailySale(amount); Navigator.pop(ctx); } }, child: const Text('إضافة'))
      ],
    ));
  }
}
// شاشة الكريدي والزبائن
class CreditScreen extends StatefulWidget {
  const CreditScreen({Key? key}) : super(key: key);

  @override
  State<CreditScreen> createState() => _CreditScreenState();
}

class _CreditScreenState extends State<CreditScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    var provider = context.watch<StoreProvider>();
    var filteredCustomers = provider.customers.where((c) => c.name.contains(searchQuery) || c.phone.contains(searchQuery)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('الكريدي والزبائن')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(labelText: 'بحث عن زبون أو موظف...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
              onChanged: (v) => setState(() => searchQuery = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredCustomers.length,
              itemBuilder: (ctx, i) {
                var c = filteredCustomers[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: Icon(c.isEmployee ? Icons.badge : Icons.person),
                    title: Text('${c.name} ${c.isEmployee ? "(موظف)" : "(آخرون)"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(c.phone),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showEditCustomerDialog(context, c)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDeleteCustomer(context, c.id)),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                    onTap: () => Navigator.push(context, smoothNavigate(CustomerDetailsScreen(customer: c))),
                  ),
                );
              },
            ),
          ),
        ],
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
                      Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: isEmployee ? Colors.blue : Colors.grey.shade400), onPressed: () => setState(() => isEmployee = true), child: const Text('موظف'))),
                      const SizedBox(width: 5),
                      Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: !isEmployee ? Colors.blue : Colors.grey.shade400), onPressed: () => setState(() { isEmployee = false; selectedDate = null; }), child: const Text('آخرون'))),
                    ],
                  ),
                  TextField(decoration: const InputDecoration(labelText: 'الاسم الكامل'), onChanged: (v) => name = v),
                  TextField(decoration: const InputDecoration(labelText: 'رقم الهاتف'), keyboardType: TextInputType.phone, onChanged: (v) => phone = v),
                  const SizedBox(height: 15),
                  if (isEmployee)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(selectedDate == null ? 'تحديد تاريخ بداية الشهر' : 'البداية: ${selectedDate.toString().substring(0, 10)}'),
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                        if (picked != null) setState(() => selectedDate = picked);
                      },
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(onPressed: () { if(name.isNotEmpty) { context.read<StoreProvider>().addCustomer(name, phone, isEmployee, selectedDate); Navigator.pop(ctx); } }, child: const Text('حفظ'))
            ],
          );
        },
      ),
    );
  }

  void _showEditCustomerDialog(BuildContext context, Customer customer) {
    String name = customer.name, phone = customer.phone;
    bool isEmployee = customer.isEmployee;
    DateTime? selectedDate = customer.monthStartDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('تعديل بيانات الزبون'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: isEmployee ? Colors.blue : Colors.grey.shade400), onPressed: () => setState(() => isEmployee = true), child: const Text('موظف'))),
                      const SizedBox(width: 5),
                      Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: !isEmployee ? Colors.blue : Colors.grey.shade400), onPressed: () => setState(() { isEmployee = false; selectedDate = null; }), child: const Text('آخرون'))),
                    ],
                  ),
                  TextField(controller: TextEditingController(text: name), decoration: const InputDecoration(labelText: 'الاسم الكامل'), onChanged: (v) => name = v),
                  TextField(controller: TextEditingController(text: phone), decoration: const InputDecoration(labelText: 'رقم الهاتف'), keyboardType: TextInputType.phone, onChanged: (v) => phone = v),
                  const SizedBox(height: 15),
                  if (isEmployee)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(selectedDate == null ? 'تحديد تاريخ بداية الشهر' : 'البداية: ${selectedDate.toString().substring(0, 10)}'),
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(context: context, initialDate: selectedDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                        if (picked != null) setState(() => selectedDate = picked);
                      },
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(onPressed: () { if(name.isNotEmpty) { context.read<StoreProvider>().updateCustomer(customer.id, name, phone, isEmployee, selectedDate); Navigator.pop(ctx); } }, child: const Text('تحديث'))
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteCustomer(BuildContext context, String id) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('تأكيد الحذف'),
      content: const Text('هل أنت متأكد من حذف هذا الزبون؟'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () { context.read<StoreProvider>().deleteCustomer(id); Navigator.pop(ctx); }, child: const Text('حذف'))
      ],
    ));
  }
}

class CustomerDetailsScreen extends StatelessWidget {
  final Customer customer;
  const CustomerDetailsScreen({Key? key, required this.customer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var provider = context.watch<StoreProvider>();
    var currentCustomer = provider.customers.firstWhere((c) => c.id == customer.id, orElse: () => customer);
    double totalDebt = currentCustomer.purchases.fold(0, (sum, p) => sum + p.amount);

    return Scaffold(
      appBar: AppBar(title: Text('حساب الزبون: ${currentCustomer.name}')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade200,
            child: Column(
              children: [
                const Text('إجمالي الكريدي (الدين) الباقي', style: TextStyle(fontSize: 16)),
                Text(totalDebt.toStringAsFixed(2), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: totalDebt > 0 ? Colors.red : Colors.green)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: currentCustomer.purchases.length,
              itemBuilder: (ctx, i) {
                var p = currentCustomer.purchases[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text('المبلغ: ${p.amount} دج'),
                    subtitle: Text('التاريخ: ${p.date.toString().substring(0, 10)}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'add_purchase',
            onPressed: () => _showAddPurchaseDialog(context),
            label: const Text('تسجيل دين جديد'),
            icon: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          if (currentCustomer.isEmployee)
            FloatingActionButton.extended(
              heroTag: 'settle_employee',
              backgroundColor: Colors.green,
              onPressed: () => _showSettleDialog(context),
              label: const Text('تخليص الشهر للموظف'),
              icon: const Icon(Icons.done_all),
            ),
        ],
      ),
    );
  }

  void _showAddPurchaseDialog(BuildContext context) {
    double amount = 0;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('تسجيل مشتريات (كريدي)'),
      content: TextField(decoration: const InputDecoration(labelText: 'قيمة المشتريات'), keyboardType: TextInputType.number, onChanged: (v) => amount = double.tryParse(v) ?? 0),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () { if(amount > 0) { context.read<StoreProvider>().addPurchaseToCustomer(customer.id, amount); Navigator.pop(ctx); } }, child: const Text('حفظ'))
      ],
    ));
  }

  void _showSettleDialog(BuildContext context) {
    double paid = 0;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('تخليص الحساب الشهري'),
      content: TextField(decoration: const InputDecoration(labelText: 'المبلغ المدفوع للتخليص'), keyboardType: TextInputType.number, onChanged: (v) => paid = double.tryParse(v) ?? 0),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () { context.read<StoreProvider>().settleMonthlyCustomer(customer.id, paid); Navigator.pop(ctx); }, child: const Text('تأكيد'))
      ],
    ));
  }
}

// شاشة الصندوق والأرباح
class BoxScreen extends StatelessWidget {
  const BoxScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var provider = context.watch<StoreProvider>();
    double sales = provider.totalMonthlySales;
    double costs = provider.totalMonthlyCosts;
    double netProfit = sales - costs;

    return Scaffold(
      appBar: AppBar(title: const Text('الصندوق والأرباح')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('حساب الصندوق الشهري', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    Text('تاريخ بدء الحساب: ${provider.boxStartDate.toString().substring(0, 10)}'),
                    const SizedBox(height: 10),
                    Text('إجمالي المبيعات: $sales دج', style: const TextStyle(color: Colors.green, fontSize: 16)),
                    Text('إجمالي التكاليف (الموردين): $costs دج', style: const TextStyle(color: Colors.red, fontSize: 16)),
                    const Divider(),
                    Text('صافي الربح: $netProfit دج', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: netProfit >= 0 ? Colors.blue : Colors.orange)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.date_range),
              label: const Text('تغيير تاريخ بداية الصندوق'),
              onPressed: () async {
                DateTime? picked = await showDatePicker(context: context, initialDate: provider.boxStartDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                if (picked != null) provider.setBoxStartDate(picked);
              },
            ),
          ],
        ),
      ),
    );
  }
}
