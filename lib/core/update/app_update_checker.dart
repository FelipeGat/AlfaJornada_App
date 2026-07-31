import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/state/auth_provider.dart';
import 'app_update_dialog.dart';
import 'app_update_service.dart';

/// Wrapper que checa atualizações uma vez após o primeiro frame do
/// widget filho. Deixa-se envolvido no shell principal (após login) —
/// não muda layout nem se propaga pra dependents.
///
/// Não checa em cada rebuild: `_checked` garante 1 execução por
/// instância. Se quiser recheque manual, usar `AppUpdateService.checar`
/// direto (ex: botão em Menu › Sobre).
class AppUpdateChecker extends StatefulWidget {
  final Widget child;
  const AppUpdateChecker({super.key, required this.child});

  @override
  State<AppUpdateChecker> createState() => _AppUpdateCheckerState();
}

class _AppUpdateCheckerState extends State<AppUpdateChecker> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checar());
  }

  Future<void> _checar() async {
    if (_checked) return;
    _checked = true;
    final produto = context.read<AuthProvider>().product;
    final result = await AppUpdateService().checar(produto: produto);
    if (result == null || !mounted) return;
    await mostrarUpdateDialog(context, result);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
