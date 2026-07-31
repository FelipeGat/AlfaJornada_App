import '../api/api_client.dart';

/// Converte a `foto` que o backend devolve (path S3/MinIO cru, ou URL
/// completa, ou base64) numa URL HTTP que o `Image.network` sabe
/// consumir. Retorna `null` quando a foto é base64 (nesse caso o caller
/// já sabe decodar via [decodeFotoBase64]) ou quando o valor é vazio.
///
/// O nginx serve o MinIO em `/files/<path>` — vamos usar isso e não
/// URLs assinadas: sempre que o gestor faz upload nova foto no web,
/// o path muda (UUID novo), então o cache do OS/Flutter serve a nova
/// automaticamente sem precisar de cache-buster.
String? resolverFotoUrlHttp(String? foto, AlfaProduct product) {
  if (foto == null || foto.isEmpty) return null;
  // Já é URL — só devolve.
  if (foto.startsWith('http://') || foto.startsWith('https://')) return foto;
  // Base64 (`data:` inline ou payload puro): quem chama que decodifique.
  if (foto.startsWith('data:') || _pareceBase64(foto)) return null;
  final base = ApiEnvironment.baseUrlFor(product);
  final path = foto.startsWith('/') ? foto.substring(1) : foto;
  return '$base/files/$path';
}

bool _pareceBase64(String s) {
  // Base64 puro não tem `/` no meio do path (paths do MinIO sempre
  // têm ao menos um), e é longo. Heurística barata que evita chutar
  // errado quando o backend manda `alunos/uuid.jpg`.
  if (s.contains('/')) return false;
  if (s.length < 200) return false;
  return RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(s);
}
