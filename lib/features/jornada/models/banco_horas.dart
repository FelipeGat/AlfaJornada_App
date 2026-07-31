import '../../../core/utils/json_parsers.dart';

/// Um movimento do extrato do banco de horas (`GET /api/banco-horas/meu`).
/// Espelha `MovimentoDTO` do backend.
class MovimentoBancoHoras {
  const MovimentoBancoHoras({
    required this.data,
    required this.tipo,
    required this.origem,
    required this.minutosFormatado,
    required this.saldoAcumuladoFormatado,
    this.descricao,
  });

  final DateTime data;

  /// CREDITO ou DEBITO.
  final String tipo;

  /// MANUAL (ajuste do RH), APURACAO (fechamento do período) ou COMPENSACAO.
  final String origem;

  /// Já formatado pelo backend, ex.: "+01:30" / "-00:45".
  final String minutosFormatado;
  final String saldoAcumuladoFormatado;
  final String? descricao;

  factory MovimentoBancoHoras.fromJson(Map<String, dynamic> j) {
    final data = asDate(j['data']);
    if (data == null) {
      throw const FormatException('MovimentoBancoHoras: data ausente');
    }
    return MovimentoBancoHoras(
      data: data,
      tipo: asString(j['tipo']) ?? 'CREDITO',
      origem: asString(j['origem']) ?? 'MANUAL',
      minutosFormatado: asString(j['minutosFormatado']) ?? '+00:00',
      saldoAcumuladoFormatado: asString(j['saldoAcumuladoFormatado']) ?? '+00:00',
      descricao: asString(j['descricao']),
    );
  }
}

/// Saldo + extrato do banco de horas do colaborador logado. Espelha
/// `BancoHorasDTO` do backend.
class BancoHorasResumo {
  const BancoHorasResumo({
    required this.saldoMinutos,
    required this.saldoFormatado,
    required this.extrato,
  });

  final int saldoMinutos;
  final String saldoFormatado;
  final List<MovimentoBancoHoras> extrato;

  factory BancoHorasResumo.fromJson(Map<String, dynamic> j) {
    final extrato = j['extrato'];
    return BancoHorasResumo(
      saldoMinutos: asInt(j['saldoMinutos']) ?? 0,
      saldoFormatado: asString(j['saldoFormatado']) ?? '+00:00',
      extrato: extrato is List
          ? extrato
              .whereType<Map>()
              .map((m) => MovimentoBancoHoras.fromJson(Map<String, dynamic>.from(m)))
              .toList()
          : const [],
    );
  }
}
