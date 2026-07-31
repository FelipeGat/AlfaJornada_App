import '../../../core/utils/json_parsers.dart';

/// Resultado de uma marcação bem-sucedida (`POST /api/ponto/registrar`).
/// Espelha `PontoRegistroResponse` do backend.
class BatidaRegistrada {
  const BatidaRegistrada({
    required this.batidaId,
    required this.funcionarioId,
    required this.nome,
    required this.dataHora,
    required this.sentido,
    required this.mensagem,
  });

  final int batidaId;
  final int funcionarioId;
  final String nome;
  final DateTime dataHora;
  final String sentido;
  final String mensagem;

  factory BatidaRegistrada.fromJson(Map<String, dynamic> j) {
    final batidaId = asInt(j['batidaId']);
    final dataHora = asDate(j['dataHora']);
    if (batidaId == null || dataHora == null) {
      throw const FormatException('BatidaRegistrada: campos obrigatórios ausentes');
    }
    return BatidaRegistrada(
      batidaId: batidaId,
      funcionarioId: asInt(j['funcionarioId']) ?? 0,
      nome: asString(j['nome']) ?? 'Colaborador',
      dataHora: dataHora,
      sentido: asString(j['sentido']) ?? 'ENTRADA',
      mensagem: asString(j['mensagem']) ?? 'Marcação registrada.',
    );
  }
}

/// Item do histórico de batidas (`GET /api/ponto/minhas-batidas`). Espelha
/// `BatidaDTO` do backend — só os campos relevantes pro colaborador ver o
/// próprio histórico (ignora campos internos como `repId`/`nsr`/`jornadaId`).
class BatidaHistorico {
  const BatidaHistorico({
    required this.id,
    required this.dataHora,
    required this.origem,
    this.observacao,
  });

  final int id;
  final DateTime dataHora;

  /// MOBILE (app), MANUAL (lançado pelo RH), DISPOSITIVO, KIOSK.
  final String origem;
  final String? observacao;

  factory BatidaHistorico.fromJson(Map<String, dynamic> j) {
    final id = asInt(j['id']);
    final dataHora = asDate(j['dataHora']);
    if (id == null || dataHora == null) {
      throw const FormatException('BatidaHistorico: campos obrigatórios ausentes');
    }
    return BatidaHistorico(
      id: id,
      dataHora: dataHora,
      origem: asString(j['origem']) ?? 'MANUAL',
      observacao: asString(j['observacao']),
    );
  }
}

/// Página de batidas (`Page<BatidaDTO>` do Spring Data).
class PaginaBatidas {
  const PaginaBatidas({
    required this.content,
    required this.totalPages,
    required this.number,
    required this.last,
  });

  final List<BatidaHistorico> content;
  final int totalPages;
  final int number;
  final bool last;

  factory PaginaBatidas.fromJson(Map<String, dynamic> j) {
    final content = j['content'];
    return PaginaBatidas(
      content: content is List
          ? content
              .whereType<Map>()
              .map((m) => BatidaHistorico.fromJson(Map<String, dynamic>.from(m)))
              .toList()
          : const [],
      totalPages: asInt(j['totalPages']) ?? 1,
      number: asInt(j['number']) ?? 0,
      last: j['last'] == true,
    );
  }
}
