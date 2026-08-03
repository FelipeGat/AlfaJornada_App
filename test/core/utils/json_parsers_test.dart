import 'package:alfajornada_app/core/utils/json_parsers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('asInt', () {
    test('aceita int, num e string numérica', () {
      expect(asInt(42), 42);
      expect(asInt(3.9), 3);
      expect(asInt('42'), 42);
    });

    test('devolve null pra null, string vazia e lixo', () {
      expect(asInt(null), isNull);
      expect(asInt(''), isNull);
      expect(asInt('abc'), isNull);
      expect(asInt('12.5'), isNull);
    });
  });

  group('asDouble', () {
    test('aceita num e string numérica', () {
      expect(asDouble(1.5), 1.5);
      expect(asDouble(2), 2.0);
      expect(asDouble('1.5'), 1.5);
    });

    test('devolve null pra null e lixo', () {
      expect(asDouble(null), isNull);
      expect(asDouble('x'), isNull);
    });
  });

  group('asString', () {
    test('string vazia vira null (convenção do projeto)', () {
      expect(asString('oi'), 'oi');
      expect(asString(''), isNull);
      expect(asString(null), isNull);
      expect(asString(42), isNull);
    });
  });

  group('asDate', () {
    test('UTC converte pra local preservando o instante', () {
      final d = asDate('2026-01-15T10:00:00Z');
      expect(d, isNotNull);
      expect(d!.isUtc, isFalse);
      expect(d.toUtc(), DateTime.utc(2026, 1, 15, 10));
    });

    test('sem offset fica como veio (naive local)', () {
      final d = asDate('2026-01-15T10:00:00');
      expect(d, DateTime(2026, 1, 15, 10));
    });

    test('devolve null pra não-string, vazio e formato inválido', () {
      expect(asDate(null), isNull);
      expect(asDate(''), isNull);
      expect(asDate(20260115), isNull);
      expect(asDate('ontem'), isNull);
    });
  });
}
