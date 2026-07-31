import '../../../core/utils/json_parsers.dart';

/// Um dia do histórico de humor do colaborador logado
/// (`GET /api/humor/meu-historico`) — sigiloso, só ele acessa.
class HumorHistoricoItem {
  const HumorHistoricoItem({required this.data, required this.nota, this.motivo});

  final DateTime data;
  final int nota;
  final String? motivo;

  factory HumorHistoricoItem.fromJson(Map<String, dynamic> j) {
    final data = asDate(j['data']);
    final nota = asInt(j['nota']);
    if (data == null || nota == null) {
      throw const FormatException('HumorHistoricoItem: campos obrigatórios ausentes');
    }
    return HumorHistoricoItem(data: data, nota: nota, motivo: asString(j['motivo']));
  }
}
