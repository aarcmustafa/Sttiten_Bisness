import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsTab extends StatefulWidget {
  final bool initialSecurityEnabled;
  final String initialPin;
  final bool initialDarkMode;
  final bool initialManualStartDate;
  final String initialStartDateStr;
  final Function(bool, String, bool, bool, String) onSave;

  const SettingsTab({
    Key? key,
    required this.initialSecurityEnabled,
    required this.initialPin,
    required this.initialDarkMode,
    required this.initialManualStartDate,
    required this.initialStartDateStr,
    required this.onSave,
  }) : super(key: key);

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  late bool isSecurityEnabled;
  late TextEditingController pinCtrl;
  late bool isDarkMode;
  late bool isManualStartDate;
  late TextEditingController dateCtrl;

  @override
  void initState() {
    super.initState();
    isSecurityEnabled = widget.initialSecurityEnabled;
    pinCtrl = TextEditingController(text: widget.initialPin);
    isDarkMode = widget.initialDarkMode;
    isManualStartDate = widget.initialManualStartDate;
    dateCtrl = TextEditingController(text: widget.initialStartDateStr);
  }

  @override
  void dispose() {
    pinCtrl.dispose();
    dateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D9488),
        title: const Text('إعدادات التطبيق والأرشيف', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSecuritySection(),
            const Divider(height: 30),
            
            _buildAppearanceSection(),
            const Divider(height: 30),
            
            _buildArchiveInfoSection(),
            const Divider(height: 30),
            
            _buildFinancialSettingsSection(),
            const Divider(height: 30),
            
            _buildDataManagementSection(context),
            const Divider(height: 30),
            
            _buildAboutSection(),
            const SizedBox(height: 40),
            
            _buildSaveButton(context),
          ],
        ),
      ),
    );
  }

  // --- 1. قسم نظام الحماية والأمان ---
  Widget _buildSecuritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🔒 نظام الحماية والأمان', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D9488), fontSize: 16)),
        const SizedBox(height: 5),
        SwitchListTile(
          title: const Text('تفعيل قفل الحماية بررمز سري'),
          subtitle: Text(isSecurityEnabled ? 'الحماية مفعلة' : 'غير مفعلة'),
          value: isSecurityEnabled,
          activeColor: const Color(0xFF0D9488),
          onChanged: (val) => setState(() => isSecurityEnabled = val),
        ),
        if (isSecurityEnabled) ...[
          const SizedBox(height: 5),
          TextField(
            controller: pinCtrl,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            decoration: const InputDecoration(
              labelText: 'إعداد/تغيير الرمز السري (4 أرقام)',
              prefixIcon: Icon(Icons.lock, color: Color(0xFF0D9488)),
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ],
    );
  }

  // --- 2. قسم المظهر والوضعية ---
  Widget _buildAppearanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🎨 المظهر والوضعية', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D9488), fontSize: 16)),
        const SizedBox(height: 5),
        SwitchListTile(
          title: const Text('الوضع الليلي (Dark Mode)'),
          subtitle: Text(isDarkMode ? 'مفعل (مظهر مظلم مريح للعين)' : 'مفعل (مظهر نهاري ساطع)'),
          value: isDarkMode,
          activeColor: const Color(0xFF0D9488),
          onChanged: (val) => setState(() => isDarkMode = val),
        ),
      ],
    );
  }

  // --- 3. قسم زمن تصفية العمليات والأرشيف ---
  Widget _buildArchiveInfoSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('⏱️ زمن تصفية العمليات والأرشيف', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D9488), fontSize: 16)),
        SizedBox(height: 8),
        Text(
          '• المبيعات النقدية: تصفية يومية يدوية (مع احتفاظ الحوصلة بكل العمليات الأبدية).\n'
          '• الموردين: أرشيف تلقائي لآخر 60 يوماً (شهرين).\n'
          '• الكريدي والديون: أرشيف تلقائي لآخر 70 يوماً.',
          style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.4),
        ),
      ],
    );
  }

  // --- 4. قسم إعدادات الحوصلة المالية ---
  Widget _buildFinancialSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📊 إعدادات الحوصلة المالية', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D9488), fontSize: 16)),
        const SizedBox(height: 5),
        SwitchListTile(
          title: const Text('تحديد تاريخ بداية يدوي للحوصلة'),
          subtitle: Text(isManualStartDate ? 'مفعل (${dateCtrl.text})' : 'تلقائي (حسب الشهر الحالي)'),
          value: isManualStartDate,
          activeColor: const Color(0xFF0D9488),
          onChanged: (val) => setState(() => isManualStartDate = val),
        ),
        if (isManualStartDate) ...[
          const SizedBox(height: 5),
          TextField(
            controller: dateCtrl,
            decoration: const InputDecoration(
              labelText: 'تاريخ البداية (YYYY-MM-DD)', 
              prefixIcon: Icon(Icons.date_range, color: Color(0xFF0D9488)),
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ],
    );
  }

  // --- 5. قسم إدارة البيانات والأرشيف ---
  Widget _buildDataManagementSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🗑️ إدارة البيانات والأرشيف', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16)),
        const SizedBox(height: 5),
        ListTile(
          title: const Text('محو أرشيف المبيعات القديم', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          subtitle: const Text('تحذير: سيؤدي لحذف الأرشيف نهائياً وتأثره على الحوصلة الشهرية والسنوية'),
          trailing: IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            onPressed: () => _showClearArchiveDialog(context),
          ),
        ),
      ],
    );
  }

  // دالة عرض رسالة التأكيد لمسح الأرشيف
  void _showClearArchiveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تحذير خطير!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text('هل أنت متأكد تماماً من رغبتك في مسح أرشيف المبيعات القديم؟ هذه الخطوة لا يمكن التراجع عنها وستقوم بتصفير الحسابات القديمة من الحوصلة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (Hive.isBoxOpen('archivedSalesBox')) {
                await Hive.box('archivedSalesBox').clear();
              } else {
                var box = await Hive.openBox('archivedSalesBox');
                await box.clear();
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم محو أرشيف المبيعات بنجاح')),
              );
            },
            child: const Text('تأكيد المحو', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- 6. قسم حول التطبيق ---
  Widget _buildAboutSection() {
    return const Center(
      child: Column(
        children: [
          Text('ℹ️ حول التطبيق', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D9488), fontSize: 16)),
          SizedBox(height: 6),
          Text('Stitten Business - ERP الإصدار: 1.0.0', style: TextStyle(color: Colors.grey, fontSize: 13)),
          SizedBox(height: 2),
          Text('المطور: جلولي مصطفى', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 14)),
        ],
      ),
    );
  }

  // --- زر حفظ الإعدادات ---
  Widget _buildSaveButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0D9488),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      onPressed: () {
        widget.onSave(
          isSecurityEnabled,
          pinCtrl.text,
          isDarkMode,
          isManualStartDate,
          dateCtrl.text,
        );
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الإعدادات وتطبيق التغييرات بنجاح')),
        );
      },
      child: const Text('حفظ الإعدادات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}
