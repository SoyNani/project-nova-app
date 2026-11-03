import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_app/core/widgets/atoms/app_page_title.dart';
import 'package:nova_app/features/auth/domain/entities/user_entity.dart';
import 'package:nova_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:nova_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:nova_app/features/auth/presentation/screens/profile_screen.dart';
import 'package:nova_app/features/organizations/domain/entities/organization_entity.dart';
import 'package:nova_app/features/organizations/presentation/providers/organization_providers.dart';
import 'package:nova_app/features/speakers/domain/entities/speaker_entity.dart';
import 'package:nova_app/features/speakers/domain/entities/speaker_failure.dart';
import 'package:nova_app/features/speakers/domain/repositories/speaker_repository.dart';
import 'package:nova_app/features/speakers/domain/usecases/watch_speaker_by_email.dart';
import 'package:nova_app/features/speakers/domain/usecases/update_speaker.dart';
import 'package:nova_app/features/speakers/presentation/providers/speaker_providers.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockSpeakerRepository extends Mock implements SpeakerRepository {}

const _user = UserEntity(
  uid: 'uid-1',
  email: 'nara@ejemplo.edu.co',
  displayName: 'Nara Restrepo',
  role: UserRole.usuario,
);

const _speaker = SpeakerEntity(
  id: 'sp-1',
  name: 'Nara Ortiz',
  profession: 'Ingeniera de software',
  specialties: ['Flutter'],
  organizationIds: ['org-1'],
  email: 'nara@ejemplo.edu.co',
  instagram: '@nara',
);

const _organizations = [
  OrganizationEntity(
    id: 'org-1',
    name: 'Colegio San José',
    city: 'Bucaramanga',
    department: 'Santander',
    address: 'Cra 27 # 45-12',
    latitude: 7.1,
    longitude: -73.1,
  ),
];

/// Alto que ocupa la barra de navegación flotante del shell.
const _navInset = 100.0;

