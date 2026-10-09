import 'package:flutter/material.dart';

class ActionSheetItem {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  const ActionSheetItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.iconColor = const Color(0xFF2563EB),
    this.backgroundColor = const Color(0xFFF1F5F9),
  });
}

class ActionSheet {
  static Future<void> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    required List<ActionSheetItem> actions,
    String closeLabel = 'إلغاء',
    IconData? headerIcon,
    Color headerIconColor = const Color(0xFF2563EB),
    Color headerIconBackground = const Color(0xFFEFF6FF),
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 52,
            vertical: 20,
          ),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 270,
              minWidth: 0,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(9, 9, 9, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // العنوان في المنتصف مثل التصميم المطلوب.
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                      height: 1.2,
                    ),
                  ),
                  if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF64748B),
                        height: 1.2,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: actions.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                      mainAxisExtent: 44,
                    ),
                    itemBuilder: (_, index) {
                      final action = actions[index];
                      return Material(
                        color: action.backgroundColor,
                        borderRadius: BorderRadius.circular(9),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(dialogContext).pop();
                            Future.microtask(action.onTap);
                          },
                          borderRadius: BorderRadius.circular(9),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  action.icon,
                                  size: 15,
                                  color: action.iconColor,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  action.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: action.iconColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF334155),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: Text(
                        closeLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
