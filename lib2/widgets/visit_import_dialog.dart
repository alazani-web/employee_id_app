import 'package:flutter/material.dart';

/// نافذة استيراد الزيارات العائلية.
/// التصميم مطابق لواجهة الاستيراد المطلوبة:
/// - خلفية بيضاء
/// - عنوان في الأعلى
/// - زر تحميل قالب
/// - منطقة رفع كبيرة
/// - زر اختيار ملف باللون الموف
/// - صندوق متطلبات باللون الموف الفاتح
///
/// يتم تمرير callbacks من visits_screen.dart حتى تبقى عملية
/// الاستيراد وتحميل القالب في الصفحة الأساسية.
class VisitImportDialog extends StatelessWidget {
  final VoidCallback onDownloadTemplate;
  final VoidCallback onPickFile;

  const VisitImportDialog({
    super.key,
    required this.onDownloadTemplate,
    required this.onPickFile,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onDownloadTemplate,
    required VoidCallback onPickFile,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (_) => VisitImportDialog(
        onDownloadTemplate: onDownloadTemplate,
        onPickFile: onPickFile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF8B35E8);
    const lightPurple = Color(0xFFF7F3FC);
    const darkText = Color(0xFF151A24);
    const greyText = Color(0xFF7D8794);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: Colors.white,
        elevation: 10,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 30,
          vertical: 28,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 680,
            maxHeight: 760,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 20, 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'استيراد الزيارات العائلية',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: darkText,
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'إغلاق',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Color(0xFF9AA2AD),
                        size: 29,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFE7E7EA),
              ),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(30, 32, 30, 30),
                  child: Column(
                    children: [
                      const Text(
                        'قم بتحميل ملف Excel أو CSV يحتوي على بيانات\nالزيارات العائلية',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: greyText,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 26),

                      // Download template button
                      SizedBox(
                        height: 52,
                        child: TextButton.icon(
                          onPressed: onDownloadTemplate,
                          style: TextButton.styleFrom(
                            backgroundColor: lightPurple,
                            foregroundColor: purple,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          icon: const Icon(
                            Icons.download_rounded,
                            size: 25,
                          ),
                          label: const Text(
                            'تحميل قالب Excel للزيارات العائلية',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Upload area
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 42,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFE2E5EA),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.file_upload_outlined,
                              color: Color(0xFFA4ACB8),
                              size: 65,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'اسحب وأفلت ملف الزيارات هنا',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: darkText,
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'أو',
                              style: TextStyle(
                                color: greyText,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),

                            SizedBox(
                              height: 58,
                              child: ElevatedButton.icon(
                                onPressed: onPickFile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: purple,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 30,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.description_outlined,
                                  size: 28,
                                ),
                                label: const Text(
                                  'اختر ملف',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Requirements
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(
                          22,
                          22,
                          22,
                          24,
                        ),
                        decoration: BoxDecoration(
                          color: lightPurple,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFEAE2F5),
                          ),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'متطلبات ملف الزيارات العائلية:',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: Color(0xFF6F2CA8),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              '• اسم الزائر، رقم التأشيرة، رقم الحدود، رقم الجواز\n'
                              '• تاريخ انتهاء الزيارة وتاريخ انتهاء التأمين',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: Color(0xFF6F2CA8),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                height: 1.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
