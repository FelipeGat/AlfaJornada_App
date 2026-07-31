import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../features/jornada/state/jornada_gestor_provider.dart';
import '../../features/jornada/state/jornada_provider.dart';
import '../../features/notificacoes/state/notificacoes_provider.dart';
import 'clearable.dart';

/// Coleta os providers globais (montados no `MultiProvider` do `main.dart`)
/// que cacheiam dados escopados ao tenant atual e precisam ser zerados
/// quando o tenant muda — logout.
///
/// Nova feature que cacheie dados do tenant deve registrar seu provider
/// aqui.
List<Clearable> tenantProviders(BuildContext context) => [
      context.read<NotificacoesProvider>(),
      context.read<JornadaProvider>(),
      context.read<JornadaGestorProvider>(),
    ];
