import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../providers/alert_provider.dart';
import '../providers/employee_provider.dart';
import '../providers/visit_provider.dart';
import '../services/local_backup_service.dart';
import '../services/notification_service.dart';
import '../widgets/top_message.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _busy = false;
  String? _lastBackup;

  @override
  void initState() {
    super.initState();
    _loadLastBackup();
  }

  Future<void> _loadLastBackup() async {
    final value = await LocalBackupService.instance.lastBackupDate();
    if (!mounted) return;
    setState(() => _lastBackup = value);
  }

  Future<void> _createBackup() async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      final saved = await LocalBackupService.instance.saveBackupFile();

      if (!mounted) return;

      if (saved) {
        await _loadLastBackup();
        TopMessage.show(
          context,
          'تم إنشاء النسخة الاحتياطية وحفظها بنجاح',
        );
      } else {
        TopMessage.show(
          context,
          'تم إلغاء حفظ النسخة الاحتياطية',
          type: TopMessageType.info,
        );
      }
    } catch (e) {
      if (!mounted) return;
      TopMessage.show(
        context,
        _cleanError(e),
        type: TopMessageType.error,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreBackup() async {
    if (_busy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('استعادة النسخة الاحتياطية'),
          content: const Text(
            'سيتم استبدال البيانات المحلية الحالية بالبيانات الموجودة في الملف. هل تريد المتابعة؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('استعادة'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);

    try {
      final restored =
          await LocalBackupService.instance.restoreBackupFile();

      if (!mounted) return;

      if (!restored) {
        TopMessage.show(
          context,
          'تم إلغاء الاستعادة',
          type: TopMessageType.info,
        );
        return;
      }

      await context.read<EmployeeProvider>().reloadFromStorage();
      await context.read<VisitProvider>().reloadFromStorage();
      await context.read<AlertProvider>().refreshDocuments();
      await NotificationService.instance.syncStoredData();

      if (!mounted) return;

      TopMessage.show(
        context,
        'تمت استعادة البيانات بنجاح',
      );
    } catch (e) {
      if (!mounted) return;
      TopMessage.show(
        context,
        _cleanError(e),
        type: TopMessageType.error,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .trim();
  }

  String _formatLastBackup(String? value) {
    if (value == null || value.isEmpty) return 'لا توجد نسخة محفوظة';

    final date = DateTime.tryParse(value);
    if (date == null) return 'تم الحفظ مسبقًا';

    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      child: ListView(
        children: [
          _buildHeader(),
          const SizedBox(height: 14),
          _buildSection(
            title: 'النسخ المحلي',
            subtitle: 'حفظ واستعادة بيانات التطبيق على الجهاز',
            icon: LucideIcons.hardDrive,
            children: [
              _buildActionButton(
                title: 'إنشاء نسخة محلية',
                icon: LucideIcons.download,
                color: const Color(0xff2864D7),
                onPressed: _createBackup,
              ),
              const SizedBox(height: 10),
              _buildActionButton(
                title: 'استعادة نسخة محلية',
                icon: LucideIcons.upload,
                color: const Color(0xff374151),
                onPressed: _restoreBackup,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSection(
            title: 'النسخ السحابي',
            subtitle: 'حفظ واستعادة بياناتك عبر السحابة',
            icon: LucideIcons.cloud,
            children: [
              _buildActionButton(
                title: 'إنشاء نسخة سحابية',
                icon: LucideIcons.cloudUpload,
                color: const Color(0xffCBD5E1),
                onPressed: () => TopMessage.show(
                  context,
                  'النسخ السحابي غير مفعل حاليًا',
                  type: TopMessageType.info,
                ),
              ),
              const SizedBox(height: 10),
              _buildActionButton(
                title: 'استعادة نسخة سحابية',
                icon: LucideIcons.cloudDownload,
                color: const Color(0xffCBD5E1),
                onPressed: () => TopMessage.show(
                  context,
                  'الاستعادة السحابية غير مفعلة حاليًا',
                  type: TopMessageType.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildLastBackupCard(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE2E6EC)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xffEAF1FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.database,
              color: Color(0xff2864D7),
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'النسخ الاحتياطي والاستعادة',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff172033),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'حفظ بيانات النظام واستعادتها عند الحاجة.',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xff7A8495),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE2E6EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xff2864D7), size: 21),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff172033),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xff8A94A6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ...children,
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: _busy ? null : onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          _busy && title == 'إنشاء نسخة محلية'
              ? 'جاري التنفيذ...'
              : title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor:
              color == const Color(0xffCBD5E1)
                  ? const Color(0xff64748B)
                  : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildLastBackupCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffE8ECF2)),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.clock3,
            size: 19,
            color: Color(0xff7A8495),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'آخر نسخة احتياطية',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff172033),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatLastBackup(_lastBackup),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xff7A8495),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
