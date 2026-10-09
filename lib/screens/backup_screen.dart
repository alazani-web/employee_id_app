import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../providers/alert_provider.dart';
import '../providers/employee_provider.dart';
import '../providers/visit_provider.dart';
import '../services/local_backup_service.dart';
import '../services/cloud_backup_service.dart';
import '../services/notification_service.dart';
import '../widgets/top_message.dart';

class BackupScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const BackupScreen({
    super.key,
    this.onBack,
  });

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


  Future<Map<String, String>?> _askCredentials({required bool create}) async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(create ? 'إنشاء حساب للنسخ السحابي' : 'تسجيل الدخول للنسخ السحابي'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                  validator: (v) => (v == null || !v.trim().contains('@')) ? 'أدخل بريدًا صحيحًا' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'كلمة المرور (8 أحرف على الأقل)'),
                  validator: (v) => (v == null || v.length < 8) ? 'كلمة المرور قصيرة' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(dialogContext, {
                  'email': emailController.text.trim(),
                  'password': passwordController.text,
                });
              },
              child: Text(create ? 'إنشاء الحساب' : 'دخول'),
            ),
          ],
        ),
      ),
    );
    emailController.dispose();
    passwordController.dispose();
    return result;
  }

  Future<void> _ensureCloudAccount() async {
    final service = CloudBackupService.instance;
    if (service.hasAccount) return;

    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حساب النسخ السحابي'),
          content: const Text('أنشئ حسابًا أو سجّل الدخول لاستعادة نسختك على أجهزتك الأخرى.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, 'cancel'), child: const Text('إلغاء')),
            TextButton(onPressed: () => Navigator.pop(dialogContext, 'login'), child: const Text('تسجيل الدخول')),
            ElevatedButton(onPressed: () => Navigator.pop(dialogContext, 'create'), child: const Text('إنشاء حساب')),
          ],
        ),
      ),
    );
    if (choice == null || choice == 'cancel') throw Exception('تم إلغاء العملية.');
    final credentials = await _askCredentials(create: choice == 'create');
    if (credentials == null) throw Exception('تم إلغاء العملية.');
    if (choice == 'create') {
      await service.createAccount(email: credentials['email']!, password: credentials['password']!);
    } else {
      await service.signIn(email: credentials['email']!, password: credentials['password']!);
    }
  }

  Future<void> _createCloudBackup() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _ensureCloudAccount();
      await CloudBackupService.instance.uploadBackup();
      if (!mounted) return;
      TopMessage.show(context, 'تم رفع النسخة الاحتياطية إلى حسابك السحابي بنجاح');
    } catch (e) {
      if (!mounted) return;
      TopMessage.show(context, _cleanError(e), type: TopMessageType.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreCloudBackup() async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('استعادة النسخة السحابية'),
          content: const Text('ستُستبدل البيانات المحلية القابلة للاستعادة بمحتويات النسخة السحابية. تأكد من إنشاء نسخة محلية حديثة أولًا. هل تريد المتابعة؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
            ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('استعادة')),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _ensureCloudAccount();
      await CloudBackupService.instance.restoreBackup();
      await context.read<EmployeeProvider>().reloadFromStorage();
      await context.read<VisitProvider>().reloadFromStorage();
      await context.read<AlertProvider>().refreshDocuments();
      await NotificationService.instance.syncStoredData();
      if (!mounted) return;
      await _loadLastBackup();
      TopMessage.show(context, 'تمت استعادة النسخة السحابية بنجاح');
    } catch (e) {
      if (!mounted) return;
      TopMessage.show(context, _cleanError(e), type: TopMessageType.error);
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),          const SizedBox(height: 14),
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
                color: const Color(0xff2864D7),
                onPressed: _createCloudBackup,
              ),
              const SizedBox(height: 10),
              _buildActionButton(
                title: 'استعادة نسخة سحابية',
                icon: LucideIcons.cloudDownload,
                color: const Color(0xff374151),
                onPressed: _restoreCloudBackup,
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
          _busy && (title == 'إنشاء نسخة محلية' || title == 'إنشاء نسخة سحابية' || title == 'استعادة نسخة سحابية' || title == 'استعادة نسخة محلية')
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
              Colors.white,
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
