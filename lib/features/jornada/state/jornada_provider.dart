import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/state/clearable.dart';
import '../models/banco_horas.dart';
import '../models/batida_ponto.dart';
import '../models/humor_historico_item.dart';
import '../models/ponto_pendente.dart';
import '../models/ponto_status.dart';
import '../services/humor_service.dart';
import '../services/jornada_service.dart';

/// Resultado de uma tentativa de bater ponto — distingue sucesso online,
/// sucesso "otimista" (sem rede, foi pra fila offline) e erro real, pra
/// tela decidir a mensagem certa.
class RegistrarPontoResultado {
  const RegistrarPontoResultado({
    this.erro,
    this.enfileirado = false,
    this.jaEmAndamento = false,
  });

  final JornadaServiceException? erro;
  final bool enfileirado;

  /// Já havia um registro em andamento (ex.: toque duplo) — a chamada
  /// foi ignorada e a tela não deve mostrar nada.
  final bool jaEmAndamento;
  bool get sucesso => erro == null && !jaEmAndamento;
}

/// Estado do módulo "Meu Ponto" — status do dia + histórico paginado +
/// fila offline. Segue o mesmo padrão de generation-token do
/// `MeAlunoProvider` (Fase AlfaGym): refresh de uma fatia nunca cancela
/// load da outra.
class JornadaProvider extends ChangeNotifier implements Clearable {
  JornadaProvider(this._service, this._humorService) {
    _carregarFila();
  }

  final JornadaService _service;
  final HumorService _humorService;

  static const _kChaveFila = 'jornada.ponto.fila_offline';

  // ── Status do dia ────────────────────────────────────────────────
  PontoStatus? _status;
  bool _loadingStatus = false;
  String? _erroStatus;
  int _genStatus = 0;

  PontoStatus? get status => _status;
  bool get loadingStatus => _loadingStatus;
  String? get erroStatus => _erroStatus;

  Future<void> carregarStatus({bool refresh = false}) async {
    if (_loadingStatus) return;
    if (refresh) _status = null;
    final my = ++_genStatus;
    _loadingStatus = true;
    _erroStatus = null;
    notifyListeners();
    try {
      final s = await _service.buscarMeuStatus();
      if (my != _genStatus) return;
      _status = s;
    } on JornadaServiceException catch (e) {
      if (my != _genStatus) return;
      _erroStatus = e.message;
    } finally {
      if (my == _genStatus) _loadingStatus = false;
      notifyListeners();
    }
  }

  // ── Registrar ponto ──────────────────────────────────────────────
  bool _registrando = false;
  bool get registrando => _registrando;

  /// Bate o ponto e recarrega o status. Quando falha por erro de
  /// **conexão** (sem rede/timeout), guarda a marcação na fila offline
  /// em vez de mostrar erro — a hora capturada aqui (`DateTime.now()`,
  /// no momento do toque) é o que será sincronizado depois, não a hora
  /// da sincronização.
  Future<RegistrarPontoResultado> registrarPonto({
    double? latitude,
    double? longitude,
  }) async {
    // Guarda de reentrância: dois toques na janela do GPS não podem
    // virar duas batidas (ENTRADA+SAÍDA com segundos de diferença).
    if (_registrando) {
      return const RegistrarPontoResultado(jaEmAndamento: true);
    }
    _registrando = true;
    notifyListeners();
    try {
      await _service.registrarPonto(latitude: latitude, longitude: longitude);
      await carregarStatus(refresh: true);
      return const RegistrarPontoResultado();
    } on JornadaServiceException catch (e) {
      if (e.isConnectionError) {
        await _enfileirar(latitude: latitude, longitude: longitude);
        return const RegistrarPontoResultado(enfileirado: true);
      }
      return RegistrarPontoResultado(erro: e);
    } finally {
      _registrando = false;
      notifyListeners();
    }
  }

  // ── Humor do dia ─────────────────────────────────────────────────
  int? _meuHumor;
  String? _meuHumorMotivo;
  bool _loadingHumor = false;
  bool _registrandoHumor = false;

  int? get meuHumor => _meuHumor;

