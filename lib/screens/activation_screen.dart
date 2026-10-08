import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  SubscriptionInfo? _info;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await SupabaseService.instance.subscriptionInfo;
    if (!mounted) return;
    setState(() {
      _info = info;
      _loading = false;
    });
  }

  String _date(DateTime value) {
    final d = value.day.toString().padLeft(2, '0');
    final m = value.month.toString().padLeft(2, '0');
    return '$d/$m/${value.year}';
  }

  String _remaining(SubscriptionInfo info) {
    if (!info.active) return 'منتهي';
    return '${info.remainingDays} يوم';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: const Color(0xffF7F9FC),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final info = _info;
    if (info == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildCard(
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.vpn_key_outlined,
                  size: 48,
                  color: Color(0xff2864D7),
                ),
                SizedBox(height: 14),
                Text(
                  'لا يوجد اشتراك مفعل',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'لا توجد بيانات اشتراك محفوظة على هذا الجهاز.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xff7A8495),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: const [
                Icon(Icons.tune_rounded, color: Color(0xff2864D7), size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'إدارة الاشتراك',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'بيانات الاشتراك الحالية لهذا الجهاز',
              style: TextStyle(fontSize: 12, color: Color(0xff7A8495)),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Icon(
                  info.active ? Icons.verified_rounded : Icons.error_outline_rounded,
                  color: info.active ? const Color(0xff16A34A) : const Color(0xffDC2626),
                  size: 21,
                ),
                const SizedBox(width: 8),
                Text(
                  info.active ? 'الترخيص مفعل' : 'الترخيص منتهي',
                  style: TextStyle(
                    color: info.active ? const Color(0xff16A34A) : const Color(0xffDC2626),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _infoField('اسم العميل', 'الحساب الحالي', Icons.person_outline_rounded),
            _infoField('مفتاح التفعيل', info.maskedKey, Icons.key_outlined),
            _infoField('تاريخ التفعيل', _date(info.activatedAt), Icons.calendar_today_outlined),
            _infoField('تاريخ الانتهاء', _date(info.expiresAt), Icons.event_available_outlined),
            _infoField('المدة المتبقية', _remaining(info), Icons.hourglass_bottom_rounded),
            _infoField('الباقة', info.plan, Icons.workspace_premium_outlined),
            _infoField('الجهاز المستخدم', 'الجهاز الحالي', Icons.devices_other_rounded),
            const SizedBox(height: 14),
            const Text(
              'ملاحظة: لا يتم عرض مفتاح التفعيل الكامل بعد حفظه، حفاظًا على أمان الاشتراك.',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 11, color: Color(0xff7A8495)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.link_off_rounded, size: 19),
                label: const Text(
                  'إلغاء تفعيل هذا الجهاز',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffDC2626),
                  disabledBackgroundColor: const Color(0xffE2E8F0),
                  disabledForegroundColor: const Color(0xff94A3B8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoField(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xff2864D7), size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xff64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xff334155),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}
