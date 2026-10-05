import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../services/import_service.dart';

class ImportProgressView extends StatefulWidget {
  final ImportProgress progress;

  /// اختياري:
  /// إذا أردت التحكم بالانتقال للصفحة التالية من هنا،
  /// مرر دالة في onCompleted.
  final VoidCallback? onCompleted;

  const ImportProgressView({
    super.key,
    required this.progress,
    this.onCompleted,
  });

  @override
  State<ImportProgressView> createState() => _ImportProgressViewState();
}

class _ImportProgressViewState extends State<ImportProgressView>
    with TickerProviderStateMixin {
  static const Color blue = Color(0xff2563EB);
  static const Color text = Color(0xff0F1E46);

  late final AnimationController _rotationController;
  late final AnimationController _progressController;

  late double _displayedProgress;
  late double _animationStartProgress;
  late double _animationTargetProgress;

  Timer? _completionTimer;
  bool _completionScheduled = false;

  @override
  void initState() {
    super.initState();

    _displayedProgress =
        widget.progress.progress.clamp(0.0, 1.0).toDouble();

    _animationStartProgress = _displayedProgress;
    _animationTargetProgress = _displayedProgress;

    // دوران الحلقات بطيء وهادئ.
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 28),
    )..repeat();

    // يتحكم في انتقال نسبة الاستيراد بشكل سلس.
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _progressController.addListener(() {
      if (!mounted) return;

      final curveValue = Curves.easeInOutCubic.transform(
        _progressController.value,
      );

      setState(() {
        _displayedProgress = _animationStartProgress +
            ((_animationTargetProgress - _animationStartProgress) *
                curveValue);
      });
    });

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed &&
          _animationTargetProgress >= 1.0) {
        _scheduleCompletion();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ImportProgressView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newProgress =
        widget.progress.progress.clamp(0.0, 1.0).toDouble();

    final oldProgress =
        oldWidget.progress.progress.clamp(0.0, 1.0).toDouble();

    // لا نعيد تشغيل الأنيميشن إذا لم تتغير النسبة.
    if ((newProgress - oldProgress).abs() < 0.0001) {
      return;
    }

    _animateToProgress(newProgress);
  }

  void _animateToProgress(double target) {
    _completionTimer?.cancel();

    _animationStartProgress = _displayedProgress;
    _animationTargetProgress = target.clamp(0.0, 1.0).toDouble();

    _completionScheduled = false;

    // كلما اقتربنا من النهاية نبطئ الحركة أكثر.
    final difference =
        (_animationTargetProgress - _animationStartProgress).abs();

    final milliseconds = difference >= 0.20
        ? 1500
        : difference >= 0.08
            ? 1200
            : 1000;

    _progressController.duration =
        Duration(milliseconds: milliseconds);

    _progressController
      ..stop()
      ..reset()
      ..forward();
  }

  void _scheduleCompletion() {
    if (_completionScheduled) return;

    _completionScheduled = true;

    // نترك 100% ظاهرًا قليلًا قبل الانتقال.
    _completionTimer = Timer(
      const Duration(milliseconds: 2200),
      () {
        if (!mounted) return;

        widget.onCompleted?.call();
      },
    );
  }

  @override
  void dispose() {
    _completionTimer?.cancel();
    _rotationController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_displayedProgress * 100).round().clamp(0, 100);

    return Column(
      children: [
        SizedBox(
          height: 300,
          width: double.infinity,
          child: AnimatedBuilder(
            animation: _rotationController,
            builder: (context, _) {
              return CustomPaint(
                painter: _ImportRingsPainter(
                  progress: _displayedProgress,
                  rotation: _rotationController.value * math.pi * 2,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$percent%',
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: text,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'جاري الاستيراد...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: text,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'يرجى عدم إغلاق التطبيق',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blueGrey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 4),

        _StageList(progress: widget.progress),
      ],
    );
  }
}

class _StageList extends StatelessWidget {
  final ImportProgress progress;

  const _StageList({
    required this.progress,
  });

  static const Color blue = Color(0xff2563EB);
  static const Color text = Color(0xff0F1E46);

  @override
  Widget build(BuildContext context) {
    final stages = [
      (
        'قراءة الملف',
        'تمت قراءة الملف بنجاح',
      ),
      (
        'تحليل البيانات',
        'جاري تحليل البيانات...',
      ),
      (
        'التحقق من التكرار',
        'في انتظار اكتمال التحليل',
      ),
      (
        'إضافة الموظفين',
        'في الانتظار...',
      ),
    ];

    final activeIndex = _activeIndex(progress.stage);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xffE5ECF8),
        ),
      ),
      child: Column(
        children: List.generate(
          stages.length,
          (index) {
            final active = index == activeIndex;

            final done =
                index < activeIndex ||
                (progress.progress >= 1.0 &&
                    index == stages.length - 1);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 7,
                  ),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: _StatusIcon(
                          key: ValueKey(
                            '$index-$done-$active',
                          ),
                          done: done,
                          active: active,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.end,
                          children: [
                            Text(
                              stages[index].$1,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              done
                                  ? 'اكتملت العملية'
                                  : active
                                      ? stages[index].$2
                                      : 'في الانتظار...',
                              style: TextStyle(
                                fontSize: 9.5,
                                color: active
                                    ? blue
                                    : Colors.blueGrey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (index == 1 || index == 2)
                        const SizedBox(width: 8),

                      if (index == 1 || index == 2)
                        Text(
                          index == 1
                              ? '${progress.processed} / ${progress.total}'
                              : '${progress.imported} مضاف',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.blueGrey.shade500,
                          ),
                        ),
                    ],
                  ),
                ),

                if (index != stages.length - 1)
                  const Divider(
                    height: 1,
                    color: Color(0xffEDF1F7),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  int _activeIndex(String stage) {
    switch (stage) {
      case 'قراءة الملف':
        return 0;

      case 'تحليل البيانات':
        return 1;

      case 'التحقق من التكرار':
        return 2;

      case 'إضافة الموظفين':
        return 3;

      default:
        return 0;
    }
  }
}

class _StatusIcon extends StatelessWidget {
  final bool done;
  final bool active;

  const _StatusIcon({
    super.key,
    required this.done,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    if (done) {
      return Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: Color(0xff2563EB),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check,
          color: Colors.white,
          size: 16,
        ),
      );
    }

    if (active) {
      return const SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          color: Color(0xff2563EB),
        ),
      );
    }

    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: Color(0xffE7ECF5),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ImportRingsPainter extends CustomPainter {
  final double progress;
  final double rotation;

  const _ImportRingsPainter({
    required this.progress,
    required this.rotation,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center = size.center(Offset.zero);

    final radius =
        math.min(size.width, size.height) * .245;

    // المسار الخلفي للعداد.
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..color = const Color(0xffDCE8FB);

    // نسبة الاستيراد.
    final value = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xff2563EB);

    canvas.drawCircle(
      center,
      radius,
      track,
    );

    final sweep =
        math.pi * 2 * progress.clamp(0.0, 1.0);

    if (sweep > 0) {
      canvas.drawArc(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
        -math.pi / 2,
        sweep,
        false,
        value,
      );
    }

    // الحلقات الخارجية.
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.05
      ..color = const Color(0xffBBD3FA);

    for (int i = 0; i < 4; i++) {
      canvas.drawCircle(
        center,
        radius + 23.0 + (i * 20),
        ringPaint,
      );
    }

    // النقاط المتحركة حول الحلقات.
    final dotPaint = Paint()
      ..color = const Color(0xff78AFFF);

    for (int i = 0; i < 8; i++) {
      final direction = i.isEven ? 1 : -1;

      final angle =
          rotation * direction +
          (i * math.pi / 4);

      final r =
          radius +
          23 +
          (i % 3) * 20;

      final offset = Offset(
        center.dx + math.cos(angle) * r,
        center.dy + math.sin(angle) * r,
      );

      canvas.drawCircle(
        offset,
        i % 3 == 0 ? 4 : 2.8,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _ImportRingsPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress ||
        oldDelegate.rotation != rotation;
  }
}