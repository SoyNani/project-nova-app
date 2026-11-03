import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_app/core/widgets/atoms/app_fab.dart';
import 'package:nova_app/features/organizations/domain/entities/organization_entity.dart';
import 'package:nova_app/features/organizations/presentation/providers/organization_providers.dart';
import 'package:nova_app/features/speakers/domain/entities/speaker_entity.dart';
import 'package:nova_app/features/speakers/domain/entities/speaker_event_entity.dart';
import 'package:nova_app/features/speakers/domain/repositories/speaker_repository.dart';
import 'package:nova_app/features/speakers/domain/usecases/create_speaker.dart';
import 'package:nova_app/features/speakers/domain/usecases/get_speaker.dart';
import 'package:nova_app/features/speakers/domain/usecases/watch_speaker_events.dart';
import 'package:nova_app/features/speakers/domain/usecases/watch_speakers.dart';
import 'package:nova_app/features/speakers/presentation/providers/speaker_providers.dart';
import 'package:nova_app/features/speakers/presentation/screens/speakers_list_screen.dart';
import 'package:nova_app/features/speakers/presentation/widgets/speaker_card.dart';

class _MockSpeakerRepository extends Mock implements SpeakerRepository {}

const _speakers = [
  SpeakerEntity(
    id: 'sp-1',
    name: 'Nara Ortiz',
    profession: 'Ingeniera de software',
    specialties: ['Flutter'],
    organizationIds: ['org-1'],
  ),
  SpeakerEntity(
    id: 'sp-2',
    name: 'Juan Pérez',
    profession: 'Docente de física',
    organizationIds: ['org-2'],
  ),
];

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
  OrganizationEntity(
    id: 'org-2',
    name: 'Universidad del Valle',
    city: 'Cali',
    department: 'Valle',
    address: 'Calle 13 # 100-00',
    latitude: 3.4,
    longitude: -76.5,
  ),
];