  /// Motivo opcional contado pelo colaborador — sigiloso, só ele vê.
  String? get meuHumorMotivo => _meuHumorMotivo;
  bool get loadingHumor => _loadingHumor;
  bool get registrandoHumor => _registrandoHumor;

  Future<void> carregarMeuHumor() async {
    _loadingHumor = true;
    notifyListeners();
    try {
      final humor = await _humorService.meuHumorHoje();
      _meuHumor = humor.nota;
      _meuHumorMotivo = humor.motivo;
    } on HumorServiceException {
      // Best-effort: se falhar, a colaborador só não vê o humor pré-selecionado hoje.
    } finally {
      _loadingHumor = false;
      notifyListeners();
    }
  }

  /// Bate o humor do dia; `motivo` é opcional — quando omitido num
  /// segundo toque (só trocando a nota), o service preserva o motivo já
  /// contado antes (ver `HumorService.registrar` no backend).
  Future<bool> registrarHumor(int nota, {String? motivo}) async {
    _registrandoHumor = true;
    notifyListeners();
    try {
      await _humorService.registrar(nota, motivo: motivo);
      _meuHumor = nota;
      if (motivo != null && motivo.trim().isNotEmpty) {
        _meuHumorMotivo = motivo.trim();
      }
      return true;
    } on HumorServiceException {
      return false;
    } finally {
      _registrandoHumor = false;
      notifyListeners();
    }
  }

  // ── Histórico de humor (sigiloso — só o próprio colaborador) ──────
  List<HumorHistoricoItem> _humorHistorico = const [];
  bool _loadingHumorHistorico = false;
  String? _erroHumorHistorico;

  List<HumorHistoricoItem> get humorHistorico => List.unmodifiable(_humorHistorico);
  bool get loadingHumorHistorico => _loadingHumorHistorico;
  String? get erroHumorHistorico => _erroHumorHistorico;

  Future<void> carregarHumorHistorico({bool refresh = false}) async {
    if (_loadingHumorHistorico) return;
    if (!refresh && _humorHistorico.isNotEmpty) return;
    _loadingHumorHistorico = true;
    _erroHumorHistorico = null;
    notifyListeners();
    try {
      _humorHistorico = await _humorService.meuHistorico();
    } on HumorServiceException catch (e) {
      _erroHumorHistorico = e.message;
    } finally {
      _loadingHumorHistorico = false;
      notifyListeners();
    }
  }

  // ── Banco de horas ─────────────────────────────────────────────────
  BancoHorasResumo? _bancoHoras;
  bool _loadingBancoHoras = false;
  String? _erroBancoHoras;

  BancoHorasResumo? get bancoHoras => _bancoHoras;
  bool get loadingBancoHoras => _loadingBancoHoras;
  String? get erroBancoHoras => _erroBancoHoras;

  Future<void> carregarBancoHoras({bool refresh = false}) async {
    if (_loadingBancoHoras) return;
    if (!refresh && _bancoHoras != null) return;
    _loadingBancoHoras = true;
    _erroBancoHoras = null;
    notifyListeners();
    try {
      _bancoHoras = await _service.buscarBancoHoras();
    } on JornadaServiceException catch (e) {
      _erroBancoHoras = e.message;
    } finally {
      _loadingBancoHoras = false;
      notifyListeners();
    }
  }

  // ── Fila offline ─────────────────────────────────────────────────
  List<PontoPendente> _fila = const [];
  bool _sincronizando = false;

  List<PontoPendente> get filaPendente => List.unmodifiable(_fila);
  bool get temPendentes => _fila.isNotEmpty;
  bool get sincronizando => _sincronizando;

