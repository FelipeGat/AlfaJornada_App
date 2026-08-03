import 'package:flutter/material.dart';

import '../../../core/branding/app_branding.dart';
import '../../../core/storage/kiosk_storage.dart';
import '../../../core/theme/design_tokens.dart';
import '../data/kiosk_api.dart';
import '../data/kiosk_face_store.dart';
import '../data/kiosk_sync_service.dart';
import 'kiosk_home_screen.dart';

/// Configuração inicial do tablet como terminal de Modo Totem — cola o
/// token do terminal (gerado hoje direto no banco pelo time Alfa; ainda
/// não existe tela de admin pra isso), valida contra o backend e faz a
/// primeira sincronização de rostos antes de abrir a tela do totem.
class KioskSetupScreen extends StatefulWidget {
  const KioskSetupScreen({super.key, required this.api, required this.storage});

  final KioskApi api;
  final KioskStorage storage;

  @override
  State<KioskSetupScreen> createState() => _KioskSetupScreenState();
}

class _KioskSetupScreenState extends State<KioskSetupScreen> {
  // O token salvo NUNCA é reexibido aqui — a tela de setup é alcançável
  // da recepção, e preencher o campo com o token em claro entregaria a
  // credencial do terminal (roster + fotos de todo o cliente) pra
  // qualquer pessoa. Reconfigurar exige colar o token de novo.
  final _tokenController = TextEditingController();
  final _pinController = TextEditingController();
  bool _validando = false;
  String? _erro;

  @override
  void dispose() {
    _tokenController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _validarEContinuar() async {
    final token = _tokenController.text.trim();
    final pin = _pinController.text.trim();
    if (token.isEmpty) {
      setState(() => _erro = 'Cole o token do terminal.');
      return;
    }
    if (pin.length < 4 || pin.length > 6 || int.tryParse(pin) == null) {
      setState(
        () =>
            _erro = 'Defina um PIN de administrador numérico de 4 a 6 dígitos.',
      );
      return;
    }
    setState(() {
      _validando = true;
      _erro = null;
    });
    try {
      final faceStore = KioskFaceStore();
      final syncService = KioskSyncService(widget.api, faceStore);
      final resultado = await syncService.sincronizar(token);
      await widget.storage.saveToken(token);
      await widget.storage.saveAdminPin(pin);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Terminal configurado — ${resultado.totalEquipe} funcionário(s) sincronizado(s).',
          ),
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => KioskHomeScreen(
            api: widget.api,
            storage: widget.storage,
            faceStore: faceStore,
          ),
        ),
      );
    } on KioskApiException catch (e) {
      setState(() => _erro = e.message);
    } catch (e) {
      setState(() => _erro = 'Não foi possível validar o terminal: $e');
    } finally {
      if (mounted) setState(() => _validando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = AppBranding.of(context);
    return Scaffold(
      backgroundColor: b.bg,
      appBar: AppBar(
        title: const Text('Configurar Modo Totem'),
        backgroundColor: b.card,
        foregroundColor: b.textDark,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.tablet_mac_outlined, size: 56, color: b.primary),
                const SizedBox(height: 16),
                Text(
                  'Este tablet vira um terminal fixo de marcação de ponto — sem login individual, com token próprio do aparelho.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: b.textMuted,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _tokenController,
                  decoration: InputDecoration(
                    labelText: 'Token do terminal',
                    helperText:
                        'Por segurança, o token não é reexibido — pra reconfigurar, cole-o de novo.',
                    helperMaxLines: 2,
                    filled: true,
                    fillColor: b.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.input),
                    ),
                  ),
                  autocorrect: false,
                  enabled: !_validando,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'PIN de administrador (4–6 dígitos)',
                    helperText: 'Exigido pra sair do Modo Totem neste tablet.',
                    counterText: '',
                    filled: true,
                    fillColor: b.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.input),
                    ),
                  ),
                  enabled: !_validando,
                ),
                if (_erro != null) ...[
                  const SizedBox(height: 12),
                  Text(_erro!, style: TextStyle(color: b.danger, fontSize: 13)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _validando ? null : _validarEContinuar,
                  style: FilledButton.styleFrom(
                    backgroundColor: b.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  child: _validando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Validar e sincronizar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
