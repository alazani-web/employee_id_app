import 'package:flutter/material.dart';

class AppLockScreen extends StatefulWidget {
  final Future<bool> Function(String pin) onUnlock;

  const AppLockScreen({
    super.key,
    required this.onUnlock,
  });

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final _pinController = TextEditingController();
  bool _checking = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    final pin = _pinController.text.trim();
    if (pin.isEmpty || _checking) return;

    setState(() {
      _checking = true;
      _error = null;
    });

    final ok = await widget.onUnlock(pin);

    if (!mounted) return;

    if (!ok) {
      setState(() {
        _checking = false;
        _error = 'الرقم السري غير صحيح';
        _pinController.clear();
      });
      return;
    }

    setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: const Color(0xffF7F9FC),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xffE5E7EB)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xffEAF1FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.lock_outline_rounded,
                          color: Color(0xff2864D7),
                          size: 31,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'التطبيق مقفل',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xff172033),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'أدخل الرقم السري للمتابعة',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xff7A8495),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _pinController,
                        obscureText: true,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 8,
                        onSubmitted: (_) => _unlock(),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '••••',
                          filled: true,
                          fillColor: const Color(0xffF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 15,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xffE5E7EB),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xffE5E7EB),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xff2864D7),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: Color(0xffDC2626),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _checking ? null : _unlock,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff2864D7),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          child: _checking
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'فتح التطبيق',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
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
        ),
      ),
    );
  }
}
