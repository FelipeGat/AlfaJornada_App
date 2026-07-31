import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/humanize_dio.dart';
import '../models/banco_horas.dart';
import '../models/batida_ponto.dart';
import '../models/ponto_status.dart';

class JornadaServiceException implements Exception {
  JornadaServiceException(
    this.message, {
    this.isConnectionError = false,
    this.naoVinculado = false,
  });

  final String message;

  /// Falha de rede (sem sinal/timeout) — quem chama pode decidir
  /// enfileirar a marcação em vez de mostrar erro (Parte 4, fila offline).
  final bool isConnectionError;

  /// 422 "usuário não vinculado a um colaborador" — a tela mostra uma
  /// mensagem própria orientando a falar com o RH, não erro genérico.
  final bool naoVinculado;

  @override
  String toString() => message;
}

/// Cliente HTTP do backend AlfaJornada (/api/ponto/*). Reaproveita o
/// `ApiClient` global — o interceptor já roteia pro baseUrl certo
/// (jornada.alfasolucoes.cloud) a partir do `AlfaProduct` salvo no
/// storage no momento do login.
class JornadaService {
  JornadaService(this._api);

  final ApiClient _api;

  Future<PontoStatus> buscarMeuStatus() async {
    try {
      final res = await _api.get<Map<String, dynamic>>('/api/ponto/meu-status');
      final data = res.data;
      if (data == null) {
        throw JornadaServiceException('Resposta vazia do servidor.');
      }
      return PontoStatus.fromJson(data);
    } on FormatException {
      throw JornadaServiceException('Resposta inválida do servidor.');
    } on DioException catch (e) {
      throw _mapDioError(e, recurso: 'status do ponto');
    }
  }

  /// Registra a batida. [dataHora] só deve ser enviada quando a marcação
  /// foi capturada offline e está sendo sincronizada depois — em uso
  /// normal (online), omitir e deixar o servidor carimbar `now()`.
  Future<BatidaRegistrada> registrarPonto({
    double? latitude,
    double? longitude,
    DateTime? dataHora,
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/api/ponto/registrar',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'dataHora': dataHora?.toIso8601String(),
        },
      );
      final data = res.data;
      if (data == null) {
        throw JornadaServiceException('Resposta vazia do servidor.');
      }
      return BatidaRegistrada.fromJson(data);
    } on FormatException {
      throw JornadaServiceException('Resposta inválida do servidor.');
    } on DioException catch (e) {
      throw _mapDioError(e, recurso: 'marcação de ponto');
    }
  }

  Future<PaginaBatidas> buscarHistorico({int page = 0, int size = 20}) async {
    try {
      final res = await _api.get<Map<String, dynamic>>(
        '/api/ponto/minhas-batidas',
        query: {'page': page, 'size': size},
      );
      final data = res.data;
      if (data == null) {
        throw JornadaServiceException('Resposta vazia do servidor.');
      }
      return PaginaBatidas.fromJson(data);
    } on FormatException {
      throw JornadaServiceException('Resposta inválida do servidor.');
    } on DioException catch (e) {
      throw _mapDioError(e, recurso: 'histórico de ponto');
    }
  }

  Future<BancoHorasResumo> buscarBancoHoras() async {
    try {
      final res = await _api.get<Map<String, dynamic>>('/api/banco-horas/meu');
      final data = res.data;
      if (data == null) {
        throw JornadaServiceException('Resposta vazia do servidor.');
      }
      return BancoHorasResumo.fromJson(data);
    } on FormatException {
      throw JornadaServiceException('Resposta inválida do servidor.');
    } on DioException catch (e) {
      throw _mapDioError(e, recurso: 'banco de horas');
    }
  }

  JornadaServiceException _mapDioError(DioException e, {required String recurso}) {
    final isConnectionError = e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.receiveTimeout;
    final body = e.response?.data;
    final backendMsg = body is Map ? (body['details'] ?? body['error']) : null;
    final naoVinculado = e.response?.statusCode == 422 &&
        backendMsg is String &&
        backendMsg.contains('vinculado');
    return JornadaServiceException(
      humanizeDio(e, recurso: recurso),
      isConnectionError: isConnectionError,
      naoVinculado: naoVinculado,
    );
  }
}
