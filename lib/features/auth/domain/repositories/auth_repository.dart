import 'package:fpdart/fpdart.dart';
import '../entities/auth_failure.dart';
import '../entities/user_entity.dart';

/// Contrato que debe cumplir cualquier implementación de auth
/// (Firebase hoy, otro proveedor mañana). `presentation` y `domain`
abstract interface class AuthRepository {
  Future<Either<AuthFailure, UserEntity>> signInWithGoogle();

  Future<void> signOut();

  /// Stream del usuario autenticado actual (null si no hay sesión).
  /// Permite que la UI reaccione en vivo a cambios de sesión.
  Stream<UserEntity?> authStateChanges();
}
