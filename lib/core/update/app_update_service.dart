import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../api/api_client.dart';
import '../log.dart';

/// Info que veio do endpoint `GET /api/app/version` do AlfaGym backend.
/// Mantém o mesmo shape do gestor_alfa_mobile pra o dialog e o resto do
/// fluxo poderem ser copiados 1:1 entre os apps.
class AppVersionManifest {
  final String versao;
  final int? build;
  final String url;
  final String changelog;
  final bool obrigatorio;
  final String? minVersaoIos;
  final DateTime? publicadoEm;

  /// SHA-256 (hex) do APK, quando o backend publica — verificado após o
  /// download antes de disparar o instalador.
  final String? sha256;

  const AppVersionManifest({
    required this.versao,
    required this.url,
    this.build,
    this.changelog = '',
    this.obrigatorio = false,
    this.minVersaoIos,
    this.publicadoEm,
    this.sha256,
  });

  factory AppVersionManifest.fromJson(Map<String, dynamic> j) =>
      AppVersionManifest(
        versao: j['versao']?.toString() ?? '0.0.0',
        build: (j['build'] as num?)?.toInt(),
        url: j['url']?.toString() ?? '',
        changelog: j['changelog']?.toString() ?? '',
        obrigatorio: j['obrigatorio'] == true,
        minVersaoIos: j['min_versao_ios']?.toString(),
        publicadoEm: j['publicado_em'] != null
            ? DateTime.tryParse(j['publicado_em'].toString())
            : null,
        sha256: j['sha256']?.toString(),
      );
}

class UpdateCheckResult {
  final AppVersionManifest manifest;
  final String versaoInstalada;
  final bool obrigatorio;

  const UpdateCheckResult({
    required this.manifest,
    required this.versaoInstalada,
    required this.obrigatorio,
  });
}

class AppUpdateResult {
  final bool sucesso;
  final String? erro;
  const AppUpdateResult({required this.sucesso, this.erro});
}

/// Coordena o auto-update do AlfaMobi.
///
/// - [checar] consulta `GET /api/app/version?produto=<academia|condominio>`
///   no AlfaGym (VPS 187.127.2.226). O backend guarda um manifest por
///   produto (`apps/alfamobi-<produto>-latest.json` no MinIO) mas, desde
///   17/07/2026, sempre devolve o de MAIOR semver+build entre todos os
///   canais publicados — o binário é único (mesmo repo, todas as
///   features), então a versão mais nova publicada por qualquer time
///   vale pra todo mundo. `produto` só desempata em caso de versões
///   idênticas entre canais.
/// - [baixarEInstalar] no Android baixa o APK pra pasta temporária e
///   abre o installer nativo. No iOS retorna erro (Apple não permite
///   instalação fora da App Store/TestFlight).
class AppUpdateService {
  /// Base fixa: o manifest sempre mora no AlfaGym, mesmo que o usuário
  /// atual esteja usando AlfaControl ou AlfaJornada — só o canal (query
  /// param `produto`) muda.
  static final String _baseUrl =
      ApiEnvironment.baseUrlFor(AlfaProduct.jornada);

