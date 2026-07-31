import '../../../core/utils/json_parsers.dart';

/// Usuário ainda sem colaborador vinculado.
class UsuarioSemVinculo {
  const UsuarioSemVinculo({required this.id, required this.nome, required this.email});
  final int id;
  final String nome;
  final String email;

  factory UsuarioSemVinculo.fromJson(Map<String, dynamic> j) => UsuarioSemVinculo(
        id: asInt(j['id']) ?? 0,
        nome: asString(j['nome']) ?? '—',
        email: asString(j['email']) ?? '—',
      );
}

/// Funcionário ativo ainda sem usuário vinculado.
class FuncionarioSemVinculo {
  const FuncionarioSemVinculo({required this.id, required this.nome});
  final int id;
  final String nome;

  factory FuncionarioSemVinculo.fromJson(Map<String, dynamic> j) => FuncionarioSemVinculo(
        id: asInt(j['id']) ?? 0,
        nome: asString(j['nome']) ?? '—',
      );
}

/// Candidatos à vinculação (`GET /api/ponto/vinculo/candidatos`). Espelha `VinculoCandidatosDTO`.
class VinculoCandidatos {
  const VinculoCandidatos({required this.usuarios, required this.funcionarios});
  final List<UsuarioSemVinculo> usuarios;
  final List<FuncionarioSemVinculo> funcionarios;

  factory VinculoCandidatos.fromJson(Map<String, dynamic> j) {
    final usuarios = j['usuarios'];
    final funcionarios = j['funcionarios'];
    return VinculoCandidatos(
      usuarios: usuarios is List
          ? usuarios.whereType<Map>().map((m) => UsuarioSemVinculo.fromJson(Map<String, dynamic>.from(m))).toList()
          : const [],
      funcionarios: funcionarios is List
          ? funcionarios.whereType<Map>().map((m) => FuncionarioSemVinculo.fromJson(Map<String, dynamic>.from(m))).toList()
          : const [],
    );
  }
}
