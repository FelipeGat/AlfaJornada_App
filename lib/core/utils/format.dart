/// Util compartilhado de formatação BR — consolida ~6 cópias de
/// `_fmtMoney`/`_fmtDateBR` espalhadas em telas Gym e SaaS.
library;

/// `R$ 1.234,56` — formato monetário brasileiro com separador de milhar
/// e duas casas decimais. Aceita negativo.
String formatBRL(num value) {
  final v = value.toDouble();
  final neg = v < 0;
  final cents = (v.abs() * 100).round();
  final reais = cents ~/ 100;
  final centavos = cents % 100;
  final reaisStr = reais.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
  final centavosStr = centavos.toString().padLeft(2, '0');
  return '${neg ? '-' : ''}R\$ $reaisStr,$centavosStr';
}

/// `25/04/2026` — formato curto BR com ano completo.
String formatDataBr(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year}';
}

/// `25/04` — formato compacto sem ano (pra eixos de gráfico,
/// linhas de período, etc).
String formatDataBrCurta(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm';
}

/// "Hoje" / "Ontem" / "há N dias" / `25/04/2026` (além de 6 dias) —
/// usado onde a proximidade importa mais que a data exata (ex.: "último
/// treino: ontem").
String formatDataRelativa(DateTime d) {
  final hoje = DateTime.now();
  final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
  final dSemHora = DateTime(d.year, d.month, d.day);
  final diff = hojeSemHora.difference(dSemHora).inDays;
  if (diff == 0) return 'Hoje';
  if (diff == 1) return 'Ontem';
  if (diff > 1 && diff <= 6) return 'Há $diff dias';
  return formatDataBr(d);
}