  /// [produto] decide qual canal de manifest consultar no servidor
  /// (`?produto=academia|condominio|jornada`). `null` cai no canal padrão
  /// (`academia`, por retrocompatibilidade com versões antigas do app).
  /// Desde 17/07/2026 o backend agrega os canais e devolve sempre o de
  /// maior semver+build entre eles — `produto` hoje só desempata em caso
  /// de versões idênticas.
  Future<UpdateCheckResult?> checar({AlfaProduct? produto}) async {
    if (kIsWeb) return null;
    try {
      final dio = Dio(BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ));
      final r = await dio.get<dynamic>(
        '/api/app/version',
        queryParameters:
            produto != null ? {'produto': produto.storageKey} : null,
      );
      // 204 = nenhum canal tem manifest publicado. Trata como "atualizado".
      if (r.statusCode == 204 || r.data == null) return null;
      final raw = r.data is Map ? (r.data as Map)['data'] : null;
      if (raw is! Map) return null;
      final manifest =
          AppVersionManifest.fromJson(Map<String, dynamic>.from(raw));

      final info = await PackageInfo.fromPlatform();
      final versaoLocal = info.version;

      // iOS não consegue baixar/instalar IPA fora da App Store/TestFlight.
      // Só avisa quando o manifest declara `min_versao_ios` e a versão
      // instalada é anterior — pra sinalizar que a versão atual está
      // desatualizada e o suporte precisa distribuir a nova.
      if (Platform.isIOS) {
        final min = manifest.minVersaoIos;
        if (min != null && _compararSemver(versaoLocal, min) < 0) {
          return UpdateCheckResult(
            manifest: manifest,
            versaoInstalada: versaoLocal,
            obrigatorio: manifest.obrigatorio,
          );
        }
        return null;
      }

      final cmp = _compararSemver(versaoLocal, manifest.versao);
      final buildLocal = int.tryParse(info.buildNumber) ?? 0;
      final buildRemoto = manifest.build ?? 0;
      // Empate no semver + build maior no remoto = hotfix; conta como update.
      final temUpdate = cmp < 0 || (cmp == 0 && buildRemoto > buildLocal);
      if (!temUpdate) return null;

      return UpdateCheckResult(
        manifest: manifest,
        versaoInstalada: versaoLocal,
        obrigatorio: manifest.obrigatorio,
      );
    } catch (e) {
      logDebug('[AppUpdate] checar erro: $e');
      return null;
    }
  }

  Future<AppUpdateResult> baixarEInstalar(
    AppVersionManifest m, {
    void Function(int recebidos, int total)? onProgress,
  }) async {
    if (Platform.isIOS) {
      return const AppUpdateResult(
        sucesso: false,
        erro:
            'No iPhone/iPad a atualização é distribuída pela loja ou pelo suporte. '
            'Aguarde a próxima versão ficar disponível.',
      );
    }
    if (!Platform.isAndroid) {
      return const AppUpdateResult(
        sucesso: false,
        erro: 'Instalação direta não suportada nesta plataforma.',
      );
    }
    // O APK instala com REQUEST_INSTALL_PACKAGES — a URL precisa ser
    // HTTPS e de host nosso; um manifest adulterado não pode apontar
    // pra qualquer lugar.
    if (!_urlConfiavel(m.url)) {
      return const AppUpdateResult(
        sucesso: false,
        erro: 'O endereço de download da atualização não é reconhecido. '
            'Fale com o suporte.',
      );
    }
    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/alfajornada-${m.versao}.apk';
      final file = File(path);
      if (file.existsSync()) file.deleteSync();

      // Dio "cru" — a URL vem completa do manifest e não passa pelo
      // baseUrl/interceptors do ApiClient (que troca de produto).
      final dio = Dio();
      final response = await dio.download(
        m.url,
        path,
        onReceiveProgress: onProgress,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      // Conexão instável pode cortar o download no meio sem o Dio
      // detectar como erro — o Android só acusa "pacote inválido" na
      // hora de instalar, uma mensagem genérica que confunde o usuário.
      // Comparar o tamanho baixado com o Content-Length pega isso antes.
      final tamanhoEsperado =
          int.tryParse(response.headers.value('content-length') ?? '');
      final tamanhoBaixado = await file.length();
      if (tamanhoBaixado == 0 ||
          (tamanhoEsperado != null && tamanhoBaixado < tamanhoEsperado)) {
        await file.delete();
        return const AppUpdateResult(
          sucesso: false,
          erro:
              'O download ficou incompleto (conexão instável). Tente de novo, '
              'de preferência com Wi-Fi.',
        );
      }

      // Integridade: quando o manifest publica o SHA-256, o hash do
      // arquivo baixado precisa bater antes de abrir o instalador.
      final esperado = m.sha256?.trim().toLowerCase();
      if (esperado != null && esperado.isNotEmpty) {
        final digest = await sha256.bind(file.openRead()).first;
        if (digest.toString() != esperado) {
          await file.delete();
          return const AppUpdateResult(
            sucesso: false,
            erro: 'O arquivo baixado falhou na verificação de integridade. '
                'Tente novamente.',
          );
        }
      }

      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done) {
        return AppUpdateResult(
          sucesso: false,
          erro:
              'Não foi possível abrir o instalador (${result.message}). '
              'Habilite "Instalar apps desconhecidos" nas configurações do celular.',
        );
      }
      return const AppUpdateResult(sucesso: true);
    } catch (e) {
      return AppUpdateResult(sucesso: false, erro: 'Erro no download: $e');
    }
  }

  /// URL aceitável pra download de APK: HTTPS num host da Alfa.
  static bool _urlConfiavel(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https') return false;
    final host = uri.host.toLowerCase();
    return host == 'alfasolucoes.cloud' || host.endsWith('.alfasolucoes.cloud');
  }

  /// Compara duas versões `X.Y.Z` — retorna -1, 0 ou 1.
  int _compararSemver(String a, String b) {
    List<int> parse(String s) => s
        .split('.')
        .map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
    final va = parse(a);
    final vb = parse(b);
    final maxLen = va.length > vb.length ? va.length : vb.length;
    for (int i = 0; i < maxLen; i++) {
      final ai = i < va.length ? va[i] : 0;
      final bi = i < vb.length ? vb[i] : 0;
      if (ai < bi) return -1;
      if (ai > bi) return 1;
    }
    return 0;
  }
}
