/// Parsers tolerantes pra payloads JSON dos services AlfaControl/AlfaGym.
/// Replicados em ~20+ models antes da extração (Fase D4.7).
///
/// Convenção:
/// * `null` ou tipo incompatível devolve `null` (não lança).
/// * `String` vazia devolve `null` em strings (consistente com pattern
///   antigo).
/// * Datas em UTC viram local automaticamente.
library;

int? asInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

double? asDouble(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

String? asString(Object? v) {
  if (v is String && v.isNotEmpty) return v;
  return null;
}

DateTime? asDate(Object? v) {
  if (v is! String || v.isEmpty) return null;
  final p = DateTime.tryParse(v);
  if (p == null) return null;
  return p.isUtc ? p.toLocal() : p;
}
