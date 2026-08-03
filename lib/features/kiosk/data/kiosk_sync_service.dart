import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'kiosk_api.dart';
import 'kiosk_face_store.dart';

class KioskSyncResult {
  const KioskSyncResult({
    required this.totalEquipe,
    required this.atualizados,
    required this.removidos,
  });

  final int totalEquipe;
  final int atualizados;
  final int removidos;
}

/// Sincroniza o roster de rostos habilitados do cliente pro SQLite local do
/// tablet. Não sincroniza embeddings (o pacote de terceiro não expõe o
/// vetor cru) — baixa a FOTO de referência e registra localmente, então
/// cada tablet roda sua própria detecção+embedding na hora do registro.
///
/// `faceVersion` (o `createdAt` da PessoaFace no backend) funciona como
/// cache-buster: só baixa de novo quem mudou desde o último sync.
class KioskSyncService {
  KioskSyncService(this._api, this._store);

  final KioskApi _api;
  final KioskFaceStore _store;

  // Sufixo .v2: a v1 gravava as fotos em getTemporaryDirectory (o SO podia
  // purgá-las e o reconhecimento morria em silêncio). Trocar a chave força
  // um re-sync completo pro diretório persistente.
  static const _kVersoesKey = 'alfa.kiosk.face_versions.v2';

  /// Diretório persistente das fotos de referência — application support,
  /// não temp: o SO não limpa sozinho, e o desprovisionamento apaga tudo.
  static Future<Directory> _dirFotos() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/kiosk_faces');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  static Future<String> fotoLocalPath(int funcionarioId) async {
    final dir = await _dirFotos();
    return '${dir.path}/kiosk_face_$funcionarioId.jpg';
  }

  Future<KioskSyncResult> sincronizar(String token) async {
    await _store.init();
    final equipe = await _api.equipe(token);
    final versoesConhecidas = await _lerVersoesConhecidas();
    final versoesNovas = <String, String>{};
    final dir = await _dirFotos();

    var atualizados = 0;
    for (final item in equipe) {
      final chave = item.funcionarioId.toString();
      versoesNovas[chave] = item.faceVersion;
      if (versoesConhecidas[chave] == item.faceVersion) {
        continue; // sem mudança, pula
      }

      final bytes = await _api.foto(token, item.funcionarioId);
      final file = File('${dir.path}/kiosk_face_$chave.jpg');
      await file.writeAsBytes(bytes, flush: true);
      await _store.registrar(
        funcionarioId: item.funcionarioId,
        imagePath: file.path,
        nome: item.nome,
      );
      atualizados++;
    }

    // Quem tinha rosto local e saiu do roster (desligado ou consentimento
    // revogado) — remove da base local pra não continuar reconhecendo.
    var removidos = 0;
    for (final chaveAntiga in versoesConhecidas.keys) {
      if (!versoesNovas.containsKey(chaveAntiga)) {
        await _store.remover(int.parse(chaveAntiga));
        removidos++;
      }
    }

    await _salvarVersoesConhecidas(versoesNovas);
    return KioskSyncResult(
      totalEquipe: equipe.length,
      atualizados: atualizados,
      removidos: removidos,
    );
  }

  /// Desprovisionamento: apaga rostos da base local, fotos de referência e
  /// o cache de versões. Chamar junto com `KioskStorage.clear()`.
  Future<void> limparDadosLocais() async {
    await _store.limparTudo();
    final dir = await _dirFotos();
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kVersoesKey);
  }

  Future<Map<String, String>> _lerVersoesConhecidas() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kVersoesKey);
    if (raw == null) return {};
    try {
      return Map<String, String>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> _salvarVersoesConhecidas(Map<String, String> versoes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kVersoesKey, jsonEncode(versoes));
  }
}
