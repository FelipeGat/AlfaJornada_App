import 'dart:async';
import 'dart:convert';

import 'package:alfajornada_app/features/jornada/models/banco_horas.dart';
import 'package:alfajornada_app/features/jornada/models/batida_ponto.dart';
import 'package:alfajornada_app/features/jornada/models/humor_historico_item.dart';
import 'package:alfajornada_app/features/jornada/models/ponto_status.dart';
import 'package:alfajornada_app/features/jornada/services/humor_service.dart';
import 'package:alfajornada_app/features/jornada/services/jornada_service.dart';
import 'package:alfajornada_app/features/jornada/state/jornada_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kChaveFila = 'jornada.ponto.fila_offline';

PontoStatus _statusFake() => PontoStatus.fromJson({'funcionarioId': 1});

BatidaRegistrada _batidaFake() => BatidaRegistrada.fromJson({
      'batidaId': 1,
      'dataHora': '2026-08-03T08:00:00',
    });

typedef _RegistrarFn = Future<BatidaRegistrada> Function({
  double? latitude,
  double? longitude,
  DateTime? dataHora,
});

class _FakeJornadaService implements JornadaService {
  _RegistrarFn? onRegistrarPonto;

  @override
  Future<BatidaRegistrada> registrarPonto({
    double? latitude,
    double? longitude,
    DateTime? dataHora,
  }) {
    return onRegistrarPonto!(
        latitude: latitude, longitude: longitude, dataHora: dataHora);
  }

  @override
  Future<PontoStatus> buscarMeuStatus() async => _statusFake();

  @override
  Future<PaginaBatidas> buscarHistorico({int page = 0, int size = 20}) async =>
      const PaginaBatidas(content: [], totalPages: 1, number: 0, last: true);

  @override
  Future<BancoHorasResumo> buscarBancoHoras() async =>
      const BancoHorasResumo(saldoMinutos: 0, saldoFormatado: '+00:00', extrato: []);
}

class _FakeHumorService implements HumorService {
  @override
  Future<MeuHumorHoje> meuHumorHoje() async => const MeuHumorHoje();

  @override
  Future<void> registrar(int nota, {String? motivo}) async {}

  @override
  Future<List<HumorHistoricoItem>> meuHistorico() async => const [];
}

