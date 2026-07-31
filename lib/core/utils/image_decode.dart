import 'dart:convert';
import 'dart:typed_data';

/// Decodifica foto vinda do backend, aceitando 3 formatos:
/// - Data URL (`data:image/jpeg;base64,AAAA...`)
/// - Base64 puro (`AAAA...`)
/// - `null` ou vazio → `null`
///
/// Retorna `null` se o conteúdo for inválido.
Uint8List? decodeFotoBase64(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final clean = raw.contains(',') ? raw.split(',').last : raw;
  if (clean.isEmpty) return null;
  try {
    return base64Decode(clean);
  } catch (_) {
    return null;
  }
}
