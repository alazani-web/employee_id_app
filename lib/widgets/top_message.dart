import 'dart:async';

import 'package:flutter/material.dart';

enum TopMessageType { success, error, info }

class TopMessage {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(
    BuildContext context,
    String message, {
    TopMessageType type = TopMessageType.success,
  }) {
    _timer?.cancel();
    _entry?.remove();
    _entry = null;

    final overlay = Overlay.of(context, rootOverlay: true);

    final entry = OverlayEntry(
      builder: (_) => _TopMessageView(
        message: message,
        type: type,
        onClose: _remove,
      ),
    );

    _entry = entry;
    overlay.insert(entry);

    _timer = Timer(const Duration(seconds: 2, milliseconds: 500), _remove);
  }

  static void _remove() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

class _TopMessageView extends StatefulWidget {
  final String message;
  final TopMessageType type;
  final VoidCallback onClose;

  const _TopMessageView({
    required this.message,
    required this.type,
    required this.onClose,
  });

  @override
  State<_TopMessageView> createState() => _TopMessageViewState();
}

class _TopMessageViewState extends State<_TopMessageView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 180),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, -0.8),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _color {
    switch (widget.type) {
      case TopMessageType.success:
        return const Color(0xff16A34A);
      case TopMessageType.error:
        return const Color(0xffDC2626);
      case TopMessageType.info:
        return const Color(0xff2563EB);
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case TopMessageType.success:
        return Icons.check_circle_outline_rounded;
      case TopMessageType.error:
        return Icons.error_outline_rounded;
      case TopMessageType.info:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Material(
              color: Colors.transparent,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 54),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _color.withOpacity(.16),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F000000),
                          blurRadius: 22,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: _color.withOpacity(.10),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_icon, color: _color, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              color: Color(0xff172033),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.close_rounded,
                          color: Colors.grey.shade500,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