void main() {
  late _MockSpeakerRepository repository;

  setUp(() {
    repository = _MockSpeakerRepository();
    when(() => repository.watchAll())
        .thenAnswer((_) => Stream.value(_speakers));
    when(() => repository.watchEvents(any()))
        .thenAnswer((_) => Stream.value(const <SpeakerEventEntity>[]));
    when(() => repository.getById(any())).thenAnswer(
      (invocation) async => right(
        _speakers.firstWhere(
          (s) => s.id == invocation.positionalArguments.first,
        ),
      ),
    );
  });

  Future<void> pumpList(
    WidgetTester tester, {
    required Size surfaceSize,
  }) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          watchSpeakersProvider.overrideWithValue(WatchSpeakers(repository)),
          getSpeakerProvider.overrideWithValue(GetSpeaker(repository)),
          createSpeakerProvider.overrideWithValue(CreateSpeaker(repository)),
          watchSpeakerEventsProvider
              .overrideWithValue(WatchSpeakerEvents(repository)),
          organizationsListProvider
              .overrideWith((ref) => Stream.value(_organizations)),
        ],
        child: const MaterialApp(home: SpeakersListScreen()),
      ),
    );
    await tester.pump();
  }

  group('SpeakersListScreen — contenido', () {
    testWidgets('muestra el buscador y el listado de speakers',
        (tester) async {
      await pumpList(tester, surfaceSize: const Size(390, 844));

      expect(find.text('Buscar por nombre'), findsOneWidget);
      expect(find.text('Nara Ortiz'), findsOneWidget);
      expect(find.text('Docente de física'), findsOneWidget);
    });

    testWidgets('el botón de filtros abre el panel lateral con los lugares',
        (tester) async {
      await pumpList(tester, surfaceSize: const Size(390, 844));
      await tester.pump();

      expect(find.text('Filtrar por lugar'), findsNothing);

      await tester.tap(find.byTooltip('Filtros'));
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsOneWidget);
      expect(find.text('Filtrar por lugar'), findsOneWidget);
      expect(find.text('Todos los lugares'), findsOneWidget);
      expect(find.text('Colegio San José'), findsOneWidget);
      expect(find.text('Bucaramanga'), findsOneWidget);
    });

    testWidgets('filtra por nombre mientras se escribe', (tester) async {
      await pumpList(tester, surfaceSize: const Size(390, 844));

      await tester.enterText(find.byType(TextFormField), 'juan');
      await tester.pumpAndSettle();

      expect(find.text('Juan Pérez'), findsOneWidget);
      expect(find.text('Nara Ortiz'), findsNothing);
    });

    testWidgets('elegir un lugar en el panel filtra y cierra el panel',
        (tester) async {
      await pumpList(tester, surfaceSize: const Size(390, 844));
      await tester.pump();

      await tester.tap(find.byTooltip('Filtros'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Colegio San José'));
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsNothing);
      expect(find.text('Nara Ortiz'), findsOneWidget);
      expect(find.text('Juan Pérez'), findsNothing);

      await tester.tap(find.byTooltip('Filtros'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Todos los lugares'));
      await tester.pumpAndSettle();

      expect(find.text('Nara Ortiz'), findsOneWidget);
      expect(find.text('Juan Pérez'), findsOneWidget);
    });

    testWidgets('muestra estado vacío cuando no hay coincidencias',
        (tester) async {
      await pumpList(tester, surfaceSize: const Size(390, 844));

      await tester.enterText(find.byType(TextFormField), 'zzzz');
      await tester.pumpAndSettle();

      expect(
        find.text('No hay speakers que coincidan con la búsqueda.'),
        findsOneWidget,
      );
    });
  });

  group('SpeakersListScreen — flujo principal', () {
    testWidgets('tocar una tarjeta abre el perfil del speaker',
        (tester) async {
      await pumpList(tester, surfaceSize: const Size(390, 844));

      await tester.tap(find.byType(SpeakerCard).first);
      await tester.pumpAndSettle();

      verify(() => repository.watchEvents('sp-1')).called(1);
      expect(find.text('Perfil del speaker'), findsOneWidget);
      expect(find.text('ESPECIALIDADES'), findsOneWidget);
    });

    testWidgets('el botón flotante abre el formulario de alta',
        (tester) async {
      await pumpList(tester, surfaceSize: const Size(390, 844));

      expect(find.byType(AppFab), findsOneWidget);
      await tester.tap(find.byType(AppFab));
      await tester.pumpAndSettle();

      expect(find.text('Nuevo speaker'), findsOneWidget);
      expect(find.text('Crear speaker'), findsOneWidget);
    });
  });

  group('SpeakersListScreen — error visible', () {
    testWidgets('muestra el error si el stream de speakers falla',
        (tester) async {
      when(() => repository.watchAll())
          .thenAnswer((_) => Stream.error(Exception('firestore caído')));

      await pumpList(tester, surfaceSize: const Size(390, 844));
      await tester.pumpAndSettle();

      expect(find.textContaining('Error:'), findsOneWidget);
    });
  });

  group('SpeakersListScreen — responsive', () {
    testWidgets('en pantalla angosta usa lista', (tester) async {
      await pumpList(tester, surfaceSize: const Size(390, 844));

      expect(find.byType(ListView), findsWidgets);
      expect(find.byType(GridView), findsNothing);
    });

    testWidgets('en pantalla ancha usa grid', (tester) async {
      await pumpList(tester, surfaceSize: const Size(1200, 800));

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Nara Ortiz'), findsOneWidget);
    });

    testWidgets('en pantalla ancha el panel de filtros también se abre',
        (tester) async {
      await pumpList(tester, surfaceSize: const Size(1200, 800));
      await tester.pump();

      await tester.tap(find.byTooltip('Filtros'));
      await tester.pumpAndSettle();

      expect(find.text('Filtrar por lugar'), findsOneWidget);
      expect(find.text('Universidad del Valle'), findsOneWidget);
    });
  });
}
