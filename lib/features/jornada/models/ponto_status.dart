import '../../../core/utils/json_parsers.dart';

/// Resumo do dia do colaborador (`GET /api/ponto/meu-status`). Espelha
/// `MeuStatusDTO` do backend do AlfaJornada.
class PontoStatus {
  const PontoStatus({
    required this.funcionarioId,
    required this.nome,
    required this.data,
    required this.proximoSentido,
    required this.batidasHoje,
    required this.marcacoesHoje,
    required this.minutosTrabalhadosHoje,
    required this.horasTrabalhadasHoje,
    required this.saldoBancoHorasMinutos,
    required this.saldoBancoHoras,
  });

  final int funcionarioId;
  final String nome;
  final DateTime data;

  /// "ENTRADA" ou "SAIDA" — rótulo do próximo botão de bater ponto.
  final String proximoSentido;
  final int batidasHoje;

  /// Horários já batidos hoje, formato "HH:mm".
  final List<String> marcacoesHoje;
  final int minutosTrabalhadosHoje;
  final String horasTrabalhadasHoje;
  final int saldoBancoHorasMinutos;
  final String saldoBancoHoras;

  bool get proximaEhEntrada => proximoSentido == 'ENTRADA';

  factory PontoStatus.fromJson(Map<String, dynamic> j) {
    final funcionarioId = asInt(j['funcionarioId']);
    if (funcionarioId == null) {
      throw const FormatException('PontoStatus: funcionarioId ausente');
    }
    return PontoStatus(
      funcionarioId: funcionarioId,
      nome: asString(j['nome']) ?? 'Colaborador',
      data: asDate(j['data']) ?? DateTime.now(),
      proximoSentido: asString(j['proximoSentido']) ?? 'ENTRADA',
      batidasHoje: asInt(j['batidasHoje']) ?? 0,
      marcacoesHoje: (j['marcacoesHoje'] is List)
          ? (j['marcacoesHoje'] as List).whereType<String>().toList()
          : const [],
      minutosTrabalhadosHoje: asInt(j['minutosTrabalhadosHoje']) ?? 0,
      horasTrabalhadasHoje: asString(j['horasTrabalhadasHoje']) ?? '00:00',
      saldoBancoHorasMinutos: asInt(j['saldoBancoHorasMinutos']) ?? 0,
      saldoBancoHoras: asString(j['saldoBancoHoras']) ?? '+00:00',
    );
  }
}