String _pendenteJson(String id, DateTime capturedAt) => jsonEncode({
      'id': id,
      'capturedAt': capturedAt.toIso8601String(),
      'latitude': null,
      'longitude': null,
      'erro': null,
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeJornadaService svc;

  JornadaProvider criarProvider() =>
      JornadaProvider(svc, _FakeHumorService());

  setUp(() {
    svc = _FakeJornadaService();
    SharedPreferences.setMockInitialValues({});
  });

  group('registrarPonto', () {
    test('falha de conexão enfileira a marcação e persiste no storage', () async {
      svc.onRegistrarPonto = ({latitude, longitude, dataHora}) async =>
          throw JornadaServiceException('sem rede', isConnectionError: true);
      final prov = criarProvider();
      await pumpEventQueue();

      final r = await prov.registrarPonto(latitude: -20.3, longitude: -40.2);

      expect(r.enfileirado, isTrue);
      expect(r.erro, isNull);
      expect(prov.temPendentes, isTrue);
      expect(prov.registrando, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList(_kChaveFila), hasLength(1));
    });

    test('erro de negócio NÃO enfileira e devolve o erro', () async {
      svc.onRegistrarPonto = ({latitude, longitude, dataHora}) async =>
          throw JornadaServiceException('Janela vencida');
      final prov = criarProvider();
      await pumpEventQueue();

      final r = await prov.registrarPonto();

      expect(r.enfileirado, isFalse);
      expect(r.erro?.message, 'Janela vencida');
      expect(prov.temPendentes, isFalse);
    });

    test('segunda chamada durante um registro em andamento é ignorada (double-tap)',
        () async {
      final completer = Completer<BatidaRegistrada>();
      var chamadas = 0;
      svc.onRegistrarPonto = ({latitude, longitude, dataHora}) {
        chamadas++;
        return completer.future;
      };
      final prov = criarProvider();
      await pumpEventQueue();

      final primeira = prov.registrarPonto();
      final segunda = await prov.registrarPonto();

      expect(segunda.jaEmAndamento, isTrue);
      expect(segunda.sucesso, isFalse);
      expect(chamadas, 1);

      completer.complete(_batidaFake());
      final r1 = await primeira;
      expect(r1.sucesso, isTrue);
      expect(prov.registrando, isFalse);
    });
  });

  group('sincronizarFila', () {
    test('envia em ordem de captura e limpa fila + storage após sucesso', () async {
      final antiga = DateTime(2026, 8, 3, 8, 0);
      final nova = DateTime(2026, 8, 3, 12, 0);
      // Semeia fora de ordem de propósito.
      SharedPreferences.setMockInitialValues({
        _kChaveFila: [_pendenteJson('b', nova), _pendenteJson('a', antiga)],
      });
      final recebidas = <DateTime?>[];
      svc.onRegistrarPonto = ({latitude, longitude, dataHora}) async {
        recebidas.add(dataHora);
        return _batidaFake();
      };
      final prov = criarProvider();
      await pumpEventQueue();
      expect(prov.filaPendente, hasLength(2));

      await prov.sincronizarFila();

      expect(recebidas, [antiga, nova]);
      expect(prov.temPendentes, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList(_kChaveFila), isEmpty);
    });

    test('erro de negócio marca o item, mantém na fila e segue pros próximos',
        () async {
      final antiga = DateTime(2026, 8, 3, 8, 0);
      final nova = DateTime(2026, 8, 3, 12, 0);
      SharedPreferences.setMockInitialValues({
        _kChaveFila: [_pendenteJson('a', antiga), _pendenteJson('b', nova)],
      });
      svc.onRegistrarPonto = ({latitude, longitude, dataHora}) async {
        if (dataHora == antiga) {
          throw JornadaServiceException('Período fechado');
        }
        return _batidaFake();
      };
      final prov = criarProvider();
      await pumpEventQueue();

      await prov.sincronizarFila();

      expect(prov.filaPendente, hasLength(1));
      expect(prov.filaPendente.single.id, 'a');
      expect(prov.filaPendente.single.erro, 'Período fechado');
    });

    test('erro de conexão para a sincronização sem perder nenhum item', () async {
      SharedPreferences.setMockInitialValues({
        _kChaveFila: [
          _pendenteJson('a', DateTime(2026, 8, 3, 8)),
          _pendenteJson('b', DateTime(2026, 8, 3, 12)),
        ],
      });
      svc.onRegistrarPonto = ({latitude, longitude, dataHora}) async =>
          throw JornadaServiceException('sem rede', isConnectionError: true);
      final prov = criarProvider();
      await pumpEventQueue();

      await prov.sincronizarFila();

      expect(prov.filaPendente, hasLength(2));
      expect(prov.sincronizando, isFalse);
    });

    test('exceção inesperada não deixa a fila travada em "sincronizando"',
        () async {
      SharedPreferences.setMockInitialValues({
        _kChaveFila: [_pendenteJson('a', DateTime(2026, 8, 3, 8))],
      });
      svc.onRegistrarPonto =
          ({latitude, longitude, dataHora}) async => throw StateError('boom');
      final prov = criarProvider();
      await pumpEventQueue();

      await expectLater(prov.sincronizarFila(), throwsStateError);
      expect(prov.sincronizando, isFalse);

      // Recuperação: com o serviço saudável, a mesma fila sincroniza.
      svc.onRegistrarPonto =
          ({latitude, longitude, dataHora}) async => _batidaFake();
      await prov.sincronizarFila();
      expect(prov.temPendentes, isFalse);
    });

    test('logout (limpar) preserva a fila offline', () async {
      SharedPreferences.setMockInitialValues({
        _kChaveFila: [_pendenteJson('a', DateTime(2026, 8, 3, 8))],
      });
      final prov = criarProvider();
      await pumpEventQueue();

      prov.limpar();

      expect(prov.temPendentes, isTrue);
    });
  });
}
