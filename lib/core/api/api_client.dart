import 'package:dio/dio.dart';

import '../log.dart';
import '../storage/auth_storage.dart';
import 'tenant_context.dart';

/// App single-product — o enum sobrevive só pra manter a assinatura dos
/// métodos abaixo estável (evita mexer em `AuthProvider`/`AuthStorage`/
/// `TenantContext`, que threadeiam `AlfaProduct` por várias camadas).
enum AlfaProduct { jornada }

extension AlfaProductX on AlfaProduct {
  String get label => 'AlfaJornada';

  String get storageKey => 'jornada';

  static AlfaProduct fromStorageKey(String key) => AlfaProduct.jornada;
}

class ApiEnvironment {
  /// Base da API. Produção é o default seguro; pra apontar pro backend
  /// local, use `--dart-define=API_BASE_URL=http://localhost:8085` no
  /// `flutter run` — nada de editar (e arriscar commitar) este arquivo.
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://jornada.alfasolucoes.cloud',
  );

  static String baseUrlFor(AlfaProduct product) => _baseUrl;

  static String loginPath(AlfaProduct product) => '/api/auth/login';
}

class ApiClient {
  ApiClient(this._storage) {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final product = await _storage.readProduct();
        // Fallback pra Academia quando nenhum produto foi selecionado
        // ainda (cadastro público /api/app/* do AlfaMobi acontece antes
        // do usuário escolher produto). Sem esse fallback o Dio saía
        // com baseUrl vazio e o mobile mostrava "sem resposta".
        options.baseUrl = ApiEnvironment.baseUrlFor(product ?? AlfaProduct.jornada);
        final token = await _storage.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        _auditTenant(response);
        handler.next(response);
      },
      onError: (e, handler) {
        final status = e.response?.statusCode;
        final sentAuth =
            e.requestOptions.headers.containsKey('Authorization');
        if (status == 401 && sentAuth) {
          final cb = _onUnauthorized;
          if (cb != null) cb();
        }
        // M2.b — 402 Payment Required = trial vencido no gate do
        // AlfaGym. Notifica pra o app abrir a tela de assinatura.
        if (status == 402) {
          final cb = _onPaymentRequired;
          if (cb != null) cb();
        }
        handler.next(e);
      },
    ));
  }

  late final Dio _dio;
  final AuthStorage _storage;
  void Function()? _onUnauthorized;
  void Function()? _onPaymentRequired;
  TenantContext Function()? _tenantContextResolver;

  /// Throttle de logs de mismatch — endpoint que polla a cada 5s pode
  /// inundar logcat se filtro server-side estiver bugado. Suprime
  /// repetição da mesma divergência por 30s na mesma rota.
  final Map<String, DateTime> _lastMismatchLog = {};

  set onUnauthorized(void Function() callback) {
    _onUnauthorized = callback;
  }

  set onPaymentRequired(void Function() callback) {
    _onPaymentRequired = callback;
  }

  /// Injeta um resolver de [TenantContext] usado pelo interceptor de
  /// response pra auditar IDs cross-tenant (Fase F3). Não chamado
  /// "Provider" pra evitar colisão com `package:provider` da camada
  /// de estado. Null = sem auditoria (default em testes).
  set tenantContextResolver(TenantContext Function() resolver) {
    _tenantContextResolver = resolver;
  }

  void _auditTenant(Response<dynamic> response) {
    try {
      final resolver = _tenantContextResolver;
      if (resolver == null) return;
      final context = resolver();
      if (context.isEmpty) return;
      final mismatches = auditTenantMismatch(response.data, context);
      if (mismatches.isEmpty) return;
      final path = response.requestOptions.path;
      final fingerprint =
          '$path|${mismatches.map((m) => m.field).join(',')}';
      final now = DateTime.now();
      final last = _lastMismatchLog[fingerprint];
      if (last != null && now.difference(last) < const Duration(seconds: 30)) {
        return;
      }
      _lastMismatchLog[fingerprint] = now;
      logDebug(
        'TenantMismatch em $path: ${mismatches.map((m) => m.toString()).join(', ')}',
      );
    } catch (e, st) {
      // Audit nunca deve quebrar a cadeia de interceptors do Dio.
      logDebug('TenantMismatch audit falhou: $e\n$st');
    }
  }

  Dio get raw => _dio;

  Future<Response<T>> post<T>(String path, {Object? data}) =>
      _dio.post<T>(path, data: data);

  Future<Response<T>> put<T>(String path, {Object? data}) =>
      _dio.put<T>(path, data: data);

  Future<Response<T>> patch<T>(String path, {Object? data}) =>
      _dio.patch<T>(path, data: data);

  Future<Response<T>> delete<T>(String path, {Object? data}) =>
      _dio.delete<T>(path, data: data);

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) =>
      _dio.get<T>(path, queryParameters: query);
}