  Future<void> _carregarFila() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kChaveFila) ?? const [];
    _fila = raw
        .map((s) {
          try {
            return PontoPendente.fromJson(Map<String, dynamic>.from(jsonDecode(s)));
          } catch (_) {
            return null;
          }
        })
        .whereType<PontoPendente>()
        .toList();
    if (_fila.isNotEmpty) notifyListeners();
  }

  Future<void> _salvarFila() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _kChaveFila, _fila.map((p) => jsonEncode(p.toJson())).toList());
  }

  Future<void> _enfileirar({double? latitude, double? longitude}) async {
    final pendente = PontoPendente(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      capturedAt: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
    );
    _fila = [..._fila, pendente];
    await _salvarFila();
  }

  /// Tenta sincronizar a fila, mais antiga primeiro — a ordem importa
  /// porque o sentido ENTRADA/SAIDA é calculado pelo servidor a partir
  /// de quantas batidas já existem no dia. Para no primeiro erro de
  /// conexão (ainda sem rede); erros de negócio (ex.: janela de
  /// tolerância vencida) marcam o item e seguem pros próximos, sem
  /// travar a fila inteira.
  Future<void> sincronizarFila() async {
    if (_sincronizando || _fila.isEmpty) return;
    _sincronizando = true;
    notifyListeners();
    // try/finally: uma exceção inesperada (ex.: PlatformException do
    // SharedPreferences) não pode deixar `_sincronizando` travado em
    // true — a fila ficaria bloqueada até reiniciar o app.
    try {
      final ordenada = [..._fila]..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
      for (final pendente in ordenada) {
        try {
          await _service.registrarPonto(
            latitude: pendente.latitude,
            longitude: pendente.longitude,
            dataHora: pendente.capturedAt,
          );
          _fila = _fila.where((p) => p.id != pendente.id).toList();
        } on JornadaServiceException catch (e) {
          if (e.isConnectionError) break;
          final idx = _fila.indexWhere((p) => p.id == pendente.id);
          if (idx != -1) _fila[idx].erro = e.message;
        }
      }
      await _salvarFila();
      await carregarStatus(refresh: true);
    } finally {
      _sincronizando = false;
      notifyListeners();
    }
  }

  Future<void> descartarPendente(String id) async {
    _fila = _fila.where((p) => p.id != id).toList();
    await _salvarFila();
    notifyListeners();
  }

  // ── Histórico (paginado) ─────────────────────────────────────────
  List<BatidaHistorico> _historico = const [];
  int _historicoPagina = 0;
  bool _historicoTemMais = true;
  bool _loadingHistorico = false;
  String? _erroHistorico;
  int _genHistorico = 0;

  List<BatidaHistorico> get historico => List.unmodifiable(_historico);
  bool get historicoTemMais => _historicoTemMais;
  bool get loadingHistorico => _loadingHistorico;
  String? get erroHistorico => _erroHistorico;

  Future<void> carregarHistorico({bool refresh = false}) async {
    if (_loadingHistorico) return;
    if (refresh) {
      _historico = const [];
      _historicoPagina = 0;
      _historicoTemMais = true;
    }
    if (!_historicoTemMais) return;
    final my = ++_genHistorico;
    _loadingHistorico = true;
    _erroHistorico = null;
    notifyListeners();
    try {
      final pagina = await _service.buscarHistorico(page: _historicoPagina);
      if (my != _genHistorico) return;
      _historico = [..._historico, ...pagina.content];
      _historicoTemMais = !pagina.last;
      _historicoPagina = pagina.number + 1;
    } on JornadaServiceException catch (e) {
      if (my != _genHistorico) return;
      _erroHistorico = e.message;
    } finally {
      if (my == _genHistorico) _loadingHistorico = false;
      notifyListeners();
    }
  }

  @override
  void limpar() {
    // A fila offline NÃO é zerada aqui de propósito — são marcações
    // reais ainda não sincronizadas; trocar de sessão/tenant não pode
    // apagar silenciosamente um ponto que o colaborador já bateu.
    _genStatus++;
    _genHistorico++;
    _status = null;
    _historico = const [];
    _historicoPagina = 0;
    _historicoTemMais = true;
    _loadingStatus = false;
    _loadingHistorico = false;
    _registrando = false;
    _erroStatus = null;
    _erroHistorico = null;
    _meuHumor = null;
    _meuHumorMotivo = null;
    _loadingHumor = false;
    _registrandoHumor = false;
    _humorHistorico = const [];
    _loadingHumorHistorico = false;
    _erroHumorHistorico = null;
    _bancoHoras = null;
    _loadingBancoHoras = false;
    _erroBancoHoras = null;
    notifyListeners();
  }
}
