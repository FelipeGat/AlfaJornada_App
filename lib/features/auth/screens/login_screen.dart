import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/branding/app_branding.dart';
import '../../jornada/branding/alfa_jornada_mark.dart';
import '../state/auth_provider.dart';

const _kJornadaBlue = Color(0xFF2563EB);

/// Saudação por horário.
String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Bom dia';
  if (h < 18) return 'Boa tarde';
  return 'Boa noite';
}

// ─── Blob decoration helper ───────────────────────────────────────────────────
Widget _blob({
  double? top,
  double? bottom,
  double? left,
  double? right,
  required double size,
  required Color color,
}) {
  return Positioned(
    top: top,
    bottom: bottom,
    left: left,
    right: right,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size / 2),
      ),
    ),
  );
}

// ─── Root screen ──────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  bool _obscure = true;
  bool _remember = false;

  String? _companyName;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(_onFocusChange);
    _passFocus.addListener(_onFocusChange);
    _loadCompanyName();
  }

  Future<void> _loadCompanyName() async {
    final name =
        await context.read<AuthProvider>().companyNameFor(AlfaProduct.jornada);
    if (!mounted) return;
    setState(() => _companyName = name);
  }

  void _onFocusChange() => setState(() {});

  @override
  void dispose() {
    _emailFocus.dispose();
    _passFocus.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
      product: AlfaProduct.jornada,
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (!mounted) return;
    if (!ok && auth.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.errorMessage!)));
    }
  }

  Future<void> _showForgotDialog() async {
    final branding = AppBranding.of(context);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recuperação de senha'),
        content: const Text(
          'Para redefinir sua senha, procure o responsável da sua organização. '
          'Assim que ele cadastrar uma nova senha, você poderá entrar no app '
          'e escolher uma senha definitiva.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(foregroundColor: branding.primary),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final branding = AppBranding.of(context);

    return Theme(
      data: Theme.of(context).copyWith(extensions: [branding]),
      child: Scaffold(
        backgroundColor: branding.bg,
        resizeToAvoidBottomInset: true,
        body: _buildLoginBody(auth, branding),
      ),
    );
  }

  Widget _buildLoginBody(AuthProvider auth, AppBranding branding) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _blob(
          top: -70,
          right: -70,
          size: 220,
          color: branding.primary.withValues(alpha: 0.08),
        ),
        _blob(
          bottom: -80,
          left: -60,
          size: 240,
          color: branding.primary.withValues(alpha: 0.06),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _companyName != null
                                  ? '${_greeting()}, $_companyName'
                                  : _greeting(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: branding.textMuted,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            AlfaJornadaAnimatedLogo(
                              size: 38,
                              brandColor: _kJornadaBlue,
                              centered: true,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Acesse sua conta',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: branding.textDark,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Gestão e controle do seu Departamento Pessoal.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: branding.textMuted,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 28),
                            // E-mail
                            _FocusGlow(
                              focused: _emailFocus.hasFocus,
                              branding: branding,
                              child: TextFormField(
                                controller: _emailCtrl,
                                focusNode: _emailFocus,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                decoration: const InputDecoration(
                                  labelText: 'E-mail',
                                  hintText: 'seu@email.com',
                                  prefixIcon: Icon(
                                    Icons.alternate_email_rounded,
                                    size: 20,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Informe o e-mail';
                                  }
                                  if (!v.contains('@')) {
                                    return 'E-mail inválido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Senha
                            _FocusGlow(
                              focused: _passFocus.hasFocus,
                              branding: branding,
                              child: TextFormField(
                                controller: _passCtrl,
                                focusNode: _passFocus,
                                obscureText: _obscure,
                                autofillHints: const [AutofillHints.password],
                                decoration: InputDecoration(
                                  labelText: 'Senha',
                                  hintText: '••••••••',
                                  prefixIcon: const Icon(
                                    Icons.lock_rounded,
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Informe a senha'
                                    : null,
                                onFieldSubmitted: (_) => _submit(),
                              ),
                            ),
                            const SizedBox(height: 14),
                            // Remember + Forgot row
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final rememberOption = GestureDetector(
                                  onTap: () =>
                                      setState(() => _remember = !_remember),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 180),
                                        curve: Curves.easeOut,
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: _remember
                                              ? branding.primary
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: _remember
                                                ? branding.primary
                                                : branding.textMuted,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: AnimatedScale(
                                          duration:
                                              const Duration(milliseconds: 140),
                                          scale: _remember ? 1 : 0,
                                          child: const Icon(
                                            Icons.check_rounded,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Lembrar meus dados',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: branding.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                final forgotButton = TextButton(
                                  onPressed: _showForgotDialog,
                                  style: TextButton.styleFrom(
                                    foregroundColor: branding.primary,
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Esqueci minha senha',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                );

                                if (constraints.maxWidth < 360) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      rememberOption,
                                      const SizedBox(height: 10),
                                      forgotButton,
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    rememberOption,
                                    const Spacer(),
                                    forgotButton,
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            // Login button
                            ElevatedButton(
                              onPressed: auth.loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: branding.primary,
                                foregroundColor: Colors.white,
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ).copyWith(
                                elevation: WidgetStateProperty.resolveWith(
                                  (states) => states.contains(WidgetState.hovered)
                                      ? 6
                                      : 0,
                                ),
                                overlayColor: WidgetStateProperty.resolveWith(
                                  (states) => states.contains(WidgetState.pressed)
                                      ? Colors.black.withValues(alpha: 0.12)
                                      : states.contains(WidgetState.hovered)
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : null,
                                ),
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                child: auth.loading
                                    ? const SizedBox(
                                        key: ValueKey('loading'),
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Entrar no sistema',
                                        key: ValueKey('label')),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                children: [
                                  Text(
                                    'Ainda não tem conta? ',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: branding.textMuted,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _showForgotDialog,
                                    child: Text(
                                      'Fale com o administrador.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: branding.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Glow sutil ao redor do campo focado — o `focusedBorder` do tema já muda
/// a cor da borda; isso soma uma sombra leve na cor de marca, dando "foco
/// visual" mais perceptível sem depender só da borda.
class _FocusGlow extends StatelessWidget {
  const _FocusGlow({
    required this.focused,
    required this.branding,
    required this.child,
  });

  final bool focused;
  final AppBranding branding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: branding.primary.withValues(alpha: 0.18),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ]
            : const [],
      ),
      child: child,
    );
  }
}
