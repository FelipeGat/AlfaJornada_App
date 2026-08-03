import 'dart:convert';
import 'dart:typed_data';

import 'package:alfajornada_app/core/api/api_client.dart';
import 'package:alfajornada_app/core/storage/auth_storage.dart';
import 'package:alfajornada_app/features/auth/services/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Adapter fake do Dio — roteia cada request pro handler do teste, sem
/// tocar rede.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      handler(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Map<String, dynamic> body, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

ResponseBody _html(String body, {int status = 200}) => ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: ['text/html'],
      },
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthStorage storage;
  late ApiClient api;
  late AuthService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    storage = AuthStorage();
    api = ApiClient(storage);
    service = AuthService(api, storage);
  });

  void responder(ResponseBody Function(RequestOptions) handler) {
    api.raw.httpClientAdapter = _FakeAdapter(handler);
  }

  Future<AuthResult> login() => service.login(
        product: AlfaProduct.jornada,
        email: 'maria@empresa.com',
        password: 'senha123',
      );

  test('sucesso em 2 fases: token inicial + selecionar-cliente troca pelo final',
      () async {
    responder((o) {
      if (o.path.contains('/api/auth/login')) {
        return _json({
          'token': 'token-inicial',
          'nome': 'Maria',
          'id': 7,
          'perfil': 'colaborador',
          'clientes': [
            {'id': 5, 'nome': 'Empresa X'},
          ],
        });
      }
      if (o.path.contains('/api/auth/selecionar-cliente')) {
        return _json({'accessToken': 'token-final'});
      }
      return _json({}, status: 404);
    });

    final r = await login();

    expect(r.token, 'token-final');
    expect(r.perfil, 'colaborador');
    expect(r.senhaProvisoria, isFalse);
    expect(await storage.readToken(), 'token-final');
    expect(await storage.readPerfil(), 'colaborador');
  });

  test('resposta 200 sem token lança AuthException clara', () async {
    responder((o) => _json({'nome': 'Maria'}));
    expect(
      login,
      throwsA(isA<AuthException>()
          .having((e) => e.message, 'message', 'Resposta de login sem token.')),
    );
  });

  test('200 não-JSON (captive portal devolvendo HTML) vira erro amigável, não TypeError',
      () async {
    responder((o) => _html('<html>Wi-Fi do hotel</html>'));
    expect(
      login,
      throwsA(isA<AuthException>().having(
        (e) => e.message,
        'message',
        contains('Resposta inesperada do servidor'),
      )),
    );
  });

  test('mais de uma empresa orienta a falar com o RH', () async {
    responder((o) => _json({
          'token': 't',
          'clientes': [
            {'id': 1},
            {'id': 2},
          ],
        }));
    expect(
      login,
      throwsA(isA<AuthException>().having(
        (e) => e.message,
        'message',
        contains('mais de uma empresa'),
      )),
    );
  });

  test('falha no selecionar-cliente vira erro de login, não estado meio-logado',
      () async {
    responder((o) {
      if (o.path.contains('/api/auth/login')) {
        return _json({
          'token': 'token-inicial',
          'clientes': [
            {'id': 5},
          ],
        });
      }
      return _json({'error': 'boom'}, status: 500);
    });
    expect(
      login,
      throwsA(isA<AuthException>().having(
        (e) => e.message,
        'message',
        contains('Não foi possível concluir o login'),
      )),
    );
  });

  test('401 do backend vira AuthException (credencial inválida)', () async {
    responder((o) => _json({'error': 'bad credentials'}, status: 401));
    expect(login, throwsA(isA<AuthException>()));
  });

  test('senha provisória propaga no resultado', () async {
    responder((o) {
      if (o.path.contains('/api/auth/login')) {
        return _json({
          'token': 't',
          'senhaProvisoria': true,
          'clientes': [
            {'id': 5},
          ],
        });
      }
      return _json({'accessToken': 'final'});
    });
    final r = await login();
    expect(r.senhaProvisoria, isTrue);
  });
}
