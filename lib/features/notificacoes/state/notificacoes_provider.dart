import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/state/clearable.dart';
import '../models/notificacao.dart';

enum FiltroStatusNotif { todas, naoLidas, lidas }

class NotificacoesProvider extends ChangeNotifier implements Clearable {
  NotificacoesProvider(this._api);

  final ApiClient _api;

  static const _debounce = Duration(milliseconds: 300);

  final List<Notificacao> _lista = [];
  int _naoLidas = 0;
  bool _loading = false;
  String? _erro;
  Timer? _timer;

  FiltroStatusNotif _filtroStatus = FiltroStatusNotif.todas;
  String? _filtroTipo;
  String _busca = '';
  DateTime? _dataInicio;
  DateTime? _dataFim;
  Timer? _debounceBusca;

  List<Notificacao> get lista => List.unmodifiable(_lista);

  List<Notificacao> get filtradas {
    final termo = _busca.trim().toLowerCase();
    return _lista.where((n) {
      if (_filtroStatus == FiltroStatusNotif.naoLidas && n.lida) return false;
      if (_filtroStatus == FiltroStatusNotif.lidas && !n.lida) return false;
      if (_filtroTipo != null && n.tipo != _filtroTipo) return false;
      if (_dataInicio != null && n.createdAt.isBefore(_dataInicio!)) {
        return false;
      }
      if (_dataFim != null && n.createdAt.isAfter(_dataFim!)) return false;
      if (termo.isNotEmpty) {
        final alvo = '${n.titulo} ${n.mensagem}'.toLowerCase();
        if (!alvo.contains(termo)) return false;
      }
      return true;
    }).toList(growable: false);
  }

  /// Tipos distintos que apareceram no feed carregado — alimenta os chips.
  List<String> get tiposDisponiveis {
    final set = <String>{};
    for (final n in _lista) {
      if (n.tipo.isNotEmpty) set.add(n.tipo);
    }
    final out = set.toList()..sort();
    return out;
  }

  int get naoLidas => _naoLidas;
  bool get loading => _loading;
  String? get erro => _erro;
  FiltroStatusNotif get filtroStatus => _filtroStatus;
  String? get filtroTipo => _filtroTipo;
  String get busca => _busca;
  DateTime? get dataInicio => _dataInicio;
  DateTime? get dataFim => _dataFim;

  bool get temAlgumFiltro =>
      _filtroStatus != FiltroStatusNotif.todas ||
      _filtroTipo != null ||
      _busca.isNotEmpty ||
      _dataInicio != null ||
      _dataFim != null;

