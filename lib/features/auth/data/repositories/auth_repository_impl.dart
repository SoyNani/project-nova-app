import 'package:fpdart/fpdart.dart';
import '../../domain/entities/auth_failure.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';

/// Traduce excepciones de `data/` en [AuthFailure] de `domain/`.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._datasource);

  final FirebaseAuthDatasource _datasource;

  @override
  Future<Either<AuthFailure, UserEntity>> signInWithGoogle() async {
    try {
      final user = await _datasource.signInWithGoogle();
      return right(user);
    } on GoogleSignInCancelledException {
      return left(const GoogleSignInCancelled());
    } catch (e) {
      return left(AuthUnknownError(e.toString()));
    }
  }

  @override
  Future<void> signOut() => _datasource.signOut();

  @override
  Stream<UserEntity?> authStateChanges() => _datasource.authStateChanges();
}
