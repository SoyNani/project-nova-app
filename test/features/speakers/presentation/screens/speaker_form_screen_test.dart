import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_app/features/organizations/domain/entities/organization_entity.dart';
import 'package:nova_app/features/organizations/presentation/providers/organization_providers.dart';
import 'package:nova_app/features/speakers/domain/entities/speaker_entity.dart';
import 'package:nova_app/features/speakers/domain/entities/speaker_failure.dart';
import 'package:nova_app/features/speakers/domain/repositories/speaker_repository.dart';
import 'package:nova_app/features/speakers/domain/usecases/create_speaker.dart';
import 'package:nova_app/features/speakers/domain/usecases/watch_speakers.dart';
import 'package:nova_app/features/speakers/presentation/providers/speaker_providers.dart';
import 'package:nova_app/features/speakers/presentation/screens/speaker_form_screen.dart';

class _MockSpeakerRepository extends Mock implements SpeakerRepository {}

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

void main() {
  late _MockSpeakerRepository repository;

  setUpAll(() {
    registerFallbackValue(
      const SpeakerEntity(id: '', name: '', profession: ''),
    );
  });

  setUp(() {
    repository = _MockSpeakerRepository();
    when(
      () => repository.watchAll(),
    ).thenAnswer((_) => Stream.value(const <SpeakerEntity>[]));
  });

  Future<void> pumpForm(
    WidgetTester tester, {
    required Size surfaceSize,
  }) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          createSpeakerProvider.overrideWithValue(CreateSpeaker(repository)),
          watchSpeakersProvider.overrideWithValue(WatchSpeakers(repository)),
          organizationsListProvider.overrideWith(
            (ref) => Stream.value(_organizations),
          ),
        ],
        child: const MaterialApp(home: SpeakerFormScreen()),
      ),
    );
    await tester.pump();
  }

  /// El selector de organización abre una hoja inferior con la lista.
  Future<void> selectOrganization(WidgetTester tester, String name) async {
    await tester.ensureVisible(find.text('Selecciona una organización'));
    await tester.tap(find.text('Selecciona una organización'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(name));
    await tester.pump();
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Crear speaker'));
    await tester.tap(find.text('Crear speaker'));
  }

  Future<void> fillRequired(WidgetTester tester) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Nara Ortiz');
    await tester.enterText(fields.at(1), 'Ingeniera de software');
    await selectOrganization(tester, 'Colegio San José');
  }

  group('SpeakerFormScreen — contenido', () {
    testWidgets('muestra los campos del formulario', (tester) async {
      await pumpForm(tester, surfaceSize: const Size(390, 844));

      expect(find.text('Nuevo speaker'), findsOneWidget);
      expect(find.text('NOMBRE'), findsOneWidget);
      expect(find.text('PROFESIÓN'), findsOneWidget);
      expect(find.text('CORREO'), findsOneWidget);
      expect(find.text('ESPECIALIDADES'), findsOneWidget);
      expect(find.text('ORGANIZACIÓN'), findsOneWidget);
      expect(find.text('REDES SOCIALES'), findsOneWidget);
      expect(find.text('Crear speaker'), findsOneWidget);
    });

    testWidgets('avisa si no hay organizaciones registradas', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            createSpeakerProvider.overrideWithValue(CreateSpeaker(repository)),
            watchSpeakersProvider.overrideWithValue(WatchSpeakers(repository)),
            organizationsListProvider.overrideWith(
              (ref) => Stream.value(const []),
            ),
          ],
          child: const MaterialApp(home: SpeakerFormScreen()),
        ),
      );
      await tester.pump();

      expect(
        find.text(
          'Primero crea una organización en el módulo de organizaciones.',
        ),
        findsOneWidget,
      );
    });
  });

  group('SpeakerFormScreen — validaciones', () {
    testWidgets('exige nombre y profesión', (tester) async {
      await pumpForm(tester, surfaceSize: const Size(390, 844));

      await submit(tester);
      await tester.pumpAndSettle();

      expect(find.text('Este campo es obligatorio.'), findsNWidgets(2));
      verifyNever(() => repository.create(any()));
    });

    testWidgets('exige al menos una organización', (tester) async {
      await pumpForm(tester, surfaceSize: const Size(390, 844));

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Nara Ortiz');
      await tester.enterText(fields.at(1), 'Ingeniera');
      await submit(tester);
      await tester.pumpAndSettle();

      expect(
        find.text('Selecciona al menos una organización.'),
        findsOneWidget,
      );
      verifyNever(() => repository.create(any()));
    });

    testWidgets('el correo es opcional pero, si se escribe, debe ser válido', (
      tester,
    ) async {
      await pumpForm(tester, surfaceSize: const Size(390, 844));
      await fillRequired(tester);

      await tester.enterText(find.byType(TextFormField).at(2), 'nara@correo');
      await submit(tester);
      await tester.pumpAndSettle();

      expect(find.text('Ingresa un correo válido.'), findsOneWidget);
      verifyNever(() => repository.create(any()));
    });
  });

  group('SpeakerFormScreen — flujo principal', () {
    testWidgets('crea el speaker y cierra el formulario', (tester) async {
      when(() => repository.create(any())).thenAnswer(
        (invocation) async =>
            right(invocation.positionalArguments.first as SpeakerEntity),
      );

      await pumpForm(tester, surfaceSize: const Size(390, 844));
      await fillRequired(tester);

      await tester.enterText(find.byType(TextFormField).at(2), 'nara@correo.com');
      await tester.enterText(find.byType(TextFormField).at(3), 'Flutter, Dart');
      await tester.enterText(find.byType(TextFormField).at(4), '@nara');

      await submit(tester);
      await tester.pumpAndSettle();

      final captured =
          verify(() => repository.create(captureAny())).captured.single
              as SpeakerEntity;
      expect(captured.name, 'Nara Ortiz');
      expect(captured.profession, 'Ingeniera de software');
      expect(captured.email, 'nara@correo.com');
      expect(captured.specialties, ['Flutter', 'Dart']);
      expect(captured.organizationIds, ['org-1']);
      expect(captured.instagram, '@nara');
    });

    testWidgets('Enter convierte la especialidad en chip y se envía', (
      tester,
    ) async {
      when(() => repository.create(any())).thenAnswer(
        (invocation) async =>
            right(invocation.positionalArguments.first as SpeakerEntity),
      );

      await pumpForm(tester, surfaceSize: const Size(390, 844));
      await fillRequired(tester);

      await tester.enterText(find.byType(TextFormField).at(3), 'UX');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(find.text('UX'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).at(3))
            .controller!
            .text,
        isEmpty,
      );

      await submit(tester);
      await tester.pumpAndSettle();

      final captured =
          verify(() => repository.create(captureAny())).captured.single
              as SpeakerEntity;
      expect(captured.specialties, ['UX']);
    });

    testWidgets('la organización elegida se muestra en el selector', (
      tester,
    ) async {
      await pumpForm(tester, surfaceSize: const Size(390, 844));
      await selectOrganization(tester, 'Colegio San José');

      expect(find.text('Colegio San José'), findsOneWidget);
      expect(find.text('Bucaramanga, Santander'), findsOneWidget);
      expect(find.text('Selecciona una organización'), findsNothing);
    });
  });

  group('SpeakerFormScreen — error visible', () {
    testWidgets('muestra SnackBar si el alta falla', (tester) async {
      when(
        () => repository.create(any()),
      ).thenAnswer((_) async => left(const SpeakerUnknownError('sin permiso')));

      await pumpForm(tester, surfaceSize: const Size(390, 844));
      await fillRequired(tester);

      await submit(tester);
      await tester.pump();
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('sin permiso'), findsOneWidget);
    });
  });

  group('SpeakerFormScreen — responsive', () {
    testWidgets('en pantalla angosta muestra todos los campos', (tester) async {
      await pumpForm(tester, surfaceSize: const Size(390, 844));

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.text('TikTok'), findsOneWidget);
    });

    testWidgets('en pantalla ancha también muestra los campos', (tester) async {
      await pumpForm(tester, surfaceSize: const Size(1200, 800));

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.text('NOMBRE'), findsOneWidget);
    });
  });
}
