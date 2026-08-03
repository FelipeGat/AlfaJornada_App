import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/humanize_dio.dart';

class KioskApiException implements Exception {
  KioskApiException(
    this.message, {
    this.isConnectionError = false,
    this.tokenInvalido = false,
  });

  final String message;
  final bool isConnectionError;

  /// 403 — token de terminal inválido/inativo. Quem chama derruba de volta
  /// pra tela de configuração em vez de mostrar um erro genérico.
  final bool tokenInvalido;

  @override
  String toString() => message;
}

class KioskEquipeItem {
  const KioskEquipeItem({
    required this.funcionarioId,
    required this.nome,
    required this.faceVersion,
  });

  final int funcionarioId;
  final String nome;
  final String faceVersion;

  factory KioskEquipeItem.fromJson(Map<String, dynamic> j) => KioskEquipeItem(
    funcionarioId: j['funcionarioId'] as int,
    nome: j['nome'] as String,
    faceVersion: j['faceVersion'] as String,
  );
}

class KioskIdentificacao {
  const KioskIdentificacao({
    required this.funcionarioId,
    required this.nome,
    required this.proximoSentido,
  });

  final int funcionarioId;
  final String nome;
  final String proximoSentido; // ENTRADA ou SAIDA

  factory KioskIdentificacao.fromJson(Map<String, dynamic> j) =>
      KioskIdentificacao(
        funcionarioId: j['funcionarioId'] as int,
        nome: j['nome'] as String,
        proximoSentido: j['proximoSentido'] as String,
      );
}

class KioskRegistro {
  const KioskRegistro({
    required this.batidaId,
    required this.funcionarioId,
    required this.nome,
    required this.sentido,
    required this.mensagem,
  });

  final int batidaId;
  final int funcionarioId;
  final String nome;
  final String sentido;
  final String mensagem;

  factory KioskRegistro.fromJson(Map<String, dynamic> j) => KioskRegistro(
    batidaId: j['batidaId'] as int,
    funcionarioId: j['funcionarioId'] as int,
    nome: j['nome'] as String,
    sentido: j['sentido'] as String,
    mensagem: j['mensagem'] as String,
  );
}

class KioskRecenteItem {
  const KioskRecenteItem({
    required this.funcionarioId,
    required this.nome,
    required this.sentido,
    required this.dataHora,
  });

  final int funcionarioId;
  final String nome;
  final String sentido; // ENTRADA ou SAIDA
  final DateTime dataHora;

  factory KioskRecenteItem.fromJson(Map<String, dynamic> j) => KioskRecenteItem(
    funcionarioId: j['funcionarioId'] as int,
    nome: j['nome'] as String,
    sentido: j['sentido'] as String,
    dataHora: DateTime.parse(j['dataHora'] as String).toLocal(),
  );
}

/// Cliente HTTP do Modo Totem (`/api/kiosk/*`). Rota pública — o token do
/// terminal viaja no corpo/query da requisição, nunca no header
/// `Authorization` (reaproveita a mesma instância de [ApiClient], que só
/// anexa JWT se houver sessão de usuário — sem conflito aqui).
class KioskApi {
  KioskApi(this._api);

  final ApiClient _api;

  /// Headers com o token do terminal — preferido sobre a query string
  /// (que vaza em access log de proxy). A query segue sendo enviada por
  /// retrocompatibilidade até o backend com suporte ao header estar
  /// deployado em produção; depois disso, remover o param.
  Options _tokenHeader(String token) =>
      Options(headers: {'X-Kiosk-Token': token});

  Future<List<KioskEquipeItem>> equipe(String token) async {
    try {
      final res = await _api.raw.get<List<dynamic>>(
        '/api/kiosk/equipe',
        queryParameters: {'token': token},
        options: _tokenHeader(token),
      );
      final data = res.data ?? const [];
      return data
          .map((e) => KioskEquipeItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e, recurso: 'equipe do totem');
    } on TypeError {
      throw KioskApiException("Resposta inválida do servidor.");
    }
  }

