import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/humanize_dio.dart';
import '../models/humor_historico_item.dart';

class HumorServiceException implements Exception {
  HumorServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Humor do dia já registrado pelo colaborador logado — `motivo` é
/// opcional e sigiloso (só volta nessa rota do próprio colaborador,
/// nunca no resumo do gestor).
class MeuHumorHoje {
  const MeuHumorHoje({this.nota, this.motivo});

  final int? nota;
  final String? motivo;
}

/// Cliente HTTP do humor diário do colaborador (`/api/humor/*`).
class HumorService {
  HumorService(this._api);

  final ApiClient _api;

  Future<void> registrar(int nota, {String? motivo}) async {
    try {
      await _api.post('/api/humor/registrar', data: {
        'nota': nota,
        if (motivo != null && motivo.trim().isNotEmpty) 'motivo': motivo.trim(),
      });
    } on DioException catch (e) {
      throw HumorServiceException(humanizeDio(e, recurso: 'humor do dia'));
    }
  }

  /// Humor (e motivo, se contado) já registrado hoje pelo colaborador logado.
  Future<MeuHumorHoje> meuHumorHoje() async {
    try {
      final res = await _api.get<Map<String, dynamic>>('/api/humor/meu-humor-hoje');
      final data = res.data;
      final nota = data?['nota'];
      final motivo = data?['motivo'];
      return MeuHumorHoje(
        nota: nota is int ? nota : null,
        motivo: motivo is String && motivo.isNotEmpty ? motivo : null,
      );
    } on DioException catch (e) {
      throw HumorServiceException(humanizeDio(e, recurso: 'humor do dia'));
    }
  }

  /// Últimos registros do colaborador logado, mais recentes primeiro.
  Future<List<HumorHistoricoItem>> meuHistorico() async {
    try {
      final res = await _api.get<List<dynamic>>('/api/humor/meu-historico');
      final data = res.data ?? const [];
      return data
          .whereType<Map>()
          .map((m) => HumorHistoricoItem.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } on DioException catch (e) {
      throw HumorServiceException(humanizeDio(e, recurso: 'histórico de humor'));
    }
  }
}
