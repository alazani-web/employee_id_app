import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/alert_provider.dart';
import '../providers/employee_provider.dart';
import '../providers/visit_provider.dart';
import '../models/employee.dart';
import '../models/visit.dart';
import '../widgets/app_date_picker.dart';
import '../utils/renewal_calculator.dart';
import '../utils/family_visit_calculator.dart';
import '../widgets/renewal_dialog.dart';
import '../widgets/action_result_dialog.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertItem {
  final String type;
  final String name;
  final String number;
  final DateTime expiryDate;
  final String description;
  final IconData icon;
  final Color iconColor;
  final String actionText;
  final String? secondaryDateLabel;
  final DateTime? secondaryDate;
  final dynamic source;

  const _AlertItem({
    required this.type,
    required this.name,
    required this.number,
    required this.expiryDate,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.actionText,
    this.secondaryDateLabel,
    this.secondaryDate,
    this.source,
  });
}

class _AlertsScreenState extends State<AlertsScreen> {
  int selectedTab = 0;
  final Color primaryBlue = const Color(0xff2563EB);
  final List<Map<String, String>> _documents = [];
  AlertProvider? _alertProvider;
  bool _loadingDocuments = true;

  static const String _documentsStorageKey = 'employee_id_app_documents_v2';

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<AlertProvider>();
    if (_alertProvider != provider) {
      _alertProvider?.removeListener(_onAlertDataChanged);
      _alertProvider = provider;
      _alertProvider!.addListener(_onAlertDataChanged);
    }
  }

  void _onAlertDataChanged() {
    if (!mounted) return;
    _loadDocuments();
  }

  @override
  void dispose() {
    _alertProvider?.removeListener(_onAlertDataChanged);
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_documentsStorageKey);
      final loaded = <Map<String, String>>[];

      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              loaded.add({
                for (final entry in item.entries)
                  entry.key.toString(): entry.value?.toString() ?? '',
              });
            }
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _documents
          ..clear()
          ..addAll(loaded);
        _loadingDocuments = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingDocuments = false);
    }
  }

  DateTime? _parseDate(String value) {
    return RenewalCalculator.parseDate(value);
  }

  int _daysRemaining(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.difference(today).inDays;
  }

  List<_AlertItem> _buildAlerts() {
    final employees = context.read<EmployeeProvider>().employees;
    final visits = context.read<VisitProvider>().visits;
    final result = <_AlertItem>[];

    for (final employee in employees) {
      final date = _parseDate(employee.expiryDate);
      if (date == null) continue;
      final days = _daysRemaining(date);
      if (days <= 30) {
        result.add(
          _AlertItem(
            type: 'هوية موظف',
            name: employee.name,
            number: employee.idNumber,
            expiryDate: date,
            description: days < 0
                ? 'هوية الموظف منتهية وتحتاج إلى تجديد.'
                : 'هوية الموظف تحتاج إلى متابعة وتجديد قريباً.',
            icon: Icons.badge_outlined,
            iconColor: primaryBlue,
            actionText: 'تجديد الهوية',
            source: employee,
          ),
        );
      }
    }

    for (final visit in visits) {
      final visitDate = _parseDate(visit.expiryDate);
      final insuranceDate = _parseDate(visit.insuranceExpiryDate);

      // تنبيه الزيارة يكون فقط عند قرب/انتهاء الزيارة نفسها.
      if (visitDate != null) {
        final days = _daysRemaining(visitDate);
        if (days <= 30) {
          result.add(
            _AlertItem(
              type: 'زيارة عائلية',
              name: visit.visitorName,
              number: visit.borderNumber.isNotEmpty
                  ? visit.borderNumber
                  : (visit.visaNumber.isNotEmpty
                      ? visit.visaNumber
                      : visit.passportNumber),
              expiryDate: visitDate,
              description: days < 0
                  ? 'الزيارة منتهية وتحتاج إلى تجديد.'
                  : 'الزيارة تحتاج إلى متابعة وتجديد قريباً.',
              icon: Icons.flight_takeoff_outlined,
              iconColor: Colors.deepPurple,
              actionText: 'تجديد الزيارة',
              source: visit,
              secondaryDateLabel: 'انتهاء التأمين',
              secondaryDate: insuranceDate,
            ),
          );
        }
      }

      // إذا كان التأمين هو المنتهي/القريب، يكون التنبيه للتأمين فقط
      // ولا نعتبر الزيارة نفسها منتهية.
      if (insuranceDate != null) {
        final days = _daysRemaining(insuranceDate);
        if (days <= 30) {
          result.add(
            _AlertItem(
              type: 'تأمين زيارة',
              name: visit.visitorName,
              number: visit.borderNumber.isNotEmpty
                  ? visit.borderNumber
                  : (visit.visaNumber.isNotEmpty
                      ? visit.visaNumber
                      : visit.passportNumber),
              expiryDate: insuranceDate,
              description: days < 0
                  ? 'تأمين الزيارة منتهٍ ويحتاج إلى تجديد.'
                  : 'تأمين الزيارة يحتاج إلى متابعة وتجديد قريباً.',
              icon: Icons.shield_outlined,
              iconColor: Colors.orange,
              actionText: 'تجديد التأمين',
              source: visit,
              secondaryDateLabel: 'انتهاء الزيارة',
              secondaryDate: visitDate,
            ),
          );
        }
      }
    }

    for (final document in _documents) {
      final date = _parseDate(document['expiry'] ?? '');
      if (date == null) continue;
      final days = _daysRemaining(date);
      if (days <= 30) {
        final type = document['type']?.trim().isNotEmpty == true
            ? document['type']!.trim()
            : 'وثيقة';
        final name = document['name']?.trim().isNotEmpty == true
            ? document['name']!.trim()
            : type;
        result.add(
          _AlertItem(
            type: type,
            name: name,
            number: document['number'] ?? '',
            expiryDate: date,
            description: type == 'السجل التجاري'
                ? (days < 0
                    ? 'موعد التأكيد السنوي متأخر ويحتاج إلى إجراء.'
                    : 'موعد التأكيد السنوي للبيانات قريب ويحتاج إلى متابعة.')
                : (days < 0
                    ? 'الوثيقة منتهية وتحتاج إلى تجديد.'
                    : 'الوثيقة تحتاج إلى متابعة وتجديد قريباً.'),
            icon: _documentIcon(document['icon'], type),
            iconColor: Colors.teal,
            actionText: type == 'السجل التجاري' ? 'التأكيد السنوي' : 'تجديد الوثيقة',
            source: document,
          ),
        );
      }
    }

    result.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return result;
  }

  IconData _documentIcon(String? icon, String type) {
    if (type == 'السجل التجاري') return Icons.business_outlined;
    if (type == 'الرخصة') return Icons.description_outlined;
    if (type == 'التأمين') return Icons.shield_outlined;
    if (icon == '📁') return Icons.folder_outlined;
    if (icon == '📌') return Icons.push_pin_outlined;
    return Icons.description_outlined;
  }

  String _daysText(int days) {
    if (days < 0) return 'منتهي منذ ${days.abs()} يوم';
    if (days == 0) return 'ينتهي اليوم';
    if (days == 1) return 'متبقي يوم واحد';
    return 'متبقي $days يوم';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  List<_AlertItem> _filteredAlerts(List<_AlertItem> alerts) {
    switch (selectedTab) {
      case 1:
        return alerts.where((a) => a.type == 'هوية موظف').toList();
      case 2:
        return alerts.where((a) => a.type == 'زيارة عائلية' || a.type == 'تأمين زيارة').toList();
      case 3:
        return alerts.where((a) => a.type != 'هوية موظف' && a.type != 'زيارة عائلية' && a.type != 'تأمين زيارة').toList();
      default:
        return alerts;
    }
  }

  @override
  Widget build(BuildContext context) {
    final alerts = _buildAlerts();
    final employeesCount = alerts.where((a) => a.type == 'هوية موظف').length;
    final visitsCount = alerts.where((a) => a.type == 'زيارة عائلية' || a.type == 'تأمين زيارة').length;
    final documentsCount = alerts.where((a) => a.type != 'هوية موظف' && a.type != 'زيارة عائلية' && a.type != 'تأمين زيارة').length;
    final expiredCount = alerts.where((a) => _daysRemaining(a.expiryDate) < 0).length;
    final urgentCount = alerts.where((a) {
      final d = _daysRemaining(a.expiryDate);
      return d >= 0 && d <= 7;
    }).length;
    final followUpCount = alerts.where((a) => _daysRemaining(a.expiryDate) >= 0).length;
    final visibleAlerts = _filteredAlerts(alerts);

    final tabs = [
      'جميع التنبيهات (${alerts.length})',
      'الهويات ($employeesCount)',
      'الزيارات ($visitsCount)',
      'الوثائق ($documentsCount)',
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF7F8FC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xff111827)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'نظام إدارة الهويات',
            style: TextStyle(
              color: Color(0xff111827),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: RefreshIndicator(
          onRefresh: _loadDocuments,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Icon(Icons.notifications_active_outlined, color: Colors.amber.shade700, size: 28),
                  const SizedBox(width: 8),
                  const Text(
                    'التنبيهات والإشعارات',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: summaryStatCard('إجمالي التنبيهات', '${alerts.length}', Icons.notifications_outlined, primaryBlue)),
                  const SizedBox(width: 10),
                  Expanded(child: summaryStatCard('منتهية الصلاحية', '$expiredCount', Icons.cancel_outlined, Colors.red)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: summaryStatCard('عاجلة (7 أيام)', '$urgentCount', Icons.warning_amber_rounded, Colors.orange)),
                  const SizedBox(width: 10),
                  Expanded(child: summaryStatCard('تحتاج متابعة', '$followUpCount', Icons.access_time_rounded, Colors.amber.shade700)),
                ],
              ),
              const SizedBox(height: 18),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(tabs.length, (index) {
                    final active = selectedTab == index;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => selectedTab = index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: active ? const Color(0xffEFF4FF) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: active ? primaryBlue : Colors.grey.shade200,
                            ),
                          ),
                          child: Text(
                            tabs[index],
                            style: TextStyle(
                              color: active ? primaryBlue : Colors.grey.shade600,
                              fontWeight: active ? FontWeight.bold : FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
              if (_loadingDocuments && alerts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (visibleAlerts.isEmpty)
                _emptyState()
              else
                ...visibleAlerts.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: alertCard(item),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget summaryStatCard(String title, String count, IconData icon, Color color) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          // الأيقونة في اليسار
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),

          // العنوان والعدد في اليمين
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xff6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  count,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 21,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget alertCard(_AlertItem item) {
    final days = _daysRemaining(item.expiryDate);
    final expired = days < 0;
    final urgent = !expired && days <= 7;
    final badgeColor = expired
        ? const Color(0xffffe5e5)
        : urgent
            ? const Color(0xffffefe0)
            : const Color(0xfffff3dc);
    final badgeTextColor = expired
        ? Colors.red.shade700
        : urgent
            ? Colors.orange.shade800
            : Colors.amber.shade900;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: expired ? const Color(0xfffecaca) : const Color(0xffe5e7eb),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.iconColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.type,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: item.iconColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff111827),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _daysText(days),
                  style: TextStyle(
                    color: badgeTextColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            item.description,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 14,
            runSpacing: 5,
            children: [
              if (item.number.isNotEmpty)
                Text(
                  'الرقم: ${item.number}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              Text(
                'التاريخ: ${_formatDate(item.expiryDate)}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              if (item.secondaryDate != null)
                Text(
                  '${item.secondaryDateLabel}: ${_formatDate(item.secondaryDate!)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: () async {
                if (item.source is Employee) {
                  await _showEmployeeRenewDialog(context, item.source as Employee);
                } else if (item.source is Visit) {
                  if (item.type == 'تأمين زيارة') {
                    await _showInsuranceRenewDialog(context, item.source as Visit);
                  } else {
                    await _showVisitOnlyRenewDialog(context, item.source as Visit);
                  }
                } else if (item.source is Map<String, String>) {
                  await _showDocumentRenewDialog(context, item.source as Map<String, String>);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: Text(
                item.actionText,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 45, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.notifications_none_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          const Text(
            'لا توجد تنبيهات حالياً',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            'جميع الهويات والزيارات والوثائق ضمن المدة المحددة.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  String _dateFromDateTime(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _showEmployeeRenewDialog(BuildContext context, Employee emp) async {
    final result = await RenewalDialog.show(
      context,
      employeeName: emp.name,
      expiryDate: emp.expiryDate,
    );

    if (result == null || !mounted) return;

    await context.read<EmployeeProvider>().renewEmployeeId(
      emp.id,
      result.formattedDate,
    );

    if (!mounted) return;
    setState(() {});

    await ActionResultDialog.show(
      context,
      type: ActionResultType.success,
      title: 'تم تجديد الهوية بنجاح',
      name: emp.name,
      message: 'تم تحديث تاريخ الانتهاء إلى ${result.formattedDate}',
    );
  }

  Future<void> _showVisitOnlyRenewDialog(BuildContext context, Visit visit) async {
    int months = 3;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final newDate = FamilyVisitCalculator.calculateRenewalDate(
              expiryDate: _parseDate(visit.expiryDate) ?? DateTime.now(),
              renewalMonths: months,
            );
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 370),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xffF3F4F6),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.close, size: 16, color: Color(0xff4B5563)),
                                onPressed: () => Navigator.pop(dialogContext),
                              ),
                            ),
                            Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(Icons.autorenew, color: Color(0xff2563EB), size: 22),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'تجديد الزيارة',
                          style: TextStyle(color: Color(0xff111827), fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(visit.visitorName, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11.5)),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xffF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            children: [
                              _renewInfoRow('انتهاء الزيارة الحالي', visit.expiryDate, const Color(0xFF6B7280)),
                              const SizedBox(height: 6),
                              _renewInfoRow('انتهاء الزيارة الجديد', _dateFromDateTime(newDate), const Color(0xff2563EB)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Text('اختر مدة التجديد', style: TextStyle(color: Color(0xff111827), fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [1, 3].map((m) {
                            final active = months == m;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(left: m == 3 ? 0 : 5),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => setDialogState(() => months = m),
                                  child: Container(
                                    height: 40,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: active ? const Color(0xff2563EB) : Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: active ? const Color(0xff2563EB) : const Color(0xFFE5E7EB)),
                                    ),
                                    child: Text('$m شهر', style: TextStyle(color: active ? Colors.white : const Color(0xff111827), fontSize: 11, fontWeight: FontWeight.w700)),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: ElevatedButton(
                            onPressed: () async {
                              await context.read<VisitProvider>().renewVisit(
                                visit.id,
                                newExpiryDate: _dateFromDateTime(newDate),
                                renewalMonths: months,
                                newInsuranceExpiryDate: null,
                              );
                              if (mounted) setState(() {});
                              if (dialogContext.mounted) Navigator.pop(dialogContext);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('تأكيد تجديد الزيارة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFF111827),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('إلغاء', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showInsuranceRenewDialog(BuildContext context, Visit visit) async {
    int months = 3;
    String newInsurance = visit.insuranceExpiryDate;
    final insuranceController = TextEditingController(text: newInsurance);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final insuranceExpiry = _parseDate(visit.insuranceExpiryDate) ?? DateTime.now();
            final newInsuranceDate = _dateFromDateTime(
              RenewalCalculator.calculateRenewalDate(
                expiryDate: insuranceExpiry,
                renewalMonths: months,
              ),
            );

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 370),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xffF3F4F6),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Color(0xff4B5563),
                                ),
                                onPressed: () => Navigator.pop(dialogContext),
                              ),
                            ),
                            Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(
                                Icons.shield_outlined,
                                color: Color(0xffF59E0B),
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'تجديد تأمين الزيارة',
                          style: TextStyle(
                            color: Color(0xff111827),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          visit.visitorName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xffF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Column(
                            children: [
                              _renewInfoRow(
                                'انتهاء التأمين الحالي',
                                visit.insuranceExpiryDate,
                                const Color(0xFF6B7280),
                              ),
                              const SizedBox(height: 6),
                              _renewInfoRow(
                                'انتهاء التأمين الجديد',
                                newInsuranceDate,
                                const Color(0xffF59E0B),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'اختر مدة تجديد التأمين',
                            style: TextStyle(
                              color: Color(0xff111827),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        GridView.count(
                          crossAxisCount: 4,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: 2.25,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [3, 6, 9, 12].map((m) {
                            final active = months == m;
                            return InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => setDialogState(() => months = m),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: active
                                      ? const Color(0xff2563EB)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: active
                                        ? const Color(0xff2563EB)
                                        : const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Text(
                                  '$m شهر',
                                  style: TextStyle(
                                    color: active
                                        ? Colors.white
                                        : const Color(0xff111827),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: insuranceController,
                          readOnly: true,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            labelText: 'تاريخ انتهاء التأمين الجديد',
                            labelStyle: const TextStyle(fontSize: 11),
                            suffixIcon: const Icon(
                              Icons.calendar_month_outlined,
                              size: 19,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          onTap: () async {
                            final picked = await AppDatePicker.show(
                              context,
                              initialDate: _parseDate(newInsuranceDate) ??
                                  DateTime.now(),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                newInsurance = picked;
                                insuranceController.text = picked;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: ElevatedButton(
                            onPressed: () async {
                              final updated = visit.copyWith(
                                insuranceExpiryDate: newInsuranceDate,
                              );
                              await context
                                  .read<VisitProvider>()
                                  .updateVisit(updated);

                              if (mounted) setState(() {});
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'تأكيد تجديد التأمين',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFF111827),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'إلغاء',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    insuranceController.dispose();
  }

  Future<void> _showDocumentRenewDialog(BuildContext context, Map<String, String> document) async {
    int years = 1;
    final type = document['type'] ?? 'وثيقة';
    final isCr = type == 'السجل التجاري';
    final notesController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (dialogContext, setDialogState) {
        final newDate = _calculateDocumentRenewal(document['expiry'] ?? '', years);
        return Directionality(textDirection: TextDirection.rtl, child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24), backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 360), child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [CircleAvatar(backgroundColor: const Color(0xffF3F4F6), radius: 18, child: IconButton(padding: EdgeInsets.zero, icon: const Icon(Icons.close, size: 17, color: Colors.grey), onPressed: () => Navigator.pop(dialogContext))), Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: const Color(0xffF0FDF4), borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.autorenew, color: Color(0xff16A34A), size: 23))]),
            const SizedBox(height: 10), Text(isCr ? 'التأكيد السنوي' : 'تجديد الوثيقة', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xff111827))), const SizedBox(height: 3), Text(document['name'] ?? type, style: const TextStyle(color: Color(0xff6B7280), fontSize: 12)), const SizedBox(height: 14),
            _renewInfoRow(isCr ? 'موعد التأكيد الحالي:' : 'الانتهاء الحالي:', document['expiry'] ?? '', const Color(0xff6B7280)), const SizedBox(height: 8), _renewInfoRow(isCr ? 'موعد التأكيد الجديد:' : 'الانتهاء الجديد:', newDate ?? '—', const Color(0xff2563EB)), const SizedBox(height: 14),
            Align(alignment: Alignment.centerRight, child: Text(isCr ? 'التأكيد السنوي للسجل التجاري' : 'مدة التجديد', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xff111827)))), const SizedBox(height: 8),
            if (isCr) Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xffEFF6FF), borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xffDBEAFE))), child: const Text('وفق نظام السجل التجاري الجديد: لا يوجد تاريخ انتهاء للسجل التجاري، ويكون الإجراء هو التأكيد السنوي للبيانات كل 12 شهراً من تاريخ القيد.', textAlign: TextAlign.right, style: TextStyle(color: Color(0xff1E40AF), fontSize: 11, height: 1.5)))
            else Column(children: [Row(children: [1,2].map((y) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: _yearChoiceAlert('${y == 2 ? 'سنتان' : 'سنة واحدة'}', y, years == y, () => setDialogState(() => years = y))))).toList()), const SizedBox(height: 8), Row(children: [3,5].map((y) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: _yearChoiceAlert('$y سنوات', y, years == y, () => setDialogState(() => years = y))))).toList())]),
             const SizedBox(height: 10),
             TextField(
               controller: notesController,
               maxLines: 2,
               textAlign: TextAlign.right,
               decoration: const InputDecoration(
                 hintText: 'ملاحظات اختيارية...',
                 filled: true,
                 fillColor: Color(0xffF8FAFC),
                 border: OutlineInputBorder(
                   borderRadius: BorderRadius.all(Radius.circular(13)),
                   borderSide: BorderSide(color: Color(0xffE2E8F0)),
                 ),
               ),
             ),
             const SizedBox(height: 14),
            Row(children: [Expanded(child: ElevatedButton(onPressed: () async { if (newDate == null) return; document['expiry'] = newDate!; final note = notesController.text.trim(); if (note.isNotEmpty) document['notes'] = note; await _saveDocumentsFromAlert(); if (dialogContext.mounted) Navigator.pop(dialogContext); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff2563EB), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(isCr ? 'تأكيد التأكيد السنوي' : 'تأكيد التجديد', style: const TextStyle(fontWeight: FontWeight.bold)))), const SizedBox(width: 10), Expanded(child: TextButton(onPressed: () => Navigator.pop(dialogContext), style: TextButton.styleFrom(backgroundColor: const Color(0xff374151), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('إلغاء', style: TextStyle(fontWeight: FontWeight.bold))))]),
          ]))),
        ));
      }),
    );
    notesController.dispose();
  }

  Widget _yearChoiceAlert(String label, int value, bool selected, VoidCallback onTap) => InkWell(
    borderRadius: BorderRadius.circular(10), onTap: onTap, child: Container(height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: selected ? const Color(0xff2563EB) : const Color(0xffF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: selected ? const Color(0xff2563EB) : const Color(0xffE5E7EB))), child: Text(label, style: TextStyle(color: selected ? Colors.white : const Color(0xff111827), fontSize: 11, fontWeight: FontWeight.w700))));

  Widget _renewInfoRow(String title, String value, Color valueColor) => Container(
    width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: const Color(0xffF8FAFC), borderRadius: BorderRadius.circular(11), border: Border.all(color: const Color(0xffE5E7EB))),
    child: Row(children: [Expanded(child: Text(title, style: const TextStyle(color: Color(0xff6B7280), fontSize: 11))), Text(value, style: TextStyle(color: valueColor, fontSize: 12, fontWeight: FontWeight.w800))]),
  );

  String? _calculateDocumentRenewal(String current, int years) {
    final start = _parseDate(current);
    if (start == null) return null;
    final target = DateTime(start.year + years, start.month, start.day);
    if (target.month != start.month) {
      return '${target.year.toString().padLeft(4, '0')}-${start.month.toString().padLeft(2, '0')}-${DateTime(target.year, start.month + 1, 0).day.toString().padLeft(2, '0')}';
    }
    return _dateFromDateTime(target);
  }

  Future<void> _saveDocumentsFromAlert() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_documentsStorageKey, jsonEncode(_documents));
    if (!mounted) return;
    await context.read<AlertProvider>().refreshDocuments();
    await _loadDocuments();
  }

}
