import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';

/// Número-resumo de um produto, cacheado localmente no momento do login
/// (ex.: "423 alunos ativos") — usado pra dar um sinal de vida nos cards
/// do Hub de seleção sem precisar autenticar em todos os produtos de
/// uma vez. Sempre um dado real do último login, nunca inventado; a UI
/// mostra junto a data pra deixar claro que pode estar desatualizado.
class ProductStat {
  const ProductStat({
    required this.emoji,
    required this.label,
    required this.value,
    required this.updatedAt,
  });

  final String emoji;
  final String label;
  final int value;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'emoji': emoji,
        'label': label,
        'value': value,
        'updatedAt': updatedAt.toIso8601String(),
      };

  static ProductStat? fromJson(Map<String, dynamic> j) {
    final emoji = j['emoji'];
    final label = j['label'];
    final value = j['value'];
    final updatedAt = j['updatedAt'];
    if (emoji is! String || label is! String || value is! int || updatedAt is! String) {
      return null;
    }
    final parsed = DateTime.tryParse(updatedAt);
    if (parsed == null) return null;
    return ProductStat(emoji: emoji, label: label, value: value, updatedAt: parsed);
  }
}

class AuthStorage {
  static const _kToken = 'alfa.auth.token';
  static const _kProduct = 'alfa.auth.product';
  static const _kUserName = 'alfa.auth.user_name';
  static const _kPessoaId = 'alfa.auth.pessoa_id';
  static const _kUsuarioId = 'alfa.auth.usuario_id';
  static const _kPerfil = 'alfa.auth.perfil';

  /// Último produto logado com sucesso NESTE aparelho — sobrevive ao
  /// logout (não é limpo por `clear()`), diferente de `_kProduct` (sessão
  /// ativa). Usado só pra pular a tela de escolha de sistema pra quem já
  /// usou o app antes; o usuário sempre pode voltar pra ela manualmente.
  static const _kLastProduct = 'alfa.auth.last_product';

  /// Nome da empresa/cliente do último login bem-sucedido em cada produto
  /// (chave por produto) — usado só pra saudação pós-seleção, nunca no
  /// Hub (onde ainda não sabemos qual produto o usuário vai abrir).
  /// Sobrevive a `clear()`, igual `_kLastProduct`.
  static const _kCompanyNamePrefix = 'alfa.auth.company_name.';

  /// Último número-resumo visto por produto (ex.: alunos ativos) — ver
  /// [ProductStat]. Também sobrevive a `clear()`.
  static const _kStatPrefix = 'alfa.auth.stat.';

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

  Future<void> saveProduct(AlfaProduct product) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProduct, product.storageKey);
  }

  Future<AlfaProduct?> readProduct() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_kProduct);
    if (key == null) return null;
    if (key == 'escola') return AlfaProduct.jornada;
    return AlfaProductX.fromStorageKey(key);
  }

  Future<void> saveLastProduct(AlfaProduct product) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastProduct, product.storageKey);
  }

  Future<AlfaProduct?> readLastProduct() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_kLastProduct);
    if (key == null) return null;
    return AlfaProductX.fromStorageKey(key);
  }

  Future<void> saveCompanyName(AlfaProduct product, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_kCompanyNamePrefix${product.storageKey}', name);
  }

  Future<String?> readCompanyName(AlfaProduct product) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_kCompanyNamePrefix${product.storageKey}');
  }

  Future<void> saveProductStat(AlfaProduct product, ProductStat stat) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_kStatPrefix${product.storageKey}',
      jsonEncode(stat.toJson()),
    );
  }

  Future<ProductStat?> readProductStat(AlfaProduct product) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_kStatPrefix${product.storageKey}');
    if (raw == null) return null;
    try {
      return ProductStat.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserName, name);
  }

  Future<String?> readUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUserName);
  }

  Future<void> savePessoaId(int? pessoaId) async {
    final prefs = await SharedPreferences.getInstance();
    if (pessoaId == null) {
      await prefs.remove(_kPessoaId);
    } else {
      await prefs.setInt(_kPessoaId, pessoaId);
    }
  }

  Future<int?> readPessoaId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kPessoaId);
  }

  Future<void> saveUsuarioId(int? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_kUsuarioId);
    } else {
      await prefs.setInt(_kUsuarioId, id);
    }
  }

  Future<int?> readUsuarioId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kUsuarioId);
  }

  Future<void> savePerfil(String? perfil) async {
    final prefs = await SharedPreferences.getInstance();
    if (perfil == null || perfil.isEmpty) {
      await prefs.remove(_kPerfil);
    } else {
      await prefs.setString(_kPerfil, perfil);
    }
  }

  Future<String?> readPerfil() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kPerfil);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kProduct);
    await prefs.remove(_kUserName);
    await prefs.remove(_kPessoaId);
    await prefs.remove(_kUsuarioId);
    await prefs.remove(_kPerfil);
    if (!kIsWeb) {
      await _secure.delete(key: _kToken);
    }
  }
}
