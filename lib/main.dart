import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'core/branding/app_branding.dart';
import 'core/log.dart';
import 'core/state/clearable.dart';
import 'core/state/tenant_state.dart';
import 'core/storage/auth_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/update/app_update_checker.dart';
import 'features/auth/screens/definir_senha_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/selecionar_unidade_screen.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/state/auth_provider.dart';
import 'features/jornada/services/humor_service.dart';
import 'features/jornada/services/jornada_gestor_service.dart';
import 'features/jornada/services/jornada_service.dart';
import 'features/jornada/state/jornada_gestor_provider.dart';
import 'features/jornada/state/jornada_provider.dart';
import 'features/notificacoes/services/push_service.dart';
import 'features/notificacoes/state/notificacoes_provider.dart';
import 'features/splash/splash_screen.dart';
import 'firebase_options.dart';
import 'shell/main_shell.dart';

/// Chave global do Navigator raiz. Serve pra empurrar telas a partir
/// de callbacks fora da árvore (ex.: interceptor 401 do ApiClient
/// derrubando a sessão).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inter vem embarcada em google_fonts/ — nunca buscar fonte na rede
  // (primeiro boot offline é caso real: bater ponto sem sinal).
  GoogleFonts.config.allowRuntimeFetching = false;

  // Locale fixo pt-BR: DatePicker/Material em português e DateFormat
  // com símbolos corretos.
  Intl.defaultLocale = 'pt_BR';
  await initializeDateFormatting('pt_BR');

  final firebaseOptions = DefaultFirebaseOptions.currentPlatform;
  if (firebaseOptions != null) {
    try {
      // Timeout defensivo — sem rede/DNS bloqueado, o Future do Firebase
      // pode nunca resolver nem lançar erro, travando o app inteiro numa
      // tela branca antes mesmo do primeiro frame (notificações push são
      // best-effort, não podem bloquear o boot do app).
      await Firebase.initializeApp(options: firebaseOptions)
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      logDebug('Firebase init falhou: $e');
    }
  }

  // Crashlytics: captura erros não tratados de Flutter e de plataforma.
  // Sem suporte web, e só quando o Firebase subiu; em debug os crashes
  // continuam indo pro console normalmente (coleta desligada).
  if (!kIsWeb && Firebase.apps.isNotEmpty) {
    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
    FlutterError.onError = crashlytics.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }

  final storage = AuthStorage();
  final api = ApiClient(storage);
  final authService = AuthService(api, storage);
  final pushService = PushService();
  final auth = AuthProvider(authService, storage, api, pushService)..bootstrap();
  api.onUnauthorized = () {
    // Qualquer status autenticado (mesmo intermediários) derruba sessão
    // em 401 — evita ficar preso com token inválido.
    if (auth.status == AuthStatus.signedIn ||
        auth.status == AuthStatus.escolhendoUnidade) {
      auth.logout();
    }
  };
  api.tenantContextResolver = () => auth.tenantContext;
  final notificacoes = NotificacoesProvider(api);
  pushService.attachNotificacoesProvider(notificacoes);
  final jornadaService = JornadaService(api);
  final humorService = HumorService(api);
  final jornada = JornadaProvider(jornadaService, humorService);
  final jornadaGestorService = JornadaGestorService(api);
  final jornadaGestor = JornadaGestorProvider(jornadaGestorService);
  final themeProvider = ThemeProvider()..load();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<NotificacoesProvider>.value(value: notificacoes),
        Provider<JornadaService>.value(value: jornadaService),
        Provider<HumorService>.value(value: humorService),
        ChangeNotifierProvider<JornadaProvider>.value(value: jornada),
        Provider<JornadaGestorService>.value(value: jornadaGestorService),
        ChangeNotifierProvider<JornadaGestorProvider>.value(value: jornadaGestor),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
      ],
      child: const AlfaJornadaApp(),
    ),
  );
}

class AlfaJornadaApp extends StatefulWidget {
  const AlfaJornadaApp({super.key});

  @override
  State<AlfaJornadaApp> createState() => _AlfaJornadaAppState();
}

class _AlfaJornadaAppState extends State<AlfaJornadaApp> {
  AuthStatus _lastStatus = AuthStatus.unknown;
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final isDark = switch (themeProvider.mode) {
      ThemeMode.light => false,
      ThemeMode.dark => true,
      ThemeMode.system => platformBrightness == Brightness.dark,
    };
    final lightBranding = AppBranding.forProduct(auth.product);
    final darkBranding = AppBranding.forProduct(auth.product, dark: true);

    if (auth.status != _lastStatus) {
      final previous = _lastStatus;
      _lastStatus = auth.status;
      final notif = context.read<NotificacoesProvider>();
      if (auth.status == AuthStatus.signedIn) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => notif.startPolling(),
        );
      } else if (previous == AuthStatus.signedIn) {
        // Só limpa em transição signedIn → signedOut. Bootstrap inicial
        // (unknown → signedOut) não precisa zerar — providers já estão
        // vazios. Postpone pra postFrameCallback pra não tocar listeners
        // durante o build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            clearAll(tenantProviders(context));
          } catch (e, st) {
            // postFrameCallback transforma exceção em FlutterError silencioso
            // — preferimos log explícito a engolir.
            logDebug('clearAll falhou no logout: $e\n$st');
          }
        });
        // Reexibe o splash entre logout e login — dá continuidade visual.
        if (mounted) setState(() => _showSplash = true);
      }
    }

    return MaterialApp(
      title: 'AlfaJornada',
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('pt', 'BR')],
      theme: AppTheme.fromBranding(lightBranding),
      darkTheme: AppTheme.darkFromBranding(darkBranding),
      themeMode: themeProvider.mode,
      // Clamp generoso de text scaling (0.85–1.30) — respeita "Tamanho do
      // Texto" e "Texto Maior" do iOS até níveis razoáveis sem permitir
      // os 1.5×–2× extremos da acessibilidade que estourariam tudo.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.30,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _showSplash
            ? SplashScreen(
                key: const ValueKey('splash'),
                onFinished: () {
                  if (mounted) setState(() => _showSplash = false);
                },
              )
            : KeyedSubtree(
                key: const ValueKey('app'),
                child: switch (auth.status) {
                  AuthStatus.unknown => Scaffold(
                      backgroundColor: isDark ? darkBranding.bg : lightBranding.bg,
                    ),
                  AuthStatus.signedOut => const LoginScreen(),
                  // Estado do fluxo multi-unidade (não usado pelo Jornada
                  // hoje) — mantido só pra AuthStatus continuar exaustivo.
                  AuthStatus.escolhendoAcademia => const LoginScreen(),
                  AuthStatus.escolhendoUnidade => const SelecionarUnidadeScreen(),
                  AuthStatus.signedIn => auth.senhaProvisoria
                      ? const DefinirSenhaScreen()
                      : const AppUpdateChecker(child: MainShell()),
                },
              ),
      ),
    );
  }
}
