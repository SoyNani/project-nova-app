import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_app/features/events/domain/entities/event_entity.dart';
import 'package:nova_app/features/events/domain/entities/event_failure.dart';
import 'package:nova_app/features/events/domain/repositories/event_repository.dart';
import 'package:nova_app/features/events/domain/usecases/create_event.dart';
import 'package:nova_app/features/events/presentation/providers/event_providers.dart';
import 'package:nova_app/features/events/presentation/screens/event_form_screen.dart';
import 'package:nova_app/features/organizations/domain/entities/organization_entity.dart';
import 'package:nova_app/features/organizations/presentation/providers/organization_providers.dart';
import 'package:nova_app/features/speakers/domain/entities/speaker_entity.dart';
import 'package:nova_app/features/speakers/presentation/providers/speaker_providers.dart';

class _MockEventRepository extends Mock implements EventRepository {}

const _organizations = [
  OrganizationEntity(
    id: 'org-1',
    name: 'Colegio San Pedro Claver',
    city: 'Bucaramanga',
    department: 'Santander',
    address: 'Cra 27 # 45-12',
    latitude: 7.1,
    longitude: -73.1,
  ),
];

const _speakers = [
  SpeakerEntity(id: 'sp-1', name: 'Laura López', profession: 'Ingeniera'),
  SpeakerEntity(id: 'sp-2', name: 'Juan Pérez', profession: 'Docente'),
];

void main() {
  late _MockEventRepository repository;

  setUpAll(() {
    registerFallbackValue(
      EventEntity(
        id: '',
        name: '',
        startAt: DateTime(2026),
        endAt: DateTime(2026),
        organizationId: '',
      ),
    );
  });

  setUp(() {
    repository = _MockEventRepository();
  });

  Future<void> pumpForm(WidgetTester tester, {Size? size}) async {
    tester.view.physicalSize = size ?? const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          createEventProvider.overrideWithValue(CreateEvent(repository)),
          organizationsListProvider.overrideWith(
            (ref) => Stream.value(_organizations),
          ),
          speakersListProvider.overrideWith((ref) => Stream.value(_speakers)),
        ],
        child: const MaterialApp(home: EventFormScreen(createdBy: 'uid-1')),
      ),
    );
    await tester.pump();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> fillAll(WidgetTester tester) async {
    await tester.enterText(
      find.byType(TextFormField).first,
      'Innovación educativa',
    );
    // Fecha: acepta el día que propone el selector (hoy).
    await tapVisible(tester, find.text('Selecciona la fecha'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    // Hora de inicio: acepta las 9:00 propuestas; el fin se sugiere 1 h después.
    await tapVisible(tester, find.text('INICIO'));
    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Selecciona una organización'));
    await tester.tap(find.text('Colegio San Pedro Claver'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Laura López'));
  }

  testWidgets('muestra las secciones del formulario', (tester) async {
    await pumpForm(tester);

    expect(find.text('Nuevo evento'), findsOneWidget);
    expect(find.text('Crear evento'), findsOneWidget);
    expect(find.text('INFORMACIÓN'), findsOneWidget);
    expect(find.text('FECHA Y HORARIO'), findsOneWidget);
    expect(find.text('ORGANIZACIÓN'), findsOneWidget);
    expect(find.text('SPEAKERS'), findsOneWidget);
  });

  testWidgets('valida nombre, horario y organización', (tester) async {
    await pumpForm(tester);

    await tapVisible(tester, find.text('Crear evento'));

    expect(find.text('Este campo es obligatorio.'), findsOneWidget);
    expect(
      find.text('Elige la fecha y las horas de inicio y fin.'),
      findsOneWidget,
    );
    expect(find.text('Selecciona una organización.'), findsOneWidget);
    verifyNever(() => repository.create(any()));
  });

  testWidgets('crea el evento con organización, horario y speakers', (
    tester,
  ) async {
    when(() => repository.create(any())).thenAnswer(
      (invocation) async =>
          right(invocation.positionalArguments.first as EventEntity),
    );

    await pumpForm(tester);
    await fillAll(tester);

    await tapVisible(tester, find.text('Crear evento'));

    final captured =
        verify(() => repository.create(captureAny())).captured.single
            as EventEntity;
    final today = DateTime.now();

    expect(captured.name, 'Innovación educativa');
    expect(captured.organizationId, 'org-1');
    expect(captured.organizationName, 'Colegio San Pedro Claver');
    expect(captured.city, 'Bucaramanga');
    expect(captured.startAt, DateTime(today.year, today.month, today.day, 9));
    expect(captured.endAt, DateTime(today.year, today.month, today.day, 10));
    expect(captured.speakerIds, ['sp-1']);
    expect(captured.speakerNames, ['Laura López']);
    expect(captured.createdBy, 'uid-1');
    expect(find.byType(EventFormScreen), findsNothing);
  });

  testWidgets('muestra el error si falla el guardado', (tester) async {
    when(
      () => repository.create(any()),
    ).thenAnswer((_) async => left(const EventUnknownError('sin permiso')));

    await pumpForm(tester);
    await fillAll(tester);

    await tester.ensureVisible(find.text('Crear evento'));
    await tester.tap(find.text('Crear evento'));
    await tester.pump();
    await tester.pump();

    expect(find.text('sin permiso'), findsOneWidget);
  });

  testWidgets('funciona en pantalla ancha', (tester) async {
    await pumpForm(tester, size: const Size(1200, 800));

    expect(find.text('NOMBRE DEL EVENTO'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
