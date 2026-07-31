import 'package:flutter/foundation.dart';

import '../../../core/state/clearable.dart';
import '../models/equipe_hoje_item.dart';
import '../models/humor_resumo.dart';
import '../models/indicadores_resumo.dart';
import '../models/vinculo_candidatos.dart';
import '../services/jornada_gestor_service.dart';

/// Estado das telas do gestor de RH no AlfaJornada — resumo do dia, clima da equipe,
/// lista "equipe hoje" (paginada) e vinculação usuário↔colaborador.
class JornadaGestorProvider extends ChangeNotifier implements Clearable {
  JornadaGestorProvider(this._service);

  final JornadaGestorService _service;

  // ── Resumo do dia ────────────────────────────────────────────────
  IndicadoresResumo? _resumo;
  bool _loadingResumo = false;
  String? _erroResumo;

  IndicadoresResumo? get resumo => _resumo;
  bool get loadingResumo => _loadingResumo;
  String? get erroResumo => _erroResumo;

  Future<void> carregarResumo({bool refresh = false}) async {
    if (_loadingResumo) return;
    if (refresh) _resumo = null;
    _loadingResumo = true;
    _erroResumo = null;
    notifyListeners();
    try {
      _resumo = await _service.resumoHoje();
    } on JornadaGestorServiceException catch (e) {
      _erroResumo = e.message;
    } finally {
      _loadingResumo = false;
      notifyListeners();
    }
  }

  // ── Clima da equipe ──────────────────────────────────────────────
  HumorResumo? _humor;
  bool _loadingHumorEquipe = false;
  String? _erroHumorEquipe;

  HumorResumo? get humor => _humor;
  bool get loadingHumorEquipe => _loadingHumorEquipe;
  String? get erroHumorEquipe => _erroHumorEquipe;

  Future<void> carregarHumorEquipe({bool refresh = false}) async {
    if (_loadingHumorEquipe) return;
    if (refresh) _humor = null;
    _loadingHumorEquipe = true;
    _erroHumorEquipe = null;
    notifyListeners();
    try {
      _humor = await _service.humorHoje();
    } on JornadaGestorServiceException catch (e) {
      _erroHumorEquipe = e.message;
    } finally {
      _loadingHumorEquipe = false;
      notifyListeners();
    }
  }

  // ── Equipe hoje (paginada) ───────────────────────────────────────
  List<EquipeHojeItem> _equipe = const [];
  int _equipePagina = 0;
  bool _equipeTemMais = true;
  bool _loadingEquipe = false;
  String? _erroEquipe;
  String _equipeBusca = '';
  int _genEquipe = 0;

  List<EquipeHojeItem> get equipe => List.unmodifiable(_equipe);
  bool get equipeTemMais => _equipeTemMais;
  bool get loadingEquipe => _loadingEquipe;
  String? get erroEquipe => _erroEquipe;

  Future<void> carregarEquipe({bool refresh = false, String? busca}) async {
    if (_loadingEquipe) return;
    if (refresh || busca != null) {
      _equipe = const [];
      _equipePagina = 0;
      _equipeTemMais = true;
      if (busca != null) _equipeBusca = busca;
    }
    if (!_equipeTemMais) return;
    final my = ++_genEquipe;
    _loadingEquipe = true;
    _erroEquipe = null;
    notifyListeners();
    try {
      final pagina = await _service.equipeHoje(page: _equipePagina, search: _equipeBusca);
      if (my != _genEquipe) return;
      _equipe = [..._equipe, ...pagina.content];
      _equipeTemMais = !pagina.last;
      _equipePagina = pagina.number + 1;
    } on JornadaGestorServiceException catch (e) {
      if (my != _genEquipe) return;
      _erroEquipe = e.message;
    } finally {
      if (my == _genEquipe) _loadingEquipe = false;
      notifyListeners();
    }
  }

  // ── Vinculação ───────────────────────────────────────────────────
  VinculoCandidatos? _candidatos;
  bool _loadingCandidatos = false;
  String? _erroCandidatos;
  bool _vinculando = false;

  VinculoCandidatos? get candidatos => _candidatos;
  bool get loadingCandidatos => _loadingCandidatos;
  String? get erroCandidatos => _erroCandidatos;
  bool get vinculando => _vinculando;

  Future<void> carregarCandidatos({bool refresh = false}) async {
    if (_loadingCandidatos) return;
    if (refresh) _candidatos = null;
    _loadingCandidatos = true;
    _erroCandidatos = null;
    notifyListeners();
    try {
      _candidatos = await _service.candidatosVinculo();
    } on JornadaGestorServiceException catch (e) {
      _erroCandidatos = e.message;
    } finally {
      _loadingCandidatos = false;
      notifyListeners();
    }
  }

  /// Vincula e já remove os dois da lista de candidatos em memória — evita
  /// esperar um novo carregarCandidatos() só pra tirar quem acabou de vincular.
  Future<String?> vincular({required int usuarioId, required int funcionarioId}) async {
    _vinculando = true;
    notifyListeners();
    try {
      await _service.vincular(usuarioId: usuarioId, funcionarioId: funcionarioId);
      final atual = _candidatos;
      if (atual != null) {
        _candidatos = VinculoCandidatos(
          usuarios: atual.usuarios.where((u) => u.id != usuarioId).toList(),
          funcionarios: atual.funcionarios.where((f) => f.id != funcionarioId).toList(),
        );
      }
      return null;
    } on JornadaGestorServiceException catch (e) {
      return e.message;
    } finally {
      _vinculando = false;
      notifyListeners();
    }
  }

  @override
  void limpar() {
    _resumo = null;
    _loadingResumo = false;
    _erroResumo = null;
    _humor = null;
    _loadingHumorEquipe = false;
    _erroHumorEquipe = null;
    _genEquipe++;
    _equipe = const [];
    _equipePagina = 0;
    _equipeTemMais = true;
    _loadingEquipe = false;
    _erroEquipe = null;
    _equipeBusca = '';
    _candidatos = null;
    _loadingCandidatos = false;
    _erroCandidatos = null;
    _vinculando = false;
    notifyListeners();
  }
}
