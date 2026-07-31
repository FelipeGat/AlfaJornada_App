import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/humanize_dio.dart';
import '../models/equipe_hoje_item.dart';
import '../models/humor_resumo.dart';
import '../models/indicadores_resumo.dart';
import '../models/vinculo_candidatos.dart';

class JornadaGestorServiceException implements Exception {
  JornadaGestorServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Cliente HTTP das telas do gestor de RH no AlfaJornada (`/api/rh/*`, `/api/ponto/equipe-hoje`,
/// `/api/ponto/vinculo/*`, `/api/humor/dashboard`).
class JornadaGestorService {
  JornadaGestorService(this._api);

  final ApiClient _api;

  Future<IndicadoresResumo> resumoHoje() async {
    try {
      final res = await _api.get<Map<String, dynamic>>('/api/rh/indicadores');
      final data = res.data;
      if (data == null) throw JornadaGestorServiceException('Resposta vazia do servidor.');
      return IndicadoresResumo.fromJson(data);
    } on DioException catch (e) {
      throw JornadaGestorServiceException(humanizeDio(e, recurso: 'resumo do dia'));
    }
  }

  Future<HumorResumo> humorHoje() async {
    try {
      final res = await _api.get<Map<String, dynamic>>('/api/humor/dashboard');
      final data = res.data;
      if (data == null) throw JornadaGestorServiceException('Resposta vazia do servidor.');
      return HumorResumo.fromJson(data);
    } on DioException catch (e) {
      throw JornadaGestorServiceException(humanizeDio(e, recurso: 'clima da equipe'));
    }
  }

  Future<PaginaEquipeHoje> equipeHoje({int page = 0, int size = 20, String? search}) async {
    try {
      final res = await _api.get<Map<String, dynamic>>(
        '/api/ponto/equipe-hoje',
        query: {
          'page': page,
          'size': size,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      final data = res.data;
      if (data == null) throw JornadaGestorServiceException('Resposta vazia do servidor.');
      return PaginaEquipeHoje.fromJson(data);
    } on DioException catch (e) {
      throw JornadaGestorServiceException(humanizeDio(e, recurso: 'equipe do dia'));
    }
  }

  Future<VinculoCandidatos> candidatosVinculo() async {
    try {
      final res = await _api.get<Map<String, dynamic>>('/api/ponto/vinculo/candidatos');
      final data = res.data;
      if (data == null) throw JornadaGestorServiceException('Resposta vazia do servidor.');
      return VinculoCandidatos.fromJson(data);
    } on DioException catch (e) {
      throw JornadaGestorServiceException(humanizeDio(e, recurso: 'candidatos à vinculação'));
    }
  }

  Future<void> vincular({required int usuarioId, required int funcionarioId}) async {
    try {
      await _api.post('/api/ponto/vinculo', data: {
        'usuarioId': usuarioId,
        'funcionarioId': funcionarioId,
      });
    } on DioException catch (e) {
      throw JornadaGestorServiceException(humanizeDio(e, recurso: 'vinculação'));
    }
  }
}