void main() {
  late _MockAuthRepository authRepository;
  late _MockSpeakerRepository speakerRepository;

  setUpAll(() {
    registerFallbackValue(
      const SpeakerEntity(id: '', name: '', profession: ''),
    );
  });

  setUp(() {
    authRepository = _MockAuthRepository();
    speakerRepository = _MockSpeakerRepository();
    when(
      () => speakerRepository.watchByEmail(any()),
    ).thenAnswer((_) => Stream.value(null));
  });

  void givenSpeaker() {
    when(
      () => speakerRepository.watchByEmail(any()),
    ).thenAnswer((_) => Stream.value(_speaker));
  }

  Future<void> pumpProfile(
    WidgetTester tester, {
    required Size surfaceSize,
  }) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          watchSpeakerByEmailProvider.overrideWithValue(
            WatchSpeakerByEmail(speakerRepository),
          ),
          updateSpeakerProvider.overrideWithValue(
            UpdateSpeaker(speakerRepository),
          ),
          organizationsListProvider.overrideWith(
            (ref) => Stream.value(_organizations),
          ),
        ],
        child: MaterialApp(
          // Simula la barra flotante del shell (`extendBody: true`).
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(padding: const EdgeInsets.only(bottom: _navInset)),
            child: child!,
          ),
          home: const ProfileScreen(user: _user),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> scrollToEnd(WidgetTester tester) async {
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -5000),
    );
    await tester.pumpAndSettle();
  }

  group('ProfileScreen — contenido', () {
    testWidgets('muestra nombre, correo y el botón de salida', (tester) async {
      await pumpProfile(tester, surfaceSize: const Size(390, 844));

      expect(find.text('Nara Restrepo'), findsOneWidget);
      expect(find.text('nara@ejemplo.edu.co'), findsOneWidget);
      expect(find.text('CUENTA'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('el título usa el mismo estilo que Conferencias', (
      tester,
    ) async {
      await pumpProfile(tester, surfaceSize: const Size(390, 844));

      expect(find.widgetWithText(AppPageTitle, 'Perfil'), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('busca el speaker con el correo del usuario', (tester) async {
      await pumpProfile(tester, surfaceSize: const Size(390, 844));

      verify(
        () => speakerRepository.watchByEmail('nara@ejemplo.edu.co'),
      ).called(1);
    });

    testWidgets('sin speaker con ese correo no muestra el formulario', (
      tester,
    ) async {
      await pumpProfile(tester, surfaceSize: const Size(390, 844));

      expect(find.text('Perfil de speaker'), findsNothing);
      expect(find.text('Guardar cambios'), findsNothing);
    });

    testWidgets('con speaker carga sus datos en el formulario', (tester) async {
      givenSpeaker();
      await pumpProfile(tester, surfaceSize: const Size(390, 844));

      expect(find.text('Perfil de speaker'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Nara Ortiz'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'Ingeniera de software'),
        findsOneWidget,
      );
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Colegio San José'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '@nara'), findsOneWidget);

      final emailField = tester.widget<EditableText>(
        find.descendant(
          of: find.widgetWithText(TextFormField, 'nara@ejemplo.edu.co'),
          matching: find.byType(EditableText),
        ),
      );
      expect(emailField.readOnly, isTrue);
    });

    testWidgets(
      'muestra el formulario si el speaker se crea con el perfil ya abierto',
      (tester) async {
        final controller = StreamController<SpeakerEntity?>();
        addTearDown(controller.close);
        when(
          () => speakerRepository.watchByEmail(any()),
        ).thenAnswer((_) => controller.stream);
        controller.add(null);

        await pumpProfile(tester, surfaceSize: const Size(390, 844));
        expect(find.text('Perfil de speaker'), findsNothing);

        controller.add(_speaker);
        await tester.pumpAndSettle();

        expect(find.text('Perfil de speaker'), findsOneWidget);
        expect(
          find.widgetWithText(TextFormField, 'Nara Ortiz'),
          findsOneWidget,
        );
      },
    );

    testWidgets('cerrar sesión queda por encima de la barra flotante', (
      tester,
    ) async {
      givenSpeaker();
      await pumpProfile(tester, surfaceSize: const Size(390, 844));
      await scrollToEnd(tester);

      final logoutBottom = tester.getBottomLeft(find.text('Cerrar sesión')).dy;
      expect(logoutBottom, lessThan(844 - _navInset));
    });
  });

  group('ProfileScreen — validaciones', () {
    testWidgets('no guarda el speaker si se borra el nombre', (tester) async {
      givenSpeaker();
      await pumpProfile(tester, surfaceSize: const Size(390, 844));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nara Ortiz'),
        '',
      );
      await tester.ensureVisible(find.text('Guardar cambios'));
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(find.text('Este campo es obligatorio.'), findsOneWidget);
      verifyNever(() => speakerRepository.update(any()));
    });
  });

  group('ProfileScreen — acciones', () {
    testWidgets('guardar actualiza el speaker y avisa', (tester) async {
      givenSpeaker();
      when(() => speakerRepository.update(any())).thenAnswer(
        (invocation) async =>
            right(invocation.positionalArguments.first as SpeakerEntity),
      );
      await pumpProfile(tester, surfaceSize: const Size(390, 844));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ingeniera de software'),
        'Arquitecta de software',
      );
      await tester.ensureVisible(find.text('Guardar cambios'));
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      final updated =
          verify(() => speakerRepository.update(captureAny())).captured.single
              as SpeakerEntity;
      expect(updated.id, 'sp-1');
      expect(updated.profession, 'Arquitecta de software');
      expect(updated.email, 'nara@ejemplo.edu.co');
      expect(updated.organizationIds, ['org-1']);
      expect(find.text('Perfil de speaker actualizado.'), findsOneWidget);
    });

    testWidgets(
      'si el stream re-emite durante el guardado el aviso igual aparece',
      (tester) async {
        final controller = StreamController<SpeakerEntity?>();
        addTearDown(controller.close);
        when(
          () => speakerRepository.watchByEmail(any()),
        ).thenAnswer((_) => controller.stream);
        when(() => speakerRepository.update(any())).thenAnswer((
          invocation,
        ) async {
          final saved = invocation.positionalArguments.first as SpeakerEntity;
          controller.add(saved);
          await Future<void>.delayed(Duration.zero);
          return right(saved);
        });
        controller.add(_speaker);
        await pumpProfile(tester, surfaceSize: const Size(390, 844));

        await tester.ensureVisible(find.text('Guardar cambios'));
        await tester.tap(find.text('Guardar cambios'));
        await tester.pumpAndSettle();

        expect(find.text('Perfil de speaker actualizado.'), findsOneWidget);
      },
    );

    testWidgets('cerrar sesión llama al repositorio', (tester) async {
      when(
        () => authRepository.signOut(),
      ).thenAnswer((_) async => const Right(null));

      await pumpProfile(tester, surfaceSize: const Size(390, 844));

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      verify(() => authRepository.signOut()).called(1);
    });
  });

  group('ProfileScreen — errores visibles', () {
    testWidgets('muestra SnackBar si falla la actualización', (tester) async {
      givenSpeaker();
      when(
        () => speakerRepository.update(any()),
      ).thenAnswer((_) async => left(const SpeakerUnknownError('sin permiso')));
      await pumpProfile(tester, surfaceSize: const Size(390, 844));

      await tester.ensureVisible(find.text('Guardar cambios'));
      await tester.tap(find.text('Guardar cambios'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('sin permiso'), findsOneWidget);
    });

    testWidgets('avisa si no se pudo consultar el speaker', (tester) async {
      when(
        () => speakerRepository.watchByEmail(any()),
      ).thenAnswer((_) => Stream.error(Exception('sin conexión')));
      await pumpProfile(tester, surfaceSize: const Size(390, 844));

      expect(
        find.text('No se pudo verificar si tienes un perfil de speaker.'),
        findsOneWidget,
      );
      expect(find.text('Cerrar sesión'), findsOneWidget);
    });
  });

  group('ProfileScreen — tamaños de pantalla', () {
    testWidgets('renderiza en pantalla angosta con el formulario', (
      tester,
    ) async {
      givenSpeaker();
      await pumpProfile(tester, surfaceSize: const Size(320, 640));

      expect(find.text('Nara Restrepo'), findsOneWidget);
      expect(find.text('Perfil de speaker'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renderiza en pantalla ancha con el formulario', (
      tester,
    ) async {
      givenSpeaker();
      await pumpProfile(tester, surfaceSize: const Size(1280, 900));

      expect(find.text('Nara Restrepo'), findsOneWidget);
      expect(find.text('Guardar cambios'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
