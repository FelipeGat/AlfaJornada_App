/// Marcação capturada offline, aguardando sincronizar — local apenas
/// (nunca vem do backend). Serializável pra autosave (`shared_preferences`),
/// mesmo padrão do `WorkoutSessionDraft` do AlfaGym.
class PontoPendente {
  PontoPendente({
    required this.id,
    required this.capturedAt,
    this.latitude,
    this.longitude,
    this.erro,
  });

  /// Id local (timestamp em microssegundos) — só pra identificar o item
  /// na fila, não tem relação com o `batidaId` do backend.
  final String id;

  /// Instante real em que o colaborador tocou o botão — é isso que vai
  /// como `dataHora` na sincronização, não o momento do envio.
  final DateTime capturedAt;
  final double? latitude;
  final double? longitude;

  /// Preenchido quando o servidor rejeitou a sincronização por regra de
  /// negócio (ex.: janela de tolerância vencida, período fechado) — o
  /// item continua na fila até o colaborador decidir tentar de novo ou
  /// descartar.
  String? erro;

  Map<String, dynamic> toJson() => {
        'id': id,
        'capturedAt': capturedAt.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'erro': erro,
      };

  factory PontoPendente.fromJson(Map<String, dynamic> j) {
    return PontoPendente(
      id: j['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      capturedAt: DateTime.tryParse(j['capturedAt'] as String? ?? '') ?? DateTime.now(),
      latitude: (j['latitude'] as num?)?.toDouble(),
      longitude: (j['longitude'] as num?)?.toDouble(),
      erro: j['erro'] as String?,
    );
  }
}
