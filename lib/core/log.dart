import 'package:flutter/foundation.dart';

/// Log que só imprime em debug builds. Em release vira no-op pra evitar
/// vazamento de tokens/payloads em logcat / Console.app.
void logDebug(String message) {
  if (kDebugMode) debugPrint(message);
}
