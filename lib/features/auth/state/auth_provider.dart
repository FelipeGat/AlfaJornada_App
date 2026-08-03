import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/tenant_context.dart';
import '../../../core/log.dart';
import '../../../core/state/clearable.dart';
import '../../../core/storage/auth_storage.dart';
import '../../notificacoes/services/push_service.dart';
import '../models/academia.dart';
import '../models/unidade.dart';
import '../services/auth_service.dart';
import 'session_type.dart';

/// Estados da sessão do usuário. `escolhendoAcademia`/`escolhendoUnidade`
/// são janelas autenticadas-mas-incompletas:
/// - `escolhendoAcademia`: admin_revenda Gym sem academia ativa (Fase B1).
/// - `escolhendoUnidade`: usuário com mais de uma unidade na academia
///   atual (Fase B2). UI mostra a tela de seleção em vez do shell.
enum AuthStatus {
  unknown,
  signedOut,
  escolhendoAcademia,
  escolhendoUnidade,
  signedIn,
}

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._service, this._storage, this._api, this._pushService);

  final AuthService _service;
  final AuthStorage _storage;
  final ApiClient _api;
  final PushService _pushService;

  AuthStatus _status = AuthStatus.unknown;
  String? _displayName;
  AlfaProduct? _product;
  AlfaProduct? _lastProduct;
  String? _errorMessage;
  bool _loading = false;
  int? _pessoaId;
  int? _usuarioId;
  String? _perfil;
  String? _pessoaFoto;
  String? _clienteSegmento;
  String? _pessoaTipoCodigo;
  bool _senhaProvisoria = false;
  String? _token;
  int? _revendaId;
  int? _clienteId;
  int? _academiaId;
  int? _unidadeId;
  /// Lista de unidades pendentes durante `escolhendoUnidade`. Volátil —
  /// não persiste em storage. Se o usuário matar o app durante a janela,
  /// bootstrap detecta e força logout (sessão recomeça).
  List<Unidade> _unidadesPendentes = const [];
  Set<String>? _tenantFeatures;
  Set<String> _activeModulos = const {};

  AuthStatus get status => _status;
  String? get displayName => _displayName;
  AlfaProduct? get product => _product;
  /// Último produto logado com sucesso neste aparelho (sobrevive a
  /// logout) — a tela de login usa isso pra pular direto pro formulário
  /// de email/senha, sem mostrar o seletor de sistema de novo.
  AlfaProduct? get lastProduct => _lastProduct;
  String? get errorMessage => _errorMessage;
  bool get loading => _loading;
  int? get pessoaId => _pessoaId;
  int? get usuarioId => _usuarioId;
  String? get perfil => _perfil;
  String? get pessoaFoto => _pessoaFoto;
  String? get clienteSegmento => _clienteSegmento;
  String? get pessoaTipoCodigo => _pessoaTipoCodigo;
  bool get senhaProvisoria => _senhaProvisoria;
  String? get currentToken => _token;
  int? get revendaId => _revendaId;
  int? get clienteId => _clienteId;
  int? get academiaId => _academiaId;
  int? get unidadeId => _unidadeId;
  List<Unidade> get unidadesPendentes =>
      List.unmodifiable(_unidadesPendentes);

  /// Nome da empresa/cliente do último login bem-sucedido no produto
  /// informado (cache local, sobrevive a logout) — usado só na tela de
  /// login pós-seleção pra uma saudação pessoal; null quando o produto
  /// nunca expôs esse dado ou o usuário nunca logou nele.
  Future<String?> companyNameFor(AlfaProduct product) =>
      _storage.readCompanyName(product);

  /// Último número-resumo cacheado do produto (ex.: "423 alunos ativos"),
  /// visto pela última vez que o usuário logou nele — usado nos cards do
  /// Hub de seleção. Null quando nunca logou ou o produto não expõe stat.
  Future<ProductStat?> statFor(AlfaProduct product) =>
      _storage.readProductStat(product);

  /// Módulos contratados ativos para o cliente logado (AlfaControl).
  /// Populado via GET /api/me/modulos após login/bootstrap.
  Set<String> get activeModulos => _activeModulos;

  /// Snapshot do tenant atual usado pelo interceptor de auditoria do
  /// `ApiClient` (Fase F3).
  TenantContext get tenantContext => TenantContext(
        revendaId: _revendaId,
        clienteId: _clienteId,
        academiaId: _academiaId,
        unidadeId: _unidadeId,
      );

  /// Features do plano SaaS contratado pelo cliente. `null` significa
  /// "backend ainda não retorna features" — convencionado como tudo
  /// liberado pra preservar funcionalidade até a dívida do backend
  /// (AlfaGym + AlfaControl) ser fechada. Conjunto vazio significa
  /// "cliente sem nenhuma feature contratada" — bloqueia tudo.
  Set<String>? get tenantFeatures => _tenantFeatures;
  SessionType get sessionType =>
      classifySession(product: _product, perfil: _perfil);

  Future<void> bootstrap() async {
    final token = await _storage.readToken();
    _token = token;
    _lastProduct = await _storage.readLastProduct();
    final product = await _storage.readProduct();
    final name = await _storage.readUserName();
    final pessoaId = await _storage.readPessoaId();
    final usuarioId = await _storage.readUsuarioId();
    final perfil = await _storage.readPerfil();
    if (token != null && token.isNotEmpty && product != null) {
      _product = product;
      _displayName = name;
      _pessoaId = pessoaId;
      _usuarioId = usuarioId;
      _perfil = perfil;
      _status = AuthStatus.signedIn;
      notifyListeners();
      final profile = await _service.fetchMyProfile();
      if (profile != null) {
        _applyProfile(profile);
        await _refreshModulos();
      }
      // Se admin_revenda Gym matou o app durante a tela de seleção
      // (academiaId ainda null no /me), refaz o gate em vez de cair em
      // signedIn — evita bypass do fluxo de B1.
      if (precisaSelecionarAcademia(_product, _perfil, _academiaId)) {
        _status = AuthStatus.escolhendoAcademia;
        notifyListeners();
        return;
      }
      if (profile != null) notifyListeners();
      unawaited(_carregarFoto());
      _maybeEnablePush();
      return;
    }
    _status = AuthStatus.signedOut;
    notifyListeners();
  }

  /// Hidrata o estado a partir de um `MeProfile`. Usado tanto pelo
  /// bootstrap quanto pelo login pra evitar drift entre os dois caminhos.
  /// Não chama `notifyListeners` — o caller decide quando notificar.
  void _applyProfile(MeProfile profile) {
    if (profile.pessoaId != null) _pessoaId = profile.pessoaId;
    if (profile.usuarioId != null) _usuarioId = profile.usuarioId;
    if (profile.perfil != null && profile.perfil!.isNotEmpty) {
      _perfil = profile.perfil;
    }
    _clienteSegmento = profile.clienteSegmento;
    _pessoaTipoCodigo = profile.pessoaTipoCodigo;
    _senhaProvisoria = profile.senhaProvisoria;
    _revendaId = profile.revendaId;
    _clienteId = profile.clienteId;
    // academiaId/unidadeId atribuídos incondicionalmente — se backend
    // revogar acesso e devolver null, mobile precisa esquecer o id antigo
    // (defesa pra troca em sessão ativa).
    _academiaId = profile.academiaId;
    _unidadeId = profile.unidadeId;
    _tenantFeatures = profile.features;
  }

  // AlfaJornada não tem catálogo de "módulos" (conceito de
  // Condomínio/Academia) — `_activeModulos` fica sempre vazio.
  Future<void> _refreshModulos() async {}

  void _maybeEnablePush() {
    if (_status != AuthStatus.signedIn) return;
    unawaited(_pushService.init(_api));
  }

  Future<bool> login({
    required AlfaProduct product,
    required String email,
    required String password,
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _service.login(
        product: product,
        email: email,
        password: password,
      );
      _product = product;
      _lastProduct = product;
      unawaited(_storage.saveLastProduct(product));
      if (result.companyName != null) {
        unawaited(_storage.saveCompanyName(product, result.companyName!));
      }
      _token = result.token;
      _displayName = result.displayName;
      _usuarioId = result.usuarioId;
      _perfil = result.perfil;
      _senhaProvisoria = result.senhaProvisoria;
      _academiaId = result.academiaId;
      // Fallback B2: backend pode enviar 1 unidade na lista mas omitir
      // unidadeId no top-level (drift de contrato). Adotar a única.
      // super_admin/admin_revenda nunca operam em unidade — não pegar
      // nada da lista mesmo que venha com 1 entry (pode ser cross-tenant).
      final perfilLower = result.perfil?.toLowerCase().trim();
      final ehSaasAdmin = perfilLower != null &&
          (kPerfisSuperAdmin.contains(perfilLower) ||
              kPerfisAdminRevenda.contains(perfilLower));
      _unidadeId = ehSaasAdmin
          ? result.unidadeId
          : (result.unidadeId ??
              (result.unidades.length == 1 ? result.unidades.first.id : null));
      if (result.precisaEscolherAcademia) {
        // admin_revenda Gym sem academia preferida — UI vai pra
        // SelecionarAcademiaScreen antes do shell normal (Fase B1).
        _status = AuthStatus.escolhendoAcademia;
        return true;
      }
      // Fase B2: se a academia tem mais de uma unidade, parar pra
      // selecionar. Length 1 é resolvido pelo backend (token já vem
      // com unidade_id) — vai direto pra signedIn.
      logDebug(
          'login: perfil=${result.perfil} unidades=${result.unidades.length} '
          'unidadeId=${result.unidadeId} academiaId=${result.academiaId} '
          'precisaEscolherAcademia=${result.precisaEscolherAcademia} '
          'precisaSelecionarUnidade=${precisaSelecionarUnidade(result.unidades, perfil: result.perfil)}');
      if (precisaSelecionarUnidade(result.unidades, perfil: result.perfil)) {
        _unidadesPendentes = result.unidades;
        _status = AuthStatus.escolhendoUnidade;
        return true;
      }
      _status = AuthStatus.signedIn;
      final profile = await _service.fetchMyProfile();
      if (profile != null) {
        // No login pessoaId pode vir nulo no MeProfile (e _pessoaId começa
        // null), então não usamos o early-return de _applyProfile aqui.
        _pessoaId = profile.pessoaId;
        _applyProfile(profile);
        unawaited(_refreshModulos());
      }
      unawaited(_carregarFoto());
      unawaited(_cacheProductStat(product));
      _maybeEnablePush();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Busca e cacheia localmente um número-resumo do produto logo após o
  /// login (ex.: alunos ativos, acessos hoje) — só pros produtos que hoje
  /// expõem um endpoint pra isso (ver Parte 3 do plano de refinamento do
  /// Hub). Falha silenciosamente: se der erro (rede, permissão, etc.), o
  /// card do Hub simplesmente mantém o cache anterior (ou nenhum).
  Future<void> _cacheProductStat(AlfaProduct product) async {
    // Backend do AlfaJornada ainda não expõe um resumo real
    // (GET /api/dashboard é um stub) — sem dado real, sem cache.
  }

  Future<void> logout() async {
    await _pushService.logout(_api);
    await _service.logout();
    _status = AuthStatus.signedOut;
    _token = null;
    _displayName = null;
    _product = null;
    _pessoaId = null;
    _usuarioId = null;
    _perfil = null;
    _pessoaFoto = null;
    _clienteSegmento = null;
    _pessoaTipoCodigo = null;
    _senhaProvisoria = false;
    _revendaId = null;
    _clienteId = null;
    _academiaId = null;
    _unidadeId = null;
    _unidadesPendentes = const [];
    _tenantFeatures = null;
    _activeModulos = const {};
    notifyListeners();
  }

  /// Lista as academias acessíveis pelo admin_revenda atual (Fase B1).
  /// Usado pela `SelecionarAcademiaScreen` pra montar o grid.
  Future<List<Academia>> listarAcademiasDaRevenda() {
    return _service.listarAcademiasDaRevenda();
  }

  /// Confirma a academia escolhida (Fase B1). Quando a academia tem
  /// mais de uma unidade, transiciona pra `escolhendoUnidade` (Fase B2)
  /// em vez de `signedIn`.
  Future<bool> escolherAcademia(
    int academiaId, {
    Iterable<Clearable> tenantCaches = const [],
  }) {
    return _trocarTenant(
      tenantCaches: tenantCaches,
      resetCamposEspecificos: () {
        // Admin pode estar trocando entre academias; unidade da
        // anterior NÃO pode permanecer no contexto durante a janela
        // de seleção da nova.
        _academiaId = null;
        _unidadeId = null;
        _unidadesPendentes = const [];
      },
      trocarToken: () async {
        final result = await _service.selecionarAcademia(academiaId);
        _academiaId = result.academiaId;
        if (precisaSelecionarUnidade(result.unidades, perfil: _perfil)) {
          _unidadesPendentes = result.unidades;
          return AuthStatus.escolhendoUnidade;
        }
        return null; // segue pro fluxo padrão (signedIn).
      },
      erroProfileMsg: 'Não foi possível carregar dados da academia.',
    );
  }

  /// Confirma a unidade escolhida (Fase B2).
  Future<bool> escolherUnidade(
    int unidadeId, {
    Iterable<Clearable> tenantCaches = const [],
  }) {
    return _trocarTenant(
      tenantCaches: tenantCaches,
      resetCamposEspecificos: () {
        _unidadeId = null;
      },
      trocarToken: () async {
        final result = await _service.selecionarUnidade(unidadeId);
        _unidadeId = result.unidadeId;
        return null;
      },
      erroProfileMsg: 'Não foi possível carregar dados da unidade.',
    );
  }

  /// Helper compartilhado entre `escolherAcademia` e `escolherUnidade`
  /// (e qualquer troca futura de tenant). Centraliza:
  /// 1. Guarda de reentrância via `_loading`.
  /// 2. Reset dos campos comuns ao tenant + `clearAll(tenantCaches)`.
  /// 3. Callback `trocarToken` faz a chamada de service e atualiza os
  ///    ids específicos. Pode retornar `AuthStatus` pra interromper o
  ///    fluxo (ex.: `escolhendoUnidade`); `null` segue pra `signedIn`.
  /// 4. `fetchMyProfile` pós-troca; `null` vira erro tratado.
  /// 5. `_applyProfile` + push + foto + finalize.
  Future<bool> _trocarTenant({
    required Iterable<Clearable> tenantCaches,
    required void Function() resetCamposEspecificos,
    required Future<AuthStatus?> Function() trocarToken,
    required String erroProfileMsg,
  }) async {
    if (_loading) return false;
    _loading = true;
    _errorMessage = null;
    _pessoaFoto = null;
    _clienteSegmento = null;
    _pessoaTipoCodigo = null;
    _clienteId = null;
    _tenantFeatures = null;
    resetCamposEspecificos();
    clearAll(tenantCaches);
    notifyListeners();
    try {
      final earlyStatus = await trocarToken();
      if (earlyStatus != null) {
        _status = earlyStatus;
        return true;
      }
      // profile==null = rede falhou pós-troca de token; tratar como erro
      // pra não cair em signedIn com tenantContext incompleto.
      final profile = await _service.fetchMyProfile();
      if (profile == null) {
        _errorMessage = erroProfileMsg;
        return false;
      }
      _applyProfile(profile);
      _unidadesPendentes = const [];
      _status = AuthStatus.signedIn;
      unawaited(_refreshModulos());
      unawaited(_carregarFoto());
      _maybeEnablePush();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Atualiza nome, email e/ou senha. Os parâmetros não-nulos/não-vazios
  /// são enviados pra `PATCH /api/auth/perfil`. Em sucesso, propaga
  /// `displayName` (e refeitos demais campos no próximo `bootstrap`).
  Future<bool> atualizarPerfil({
    String? nome,
    String? email,
    String? novaSenha,
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final data = await _service.atualizarPerfil(
        nome: nome,
        email: email,
        novaSenha: novaSenha,
      );
      if (data != null) {
        final nomeAtualizado = data['nome'];
        if (nomeAtualizado is String && nomeAtualizado.isNotEmpty) {
          _displayName = nomeAtualizado;
          await _storage.saveUserName(nomeAtualizado);
        }
        if (novaSenha != null && novaSenha.isNotEmpty) {
          _senhaProvisoria = false;
        }
      }
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> trocarSenha(String novaSenha) async {
    _errorMessage = null;
    _loading = true;
    notifyListeners();
    try {
      await _service.trocarSenha(novaSenha);
      _senhaProvisoria = false;
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _carregarFoto() async {
    final id = _pessoaId;
    if (id == null) return;
    try {
      final res = await _api.get<Map<String, dynamic>>('/api/pessoas/$id');
      final data = res.data;
      final foto = data?['foto'];
      if (foto is String && foto.isNotEmpty) {
        _pessoaFoto = foto;
        notifyListeners();
      }
    } catch (_) {
      // Sem foto ou sem acesso — mantem fallback.
    }
  }
}
