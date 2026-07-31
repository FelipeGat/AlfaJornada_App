import 'package:geolocator/geolocator.dart';

/// Localização best-effort pra marcação de ponto — GPS é sempre opcional
/// (o backend aceita `latitude`/`longitude` nulos), então qualquer falha
/// aqui (permissão negada, serviço desligado, timeout) só devolve `null`
/// em vez de bloquear o colaborador de bater o ponto.
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
