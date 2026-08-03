import 'package:alfajornada_app/core/api/humanize_dio.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _dio({
  DioExceptionType type = DioExceptionType.badResponse,
  int? status,
  Object? body,
}) {
  final req = RequestOptions(path: '/x');
  return DioException(
    requestOptions: req,
    type: type,
    response: status == null
        ? null
        : Response<dynamic>(requestOptions: req, statusCode: status, data: body),
  );
}

void main() {
  test('erros de conexão (timeout/connection/receive) viram mensagem de rede', () {
    for (final t in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.connectionError,
      DioExceptionType.receiveTimeout,
    ]) {
      expect(
        humanizeDio(_dio(type: t), recurso: 'x'),
        'Não foi possível conectar ao servidor.',
      );
    }
  });

  test('override por status tem prioridade sobre tudo', () {
    expect(
      humanizeDio(
        _dio(status: 401),
        recurso: 'x',
        overrides: {401: 'custom'},
      ),
      'custom',
    );
  });

  test('401 e 403', () {
    expect(humanizeDio(_dio(status: 401), recurso: 'x'),
        'Sessão expirada. Saia e entre de novo.');
    expect(humanizeDio(_dio(status: 403), recurso: 'banco de horas'),
        'Sem permissão pra acessar banco de horas.');
  });

  test('mensagem formatada do backend tem prioridade sobre fallback', () {
    expect(
      humanizeDio(_dio(status: 422, body: {'error': 'Janela vencida'}), recurso: 'x'),
      'Janela vencida',
    );
    expect(
      humanizeDio(_dio(status: 400, body: {'message': 'Campo obrigatório'}), recurso: 'x'),
      'Campo obrigatório',
    );
  });

  test('5xx sem mensagem do backend', () {
    expect(humanizeDio(_dio(status: 500), recurso: 'x'),
        'Erro interno do servidor. Tente de novo em instantes.');
    expect(humanizeDio(_dio(status: 503, body: 'html'), recurso: 'x'),
        'Erro interno do servidor. Tente de novo em instantes.');
  });

  test('fallback com e sem status', () {
    expect(humanizeDio(_dio(status: 418), recurso: 'x'), 'Erro ao carregar (418).');
    expect(humanizeDio(_dio(type: DioExceptionType.unknown), recurso: 'x'),
        'Erro ao carregar (sem resposta).');
  });
}
