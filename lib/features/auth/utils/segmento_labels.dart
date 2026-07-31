/// Rótulos humanos dos segmentos de cliente existentes.
/// O sistema é multi-domínio — UI que precise nomear o contexto do
/// usuário logado deve puxar de `AuthProvider.clienteSegmento` e traduzir
/// por aqui, nunca hardcoded "condomínio".
const Map<String, String> segmentoLabels = {
  'condominio': 'Condomínio',
  'escola': 'Escola',
  'empresa': 'Empresa',
  'clube': 'Clube',
  'academia': 'Academia',
};

/// Retorna o label humanizado do segmento, case-insensitive.
/// Quando ausente ou desconhecido, devolve `null` — o chamador decide
/// se cai em fallback do produto, texto genérico ou esconde.
String? labelSegmento(String? codigo) {
  if (codigo == null || codigo.trim().isEmpty) return null;
  return segmentoLabels[codigo.toLowerCase().trim()];
}

/// Retorna a forma possessiva pra frases tipo "cadastrados NA_SUA_X".
/// Ex: "no seu condomínio", "na sua escola". Fallback genérico:
/// "na sua organização".
String labelSegmentoPossessivo(String? codigo) {
  switch (codigo?.toLowerCase().trim()) {
    case 'condominio':
      return 'no seu condomínio';
    case 'escola':
      return 'na sua escola';
    case 'empresa':
      return 'na sua empresa';
    case 'clube':
      return 'no seu clube';
    case 'academia':
      return 'na sua academia';
    default:
      return 'na sua organização';
  }
}
