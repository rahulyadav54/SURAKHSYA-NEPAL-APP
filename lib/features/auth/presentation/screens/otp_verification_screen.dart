import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_state.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  const OtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends ConsumerState<OtpVerificationScreen> {
  // 6 individual controllers for each OTP digit box
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Auto-focus first box
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    setState(() => _resendCountdown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        _timer?.cancel();
      }
    });
  }

  String get _otpCode =>
      _controllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    final code = _otpCode;
    if (code.length < 6) {
      _showSnack('Please enter the complete 6-digit OTP code');
      return;
    }
    await ref
        .read(authControllerProvider.notifier)
        .verifyOtp(widget.phoneNumber, code);
  }

  Future<void> _resendOtp() async {
    _startTimer();
    // Clear all boxes
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
    await ref
        .read(authControllerProvider.notifier)
        .signInWithOtp(widget.phoneNumber);
    if (!mounted) return;
    _showSnack('New OTP code sent!', success: true);
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? Colors.green[700] : Colors.red[700],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _onDigitChanged(String value, int index) {
    if (value.length == 1) {
      // Move forward
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Auto verify when last digit is entered
        _focusNodes[index].unfocus();
        _verifyOtp();
      }
    } else if (value.isEmpty && index > 0) {
      // Move backward on delete
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);

    ref.listen<AuthState>(authControllerProvider, (_, next) {
      if (next is Authenticated) {
        context.go('/home');
      } else if (next is NeedsProfileCreation) {
        context.go('/create-profile');
      } else if (next is AuthError) {
        _showSnack(next.message);
        // Clear boxes on error
        for (final c in _controllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          children: [
            // ── Background gradient ────────────────────────────────
            Container(
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFB71C1C), Color(0xFF7B0000)],
                ),
              ),
            ),

            // ── Background circles ────────────────────────────────
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // ── Back Button ───────────────────────────────────
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white),
                    ),
                  ).animate().fadeIn(duration: 400.ms),

                  const SizedBox(height: 16),

                  // ── Lock Icon ─────────────────────────────────────
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2),
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  )
                      .animate()
                      .scale(duration: 500.ms, curve: Curves.easeOutBack)
                      .fadeIn(),

                  const SizedBox(height: 20),

                  Text(
                    'Verification Code',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 8),

                  Text(
                    'Enter the 6-digit OTP sent to',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 4),

                  Text(
                    widget.phoneNumber,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 36),

                  // ── White Card ────────────────────────────────────
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 20,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // ── 6 OTP Boxes ─────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              6,
                              (i) => _OtpBox(
                                controller: _controllers[i],
                                focusNode: _focusNodes[i],
                                onChanged: (val) => _onDigitChanged(val, i),
                              ).animate().scale(
                                    delay: (80 * i).ms,
                                    duration: 300.ms,
                                    curve: Curves.easeOutBack,
                                  ),
                            ),
                          ),

                          const SizedBox(height: 36),

                          // ── Verify Button ────────────────────────
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed:
                                  authState is AuthLoading ? null : _verifyOtp,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFB71C1C),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: authState is AuthLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.verified_rounded, size: 20),
                                        SizedBox(width: 10),
                                        Text(
                                          'Verify & Continue',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

                          const SizedBox(height: 24),

                          // ── Resend OTP ───────────────────────────
                          if (_resendCountdown > 0)
                            RichText(
                              text: TextSpan(
                                style: theme.textTheme.bodyMedium,
                                children: [
                                  const TextSpan(
                                      text: 'Resend code in '),
                                  TextSpan(
                                    text: '${_resendCountdown}s',
                                    style: const TextStyle(
                                      color: Color(0xFFB71C1C),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            TextButton.icon(
                              onPressed: _resendOtp,
                              icon: const Icon(Icons.refresh_rounded,
                                  color: Color(0xFFB71C1C)),
                              label: const Text(
                                'Resend OTP Code',
                                style: TextStyle(
                                  color: Color(0xFFB71C1C),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                          const SizedBox(height: 12),

                          // ── Security note ─────────────────────────
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.shield_outlined,
                                    color: Colors.green[600], size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'This code expires in 10 minutes. Never share it with anyone.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 700.ms),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual OTP Digit Box
// ─────────────────────────────────────────────────────────────────────────────
class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFFB71C1C),
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFFB71C1C), width: 2.5),
          ),
          filled: true,
          fillColor: focusNode.hasFocus
              ? const Color(0xFFB71C1C).withValues(alpha: 0.06)
              : Colors.grey.withValues(alpha: 0.04),
        ),
      ),
    );
  }
}
