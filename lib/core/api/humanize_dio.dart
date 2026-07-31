import 'package:dio/dio.dart';

/// Util compartilhado pra traduzir `DioException` em mensagem amigável.
///
/// Consolida o padrão `_humanize` que está duplicado em ~10 services
/// (Gym + SaaS Gym). Migração dos services antigos é incremental.
///
/// [recurso] aparece nas mensagens 403/fallback (ex.: "revendas",
/// "tenants", "métricas SaaS"). [overrides] permite customizar resposta
/// pra status codes específicos sem perder o restante da lógica.
String humanizeDio(
  DioException e, {
  required String recurso,
  Map<int, String> overrides = const {},
}) {
  final t = e.type;
  if (t == DioExceptionType.connectionTimeout ||
      t == DioExceptionType.connectionError ||
      t == DioExceptionType.receiveTimeout) {
    return 'Não foi possível conectar ao servidor.';
  }
  final status = e.response?.statusCode;
  if (status != null && overrides.containsKey(status)) {
    return overrides[status]!;
  }
  if (status == 401) return 'Sessão expirada. Saia e entre de novo.';
  if (status == 403) return 'Sem permissão pra acessar $recurso.';
  // Mensagem do backend tem prioridade quando vier formatada
  // (`{"error": "..."}` ou `{"message": "..."}`).
  final body = e.response?.data;
  if (body is Map) {
    final msg = body['error'] ?? body['message'];
    if (msg is String && msg.isNotEmpty) return msg;
  }
  if (status != null && status >= 500) {
    return 'Erro interno do servidor. Tente de novo em instantes.';
  }
  return 'Erro ao carregar (${status ?? 'sem resposta'}).';
}
