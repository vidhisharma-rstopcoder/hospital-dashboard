import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hospital_dashboard/common/widgets/entrance.dart';
import 'package:hospital_dashboard/common/widgets/glass_panel.dart';
import 'package:hospital_dashboard/common/widgets/hospital_logo.dart';
import 'package:hospital_dashboard/common/widgets/hospital_scene.dart';
import 'package:hospital_dashboard/common/widgets/mesh_backdrop.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hospital_dashboard/features/auth/data/auth_repository.dart';
import 'package:hospital_dashboard/features/auth/presentation/auth_controller.dart';
import 'package:hospital_dashboard/theme/app_colors.dart';
import 'package:hospital_dashboard/theme/app_theme.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _submitted = false;
  var _obscure = true;
  var _remember = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('cityhospital.remember.email');
    if (!mounted || saved == null || saved.isEmpty) return;
    setState(() {
      _email.text = saved;
      _remember = true;
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _submitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final signedIn = await ref
        .read(authControllerProvider.notifier)
        .signIn(_email.text, _password.text);
    if (!signedIn || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    if (_remember) {
      await prefs.setString(
        'cityhospital.remember.email',
        _email.text.trim().toLowerCase(),
      );
    } else {
      await prefs.remove('cityhospital.remember.email');
    }
  }

  void _useDemo(String email) {
    _email.text = email;
    _password.text = AuthRepository.demoPassword;
    ref.read(authControllerProvider.notifier).clearError();
    setState(() => _submitted = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 980;
          final form = _LoginForm(
            formKey: _formKey,
            email: _email,
            password: _password,
            obscure: _obscure,
            submitted: _submitted,
            submitting: auth.submitting,
            errorMessage: auth.errorMessage,
            onToggleObscure: () => setState(() => _obscure = !_obscure),
            onSubmit: _submit,
            onUseDemo: _useDemo,
            remember: _remember,
            onRemember: (value) => setState(() => _remember = value),
            onEdited: () =>
                ref.read(authControllerProvider.notifier).clearError(),
          );
          if (!wide) {
            return Stack(
              children: [
                const Positioned.fill(child: MeshBackdrop()),
                SingleChildScrollView(
                  child: Column(
                    children: [
                      const _CompactBrand(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                        child: GlassPanel(child: form),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          return Row(
            children: [
              const Expanded(flex: 6, child: _BrandPanel()),
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    const Positioned.fill(child: MeshBackdrop()),
                    LayoutBuilder(
                      builder: (context, pane) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 32,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: math.max(0, pane.maxHeight - 64),
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 440,
                                ),
                                child: GlassPanel(child: form),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.email,
    required this.password,
    required this.obscure,
    required this.submitted,
    required this.submitting,
    required this.errorMessage,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.onUseDemo,
    required this.remember,
    required this.onRemember,
    required this.onEdited,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final bool obscure;
  final bool submitted;
  final bool submitting;
  final String? errorMessage;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final ValueChanged<String> onUseDemo;
  final bool remember;
  final ValueChanged<bool> onRemember;
  final VoidCallback onEdited;

  @override
  Widget build(BuildContext context) {
    return Entrance(
      child: Form(
        key: formKey,
        autovalidateMode: submitted
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome back',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in to the hospital desk.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 15.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 22),
            _DemoCard(onUseDemo: onUseDemo),
            const SizedBox(height: 22),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: errorMessage == null
                  ? const SizedBox(width: double.infinity)
                  : Container(
                      key: const ValueKey('auth-error'),
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFECDD3)),
                      ),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: AppColors.critical,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
            TextFormField(
              key: const Key('email-field'),
              controller: email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              validator: validateEmail,
              onChanged: (_) => onEdited(),
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'name@cityhospital.org',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('password-field'),
              controller: password,
              obscureText: obscure,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              validator: validatePassword,
              onChanged: (_) => onEdited(),
              onFieldSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: onToggleObscure,
                  tooltip: obscure ? 'Show password' : 'Hide password',
                  icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: remember,
                  onChanged: (value) => onRemember(value ?? false),
                ),
                const Text(
                  'Remember me',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Password reset'),
                        content: const Text(
                          'This desk does not send reset mail. Use the shared demonstration password Ward1234, or ask an administrator.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Forgot password?'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _SignInButton(submitting: submitting, onPressed: onSubmit),
            const SizedBox(height: 16),
            const Text(
              'Ward staff only. Don’t share this login.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignInButton extends StatefulWidget {
  const _SignInButton({required this.submitting, required this.onPressed});

  final bool submitting;
  final VoidCallback onPressed;

  @override
  State<_SignInButton> createState() => _SignInButtonState();
}

class _SignInButtonState extends State<_SignInButton> {
  var _hover = false;
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = widget.submitting
        ? 1.0
        : _pressed
        ? 0.98
        : _hover
        ? 1.02
        : 1.0;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _pressed = false;
      }),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF38BDF8), AppColors.teal],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.teal.withValues(alpha: _hover ? 0.35 : 0.2),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: const Key('sign-in-button'),
                borderRadius: BorderRadius.circular(14),
                onTap: widget.submitting ? null : widget.onPressed,
                onTapDown: widget.submitting
                    ? null
                    : (_) => setState(() => _pressed = true),
                onTapUp: (_) => setState(() => _pressed = false),
                onTapCancel: () => setState(() => _pressed = false),
                child: Center(
                  child: widget.submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Sign in',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: appFontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
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

class _DemoCard extends StatelessWidget {
  const _DemoCard({required this.onUseDemo});

  final ValueChanged<String> onUseDemo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9DDFC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.key_rounded, color: AppColors.teal),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Test accounts · password Ward1234',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          Wrap(
            children: [
              TextButton(
                onPressed: () => onUseDemo('admin@cityhospital.org'),
                child: const Text('Admin'),
              ),
              TextButton(
                onPressed: () => onUseDemo(AuthRepository.demoEmail),
                child: const Text('Doctor'),
              ),
              TextButton(
                onPressed: () => onUseDemo('patient@cityhospital.org'),
                child: const Text('Patient'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactBrand extends StatelessWidget {
  const _CompactBrand();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 220,
      child: Stack(
        fit: StackFit.expand,
        children: [
          HospitalScene(),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Row(
                children: [
                  HospitalLogo(size: 42),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rounds',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'City Hospital',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w500,
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
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        HospitalScene(),
        Padding(
          padding: EdgeInsets.all(36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  HospitalLogo(size: 40),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rounds',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'City Hospital',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
