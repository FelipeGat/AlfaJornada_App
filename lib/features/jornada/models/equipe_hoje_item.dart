import '../../../core/utils/json_parsers.dart';

/// Um colaborador na lista "Equipe hoje" do gestor. Espelha `EquipeHojeItemDTO` do backend.
class EquipeHojeItem {
  const EquipeHojeItem({
    required this.funcionarioId,
    required this.nome,
    this.departamentoNome,
    required this.bateuPontoHoje,
    this.ultimaMarcacao,
  });

  final int funcionarioId;
  final String nome;
  final String? departamentoNome;
  final bool bateuPontoHoje;
  final String? ultimaMarcacao;

  factory EquipeHojeItem.fromJson(Map<String, dynamic> j) {
    final id = asInt(j['funcionarioId']);
    if (id == null) {
      throw const FormatException('EquipeHojeItem: funcionarioId ausente');
    }
    return EquipeHojeItem(
      funcionarioId: id,
      nome: asString(j['nome']) ?? 'Colaborador',
      departamentoNome: asString(j['departamentoNome']),
      bateuPontoHoje: j['bateuPontoHoje'] == true,
      ultimaMarcacao: asString(j['ultimaMarcacao']),
    );
  }
}

/// Página de `EquipeHojeItem` (`Page<EquipeHojeItemDTO>` do Spring Data).
class PaginaEquipeHoje {
  const PaginaEquipeHoje({
    required this.content,
    required this.number,
    required this.last,
  });

  final List<EquipeHojeItem> content;
  final int number;
  final bool last;

  factory PaginaEquipeHoje.fromJson(Map<String, dynamic> j) {
    final content = j['content'];
    return PaginaEquipeHoje(
      content: content is List
          ? content
              .whereType<Map>()
              .map((m) => EquipeHojeItem.fromJson(Map<String, dynamic>.from(m)))
              .toList()
          : const [],
      number: asInt(j['number']) ?? 0,
      last: j['last'] == true,
    );
  }
}
