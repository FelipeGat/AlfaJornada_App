import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/log.dart';
import '../../../core/storage/auth_storage.dart';
import '../models/academia.dart';
import '../models/unidade.dart';
import '../state/session_type.dart';

class AuthResult {
  AuthResult({
    required this.token,
    required this.displayName,
    this.usuarioId,
    this.perfil,
    this.senhaProvisoria = false,
    this.academiaId,
    this.unidadeId,
    this.precisaEscolherAcademia = false,
    this.unidades = const [],
    this.companyName,
  });
  final String token;
  final String displayName;
  final int? usuarioId;
  final String? perfil;
  final bool senhaProvisoria;

  /// Nome da empresa/cliente logado (ex.: "INVEST") — só disponível pra
  /// Condomínio/Jornada, e só quando o backend resolveu 1 empresa só
  /// (`clientes` com exatamente 1 item). AlfaGym não tem esse campo em
  /// nenhum endpoint chamado no login normal — fica sempre null ali.
  final String? companyName;

  /// `academiaId` retornado no LoginResponse do AlfaGym. Null pra
  /// admin_revenda que ainda não escolheu academia.
  final int? academiaId;

  /// `unidadeId` retornado quando o backend já consegue resolver
  /// (academia com 1 unidade só ou usuário escopado à uma unidade).
  final int? unidadeId;

  /// True quando admin_revenda Gym loga sem academia preferida — mobile
  /// precisa mostrar `SelecionarAcademiaScreen` antes de chegar à Home.
  final bool precisaEscolherAcademia;

  /// Lista de unidades disponíveis. Vazia pra admin_revenda (não tem
  /// unidade ainda) e quando produto não é Gym. Quando length>1, mobile
  /// mostra `SelecionarUnidadeScreen`. Quando length==1, mobile faz
  /// bypass automático — chama `selecionarUnidade(id)` em background.
  final List<Unidade> unidades;
}

class MeProfile {
  MeProfile({
    this.usuarioId,
    this.pessoaId,
    this.clienteId,
    this.revendaId,
    this.academiaId,
    this.unidadeId,
    this.perfil,
    this.clienteSegmento,
    this.pessoaTipoCodigo,
    this.senhaProvisoria = false,
    this.features,
  });
  final int? usuarioId;
  final int? pessoaId;
  final int? clienteId;
  final int? revendaId;
  final int? academiaId;
  final int? unidadeId;
  final String? perfil;
  final String? clienteSegmento;
  final String? pessoaTipoCodigo;
  final bool senhaProvisoria;

  /// Features do plano SaaS contratado pelo cliente (Fase F1). Quando o
  /// backend ainda não devolve o campo, fica `null` — convencionado como
  /// "tudo liberado" pra evitar quebrar funcionalidade existente até a
  /// dívida do backend ser fechada.
  final Set<String>? features;

  factory MeProfile.fromJson(Map<String, dynamic> j) => MeProfile(
        usuarioId: _asInt(j['usuarioId'] ?? j['id']),
        pessoaId: _asInt(j['pessoaId']),
        clienteId: _asInt(j['clienteId']),
        revendaId: _asInt(j['revendaId']),
        academiaId: _asInt(j['academiaId']),
        unidadeId: _asInt(j['unidadeId']),
        perfil: j['perfil'] is String ? j['perfil'] as String : null,
        clienteSegmento: j['clienteSegmento'] is String
            ? j['clienteSegmento'] as String
            : null,
        pessoaTipoCodigo: j['pessoaTipoCodigo'] is String
            ? j['pessoaTipoCodigo'] as String
            : null,
        senhaProvisoria: j['senhaProvisoria'] == true,
        features: _parseFeatures(j['features']),
      );

