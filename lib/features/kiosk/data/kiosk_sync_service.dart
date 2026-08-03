import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'kiosk_api.dart';
import 'kiosk_face_store.dart';

class KioskSyncResult {
  const KioskSyncResult({required this.totalEquipe, required this.atualizados, required this.removidos});

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

  static const _kVersoesKey = 'alfa.kiosk.face_versions';

  Future<KioskSyncResult> sincronizar(String token) async {
    await _store.init();
    final equipe = await _api.equipe(token);
    final versoesConhecidas = await _lerVersoesConhecidas();
    final versoesNovas = <String, String>{};
    final dir = await getTemporaryDirectory();

    var atualizados = 0;
    for (final item in equipe) {
      final chave = item.funcionarioId.toString();
      versoesNovas[chave] = item.faceVersion;
      if (versoesConhecidas[chave] == item.faceVersion) continue; // sem mudança, pula

      final bytes = await _api.foto(token, item.funcionarioId);
      final file = File('${dir.path}/kiosk_face_$chave.jpg');
      await file.writeAsBytes(bytes, flush: true);
      await _store.registrar(funcionarioId: item.funcionarioId, imagePath: file.path, nome: item.nome);
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
    return KioskSyncResult(totalEquipe: equipe.length, atualizados: atualizados, removidos: removidos);
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
