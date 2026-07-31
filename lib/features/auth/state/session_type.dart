import '../../../core/api/api_client.dart';

/// Categorias de sessão do AlfaJornada. A distinção operacional real
/// (colaborador × gestor de RH) é feita direto pelo `perfil` na Home
/// (ver `_JornadaHomeSection`/`_JornadaGestorHomeSection`) — `SessionType`
/// só separa os perfis administrativos de plataforma (super_admin/
/// admin_revenda), que caem num shell diferente.
enum SessionType { superAdmin, adminRevenda, usuario, pessoa, aluno, usuarioApp }

const Set<String> kPerfisSuperAdmin = {
  'super_admin',
  'super_user',
};

const Set<String> kPerfisAdminRevenda = {
  'admin_revenda',
};

SessionType classifySession({
  required AlfaProduct? product,
  required String? perfil,
}) {
  final normalized = perfil?.trim().toLowerCase();

  if (normalized != null && kPerfisSuperAdmin.contains(normalized)) {
    return SessionType.superAdmin;
  }
  if (normalized != null && kPerfisAdminRevenda.contains(normalized)) {
    return SessionType.adminRevenda;
  }
  return SessionType.pessoa;
}
