import 'package:alfajornada_app/features/jornada/utils/jornada_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('rotuloMarcacaoJornada', () {
    test('ciclo de 4 marcações (entrada/almoço/volta/saída)', () {
      expect(rotuloMarcacaoJornada(0), 'Entrada');
      expect(rotuloMarcacaoJornada(1), 'Saída (almoço)');
      expect(rotuloMarcacaoJornada(2), 'Volta (almoço)');
      expect(rotuloMarcacaoJornada(3), 'Saída');
    });

    test('quinta marcação em diante repete o ciclo', () {
      expect(rotuloMarcacaoJornada(4), 'Entrada');
      expect(rotuloMarcacaoJornada(5), 'Saída (almoço)');
      expect(rotuloMarcacaoJornada(7), 'Saída');
    });
  });

  group('dataExtensoJornada', () {
    test('domingo (weekday=7) não estoura o índice — clássico off-by-one', () {
      // 02/08/2026 é domingo.
      expect(dataExtensoJornada(DateTime(2026, 8, 2)), 'Domingo, 2 de agosto');
    });

    test('segunda e sábado', () {
      // 03/08/2026 segunda; 01/08/2026 sábado.
      expect(dataExtensoJornada(DateTime(2026, 8, 3)), 'Segunda-feira, 3 de agosto');
      expect(dataExtensoJornada(DateTime(2026, 8, 1)), 'Sábado, 1 de agosto');
    });

    test('meses de borda', () {
      expect(dataExtensoJornada(DateTime(2026, 1, 1)), 'Quinta-feira, 1 de janeiro');
      expect(dataExtensoJornada(DateTime(2026, 12, 31)), 'Quinta-feira, 31 de dezembro');
    });
  });

  group('dataCurtaJornada / duasCasasJornada', () {
    test('zero à esquerda', () {
      expect(dataCurtaJornada(DateTime(2026, 7, 26)), '26/07');
      expect(dataCurtaJornada(DateTime(2026, 11, 3)), '03/11');
      expect(duasCasasJornada(0), '00');
      expect(duasCasasJornada(9), '09');
      expect(duasCasasJornada(10), '10');
    });
  });
}
