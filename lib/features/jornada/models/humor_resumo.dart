import '../../../core/utils/json_parsers.dart';

/// Humor de um colaborador que já respondeu no dia.
class HumorIndividual {
  const HumorIndividual({required this.funcionarioId, required this.funcionarioNome, required this.nota});
  final int funcionarioId;
  final String funcionarioNome;
  final int nota;

  factory HumorIndividual.fromJson(Map<String, dynamic> j) => HumorIndividual(
        funcionarioId: asInt(j['funcionarioId']) ?? 0,
        funcionarioNome: asString(j['funcionarioNome']) ?? 'Colaborador',
        nota: asInt(j['nota']) ?? 3,
      );
}

/// Resumo do clima da equipe hoje (`GET /api/humor/dashboard`). Espelha `HumorResumoDTO`.
class HumorResumo {
  const HumorResumo({
    required this.media,
    required this.responderam,
    required this.totalAtivos,
    required this.individual,
  });

  final double media;
  final int responderam;
  final int totalAtivos;
  final List<HumorIndividual> individual;

  factory HumorResumo.fromJson(Map<String, dynamic> j) {
    final individual = j['individual'];
    return HumorResumo(
      media: asDouble(j['media']) ?? 0,
      responderam: asInt(j['responderam']) ?? 0,
      totalAtivos: asInt(j['totalAtivos']) ?? 0,
      individual: individual is List
          ? individual.whereType<Map>().map((m) => HumorIndividual.fromJson(Map<String, dynamic>.from(m))).toList()
          : const [],
    );
  }
}
