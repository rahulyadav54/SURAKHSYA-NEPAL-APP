import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Colours used throughout this screen
// ─────────────────────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFFB71C1C);
const _kPrimaryDark = Color(0xFF7B0000);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Phone fields
  final _phoneController = TextEditingController();
  String _selectedDialCode = '+977'; // default Nepal
  String _selectedCountryCode = 'NP';

  // Email fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _showSnack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? Colors.green[700] : _kPrimary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _handlePhoneSubmit() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showSnack('Please enter your phone number');
      return;
    }

    // Build E.164 formatted number: dialCode + digits
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    final fullNumber = '$_selectedDialCode$digitsOnly';

    final success = await ref
        .read(authControllerProvider.notifier)
        .signInWithOtp(fullNumber);
    if (success && mounted) {
      context.push('/otp-verify', extra: fullNumber);
    }
  }

  Future<void> _handleEmailSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showSnack('Please fill in all fields');
      return;
    }
    final controller = ref.read(authControllerProvider.notifier);
    if (_isSignUp) {
      final ok = await controller.signUpWithEmailAndPassword(email, password);
      if (ok && mounted) {
        _showSnack('Registered! Check your email to confirm.', success: true);
      }
    } else {
      await controller.signInWithEmailAndPassword(email, password);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authControllerProvider, (_, next) {
      if (next is Authenticated) {
        context.go('/home');
      } else if (next is NeedsProfileCreation) {
        context.go('/create-profile');
      } else if (next is AuthError) {
        _showSnack(next.message);
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          children: [
            // ── Deep red gradient top half ────────────────────────────────
            Container(
              height: MediaQuery.of(context).size.height * 0.48,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_kPrimary, _kPrimaryDark],
                ),
              ),
            ),

            // ── Decorative circles ────────────────────────────────────────
            Positioned(
              top: -70,
              right: -70,
              child: _circle(240, 0.06),
            ),
            Positioned(
              top: 80,
              left: -50,
              child: _circle(160, 0.04),
            ),
            Positioned(
              top: 180,
              right: 20,
              child: _circle(60, 0.08),
            ),

            // ── Scroll content ────────────────────────────────────────────
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 32),

                    // ── Logo ─────────────────────────────────────────────
                    _buildLogo(),
                    const SizedBox(height: 20),

                    // ── App name ──────────────────────────────────────────
                    Text(
                      'Suraksha Nepal',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 250.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 4),

                    Text(
                      'सुरक्षित जीवन • Safe Nation',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        letterSpacing: 0.4,
                      ),
                    ).animate().fadeIn(delay: 350.ms),

                    const SizedBox(height: 32),

                    // ── White auth card ───────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _buildAuthCard(theme, isLoading),
                    )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 500.ms)
                        .slideY(begin: 0.08, end: 0),

                    const SizedBox(height: 28),

                    // ── Footer text ───────────────────────────────────────
                    Text(
                      'तपाईंको सुरक्षा, हाम्रो दायित्व',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white60,
                      ),
                    ).animate().fadeIn(delay: 650.ms),
                    const SizedBox(height: 4),
                    Text(
                      'Your Safety, Our Responsibility',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ).animate().fadeIn(delay: 750.ms),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Logo Widget ──────────────────────────────────────────────────────────

  Widget _buildLogo() {
    return Hero(
      tag: 'app_logo',
      child: Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: _kPrimary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/logo.png',
            width: 104,
            height: 104,
            fit: BoxFit.contain, // contain keeps full logo visible
            errorBuilder: (_, __, ___) => const Icon(
              Icons.security_rounded,
              size: 52,
              color: _kPrimary,
            ),
          ),
        ),
      ),
    )
        .animate()
        .scale(duration: 700.ms, curve: Curves.easeOutBack)
        .fadeIn(duration: 500.ms);
  }

  // ── Auth card ────────────────────────────────────────────────────────────

  Widget _buildAuthCard(ThemeData theme, bool isLoading) {
    return Card(
      elevation: 20,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Styled TabBar ────────────────────────────────────────
            _buildTabBar(theme),
            const SizedBox(height: 24),

            // ── TabBarView ───────────────────────────────────────────
            SizedBox(
              height: _tabController.index == 1 && _isSignUp ? 240 : 210,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 0 – Phone OTP
                  _PhoneTab(
                    controller: _phoneController,
                    selectedDialCode: _selectedDialCode,
                    selectedCountryCode: _selectedCountryCode,
                    isLoading: isLoading,
                    onCountryChanged: (code) {
                      setState(() {
                        _selectedDialCode = code.dialCode ?? '+977';
                        _selectedCountryCode = code.code ?? 'NP';
                      });
                    },
                    onSubmit: _handlePhoneSubmit,
                  ),

                  // Tab 1 – Email
                  _EmailTab(
                    emailController: _emailController,
                    passwordController: _passwordController,
                    isLoading: isLoading,
                    isSignUp: _isSignUp,
                    obscurePassword: _obscurePassword,
                    onToggleObscure: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    onSubmit: _handleEmailSubmit,
                  ),
                ],
              ),
            ),

            // ── Toggle sign-up / sign-in for email tab ───────────────
            AnimatedBuilder(
              animation: _tabController,
              builder: (_, __) {
                if (_tabController.index != 1) return const SizedBox.shrink();
                return TextButton(
                  onPressed: () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Sign In'
                        : "Don't have an account? Register",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: _kPrimary),
                  ),
                );
              },
            ),

            // ── Divider ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('OR',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: Colors.grey)),
                ),
                const Expanded(child: Divider()),
              ]),
            ),

            const SizedBox(height: 8),

            // ── Google Sign-In ────────────────────────────────────────
            _GoogleButton(
              isLoading: isLoading,
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).signInWithGoogle(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
        ),
        child: TabBar(
          controller: _tabController,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
                colors: [_kPrimary, _kPrimaryDark]),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          labelColor: Colors.white,
          unselectedLabelColor: theme.colorScheme.onSurface,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 13),
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(icon: Icon(Icons.phone_android_rounded, size: 17),
                text: 'Phone OTP'),
            Tab(icon: Icon(Icons.email_outlined, size: 17), text: 'Email'),
          ],
        ),
      ),
    );
  }

  // ── Utility ──────────────────────────────────────────────────────────────

  Widget _circle(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// Phone OTP Tab  (with country code picker)
// ═════════════════════════════════════════════════════════════════════════════
class _PhoneTab extends StatelessWidget {
  final TextEditingController controller;
  final String selectedDialCode;
  final String selectedCountryCode;
  final bool isLoading;
  final ValueChanged<CountryCode> onCountryChanged;
  final VoidCallback onSubmit;

  const _PhoneTab({
    required this.controller,
    required this.selectedDialCode,
    required this.selectedCountryCode,
    required this.isLoading,
    required this.onCountryChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ── Phone number field with country picker ──────────────────
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              // Country code picker
              CountryCodePicker(
                onChanged: onCountryChanged,
                initialSelection: selectedCountryCode,
                favorite: const ['+977', '+91', '+1', '+44', '+61'],
                showCountryOnly: false,
                showOnlyCountryWhenClosed: false,
                alignLeft: false,
                showFlag: true,
                showFlagDialog: true,
                dialogSize: const Size(400, 550),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
                dialogTextStyle: const TextStyle(fontSize: 14),
                searchDecoration: InputDecoration(
                  hintText: 'Search country...',
                  prefixIcon:
                      const Icon(Icons.search_rounded, color: _kPrimary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: _kPrimary, width: 2),
                  ),
                ),
              ),

              // Vertical divider
              Container(
                  width: 1,
                  height: 28,
                  color: Colors.grey.shade300),

              // Phone number input
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  decoration: const InputDecoration(
                    hintText: 'Phone number',
                    hintStyle:
                        TextStyle(fontSize: 14, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // ── International note ──────────────────────────────────────
        Row(
          children: [
            Icon(Icons.public_rounded,
                size: 13, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(
              'Works with any country ($selectedDialCode selected)',
              style: TextStyle(
                  fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ── Send OTP button ─────────────────────────────────────────
        _PrimaryButton(
          text: 'Send OTP Code',
          icon: Icons.send_rounded,
          isLoading: isLoading,
          onPressed: onSubmit,
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Email Tab
// ═════════════════════════════════════════════════════════════════════════════
class _EmailTab extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final bool isSignUp;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  const _EmailTab({
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.isSignUp,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _field(
            controller: emailController,
            label: 'Email Address',
            icon: Icons.email_outlined,
            keyboard: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _field(
            controller: passwordController,
            label: 'Password',
            icon: Icons.lock_outline_rounded,
            obscure: obscurePassword,
            suffix: IconButton(
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
              ),
              onPressed: onToggleObscure,
            ),
          ),
          const SizedBox(height: 16),
          _PrimaryButton(
            text: isSignUp ? 'Create Account' : 'Sign In',
            icon: isSignUp
                ? Icons.person_add_rounded
                : Icons.login_rounded,
            isLoading: isLoading,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Colors.grey, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kPrimary, width: 2),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Shared Primary Button
// ═════════════════════════════════════════════════════════════════════════════
class _PrimaryButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.text,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: _kPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
      ),
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: Colors.white),
            )
          : Icon(icon, size: 20),
      label: Text(
        isLoading ? 'Please wait...' : text,
        style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Google Sign-In Button
// ═════════════════════════════════════════════════════════════════════════════
class _GoogleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _GoogleButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          side: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google G logo in a gradient circle
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF4285F4), Color(0xFF34A853)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.25),
                    blurRadius: 6,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text(
                'G',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Continue with Google',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
