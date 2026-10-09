import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/supabase_service.dart';

class AdminKeyCreationScreen extends StatefulWidget {
  final VoidCallback onBack;

  const AdminKeyCreationScreen({
    super.key,
    required this.onBack,
  });

  @override
  State<AdminKeyCreationScreen> createState() => _AdminKeyCreationScreenState();
}

class _AdminKeyCreationScreenState extends State<AdminKeyCreationScreen> {
  final TextEditingController _customerController = TextEditingController();
  bool _loading = false;
  String _plan = 'premium';
  int _days = 365;
  String? _generatedKey;

  @override
  void dispose() {
    _customerController.dispose();
    super.dispose();
  }

  Future<void> _createKey() async {
    final customer = _customerController.text.trim();
    if (customer.isEmpty) {
      _message('أدخل اسم العميل أولاً.');
      return;
    }

    setState(() {
      _loading = true;
      _generatedKey = null;
    });

    try {
      final key = await SupabaseService.instance.createLicenseKey(
        customerName: customer,
        plan: _plan,
        days: _days,
      );

      if (!mounted) return;
      setState(() => _generatedKey = key);
    } catch (e) {
      if (mounted) {
        _message(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _copyKey() async {
    final key = _generatedKey;
    if (key == null) return;
    await Clipboard.setData(ClipboardData(text: key));
    if (mounted) _message('تم نسخ مفتاح الاشتراك.');
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xff2864D7)),
      filled: true,
      fillColor: const Color(0xffF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xffD7DFEA)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF7F9FC),
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'رجوع',
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text('التفعيل وإنشاء المفاتيح'),
          centerTitle: true,
          backgroundColor: const Color(0xff2864D7),
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xffEAF2FF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xffC9DCFF)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user_rounded,
                        color: Color(0xff2864D7), size: 30),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ترخيص الإدارة',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w900)),
                          SizedBox(height: 4),
                          Text('صلاحية الإدارة مدى الحياة — لا تحتاج إلى مفتاح اشتراك.',
                              style: TextStyle(height: 1.5)),
                        ],
                      ),
                    ),
                    Icon(Icons.all_inclusive_rounded,
                        color: Color(0xff2864D7), size: 28),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xffE1E7F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('إنشاء مفتاح اشتراك جديد',
                        style: TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _customerController,
                      textInputAction: TextInputAction.next,
                      decoration: _decoration('اسم العميل', Icons.person_outline),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _plan,
                      decoration: _decoration('الباقة', Icons.workspace_premium_outlined),
                      items: const [
                        DropdownMenuItem(value: 'basic', child: Text('Basic')),
                        DropdownMenuItem(value: 'premium', child: Text('Premium')),
                        DropdownMenuItem(value: 'pro', child: Text('Pro')),
                      ],
                      onChanged: _loading
                          ? null
                          : (value) {
                              if (value != null) setState(() => _plan = value);
                            },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<int>(
                      value: _days,
                      decoration: _decoration('مدة الاشتراك', Icons.calendar_month_outlined),
                      items: const [
                        DropdownMenuItem(value: 30, child: Text('30 يوم')),
                        DropdownMenuItem(value: 90, child: Text('90 يوم')),
                        DropdownMenuItem(value: 365, child: Text('365 يوم')),
                        DropdownMenuItem(value: 1095, child: Text('3 سنوات')),
                      ],
                      onChanged: _loading
                          ? null
                          : (value) {
                              if (value != null) setState(() => _days = value);
                            },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _createKey,
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.key_rounded),
                        label: Text(_loading ? 'جارٍ إنشاء المفتاح...' : 'إنشاء مفتاح الاشتراك'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff2864D7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_generatedKey != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xffB7E4C7)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xff16834A), size: 32),
                      const SizedBox(height: 8),
                      const Text('تم إنشاء المفتاح بنجاح',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                      const SizedBox(height: 12),
                      SelectableText(
                        _generatedKey!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xff2864D7)),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _copyKey,
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('نسخ المفتاح'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
