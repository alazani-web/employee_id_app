import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/supabase_service.dart';

class LicenseManagerScreen extends StatefulWidget {
  final VoidCallback onBack;

  const LicenseManagerScreen({
    super.key,
    required this.onBack,
  });

  @override
  State<LicenseManagerScreen> createState() => _LicenseManagerScreenState();
}

class _LicenseManagerScreenState extends State<LicenseManagerScreen> {
  bool _loading = true;
  bool _working = false;
  String? _error;
  List<LicenseRecord> _records = [];
  Timer? _timer;
  final _searchController = TextEditingController();
  String _statusFilter = 'all';
  final Set<String> _expanded = <String>{};

  static const _blue = Color(0xff2864D7);
  static const _ink = Color(0xff182230);
  static const _muted = Color(0xff667085);
  static const _border = Color(0xffE5EAF2);
  static const _canvas = Color(0xffF7F9FC);

  @override
  void initState() {
    super.initState();
    _loadRecords();
    _timer = Timer.periodic(const Duration(seconds: 45), (_) {
      _loadRecords(silent: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final service = SupabaseService.instance;
      if (!await service.isAdmin) {
        throw Exception('الحساب الحالي ليس حساب مدير.');
      }
      final rows = await service.getAdminLicenseRecords();
      if (!mounted) return;
      setState(() {
        _records = rows;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _date(DateTime? value) {
    if (value == null) return 'غير متوفر';
    final d = value.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _statusLabel(LicenseRecord record) {
    if (record.status == 'cancelled') return 'ملغى إداريًا';
    if (record.isExpired) return 'منتهي';
    if (record.isActive) return 'فعال';
    if (record.status == 'available') return 'غير مستخدم';
    return record.status;
  }

  Color _statusColor(LicenseRecord record) {
    if (record.status == 'cancelled' || record.isExpired) {
      return const Color(0xffD92D20);
    }
    if (record.isActive) return const Color(0xff16834A);
    if (record.status == 'available') return const Color(0xffB76E00);
    return _muted;
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    _message('تم نسخ بصمة المفتاح');
  }

  Future<void> _renew(LicenseRecord record) async {
    final amount = TextEditingController(text: '1');
    String unit = 'months';
    final result = await showDialog<({int days, String label})>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تجديد الاشتراك'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('حدد مدة التجديد للعميل ${record.customerName}.'),
                const SizedBox(height: 14),
                TextField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'مدة التجديد',
                    hintText: 'أدخل رقمًا',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: unit,
                  decoration: const InputDecoration(
                    labelText: 'الوحدة',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'days', child: Text('أيام')),
                    DropdownMenuItem(value: 'months', child: Text('أشهر (30 يومًا للشهر)')),
                    DropdownMenuItem(value: 'years', child: Text('سنوات (365 يومًا للسنة)')),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => unit = value);
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'تُضاف المدة إلى تاريخ الانتهاء الحالي إذا كان الاشتراك ساريًا، وإلا يبدأ من اليوم.',
                  style: TextStyle(color: _muted, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final n = int.tryParse(amount.text.trim());
                if (n == null || n <= 0) {
                  _message('أدخل مدة صحيحة أكبر من صفر.');
                  return;
                }
                final days = n * (unit == 'years' ? 365 : unit == 'months' ? 30 : 1);
                if (days > 36500) {
                  _message('الحد الأقصى للتجديد هو 36500 يومًا.');
                  return;
                }
                final label = unit == 'years' ? '$n سنة' : unit == 'months' ? '$n شهر' : '$n يوم';
                Navigator.of(dialogContext).pop((days: days, label: label));
              },
              child: const Text('تأكيد التجديد'),
            ),
          ],
        ),
      ),
    );
    amount.dispose();
    if (result == null || !mounted) return;

    setState(() => _working = true);
    try {
      await SupabaseService.instance.adminRenewLicenseKey(
        keyId: record.id,
        additionalDays: result.days,
      );
      _message('تم تجديد الاشتراك لمدة ${result.label}.');
      await _loadRecords(silent: true);
    } catch (e) {
      _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _cancel(LicenseRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إلغاء اشتراك العميل'),
        content: Text(
          'سيتم إلغاء اشتراك ${record.customerName} إداريًا. لن يُعاد المفتاح تلقائيًا إلى المفاتيح المتاحة. هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('رجوع'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xffD92D20)),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('تأكيد الإلغاء'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _working = true);
    try {
      await SupabaseService.instance.adminCancelLicenseKey(keyId: record.id);
      _message('تم إلغاء الاشتراك إداريًا.');
      await _loadRecords(silent: true);
    } catch (e) {
      _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  List<LicenseRecord> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return _records.where((r) {
      final queryMatch = query.isEmpty ||
          r.customerName.toLowerCase().contains(query) ||
          r.id.toLowerCase().contains(query) ||
          r.plan.toLowerCase().contains(query);
      final statusMatch = _statusFilter == 'all' ||
          (_statusFilter == 'active' && r.isActive) ||
          (_statusFilter == 'available' && r.status == 'available') ||
          (_statusFilter == 'expired' && r.isExpired) ||
          (_statusFilter == 'cancelled' && r.status == 'cancelled');
      return queryMatch && statusMatch;
    }).toList();
  }

  Widget _stat(String label, int value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(.10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
                  Text(label, style: const TextStyle(fontSize: 10, color: _muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xffF4F7FC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xffE9EEF5)),
      ),
      child: Text('$label: $value', style: const TextStyle(fontSize: 12, color: _ink)),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: _blue),
          const SizedBox(width: 9),
          SizedBox(
            width: 112,
            child: Text(label, style: const TextStyle(fontSize: 12, color: _muted)),
          ),
          Expanded(
            child: SelectableText(value, style: const TextStyle(fontSize: 12, color: _ink)),
          ),
        ],
      ),
    );
  }

  Widget _recordCard(LicenseRecord record) {
    final statusColor = _statusColor(record);
    final expanded = _expanded.contains(record.id);
    final canManage = record.status != 'cancelled' && record.status != 'available';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(color: Color(0x070F172A), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xffEEF4FF),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(LucideIcons.userRound, color: _blue, size: 20),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.customerName.isEmpty ? 'بدون اسم' : record.customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _ink),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(LucideIcons.calendarClock, size: 14, color: _muted),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              'الانتهاء: ${_date(record.expiresAt)}',
                              style: const TextStyle(fontSize: 12, color: _muted),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(.10),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    _statusLabel(record),
                    style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    icon: LucideIcons.refreshCw,
                    label: 'تجديد',
                    color: _blue,
                    onTap: canManage && !_working ? () => _renew(record) : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionButton(
                    icon: LucideIcons.ban,
                    label: 'إلغاء الاشتراك',
                    color: const Color(0xffD92D20),
                    onTap: canManage && !_working ? () => _cancel(record) : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionButton(
                    icon: expanded ? LucideIcons.eyeOff : LucideIcons.eye,
                    label: expanded ? 'إخفاء السجل' : 'عرض السجل',
                    color: const Color(0xff475467),
                    onTap: () {
                      setState(() {
                        if (expanded) {
                          _expanded.remove(record.id);
                        } else {
                          _expanded.add(record.id);
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            if (expanded) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1, color: _border),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip('الباقة', record.plan.toUpperCase()),
                  _chip('المدة الأصلية', '${record.durationDays} يوم'),
                  _chip('المتبقي', record.isActive ? '${record.remainingDays} يوم' : '0 يوم'),
                ],
              ),
              const SizedBox(height: 10),
              _detailRow(LucideIcons.calendarCheck, 'تاريخ التفعيل', _date(record.activatedAt)),
              _detailRow(LucideIcons.calendarX, 'تاريخ الانتهاء', _date(record.expiresAt)),
              _detailRow(LucideIcons.keyRound, 'معرّف المفتاح', record.id),
              _detailRow(LucideIcons.fingerprint, 'بصمة المفتاح', record.keyHash.isEmpty ? 'غير متوفرة' : record.keyHash),
              _detailRow(LucideIcons.userRound, 'معرّف المستخدم', record.activatedBy ?? 'غير مرتبط'),
              _detailRow(LucideIcons.history, 'عدد مرات التجديد', 'يظهر بعد تفعيل سجل التجديدات في قاعدة البيانات'),
              if (record.keyHash.isNotEmpty)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: () => _copy(record.keyHash),
                    icon: const Icon(LucideIcons.copy, size: 16),
                    label: const Text('نسخ بصمة المفتاح'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(.30)),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 5),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _records.where((r) => r.isActive).length;
    final available = _records.where((r) => r.status == 'available').length;
    final expired = _records.where((r) => r.isExpired).length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _canvas,
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'رجوع',
            onPressed: widget.onBack,
            icon: const Icon(LucideIcons.arrowRight),
          ),
          title: const Text('إدارة الاشتراكات'),
          centerTitle: true,
          backgroundColor: _blue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SafeArea(
          child: Stack(
            children: [
              RefreshIndicator(
                onRefresh: _loadRecords,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xff2864D7), Color(0xff1747A6)],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('لوحة الاشتراكات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                                SizedBox(height: 4),
                                Text('إدارة العملاء والمفاتيح والتجديدات', style: TextStyle(color: Color(0xffDCE8FF), fontSize: 12)),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'تحديث',
                            onPressed: _working ? null : () => _loadRecords(),
                            icon: const Icon(LucideIcons.refreshCw, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _stat('إجمالي المفاتيح', _records.length, _blue, LucideIcons.keyRound),
                        const SizedBox(width: 8),
                        _stat('فعالة', active, const Color(0xff16834A), LucideIcons.circleCheck),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _stat('غير مستخدمة', available, const Color(0xffB76E00), LucideIcons.key),
                        const SizedBox(width: 8),
                        _stat('منتهية', expired, const Color(0xffD92D20), LucideIcons.calendarX),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'ابحث باسم العميل أو الباقة أو المعرّف',
                        prefixIcon: const Icon(LucideIcons.search, size: 19),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _border)),
                      ),
                    ),
                    const SizedBox(height: 9),
                    DropdownButtonFormField<String>(
                      value: _statusFilter,
                      decoration: InputDecoration(
                        labelText: 'تصفية حسب الحالة',
                        prefixIcon: const Icon(LucideIcons.listFilter, size: 18),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _border)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('كل الاشتراكات')),
                        DropdownMenuItem(value: 'active', child: Text('فعالة')),
                        DropdownMenuItem(value: 'available', child: Text('غير مستخدمة')),
                        DropdownMenuItem(value: 'expired', child: Text('منتهية')),
                        DropdownMenuItem(value: 'cancelled', child: Text('ملغاة إداريًا')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _statusFilter = v);
                      },
                    ),
                    const SizedBox(height: 14),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: const Color(0xfffff1f0), borderRadius: BorderRadius.circular(14)),
                        child: Column(
                          children: [
                            Text(_error!, style: const TextStyle(color: Color(0xffB42318))),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () => _loadRecords(),
                              icon: const Icon(LucideIcons.refreshCw),
                              label: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      )
                    else if (_filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _records.isEmpty ? 'لا توجد اشتراكات مسجلة.' : 'لا توجد نتائج مطابقة.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _muted),
                        ),
                      )
                    else
                      ..._filtered.map(_recordCard),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              if (_working)
                Container(
                  color: Colors.black.withOpacity(.05),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
