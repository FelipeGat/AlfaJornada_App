class Notificacao {
  const Notificacao({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensagem,
    required this.lida,
    required this.createdAt,
    this.referenciaTipo,
    this.referenciaId,
  });

  final int id;
  final String tipo;
  final String titulo;
  final String mensagem;
  final bool lida;
  final DateTime createdAt;
  final String? referenciaTipo;
  final int? referenciaId;

  factory Notificacao.fromJson(Map<String, dynamic> j) => Notificacao(
        id: (j['id'] as num).toInt(),
        tipo: j['tipo']?.toString() ?? '',
        titulo: j['titulo']?.toString() ?? '',
        mensagem: j['mensagem']?.toString() ?? '',
        lida: j['lida'] == true,
        createdAt: DateTime.parse(j['createdAt'].toString()).toLocal(),
        referenciaTipo: j['referenciaTipo']?.toString(),
        referenciaId: j['referenciaId'] is num
            ? (j['referenciaId'] as num).toInt()
            : null,
      );
}