  Future<Uint8List> foto(String token, int funcionarioId) async {
    try {
      final res = await _api.raw.get<List<int>>(
        '/api/kiosk/foto/$funcionarioId',
        queryParameters: {'token': token},
        options: _tokenHeader(token).copyWith(responseType: ResponseType.bytes),
      );
      final data = res.data;
      if (data == null) throw KioskApiException('Foto vazia.');
      return Uint8List.fromList(data);
    } on DioException catch (e) {
      throw _mapError(e, recurso: 'foto de referência');
    } on TypeError {
      throw KioskApiException("Resposta inválida do servidor.");
    }
  }

  /// Confirma a identificação (PIN/PIS/QRCODE/FACE) sem gravar batida —
  /// tela de "é você?" antes do toque final de confirmar.
  Future<KioskIdentificacao> identificar(
    String token,
    String tipo,
    String valor,
  ) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/api/kiosk/identificar',
        data: {'token': token, 'tipo': tipo, 'valor': valor},
      );
      final data = res.data;
      if (data == null) throw KioskApiException('Resposta vazia do servidor.');
      return KioskIdentificacao.fromJson(data);
    } on DioException catch (e) {
      throw _mapError(e, recurso: 'identificação');
    } on TypeError {
      throw KioskApiException("Resposta inválida do servidor.");
    }
  }

  /// Registra a batida por PIN/PIS/QRCODE (fallback quando o rosto não é
  /// reconhecido).
  Future<KioskRegistro> registrar(
    String token,
    String tipo,
    String valor,
  ) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/api/kiosk/registrar',
        data: {'token': token, 'tipo': tipo, 'valor': valor},
      );
      final data = res.data;
      if (data == null) throw KioskApiException('Resposta vazia do servidor.');
      return KioskRegistro.fromJson(data);
    } on DioException catch (e) {
      throw _mapError(e, recurso: 'marcação de ponto');
    } on TypeError {
      throw KioskApiException("Resposta inválida do servidor.");
    }
  }

  /// Registra a batida por reconhecimento facial — exige a foto capturada
  /// no instante da confirmação como evidência.
  Future<KioskRegistro> registrarPorFace(
    String token,
    int funcionarioId,
    String fotoEvidenciaDataUri,
  ) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/api/kiosk/face/registrar',
        data: {
          'token': token,
          'funcionarioId': funcionarioId,
          'fotoEvidenciaBase64': fotoEvidenciaDataUri,
        },
      );
      final data = res.data;
      if (data == null) throw KioskApiException('Resposta vazia do servidor.');
      return KioskRegistro.fromJson(data);
    } on DioException catch (e) {
      throw _mapError(e, recurso: 'marcação por reconhecimento facial');
    } on TypeError {
      throw KioskApiException("Resposta inválida do servidor.");
    }
  }

  /// Feed "Últimos registros" da tela de espera — silencioso na falha (quem
  /// chama trata como lista vazia, não bloqueia a tela por causa disso).
  Future<List<KioskRecenteItem>> recentes(String token) async {
    try {
      final res = await _api.raw.get<List<dynamic>>(
        '/api/kiosk/recentes',
        queryParameters: {'token': token},
        options: _tokenHeader(token),
      );
      final data = res.data ?? const [];
      return data
          .map((e) => KioskRecenteItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e, recurso: 'últimos registros');
    } on TypeError {
      throw KioskApiException("Resposta inválida do servidor.");
    }
  }

  KioskApiException _mapError(DioException e, {required String recurso}) {
    final isConnectionError =
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.receiveTimeout;
    final status = e.response?.statusCode;
    final body = e.response?.data;
    final detalhes = body is Map ? body['details'] : null;
    final mensagem = (detalhes is String && detalhes.isNotEmpty)
        ? detalhes
        : humanizeDio(e, recurso: recurso);
    return KioskApiException(
      mensagem,
      isConnectionError: isConnectionError,
      tokenInvalido: status == 403,
    );
  }
}
