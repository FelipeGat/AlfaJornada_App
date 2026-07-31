/// Academia disponível pra seleção pós-login do admin_revenda Gym.
/// Backend retorna o registro completo, mas o mobile só precisa de id
/// e nome pra montar a tela de seleção (Fase B1).
class Academia {
  const Academia({
    required this.id,
    required this.nome,
  });

  final int id;
  final String nome;

  factory Academia.fromJson(Map<String, dynamic> j) {
    final id = j['id'];
    final idInt = id is int ? id : (id is num ? id.toInt() : null);
    if (idInt == null) {
      throw const FormatException('Academia: campo "id" ausente ou inválido');
    }
    final nome = j['nome'];
    return Academia(
      id: idInt,
      nome: nome is String && nome.isNotEmpty ? nome : 'Academia #$idInt',
    );
  }
}
