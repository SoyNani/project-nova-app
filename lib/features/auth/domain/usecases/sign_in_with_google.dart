import 'package:fpdart/fpdart.dart';
import '../entities/auth_failure.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Usecase: una sola responsabilidad — iniciar sesión con Google.
/// No sabe de Firebase, no sabe de UI, solo orquesta la regla de
/// negocio "iniciar sesión" contra el contrato del repositorio.
class SignInWithGoogle {
  const SignInWithGoogle(this._repository);

  final AuthRepository _repository;

  Future<Either<AuthFailure, UserEntity>> call() {
    return _repository.signInWithGoogle();
  }
}
