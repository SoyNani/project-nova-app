import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/firebase_debug.dart';
import '../../data/datasources/firebase_auth_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_out.dart';


final firebaseAuthDatasourceProvider = Provider<FirebaseAuthDatasource>((ref) {
  return FirebaseAuthDatasource();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(firebaseAuthDatasourceProvider));
});

final signInWithGoogleProvider = Provider<SignInWithGoogle>((ref) {
  return SignInWithGoogle(ref.watch(authRepositoryProvider));
});

final signOutProvider = Provider<SignOut>((ref) {
  return SignOut(ref.watch(authRepositoryProvider));
});

/// Usuario actual en vivo (null = no autenticado). Guards de rutas y
/// widgets condicionados por rol observan este provider.
final authStateProvider = StreamProvider<UserEntity?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final loginControllerProvider =
  NotifierProvider<LoginController, LoginState>(LoginController.new);

sealed class LoginState {
  const LoginState();
}

class LoginIdle extends LoginState {
  const LoginIdle();
}

class LoginLoading extends LoginState {
  const LoginLoading();
}

class LoginError extends LoginState {
  const LoginError(this.message);
  final String message;
}

class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginIdle();

  Future<void> signInWithGoogle() async {
    state = const LoginLoading();
    final result = await ref.read(signInWithGoogleProvider)();
    result.match(
      (failure) {
        FirebaseDebug.error('Login falló: ${failure.message}');
        state = LoginError(failure.message);
      },
      (user) {
        FirebaseDebug.data('Login exitoso', {
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'role': user.role.name,
          'isAdmin': user.isAdmin,
        });
        state = const LoginIdle();
      },
    );
  }
}
