import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Trazas de depuración del flujo de Firebase (login, claims/permisos
/// y documentos de Firestore). Todo se imprime con prefijo `[FIREBASE]`
/// para poder filtrarlo fácil en la consola.
///
/// Solo actúa en debug: en release los logs se descartan.
class FirebaseDebug {
  FirebaseDebug._();

  static const String prefix = '[FIREBASE]';

  /// Cambia a `false` para silenciar las trazas sin tocar el código.
  static bool enabled = true;

  static void section(String title) {
    if (!enabled || !kDebugMode) return;
    debugPrint('$prefix ─── $title ───────────────────────');
  }

  static void log(String message) {
    if (!enabled || !kDebugMode) return;
    debugPrint('$prefix $message');
  }

  static void step(String message) {
    if (!enabled || !kDebugMode) return;
    debugPrint('$prefix ▸ $message');
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (!kDebugMode) return;
    debugPrint('$prefix ✖ $message');
    if (error != null) debugPrint('$prefix   error: $error');
    if (stackTrace != null) debugPrint('$prefix   stack: $stackTrace');
  }

  /// Imprime un mapa/objeto legible (respuestas de Firestore, claims, etc).
  static void data(String label, Object? data) {
    if (!enabled || !kDebugMode) return;
    debugPrint('$prefix $label:');
    debugPrint(const JsonEncoder.withIndent('  ').convert(data));
  }

  /// Decodifica el payload de un JWT (ID token de Firebase) para poder ver
  /// los custom claims — que es donde Firebase guarda los roles/permisos.
  static Map<String, dynamic>? decodeJwtPayload(String? token) {
    if (token == null || token.isEmpty) return null;
    final parts = token.split('.');
    if (parts.length != 3) {
      debugPrint('$prefix ✖ El token no tiene formato JWT válido');
      return null;
    }
    try {
      final normalized = base64Url.normalize(parts[1]);
      final json = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('$prefix ✖ No se pudo decodificar el token: $e');
      return null;
    }
  }
}
