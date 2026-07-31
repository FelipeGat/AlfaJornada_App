import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/branding/app_branding.dart';
import '../state/auth_provider.dart';

class DefinirSenhaScreen extends StatefulWidget {
  const DefinirSenhaScreen({super.key});

  @override
  State<DefinirSenhaScreen> createState() => _DefinirSenhaScreenState();
}

class _DefinirSenhaScreenState extends State<DefinirSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _senhaCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _senhaCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final ok = await auth.trocarSenha(_senhaCtrl.text);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Erro ao definir a senha')),
      );
    }
  }

  Future<void> _sair() async {
    final auth = context.read<AuthProvider>();
    await auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    final b = AppBranding.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: b.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.lock_reset, size: 72, color: b.primary),
                    const SizedBox(height: 16),
                    const Text(
                      'Defina sua senha',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Para continuar, escolha uma nova senha pessoal.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: b.textMuted, height: 1.35),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _senhaCtrl,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: 'Nova senha',
                        hintText: 'Mínimo 6 caracteres',
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Informe a nova senha';
                        if (v.length < 6) return 'Mínimo de 6 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: _obscure,
                      decoration: const InputDecoration(
                        labelText: 'Repita a nova senha',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Confirme a senha';
                        if (v != _senhaCtrl.text) return 'As senhas não conferem';
                        return null;
                      },
                      onFieldSubmitted: (_) => _salvar(),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: auth.loading ? null : _salvar,
                      child: auth.loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Salvar e entrar'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: auth.loading ? null : _sair,
                      style: TextButton.styleFrom(foregroundColor: b.textMuted),
                      child: const Text('Sair'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