  void startPolling({Duration every = const Duration(seconds: 15)}) {
    _timer?.cancel();
    _carregarNaoLidas();
    _timer = Timer.periodic(every, (_) => _carregarNaoLidas());
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _carregarNaoLidas() async {
    try {
      final res = await _api.get<Map<String, dynamic>>(
        '/api/notificacoes/me/nao-lidas/count',
      );
      final total = (res.data?['total'] as num?)?.toInt() ?? 0;
      if (total != _naoLidas) {
        _naoLidas = total;
        notifyListeners();
      }
    } catch (_) {
      // silencioso — polling continua
    }
  }

  Future<void> carregarTudo() async {
    _loading = true;
    _erro = null;
    notifyListeners();
    try {
      final res = await _api.get<List<dynamic>>('/api/notificacoes/me');
      // Um item malformado não pode derrubar o feed inteiro — pula.
      _lista
        ..clear()
        ..addAll(
          (res.data ?? []).whereType<Map<String, dynamic>>().map((j) {
            try {
              return Notificacao.fromJson(j);
            } catch (_) {
              return null;
            }
          }).whereType<Notificacao>(),
        );
      _naoLidas = _lista.where((n) => !n.lida).length;
    } on DioException catch (e) {
      // Backend do AlfaGym ainda não implementa listagem de notificações
      // (só tem device tokens pra FCM) — 404 aqui é ausência de módulo,
      // não erro. Mostra lista vazia ao invés do stacktrace feio.
      if (e.response?.statusCode == 404) {
        _lista.clear();
        _naoLidas = 0;
      } else {
        _erro = 'Não foi possível carregar as notificações.';
      }
    } catch (_) {
      _erro = 'Não foi possível carregar as notificações.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Retorna false quando a chamada falhou (ex.: sem rede) — a tela
  /// avisa em vez de o toque morrer em silêncio.
  Future<bool> marcarLida(int id) async {
    try {
      await _api.raw.patch('/api/notificacoes/$id/lida');
      final idx = _lista.indexWhere((n) => n.id == id);
      if (idx >= 0 && !_lista[idx].lida) {
        _lista[idx] = Notificacao(
          id: _lista[idx].id,
          tipo: _lista[idx].tipo,
          titulo: _lista[idx].titulo,
          mensagem: _lista[idx].mensagem,
          lida: true,
          createdAt: _lista[idx].createdAt,
          referenciaTipo: _lista[idx].referenciaTipo,
          referenciaId: _lista[idx].referenciaId,
        );
        _naoLidas = (_naoLidas - 1).clamp(0, 1 << 31);
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Retorna false quando a chamada falhou — ver [marcarLida].
  Future<bool> marcarTodasLidas() async {
    try {
      await _api.raw.patch('/api/notificacoes/me/marcar-todas-lidas');
      _naoLidas = 0;
      for (var i = 0; i < _lista.length; i++) {
        if (!_lista[i].lida) {
          _lista[i] = Notificacao(
            id: _lista[i].id,
            tipo: _lista[i].tipo,
            titulo: _lista[i].titulo,
            mensagem: _lista[i].mensagem,
            lida: true,
            createdAt: _lista[i].createdAt,
            referenciaTipo: _lista[i].referenciaTipo,
            referenciaId: _lista[i].referenciaId,
          );
        }
      }
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  bool setFiltroStatus(FiltroStatusNotif status) {
    if (_filtroStatus == status) return false;
    _filtroStatus = status;
    notifyListeners();
    return true;
  }

  bool setFiltroTipo(String? tipo) {
    if (_filtroTipo == tipo) return false;
    _filtroTipo = tipo;
    notifyListeners();
    return true;
  }

  /// Busca com debounce — UI pode chamar a cada tecla digitada sem custo.
  void setBusca(String valor) {
    final normalizado = valor;
    if (normalizado == _busca) return;
    _debounceBusca?.cancel();
    _debounceBusca = Timer(_debounce, () {
      _busca = normalizado;
      notifyListeners();
    });
  }

  bool setDataInicio(DateTime? data) {
    final normalizado = data == null
        ? null
        : DateTime(data.year, data.month, data.day);
    if (_dataInicio == normalizado) return false;
    _dataInicio = normalizado;
    notifyListeners();
    return true;
  }

  bool setDataFim(DateTime? data) {
    final normalizado = data == null
        ? null
        : DateTime(data.year, data.month, data.day, 23, 59, 59);
    if (_dataFim == normalizado) return false;
    _dataFim = normalizado;
    notifyListeners();
    return true;
  }

  bool limparFiltros() {
    if (!temAlgumFiltro) return false;
    _filtroStatus = FiltroStatusNotif.todas;
    _filtroTipo = null;
    _busca = '';
    _dataInicio = null;
    _dataFim = null;
    _debounceBusca?.cancel();
    notifyListeners();
    return true;
  }

  @override
  void limpar() {
    // Para polling, zera badge, limpa histórico e filtros — evita
    // vazar notificações entre sessões/contas no mesmo device (Fase F2).
    _timer?.cancel();
    _timer = null;
    _debounceBusca?.cancel();
    _debounceBusca = null;
    _lista.clear();
    _naoLidas = 0;
    _loading = false;
    _erro = null;
    _filtroStatus = FiltroStatusNotif.todas;
    _filtroTipo = null;
    _busca = '';
    _dataInicio = null;
    _dataFim = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _debounceBusca?.cancel();
    super.dispose();
  }
}
