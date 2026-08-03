import 'package:alfajornada_app/features/jornada/models/banco_horas.dart';
import 'package:alfajornada_app/features/jornada/models/batida_ponto.dart';
import 'package:alfajornada_app/features/jornada/models/ponto_pendente.dart';
import 'package:alfajornada_app/features/jornada/models/ponto_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BatidaRegistrada.fromJson', () {
    test('payload completo', () {
      final b = BatidaRegistrada.fromJson({
        'batidaId': 10,
        'funcionarioId': 3,
        'nome': 'Maria',
        'dataHora': '2026-08-03T08:00:00',
        'sentido': 'SAIDA',
        'mensagem': 'ok',
      });
      expect(b.batidaId, 10);
      expect(b.sentido, 'SAIDA');
      expect(b.dataHora, DateTime(2026, 8, 3, 8));
    });

    test('id como string numérica (drift de contrato) ainda parseia', () {
      final b = BatidaRegistrada.fromJson({
        'batidaId': '10',
        'dataHora': '2026-08-03T08:00:00',
      });
      expect(b.batidaId, 10);
      expect(b.nome, 'Colaborador');
      expect(b.sentido, 'ENTRADA');
    });

    test('campos obrigatórios ausentes lançam FormatException', () {
      expect(
        () => BatidaRegistrada.fromJson({'dataHora': '2026-08-03T08:00:00'}),
        throwsFormatException,
      );
      expect(
        () => BatidaRegistrada.fromJson({'batidaId': 1, 'dataHora': 'lixo'}),
        throwsFormatException,
      );
    });
  });

  group('PontoStatus.fromJson', () {
    test('payload completo', () {
      final s = PontoStatus.fromJson({
        'funcionarioId': 7,
        'nome': 'João',
        'data': '2026-08-03',
        'proximoSentido': 'SAIDA',
        'batidasHoje': 2,
        'marcacoesHoje': ['08:00', '12:00'],
        'minutosTrabalhadosHoje': 240,
        'horasTrabalhadasHoje': '04:00',
        'saldoBancoHorasMinutos': -30,
        'saldoBancoHoras': '-00:30',
      });
      expect(s.funcionarioId, 7);
      expect(s.proximaEhEntrada, isFalse);
      expect(s.marcacoesHoje, ['08:00', '12:00']);
      expect(s.saldoBancoHorasMinutos, -30);
    });

    test('defaults tolerantes com payload mínimo', () {
      final s = PontoStatus.fromJson({'funcionarioId': 1});
      expect(s.proximaEhEntrada, isTrue);
      expect(s.marcacoesHoje, isEmpty);
      expect(s.batidasHoje, 0);
      expect(s.saldoBancoHoras, '+00:00');
    });

    test('marcações com item não-string são filtradas sem quebrar', () {
      final s = PontoStatus.fromJson({
        'funcionarioId': 1,
        'marcacoesHoje': ['08:00', null, 12],
      });
      expect(s.marcacoesHoje, ['08:00']);
    });

    test('funcionarioId ausente lança FormatException', () {
      expect(() => PontoStatus.fromJson({}), throwsFormatException);
    });
  });

  group('PaginaBatidas.fromJson', () {
    test('página do Spring Data', () {
      final p = PaginaBatidas.fromJson({
        'content': [
          {'id': 1, 'dataHora': '2026-08-03T08:00:00', 'origem': 'MOBILE'},
          {'id': 2, 'dataHora': '2026-08-03T12:00:00'},
        ],
        'totalPages': 3,
        'number': 0,
        'last': false,
      });
      expect(p.content, hasLength(2));
      expect(p.content[1].origem, 'MANUAL');
      expect(p.last, isFalse);
    });

    test('content ausente vira lista vazia', () {
      final p = PaginaBatidas.fromJson({'totalPages': 1});
      expect(p.content, isEmpty);
      expect(p.last, isFalse);
    });
  });

  group('BancoHorasResumo.fromJson', () {
    test('saldo negativo com extrato', () {
      final b = BancoHorasResumo.fromJson({
        'saldoMinutos': -90,
        'saldoFormatado': '-01:30',
        'extrato': [
          {
            'data': '2026-07-31',
            'tipo': 'DEBITO',
            'origem': 'APURACAO',
            'minutosFormatado': '-01:30',
            'saldoAcumuladoFormatado': '-01:30',
          },
        ],
      });
      expect(b.saldoMinutos, -90);
      expect(b.extrato.single.tipo, 'DEBITO');
    });

    test('payload vazio não quebra', () {
      final b = BancoHorasResumo.fromJson({});
      expect(b.saldoMinutos, 0);
      expect(b.extrato, isEmpty);
    });
  });

  group('PontoPendente', () {
    test('round-trip toJson/fromJson preserva capturedAt e coordenadas', () {
      final original = PontoPendente(
        id: '123',
        capturedAt: DateTime(2026, 8, 3, 7, 58, 12),
        latitude: -20.33,
        longitude: -40.29,
        erro: 'Janela vencida',
      );
      final volta = PontoPendente.fromJson(original.toJson());
      expect(volta.id, '123');
      expect(volta.capturedAt, original.capturedAt);
      expect(volta.latitude, -20.33);
      expect(volta.longitude, -40.29);
      expect(volta.erro, 'Janela vencida');
    });
  });
}
