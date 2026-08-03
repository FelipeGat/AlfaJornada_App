import 'package:face_verification/face_verification.dart';

/// Wrapper fino sobre o pacote `face_verification` — isola o resto do app
/// da API de terceiro (detecção ML Kit + embedding FaceNet TFLite + base
/// SQLite local, tudo dentro do pacote). Cada tablet mantém sua própria
/// base: não há sincronização de embeddings entre terminais, só de fotos
/// (ver [KioskSyncService]) — cada aparelho re-registra localmente.
class KioskFaceStore {
  bool _inicializado = false;

  Future<void> init() async {
    if (_inicializado) return;
    await FaceVerification.instance.init();
    _inicializado = true;
  }

  /// Registra/atualiza o rosto de um funcionário a partir de uma foto local
  /// (baixada do backend). `id` é o próprio funcionarioId — assim o match
  /// de [identificar] já devolve o identificador que o backend espera.
  Future<void> registrar({
    required int funcionarioId,
    required String imagePath,
    required String nome,
  }) {
    return FaceVerification.instance.registerFromImagePath(
      id: funcionarioId.toString(),
      imagePath: imagePath,
      imageId: 'ref',
      name: nome,
      replace: true,
    );
  }

  Future<void> remover(int funcionarioId) {
    return FaceVerification.instance.deleteUserFaces(funcionarioId.toString());
  }

  /// Apaga TODOS os rostos da base local — usado no desprovisionamento do
  /// terminal (LGPD: biometria não fica pra trás quando o tablet deixa de
  /// ser totem).
  Future<void> limparTudo() async {
    await init();
    final ids = await registrados();
    for (final id in ids) {
      await FaceVerification.instance.deleteUserFaces(id);
    }
  }

  Future<List<String>> registrados() {
    return FaceVerification.instance.getAllRegisteredUsers();
  }

  /// Roda a detecção+matching contra a base local. Retorna os funcionarioIds
  /// (como String) que bateram acima do threshold — 0 é "não reconheceu
  /// ninguém", >1 é ambíguo e nunca deve autoconfirmar sozinho.
  Future<List<String>> identificar(
    String imagePath, {
    double threshold = 0.62,
  }) {
    return FaceVerification.instance.identifyAllUsersFromImagePath(
      imagePath: imagePath,
      threshold: threshold,
    );
  }
}
