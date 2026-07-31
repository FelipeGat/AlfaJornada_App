import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../core/api/api_client.dart';
import '../../../core/log.dart';
import '../state/notificacoes_provider.dart';

class PushService {
  PushService();

  NotificacoesProvider? _notificacoes;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  String? _currentToken;
  bool _initialized = false;

  void attachNotificacoesProvider(NotificacoesProvider provider) {
    _notificacoes = provider;
  }

  bool get _firebaseAvailable => Firebase.apps.isNotEmpty;

  Future<void> init(ApiClient api) async {
    if (_initialized) return;
    if (!_firebaseAvailable) {
      logDebug('PushService: Firebase não inicializado — pulando.');
      return;
    }
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        logDebug('PushService: permissão negada.');
        return;
      }

      // iOS: FCM só consegue gerar token depois que APNs entrega o seu.
      // Requer Apple Developer pago + chave APNs no Firebase Console.
      if (Platform.isIOS) {
        final apns = await messaging.getAPNSToken();
        if (apns == null || apns.isEmpty) {
          logDebug('PushService: APNs token indisponível — push iOS não habilitado.');
          return;
        }
      }

      final token = await messaging.getToken();
      if (token == null || token.isEmpty) {
        logDebug('PushService: getToken retornou vazio.');
        return;
      }

      await _registrar(api, token);
      _currentToken = token;

      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = messaging.onTokenRefresh.listen((newToken) async {
        _currentToken = newToken;
        await _registrar(api, newToken);
      });

      _onMessageSub?.cancel();
      _onMessageSub = FirebaseMessaging.onMessage.listen((message) {
        _notificacoes?.carregarTudo();
      });

      _initialized = true;
    } catch (e) {
      logDebug('PushService.init falhou: $e');
    }
  }

  Future<void> logout(ApiClient api) async {
    if (!_firebaseAvailable) return;
    try {
      final token = _currentToken ?? await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        try {
          await api.raw.delete('/api/usuarios/me/device-tokens/$token');
        } catch (_) {}
      }
      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = null;
      await _onMessageSub?.cancel();
      _onMessageSub = null;
      try {
        await FirebaseMessaging.instance.deleteToken();
      } catch (_) {}
      _currentToken = null;
      _initialized = false;
    } catch (e) {
      logDebug('PushService.logout falhou: $e');
    }
  }

  Future<void> _registrar(ApiClient api, String token) async {
    try {
      await api.raw.post(
        '/api/usuarios/me/device-tokens',
        data: {'token': token, 'platform': Platform.isIOS ? 'ios' : 'android'},
      );
    } catch (e) {
      logDebug('PushService: falha ao registrar token: $e');
    }
  }
}
