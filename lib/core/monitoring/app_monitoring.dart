import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Punto único de monitoreo: Crashlytics (errores), Performance (tiempos
/// de carga y trazas) y Analytics (pantallas vistas).
/// Mientras no se llame [init] (tests, widgets aislados) todo es no-op,
/// así el resto de la app puede instrumentarse sin depender de Firebase.
class AppMonitoring {
  AppMonitoring._();

  static bool _enabled = false;

  /// Traza `app_start`: desde que arranca `main()` hasta el primer frame.
  static Trace? _appStartTrace;

  /// En debug no se envían datos para no ensuciar los dashboards. Cambia a
  /// `true` si necesitas probar el envío desde un build de desarrollo.
  static const bool collectInDebug = false;

  static bool get _collect => kReleaseMode || kProfileMode || collectInDebug;

  /// Llamar justo después de `Firebase.initializeApp`.
  static Future<void> init() async {
    final crashlytics = FirebaseCrashlytics.instance;
    final performance = FirebasePerformance.instance;

    await Future.wait([
      crashlytics.setCrashlyticsCollectionEnabled(_collect),
      performance.setPerformanceCollectionEnabled(_collect),
      FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(_collect),
    ]);

    // Errores del framework (build, layout, paint).
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      crashlytics.recordFlutterFatalError(details);
    };
    // Errores asíncronos no capturados (Futures, Streams, platform channels).
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };

    _enabled = true;

    _appStartTrace = performance.newTrace('app_start');
    await _appStartTrace!.start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appStartTrace?.stop();
      _appStartTrace = null;
    });
  }

  /// Observer para registrar `screen_view` de las rutas con nombre
  /// (`Navigator.push` con `RouteSettings(name: ...)`).
  static List<NavigatorObserver> get navigatorObservers => _enabled
      ? [FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)]
      : const [];

  /// Registra una vista de pantalla manual (pestañas del shell, que no son
  /// rutas del Navigator).
  static Future<void> logScreen(String screenName) async {
    if (!_enabled) return;
    await FirebaseAnalytics.instance.logScreenView(screenName: screenName);
    await FirebaseCrashlytics.instance.log('screen: $screenName');
  }

  /// Asocia los reportes de errores y la analítica al usuario actual.
  static Future<void> setUser({String? uid, String? role}) async {
    if (!_enabled) return;
    await Future.wait([
      FirebaseCrashlytics.instance.setUserIdentifier(uid ?? ''),
      FirebaseAnalytics.instance.setUserId(id: uid),
      FirebaseAnalytics.instance.setUserProperty(name: 'role', value: role),
    ]);
  }

  /// Error capturado (no fatal) que igual queremos ver en Crashlytics.
  static Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
  }) async {
    if (!_enabled) return;
    await FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      reason: reason,
    );
  }

  /// Mide cuánto tarda [action] como una traza personalizada de
  /// Performance. Si falla, la traza queda con `result=error`.
  static Future<T> trace<T>(
    String name,
    Future<T> Function() action, {
    Map<String, String> attributes = const {},
  }) async {
    if (!_enabled) return action();

    final trace = FirebasePerformance.instance.newTrace(name);
    attributes.forEach(trace.putAttribute);
    await trace.start();
    try {
      final result = await action();
      trace.putAttribute('result', 'ok');
      return result;
    } catch (_) {
      trace.putAttribute('result', 'error');
      rethrow;
    } finally {
      await trace.stop();
    }
  }

  /// Mide el tiempo hasta el primer valor de un stream (p. ej. la primera
  /// carga de un `snapshots()` de Firestore). Las actualizaciones
  /// posteriores pasan sin medir. [itemCount] guarda la métrica `items`.
  static Stream<T> traceFirstEvent<T>(
    String name,
    Stream<T> source, {
    int Function(T value)? itemCount,
  }) async* {
    if (!_enabled) {
      yield* source;
      return;
    }

    final trace = FirebasePerformance.instance.newTrace(name);
    await trace.start();
    var stopped = false;

    Future<void> stop(String result) async {
      if (stopped) return;
      stopped = true;
      trace.putAttribute('result', result);
      await trace.stop();
    }

    try {
      await for (final value in source) {
        if (!stopped) {
          if (itemCount != null) trace.setMetric('items', itemCount(value));
          await stop('ok');
        }
        yield value;
      }
    } catch (_) {
      await stop('error');
      rethrow;
    } finally {
      // Cancelado antes de recibir datos (el usuario salió de la pantalla).
      await stop('cancelled');
    }
  }
}
