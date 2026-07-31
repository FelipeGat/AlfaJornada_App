import '../../../core/utils/json_parsers.dart';

/// Resumo do dia da empresa (`GET /api/rh/indicadores`). Espelha `IndicadoresRhDTO` do backend.
class IndicadoresResumo {
  const IndicadoresResumo({
    required this.funcionariosAtivos,
    required this.registrosHoje,
    required this.jornadasInconsistentesHoje,
    required this.documentosVencendo,
    required this.episVencendo,
    required this.feriasVencendo,
  });

  final int funcionariosAtivos;
  final int registrosHoje;
  final int jornadasInconsistentesHoje;
  final int documentosVencendo;
  final int episVencendo;
  final int feriasVencendo;

  int get adesaoPercentual => funcionariosAtivos > 0
      ? ((registrosHoje / funcionariosAtivos) * 100).round()
      : 0;

  factory IndicadoresResumo.fromJson(Map<String, dynamic> j) => IndicadoresResumo(
        funcionariosAtivos: asInt(j['funcionariosAtivos']) ?? 0,
        registrosHoje: asInt(j['registrosHoje']) ?? 0,
        jornadasInconsistentesHoje: asInt(j['jornadasInconsistentesHoje']) ?? 0,
        documentosVencendo: asInt(j['documentosVencendo']) ?? 0,
        episVencendo: asInt(j['episVencendo']) ?? 0,
        feriasVencendo: asInt(j['feriasVencendo']) ?? 0,
      );
}
