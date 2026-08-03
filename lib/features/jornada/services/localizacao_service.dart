import 'package:geolocator/geolocator.dart';

/// Localização best-effort pra marcação de ponto — qualquer falha aqui
/// (permissão negada, serviço desligado, timeout) devolve `null` em vez
/// de travar o fluxo. Atenção: o backend EXIGE coordenada na batida
/// mobile (auditoria) e recusa com mensagem própria quando ela falta —
/// deixamos o servidor dar essa resposta, que já orienta o colaborador.
Future<Position?> obterLocalizacaoAtual() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    if (permissao == LocationPermission.denied ||
        permissao == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 5),
      ),
    );
  } catch (_) {
    return null;
  }
}
