/// Unidade (filial) de uma academia disponível pra seleção pós-login
/// (Fase B2). Backend pode retornar tanto o shape completo
/// (`UnidadesDto` com endereço, telefone, etc.) quanto o reduzido
/// (`UnidadeInfo` só id+nome) — model fica tolerante aos dois.
class Unidade {
  const Unidade({
    required this.id,
    required this.nome,
  });

  final int id;
  final String nome;

  factory Unidade.fromJson(Map<String, dynamic> j) {
    final id = j['id'];
    final idInt = id is int ? id : (id is num ? id.toInt() : null);
    if (idInt == null) {
      throw const FormatException('Unidade: campo "id" ausente ou inválido');
    }
    final nome = j['nome'];
    return Unidade(
      id: idInt,
      nome: nome is String && nome.isNotEmpty ? nome : 'Unidade #$idInt',
    );
  }

  static List<Unidade> parseList(Object? raw) {
    if (raw is! List) return const [];
    final out = <Unidade>[];
    for (final item in raw) {
      // Aceita `Map` genérico (Dio pode entregar `Map<dynamic, dynamic>`
      // em respostas aninhadas) e converte pra `Map<String, dynamic>`.
      if (item is Map) {
        try {
          out.add(Unidade.fromJson(Map<String, dynamic>.from(item)));
        } on FormatException {
          // Item sem id é descartado silenciosamente — não bloqueia
          // o restante da lista (backend pode evoluir o shape).
        }
      }
    }
    return out;
  }
}
