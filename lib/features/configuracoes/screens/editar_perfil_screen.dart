import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/branding/app_branding.dart';
import '../../../core/utils/image_decode.dart';
import '../../auth/state/auth_provider.dart';

class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _hidratado = false;
  bool _salvando = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _avisoEmBreve(String recurso) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$recurso vai chegar num próximo update.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = AppBranding.of(context);
    final auth = context.watch<AuthProvider>();

    if (!_hidratado) {
      _nomeCtrl.text = auth.displayName ?? '';
      _hidratado = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar perfil'),
        actions: [
          if (_salvando || auth.loading)
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
            _FotoPicker(
              foto: auth.pessoaFoto,
              nome: _nomeCtrl.text.trim().isEmpty
                  ? (auth.displayName ?? '')
                  : _nomeCtrl.text.trim(),
              b: b,
              onTap: () => _avisoEmBreve('Trocar foto'),
            ),
            const SizedBox(height: 20),
            _CardSecao(
              titulo: 'Dados básicos',
              b: b,
              children: [
                TextFormField(
                  controller: _nomeCtrl,
                  decoration: const InputDecoration(labelText: 'Nome *'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe o nome'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'E-mail (opcional)',
                    helperText: 'Deixe em branco para manter o atual',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return null;
                    if (!t.contains('@')) return 'E-mail inválido';
                    return null;
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _salvar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final b = AppBranding.of(context);
    setState(() => _salvando = true);
    try {
      final sucesso = await auth.atualizarPerfil(
        nome: _nomeCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(sucesso
              ? 'Perfil atualizado.'
              : (auth.errorMessage ?? 'Não foi possível atualizar.')),
          backgroundColor: sucesso ? b.success : b.danger,
        ),
      );
      if (sucesso) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
            content: Text('Erro ao salvar: $e'), backgroundColor: b.danger),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }
}

class _FotoPicker extends StatelessWidget {
  const _FotoPicker({
    required this.foto,
    required this.nome,
    required this.b,
    required this.onTap,
  });
  final String? foto;
  final String nome;
  final AppBranding b;
  final VoidCallback onTap;

  String _iniciais() {
    final partes = nome.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes.first[0] + partes.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final f = foto;
    Widget avatar;
    if (f != null && f.isNotEmpty && f.startsWith('http')) {
      avatar = ClipOval(
        child: Image.network(
          f,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallback(),
        ),
      );
    } else if (f != null && f.isNotEmpty) {
      final bytes = decodeFotoBase64(f);
      avatar = bytes == null
          ? _fallback()
          : ClipOval(
              child: Image.memory(
                bytes,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback(),
              ),
            );
    } else {
      avatar = _fallback();
    }
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              avatar,
              Positioned(
                right: -2,
                bottom: -2,
                child: Material(
                  color: b.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onTap,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.photo_camera_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Toque no ícone para trocar a foto',
            style: TextStyle(color: b.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: b.primarySoft,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _iniciais(),
        style: TextStyle(
          color: b.primary,
          fontSize: 32,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CardSecao extends StatelessWidget {
  const _CardSecao({
    required this.titulo,
    required this.b,
    required this.children,
  });
  final String titulo;
  final AppBranding b;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: b.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: b.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              color: b.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
