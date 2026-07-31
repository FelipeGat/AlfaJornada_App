import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/branding/app_branding.dart';
import '../../auth/state/auth_provider.dart';

class AlterarSenhaScreen extends StatefulWidget {
  const AlterarSenhaScreen({super.key});

  @override
  State<AlterarSenhaScreen> createState() => _AlterarSenhaScreenState();
}

class _AlterarSenhaScreenState extends State<AlterarSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _novaCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _novaCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = AppBranding.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alterar senha'),
        actions: [
          if (auth.loading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _salvar,
              child: const Text('Salvar'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: b.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: b.border),
              ),
              child: Column(
                children: [
                  TextFormField(
                    controller: _novaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nova senha *',
                      helperText: 'Mínimo 6 caracteres',
                    ),
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.length < 6) {
                        return 'Mínimo 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Confirme a nova senha *',
                    ),
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Repita a nova senha';
                      }
                      if (v != _novaCtrl.text) {
                        return 'Senhas não conferem';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _salvar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthProvider>();
    final sucesso = await auth.atualizarPerfil(novaSenha: _novaCtrl.text);
    if (!mounted) return;
    final b = AppBranding.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sucesso
              ? 'Senha alterada.'
              : (auth.errorMessage ?? 'Não foi possível alterar.'),
        ),
        backgroundColor: sucesso ? b.success : b.danger,
      ),
    );
    if (sucesso) Navigator.of(context).pop(true);
  }
}
