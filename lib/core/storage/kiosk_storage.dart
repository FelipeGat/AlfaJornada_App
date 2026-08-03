import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Credenciais do Modo Totem, guardadas à parte de [AuthStorage] — o totem
/// não representa uma sessão de usuário, é um terminal configurado uma vez.
/// Mantido separado de propósito: `AuthStorage.clear()` roda no logout de
/// qualquer sessão de usuário eventualmente aberta no mesmo tablet, e não
/// deveria arrastar junto a configuração do terminal.
class KioskStorage {
  static const _kToken = 'alfa.kiosk.token';
  static const _kNome = 'alfa.kiosk.nome';
  static const _kClienteNome = 'alfa.kiosk.cliente_nome';

  final _secure = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kToken, token);
    } else {
      await _secure.write(key: _kToken, value: token);
    }
  }

  Future<String?> readToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kToken);
    }
    return _secure.read(key: _kToken);
  }

  Future<void> saveTerminalInfo({required String nome}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNome, nome);
  }

  Future<String?> readTerminalNome() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kNome);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kNome);
    await prefs.remove(_kClienteNome);
    if (kIsWeb) {
      await prefs.remove(_kToken);
    } else {
      await _secure.delete(key: _kToken);
    }
  }
}
