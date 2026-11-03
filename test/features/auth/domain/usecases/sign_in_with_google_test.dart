import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_app/features/auth/domain/entities/auth_failure.dart';
import 'package:nova_app/features/auth/domain/entities/user_entity.dart';
import 'package:nova_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:nova_app/features/auth/domain/usecases/sign_in_with_google.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  late SignInWithGoogle usecase;

  setUp(() {
    repository = _MockAuthRepository();
    usecase = SignInWithGoogle(repository);
  });

  const tUser = UserEntity(
    uid: 'uid-1',
    email: 'nani@ejemplo.edu.co',
    displayName: 'Nani',
    role: UserRole.usuario,
  );

  group('SignInWithGoogle', () {
    test(
      'retorna Right(UserEntity) cuando el repositorio tiene éxito',
      () async {
        when(
          () => repository.signInWithGoogle(),
        ).thenAnswer((_) async => right(tUser));

        final result = await usecase();

        expect(result, right(tUser));
        verify(() => repository.signInWithGoogle()).called(1);
      },
    );

    test(
      'retorna Left(AuthFailure) cuando el usuario cancela el login',
      () async {
        when(
          () => repository.signInWithGoogle(),
        ).thenAnswer((_) async => left(const GoogleSignInCancelled()));

        final result = await usecase();

        expect(result.isLeft(), true);
        result.match(
          (failure) => expect(failure, isA<GoogleSignInCancelled>()),
          (_) => fail('no debería retornar Right en este caso'),
        );
      },
    );

    test('propaga un AuthUnknownError si el repositorio lo retorna', () async {
      when(
        () => repository.signInWithGoogle(),
      ).thenAnswer((_) async => left(AuthUnknownError('network down')));

      final result = await usecase();

      expect(
        result.getLeft().toNullable(),
        isA<AuthUnknownError>().having(
          (f) => f.message,
          'message',
          'network down',
        ),
      );
    });
  });
}