  static int? _asInt(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  /// Aceita lista de strings; ignora itens não-string e devolve null
  /// quando o campo está ausente (preserva semântica "tudo liberado").
  /// Quando o campo vem com tipo errado (ex.: CSV/objeto), loga em debug
  /// e cai em null — drift de contrato com backend é detectável em QA.
  static Set<String>? _parseFeatures(Object? v) {
    if (v == null) return null;
    if (v is! List) {
      logDebug('MeProfile: campo "features" com tipo inesperado: ${v.runtimeType}');
      return null;
    }
    final out = <String>{};
    for (final item in v) {
      if (item is String && item.isNotEmpty) out.add(item.toLowerCase());
    }
    return out;
  }
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Regra pura que decide se a sessão precisa parar em
/// `SelecionarAcademiaScreen` antes de chegar à Home (Fase B1).
/// Backend devolve `academiaId=null` pra admin_revenda Gym que pode
/// gerenciar várias academias. Outros perfis (super_admin, gestor, aluno)
/// seguem direto. Função pura, testável sem rede.
bool precisaSelecionarAcademia(
  AlfaProduct? product,
  String? perfil,
  int? academiaId,
) {
  // Fluxo exclusivo do AlfaGym (admin_revenda escolhendo entre várias
  // academias) — o AlfaJornada nunca passa por essa tela.
  return false;
}

/// Regra pura que decide se a sessão precisa parar em
/// `SelecionarUnidadeScreen` antes de chegar à Home (Fase B2).
/// Mais de uma unidade exige escolha explícita. Length 1 dispara
/// bypass automático no caller (não retorna `true` aqui — o bypass
/// fica em quem invoca). super_admin e admin_revenda nunca operam em
/// unidade — o backend pode mandar uma lista cross-tenant pra exibir
/// no SaaS Hub, mas pro fluxo de login eles sempre seguem direto.
/// ALUNO (Fase D2.A) também não opera em unidade — `/me/*` resolve
/// pelo `aluno_id` do JWT, sem necessidade de unidade selecionada.
bool precisaSelecionarUnidade(List<Unidade> unidades, {String? perfil}) {
  final p = perfil?.toLowerCase().trim();
  if (p != null &&
      (kPerfisSuperAdmin.contains(p) ||
          kPerfisAdminRevenda.contains(p) ||
          p == 'aluno')) {
    return false;
  }
  return unidades.length > 1;
}

class AuthService {
  AuthService(this._api, this._storage);

  final ApiClient _api;
  final AuthStorage _storage;

  Future<AuthResult> login({
    required AlfaProduct product,
    required String email,
    required String password,
  }) async {
    await _storage.saveProduct(product);

    final path = ApiEnvironment.loginPath(product);
    final body = _buildLoginBody(product, email, password);

    try {
      final res = await _api.raw.post(
        '${ApiEnvironment.baseUrlFor(product)}$path',
        data: body,
      );
      // Resposta 200 não-JSON (ex.: captive portal de Wi-Fi devolvendo
      // HTML) não pode virar TypeError silencioso — vira erro amigável.
      final raw = res.data;
      if (raw is! Map<String, dynamic>) {
        throw AuthException(
            'Resposta inesperada do servidor. Verifique sua conexão e tente novamente.');
      }
      final data = raw;
      var token = _extractToken(data);
      final name = _extractName(data, email);
      final usuarioId = MeProfile._asInt(data['id']);
      final perfil = _extractPerfil(data);
      await _storage.saveToken(token);
      await _storage.saveUserName(name);
      await _storage.saveUsuarioId(usuarioId);
      await _storage.savePerfil(perfil);

      final companyName = _extractCompanyName(data);

      if (product == AlfaProduct.jornada) {
        // Login do AlfaJornada é sempre em 2 fases: o token inicial vem
        // sem clienteId, com a lista de empresas do usuário em `clientes`.
        // Colaborador normalmente só tem 1 empresa — pula a tela de
        // escolha e já troca pelo token final direto.
        final clientes = data['clientes'];
        final clienteId = (clientes is List && clientes.length == 1)
            ? MeProfile._asInt((clientes.first as Map)['id'])
            : null;
        if (clienteId == null) {
          throw AuthException(clientes is List && clientes.length > 1
              ? 'Sua conta tem acesso a mais de uma empresa — fale com o RH.'
              : 'Não foi possível identificar sua empresa. Fale com o RH.');
        }
        final finalToken = await _selecionarCliente(clienteId);
        if (finalToken == null) {
          throw AuthException('Não foi possível concluir o login. Tente novamente.');
        }
        token = finalToken;
        await _storage.saveToken(token);
      }

      final academiaId = MeProfile._asInt(data['academiaId']);
      final unidadeId = MeProfile._asInt(data['unidadeId']);
      final precisaEscolherAcademia =
          precisaSelecionarAcademia(product, perfil, academiaId);
      final unidades = const <Unidade>[];

      return AuthResult(
        token: token,
        displayName: name,
        usuarioId: usuarioId,
        perfil: perfil,
        senhaProvisoria: data['senhaProvisoria'] == true,
        academiaId: academiaId,
        unidadeId: unidadeId,
        precisaEscolherAcademia: precisaEscolherAcademia,
        unidades: unidades,
        companyName: companyName,
      );
    } on DioException catch (e) {
      throw AuthException(_humanizeDioError(e));
    }
  }

  /// Seleciona uma unidade específica (Fase B2). Backend troca o token
  /// pelo definitivo (escopado à unidade); pra usuários com 1 unidade
  /// só, mobile chama isto automaticamente em background — sem tela.
  Future<({String token, int unidadeId})> selecionarUnidade(
      int unidadeId) async {
    try {
      final res = await _api.raw.post(
        '/api/auth/selecionar-unidade',
        data: {'unidadeId': unidadeId},
      );
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        throw AuthException('Resposta inválida ao selecionar unidade.');
      }
      final novoToken = _extractToken(data);
      final confirmado = MeProfile._asInt(data['unidadeId']) ?? unidadeId;
      await _storage.saveToken(novoToken);
      return (token: novoToken, unidadeId: confirmado);
    } on DioException catch (e) {
      throw AuthException(_humanizeDioError(e));
    }
  }

  /// Lista academias disponíveis pra seleção do admin_revenda (Fase B1).
  /// Backend filtra automaticamente por revendaId do JWT.
  Future<List<Academia>> listarAcademiasDaRevenda() async {
    try {
      final res = await _api.get<List<dynamic>>('/api/academias/revenda/minhas');
      final data = res.data ?? const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(Academia.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw AuthException(_humanizeDioError(e));
    }
  }

  /// Seleciona uma academia (Fase B1) e troca o token pelo definitivo
  /// (escopado àquela academia). Backend AlfaGym pode incluir as
  /// unidades dessa academia no retorno — caller usa pra decidir se
  /// precisa parar em `SelecionarUnidadeScreen` (Fase B2).
  Future<({String token, int academiaId, List<Unidade> unidades})>
      selecionarAcademia(int academiaId) async {
    try {
      final res = await _api.raw.post(
        '/api/auth/selecionar-academia',
        data: {'academiaId': academiaId},
      );
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        throw AuthException('Resposta inválida ao selecionar academia.');
      }
      final novoToken = _extractToken(data);
      final confirmado =
          MeProfile._asInt(data['academiaId']) ?? academiaId;
      final unidades = Unidade.parseList(data['unidades']);
      await _storage.saveToken(novoToken);
      return (
        token: novoToken,
        academiaId: confirmado,
        unidades: unidades,
      );
    } on DioException catch (e) {
      throw AuthException(_humanizeDioError(e));
    }
  }

  /// Troca a senha do usuario autenticado. Usado para destravar a senha
  /// provisoria entregue pelo gestor no primeiro login.
  Future<void> trocarSenha(String novaSenha) async {
    try {
      await _api.raw.patch('/api/auth/perfil', data: {'senha': novaSenha});
    } on DioException catch (e) {
      throw AuthException(_humanizeDioError(e));
    }
  }

  /// Atualiza nome, email e/ou senha do próprio usuário autenticado.
  /// Body só inclui campos não-nulos/não-vazios.
  /// Backend (`PATCH /api/auth/perfil`) retorna `LoginResponse` com os
  /// dados atualizados — útil pra propagar `displayName` no AuthProvider.
  Future<Map<String, dynamic>?> atualizarPerfil({
    String? nome,
    String? email,
    String? novaSenha,
  }) async {
    final body = <String, String>{};
    if (nome != null && nome.trim().isNotEmpty) body['nome'] = nome.trim();
    if (email != null && email.trim().isNotEmpty) {
      body['email'] = email.trim();
    }
    if (novaSenha != null && novaSenha.isNotEmpty) {
      body['senha'] = novaSenha;
    }
    if (body.isEmpty) return null;
    try {
      final res = await _api.raw.patch<Map<String, dynamic>>(
        '/api/auth/perfil',
        data: body,
      );
      return res.data;
    } on DioException catch (e) {
      throw AuthException(_humanizePerfilError(e));
    }
  }

  String _humanizePerfilError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Não foi possível conectar ao servidor.';
    }
    final status = e.response?.statusCode;
    final data = e.response?.data;
    String? rawMsg;
    if (data is Map) {
      final v = data['message'] ?? data['error'] ?? data['details'];
      if (v is String && v.isNotEmpty) rawMsg = v;
    }
    if (status == 409) return rawMsg ?? 'Este e-mail já está em uso.';
    if (status == 400) return rawMsg ?? 'Dados inválidos.';
    if (rawMsg != null) return rawMsg;
    return 'Não foi possível atualizar o perfil (${status ?? 'sem resposta'}).';
  }

  Future<String?> _selecionarCliente(int clienteId) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/api/auth/selecionar-cliente',
        data: {'clienteId': clienteId},
      );
      final data = res.data;
      if (data == null) return null;
      final token = data['accessToken'] ?? data['token'];
      if (token is String && token.isNotEmpty) return token;
      return null;
    } on DioException {
      return null;
    }
  }

  Future<MeProfile?> fetchMyProfile() async {
    const path = '/api/auth/me';
    try {
      final res = await _api.get(path);
      final data = res.data;
      if (data is Map<String, dynamic>) {
        final profile = MeProfile.fromJson(data);
        await _storage.savePessoaId(profile.pessoaId);
        if (profile.usuarioId != null) {
          await _storage.saveUsuarioId(profile.usuarioId);
        }
        if (profile.perfil != null && profile.perfil!.isNotEmpty) {
          await _storage.savePerfil(profile.perfil);
        }
        return profile;
      }
    } on DioException {
      return null;
    }
    return null;
  }

  Future<Set<String>> fetchActiveModulos() async {
    try {
      final res = await _api.get('/api/me/modulos');
      final data = res.data;
      if (data is List) {
        return data.whereType<String>().toSet();
      }
    } on DioException {
      return {};
    }
    return {};
  }

  Future<void> logout() => _storage.clear();

  Map<String, dynamic> _buildLoginBody(
      AlfaProduct product, String email, String password) {
    return {'email': email, 'senha': password};
  }

  String _extractToken(Map<String, dynamic> data) {
    final token = data['token'] ??
        data['accessToken'] ??
        data['access_token'] ??
        data['jwt'];
    if (token is String && token.isNotEmpty) return token;
    throw AuthException('Resposta de login sem token.');
  }

  /// Extrai o nome da empresa/cliente logado a partir de `data['clientes']`
  /// — só confiável quando a lista tem exatamente 1 item (com mais de 1,
  /// o usuário tem acesso a várias empresas e não dá pra saber qual é "a"
  /// empresa da sessão sem adivinhar; nesse caso retorna null).
  String? _extractCompanyName(Map<String, dynamic> data) {
    final clientes = data['clientes'];
    if (clientes is! List || clientes.length != 1) return null;
    final first = clientes.first;
    if (first is! Map) return null;
    final nome = first['nome'];
    return (nome is String && nome.isNotEmpty) ? nome : null;
  }

  String? _extractPerfil(Map<String, dynamic> data) {
    final p = data['perfil'];
    if (p is String && p.isNotEmpty) return p;
    final user = data['usuario'] ?? data['user'];
    if (user is Map) {
      final up = user['perfil'];
      if (up is String && up.isNotEmpty) return up;
    }
    return null;
  }

  String _extractName(Map<String, dynamic> data, String fallback) {
    final user = data['usuario'] ?? data['user'];
    if (user is Map) {
      final n = user['nome'] ?? user['name'];
      if (n is String && n.isNotEmpty) return n;
    }
    final n = data['nome'] ?? data['name'];
    if (n is String && n.isNotEmpty) return n;
    return fallback.split('@').first;
  }

  String _humanizeDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Não foi possível conectar ao servidor.';
    }
    // Backend já monta mensagens úteis (ex.: "Restam 2 tentativas antes
    // do bloqueio", "Conta bloqueada — aguarde X minutos"). Só cai no
    // genérico quando não veio nada legível.
    final msg = e.response?.data is Map
        ? (e.response?.data['message'] ?? e.response?.data['error'])
        : null;
    if (msg is String && msg.isNotEmpty) return msg;
    final status = e.response?.statusCode;
    if (status == 401 || status == 403) return 'E-mail ou senha inválidos.';
    if (status == 429) {
      return 'Muitas tentativas. Aguarde alguns minutos antes de tentar novamente.';
    }
    return 'Erro ao entrar (${status ?? 'sem resposta'}).';
  }
}
