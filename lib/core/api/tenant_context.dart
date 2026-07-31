/// Tamanho máximo de itens da lista que [auditTenantMismatch] examina —
/// auditoria não pode dominar custo de cada response em endpoints de
/// listagem grandes (paginação). Amostra detecta bug de filtro mesmo
/// que não cubra 100% dos itens.
const int _kAuditSampleSize = 5;

/// Contexto do tenant atual usado pra auditar respostas do backend
/// (Fase F3 da integração AlfaGym). Cada campo é o ID conhecido na
/// sessão; null significa "ainda não carregado/aplicável" e não dispara
/// auditoria pra esse campo.
///
/// Pra AlfaControl: `revendaId` + `clienteId`.
/// Pra AlfaGym: `revendaId` + `academiaId` (+ `unidadeId` quando B2 chegar).
class TenantContext {
  const TenantContext({
    this.revendaId,
    this.clienteId,
    this.academiaId,
    this.unidadeId,
  });

  final int? revendaId;
  final int? clienteId;
  final int? academiaId;
  final int? unidadeId;

  static const empty = TenantContext();

  bool get isEmpty =>
      revendaId == null &&
      clienteId == null &&
      academiaId == null &&
      unidadeId == null;
}

/// Resultado de uma divergência de tenant em resposta do backend.
/// Quando `expected != actual` (e expected != null), é sinal de que o
/// backend retornou dado de outro tenant — bug de filtro server-side
/// ou cache desatualizado no mobile.
class TenantMismatch {
  const TenantMismatch({
    required this.field,
    required this.expected,
    required this.actual,
  });

  final String field;
  final int expected;
  final int actual;

  @override
  String toString() => '$field=$actual (esperado $expected)';
}

/// Inspeciona o body de uma resposta e detecta divergências entre IDs
/// de tenant retornados e o contexto da sessão. Função pura — sem rede,
/// sem efeito colateral, segura pra rodar em todo response.
///
/// Examina o root (Map) e, se houver chave `content`/`data` com lista,
/// examina os 5 primeiros itens. Não desce mais que 1 nível pra manter
/// custo baixo.
List<TenantMismatch> auditTenantMismatch(
  Object? body,
  TenantContext context,
) {
  if (context.isEmpty) return const [];
  final out = <TenantMismatch>[];
  if (body is Map<String, dynamic>) {
    _checkMap(body, context, out);
    final inner = body['content'] ?? body['data'];
    if (inner is List) {
      _checkList(inner, context, out);
    }
  } else if (body is List) {
    _checkList(body, context, out);
  }
  return out;
}

void _checkList(
  List<dynamic> items,
  TenantContext ctx,
  List<TenantMismatch> out,
) {
  final limit = items.length > _kAuditSampleSize
      ? _kAuditSampleSize
      : items.length;
  for (var i = 0; i < limit; i++) {
    final item = items[i];
    if (item is Map<String, dynamic>) {
      _checkMap(item, ctx, out);
    }
  }
}

void _checkMap(Map<String, dynamic> map, TenantContext ctx, List<TenantMismatch> out) {
  _check('revendaId', map, ctx.revendaId, out);
  _check('clienteId', map, ctx.clienteId, out);
  _check('academiaId', map, ctx.academiaId, out);
  _check('unidadeId', map, ctx.unidadeId, out);
}

void _check(
  String field,
  Map<String, dynamic> map,
  int? expected,
  List<TenantMismatch> out,
) {
  if (expected == null) return;
  final raw = map[field];
  final actual = _asInt(raw);
  if (actual == null) return;
  if (actual == expected) return;
  out.add(TenantMismatch(field: field, expected: expected, actual: actual));
}

int? _asInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}
