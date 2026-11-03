import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/monitoring/app_monitoring.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/firebase_debug.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import 'main_shell_screen.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Nova · Events',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('es', 'CO'),
      supportedLocales: const [Locale('es', 'CO'), Locale('es'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      navigatorObservers: AppMonitoring.navigatorObservers,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // Crashlytics y Analytics quedan asociados al usuario en sesión.
    ref.listen(authStateProvider, (_, next) {
      final user = next.value;
      AppMonitoring.setUser(uid: user?.uid, role: user?.role.name);
    });

    return authState.when(
      data: (user) {
        if (user == null) {
          FirebaseDebug.log('AuthGate → sin sesión: LoginScreen');
          return const LoginScreen();
        }
        FirebaseDebug.data('AuthGate → sesión activa', {
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'role': user.role.name,
          'isAdmin': user.isAdmin,
        });
        return MainShellScreen(user: user);
      },
      loading: () {
        FirebaseDebug.step('AuthGate → verificando sesión...');
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
      error: (error, stackTrace) {
        FirebaseDebug.error('AuthGate falló', error, stackTrace);
        AppMonitoring.recordError(error, stackTrace, reason: 'AuthGate');
        return Scaffold(body: Center(child: Text('Error de sesión: $error')));
      },
    );
  }
}
