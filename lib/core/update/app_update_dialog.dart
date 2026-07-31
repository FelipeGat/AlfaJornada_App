import 'package:flutter/material.dart';

import '../branding/app_branding.dart';
import 'app_update_service.dart';

/// Abre o dialog "Nova versão disponível". Retorna `true` se o installer
/// chegou a ser disparado (não garante que o usuário clicou "Instalar"
/// no dialog nativo do sistema).
Future<bool> mostrarUpdateDialog(
  BuildContext context,
  UpdateCheckResult result,
) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: !result.obrigatorio,
        builder: (_) => _UpdateDialog(result: result),
      ) ??
      false;
}

class _UpdateDialog extends StatefulWidget {
  final UpdateCheckResult result;
  const _UpdateDialog({required this.result});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  final _service = AppUpdateService();
  bool _baixando = false;
  double _progresso = 0;
  int _bytesRecebidos = 0;
  int _bytesTotal = 0;
  String? _erro;

  Future<void> _atualizar() async {
    setState(() {
      _baixando = true;
      _erro = null;
    });
    final res = await _service.baixarEInstalar(
      widget.result.manifest,
      onProgress: (recebidos, total) {
        if (!mounted) return;
        setState(() {
          _bytesRecebidos = recebidos;
          _bytesTotal = total;
          _progresso = total > 0 ? recebidos / total : 0;
        });
      },
    );
    if (!mounted) return;
    if (res.sucesso) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _baixando = false;
        _erro = res.erro ?? 'Falha desconhecida';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = AppBranding.of(context);
    final m = widget.result.manifest;
    final obrigatorio = widget.result.obrigatorio;
    return PopScope(
      canPop: !obrigatorio && !_baixando,
      child: AlertDialog(
        title: Row(children: [
          Icon(Icons.system_update_rounded, color: b.primary),
          const SizedBox(width: 8),
          const Expanded(child: Text('Nova versão disponível')),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _chip('v${widget.result.versaoInstalada}', b.textMuted),
              const Icon(Icons.arrow_forward_rounded, size: 14),
              _chip('v${m.versao}', b.primary, destaque: true),
              if (obrigatorio) ...[
                const SizedBox(width: 6),
                _chip('Obrigatória', b.danger, destaque: true),
              ],
            ]),
            if (m.changelog.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Novidades',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.4,
                      color: b.textMuted)),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Text(
                    m.changelog.trim(),
                    style: TextStyle(
                        fontSize: 13, height: 1.4, color: b.textDark),
                  ),
                ),
              ),
            ],
            if (_baixando) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: _progresso > 0 ? _progresso : null,
                  minHeight: 6,
                  backgroundColor: b.border,
                  valueColor: AlwaysStoppedAnimation(b.primary),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _bytesTotal > 0
                    ? '${(_bytesRecebidos ~/ 1024)} KB de ${(_bytesTotal ~/ 1024)} KB · ${(_progresso * 100).toStringAsFixed(0)}%'
                    : 'Baixando…',
                style: TextStyle(fontSize: 11, color: b.textMuted),
              ),
            ],
            if (_erro != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: b.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: b.danger.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _erro!,
                  style: TextStyle(color: b.danger, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!obrigatorio && !_baixando)
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Depois'),
            ),
          FilledButton.icon(
            onPressed: _baixando ? null : _atualizar,
            icon: _baixando
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download_rounded, size: 18),
            label: Text(_baixando ? 'Baixando…' : 'Atualizar agora'),
            style: FilledButton.styleFrom(
              backgroundColor: b.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String texto, Color cor, {bool destaque = false}) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: destaque ? cor : cor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: destaque ? Colors.white : cor,
          ),
        ),
      );
}
