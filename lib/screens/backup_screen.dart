import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),

          const SizedBox(height: 18),

          _buildSection(
            title: 'النسخ المحلي',
            subtitle: 'حفظ واستعادة بيانات التطبيق على الجهاز',
            icon: LucideIcons.hardDrive,
            children: [
              _buildActionButton(
                title: 'إنشاء نسخة محلية',
                icon: LucideIcons.download,
                color: const Color(0xff2864D7),
                onPressed: () {
                  _showMessage(
                    context,
                    'سيتم تفعيل النسخ المحلي هنا',
                  );
                },
              ),

              const SizedBox(height: 10),

              _buildActionButton(
                title: 'استعادة نسخة محلية',
                icon: LucideIcons.upload,
                color: const Color(0xff374151),
                onPressed: () {
                  _showMessage(
                    context,
                    'سيتم تفعيل الاستعادة المحلية هنا',
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildSection(
            title: 'النسخ السحابي',
            subtitle: 'حفظ واستعادة بياناتك عبر السحابة',
            icon: LucideIcons.cloud,
            children: [
              _buildActionButton(
                title: 'إنشاء نسخة سحابية',
                icon: LucideIcons.cloudUpload,
                color: const Color(0xff2864D7),
                onPressed: () {
                  _showMessage(
                    context,
                    'سيتم تفعيل النسخ السحابي مع Supabase لاحقًا',
                  );
                },
              ),

              const SizedBox(height: 10),

              _buildActionButton(
                title: 'استعادة نسخة سحابية',
                icon: LucideIcons.cloudDownload,
                color: const Color(0xff374151),
                onPressed: () {
                  _showMessage(
                    context,
                    'سيتم تفعيل الاستعادة السحابية مع Supabase لاحقًا',
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildLastBackupCard(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xffE2E6EC),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xffEAF1FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.database,
              color: Color(0xff2864D7),
              size: 25,
            ),
          ),

          const SizedBox(width: 13),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'النسخ الاحتياطي والاستعادة',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff172033),
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'إدارة النسخ الاحتياطية واستعادة بيانات النظام.',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xffE2E6EC),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xff2864D7),
                size: 22,
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff172033),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xff8A94A6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

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
      height: 46,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 19,
        ),
        label: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xffE8ECF2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.clock3,
            size: 20,
            color: Color(0xff7A8495),
          ),

          const SizedBox(width: 10),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'آخر نسخة احتياطية',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff172033),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'لا توجد نسخة محفوظة',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
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

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.right,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}