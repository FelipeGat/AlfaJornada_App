import 'package:flutter/material.dart';

/// Diálogo padrão pra funcionalidades ainda não implementadas (sem dado ou
/// integração real ainda) — usado nos placeholders de métricas e ações do
/// redesign "Premium", pra não inventar dado nem simular funcionalidade que
/// não existe de fato.
Future<void> showComingSoon(BuildContext context, {required String feature}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(feature),
      content: const Text('Essa função chega em breve por aqui.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Entendi'),
        ),
      ],
    ),
  );
}
