import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum ActionResultType { success, delete, error, info }

class ActionResultDialog extends StatefulWidget {
  final ActionResultType type;
  final String title;
  final String? name;
  final String message;

  const ActionResultDialog({
    super.key,
    required this.type,
    required this.title,
    this.name,
    required this.message,
  });

  static Future<void> show(
    BuildContext context, {
    required ActionResultType type,
    required String title,
    String? name,
    required String message,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'إغلاق',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, __, ___) => ActionResultDialog(
        type: type,
        title: title,
        name: name,
        message: message,
      ),
      transitionBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: .82, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Color get mainColor => type == ActionResultType.delete || type == ActionResultType.error
      ? const Color(0xffE5252A)
      : type == ActionResultType.info
          ? const Color(0xff2864D7)
          : const Color(0xff16A34A);

  Color get lightColor => type == ActionResultType.delete || type == ActionResultType.error
      ? const Color(0xffffe1e1)
      : type == ActionResultType.info
          ? const Color(0xffEAF1FF)
          : const Color(0xffDDFBE8);

  @override
  State<ActionResultDialog> createState() => _ActionResultDialogState();
}

class _ActionResultDialogState extends State<ActionResultDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _checkController;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDelete = widget.type == ActionResultType.delete;
    final isError = widget.type == ActionResultType.error;
    final isInfo = widget.type == ActionResultType.info;

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [BoxShadow(blurRadius: 35, offset: Offset(0, 16), color: Color(0x33000000))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _iconCircle(isDelete, isError, isInfo),
                  const SizedBox(height: 22),
                  Text(widget.title, textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xff172033), fontSize: 21, fontWeight: FontWeight.w800)),
                  if (widget.name != null && widget.name!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(widget.name!, textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xff526078), fontSize: 15, fontWeight: FontWeight.w600)),
                  ],
                  const SizedBox(height: 8),
                  Text(widget.message, textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xff7A8495), fontSize: 12.5, height: 1.5)),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(color: widget.lightColor, borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      AnimatedBuilder(
                        animation: _checkController,
                        builder: (_, __) => SizedBox(
                          width: 19, height: 19,
                          child: CustomPaint(painter: _CheckPainter(
                            progress: _checkController.value,
                            color: widget.mainColor,
                            showCheck: !isInfo && !isError,
                            icon: isDelete ? LucideIcons.trash2 : isInfo ? LucideIcons.info : LucideIcons.circleAlert,
                          )),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(isDelete ? 'تم حفظ عملية الحذف بنجاح' : 'تم حفظ العملية بنجاح',
                        style: TextStyle(color: widget.mainColor, fontSize: 12.5, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconCircle(bool isDelete, bool isError, bool isInfo) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .65, end: 1), duration: const Duration(milliseconds: 500), curve: Curves.easeOutBack,
      builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        width: 92, height: 92,
        decoration: BoxDecoration(color: widget.lightColor, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: widget.mainColor, shape: BoxShape.circle),
          child: (isDelete || isError || isInfo)
              ? Icon(isDelete ? LucideIcons.trash2 : isInfo ? LucideIcons.info : LucideIcons.circleAlert, color: Colors.white, size: 30)
              : AnimatedBuilder(
                  animation: _checkController,
                  builder: (_, __) => CustomPaint(painter: _CheckPainter(progress: _checkController.value, color: Colors.white)),
                ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool showCheck;
  final IconData? icon;

  const _CheckPainter({required this.progress, required this.color, this.showCheck = true, this.icon});

  @override
  void paint(Canvas canvas, Size size) {
    if (!showCheck) return;
    final paint = Paint()..color = color..strokeWidth = 4.2..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..style = PaintingStyle.stroke;
    final path = Path()..moveTo(size.width * .22, size.height * .52)..lineTo(size.width * .43, size.height * .70)..lineTo(size.width * .78, size.height * .30);
    final metric = path.computeMetrics().first;
    canvas.drawPath(metric.extractPath(0, metric.length * progress.clamp(0, 1)), paint);
  }

  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.color != color;
}
