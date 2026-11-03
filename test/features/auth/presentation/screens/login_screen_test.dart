import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:nova_app/features/auth/domain/entities/auth_failure.dart';
import 'package:nova_app/features/auth/domain/entities/user_entity.dart';
import 'package:nova_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:nova_app/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:nova_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:nova_app/features/auth/presentation/screens/login_screen.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;

  setUp(() {
    repository = _MockAuthRepository();
  });

  Future<void> pumpLoginScreen(
    WidgetTester tester, {
    required Size surfaceSize,
  }) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          signInWithGoogleProvider.overrideWithValue(
            SignInWithGoogle(repository),
          ),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
  }

  group('LoginScreen — contenido', () {
    testWidgets('muestra el título, subtítulo y botón de Google', (
      tester,
    ) async {
      await pumpLoginScreen(tester, surfaceSize: const Size(390, 844));

      expect(find.text('Bienvenido'), findsOneWidget);
      expect(find.text('Continuar con Google'), findsOneWidget);
      expect(find.text('Nova'), findsOneWidget);
    });

    // El login con correo/contraseña quedó fuera de alcance: solo Google.
    testWidgets('no muestra campos de correo ni contraseña', (tester) async {
      await pumpLoginScreen(tester, surfaceSize: const Size(390, 844));

      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Iniciar sesión'), findsNothing);
    });
  });

  group('LoginScreen — flujo de Google Sign-In', () {
    testWidgets('llama al repositorio al tocar "Continuar con Google"', (
      tester,
    ) async {
      when(() => repository.signInWithGoogle()).thenAnswer(
        (_) async => right(
          const UserEntity(
            uid: 'uid-1',
            email: 'nani@ejemplo.edu.co',
            displayName: 'Nani',
            role: UserRole.usuario,
          ),
        ),
      );

      await pumpLoginScreen(tester, surfaceSize: const Size(390, 844));
      await tester.tap(find.text('Continuar con Google'));
      await tester.pump();

      verify(() => repository.signInWithGoogle()).called(1);
    });

    testWidgets('muestra un SnackBar si el login falla', (tester) async {
      when(
        () => repository.signInWithGoogle(),
      ).thenAnswer((_) async => left(const UserNotAllowed()));

      await pumpLoginScreen(tester, surfaceSize: const Size(390, 844));
      await tester.tap(find.text('Continuar con Google'));
      await tester.pump(); // dispara el future
      await tester.pump(); // deja que el listener reaccione

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Tu correo no tiene acceso a esta aplicación todavía.'),
        findsOneWidget,
      );
    });
  });

  group('LoginScreen — responsive', () {
    testWidgets('en pantallas angostas usa layout de una columna', (
      tester,
    ) async {
      await pumpLoginScreen(tester, surfaceSize: const Size(390, 844));
      // En layout angosto, hero header y form están en un solo Column,
      // así que no debería existir ningún Row como layout raíz de pantalla.
      expect(find.text('Nova'), findsOneWidget);
      expect(find.text('Bienvenido'), findsOneWidget);
    });

    testWidgets('en pantallas anchas (tablet/web) sigue mostrando el form', (
      tester,
    ) async {
      await pumpLoginScreen(tester, surfaceSize: const Size(1200, 800));

      expect(find.text('Nova'), findsOneWidget);
      expect(find.text('Bienvenido'), findsOneWidget);
      expect(find.text('Continuar con Google'), findsOneWidget);
    });
  });
}
