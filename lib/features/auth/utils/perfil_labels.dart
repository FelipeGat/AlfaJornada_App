/// Rótulos humanos dos perfis existentes no sistema.
/// Única fonte da verdade — telas devem importar daqui (Fase 28).
const Map<String, String> perfilLabels = {
  'super_admin': 'Super Admin',
  'super_user': 'Super User',
  'admin_revenda': 'Admin Revenda',
  'gestor_cliente': 'Gestor Cliente',
  'porteiro': 'Porteiro',
  'recepcionista': 'Recepcionista',
  'operador': 'Operador',
  'morador': 'Morador',
};

/// Retorna o label humanizado do perfil, case-insensitive. Se não mapeado,
/// devolve o valor cru; se null/vazio, devolve `'—'`.
String labelPerfil(String? perfil) {
  if (perfil == null || perfil.trim().isEmpty) return '—';
  final chave = perfil.toLowerCase().trim();
  return perfilLabels[chave] ?? perfil;
}

/// Extrai as iniciais de um nome (máximo 2 caracteres, primeira letra do
/// primeiro nome e primeira letra do sobrenome). Retorna `?` quando vazio.
String iniciaisDeNome(String? nome) {
  if (nome == null || nome.trim().isEmpty) return '?';
  final partes =
      nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
  return '${partes.first.substring(0, 1)}${partes.last.substring(0, 1)}'
      .toUpperCase();
}
