import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_app/features/speakers/domain/entities/speaker_entity.dart';
import 'package:nova_app/features/speakers/domain/entities/speaker_event_entity.dart';
import 'package:nova_app/features/speakers/domain/entities/speaker_failure.dart';
import 'package:nova_app/features/speakers/domain/repositories/speaker_repository.dart';
import 'package:nova_app/features/speakers/domain/usecases/get_speaker.dart';
import 'package:nova_app/features/speakers/domain/usecases/watch_speaker_events.dart';
import 'package:nova_app/features/speakers/presentation/providers/speaker_providers.dart';
import 'package:nova_app/features/speakers/presentation/screens/speaker_detail_screen.dart';

class _MockSpeakerRepository extends Mock implements SpeakerRepository {}

const _speaker = SpeakerEntity(
  id: 'sp-1',
  name: 'Nara María Ortiz',
  profession: 'Ingeniera de software',
  specialties: ['Flutter', 'Dart'],
  organizationIds: ['org-1'],
  instagram: '@nara',
  linkedin: 'linkedin.com/in/nara',
  tiktok: '@naratiktok',
);

void main() {
  late _MockSpeakerRepository repository;

  Future<void> pumpDetail(
    WidgetTester tester, {
    required Size surfaceSize,
    SpeakerEntity speaker = _speaker,
  }) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          getSpeakerProvider.overrideWithValue(GetSpeaker(repository)),
          watchSpeakerEventsProvider
              .overrideWithValue(WatchSpeakerEvents(repository)),
        ],
        child: MaterialApp(home: SpeakerDetailScreen(speaker: speaker)),
      ),
    );
    await tester.pump();
  }

  setUp(() {
    repository = _MockSpeakerRepository();
    when(() => repository.watchEvents(any()))
        .thenAnswer((_) => Stream.value(const <SpeakerEventEntity>[]));
    when(() => repository.getById(any()))
        .thenAnswer((_) async => right(_speaker));
  });

  group('SpeakerDetailScreen — contenido', () {
    testWidgets('muestra nombre, profesión, iniciales y especialidades',
        (tester) async {
      await pumpDetail(tester, surfaceSize: const Size(390, 844));
      await tester.pumpAndSettle();

      expect(find.text('Perfil del speaker'), findsOneWidget);
      expect(find.text('Nara María Ortiz'), findsOneWidget);
      expect(find.text('Ingeniera de software'), findsOneWidget);
      expect(find.text('NM'), findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Dart'), findsOneWidget);
    });

    testWidgets('muestra las tres redes sociales', (tester) async {
      await pumpDetail(tester, surfaceSize: const Size(390, 844));
      await tester.pumpAndSettle();

      expect(find.text('REDES SOCIALES'), findsOneWidget);
      expect(find.text('@nara'), findsOneWidget);
      expect(find.text('linkedin.com/in/nara'), findsOneWidget);
      expect(find.text('@naratiktok'), findsOneWidget);
    });

    testWidgets('oculta las redes que el speaker no tiene',
        (tester) async {
      when(() => repository.getById(any())).thenAnswer(
        (_) async => right(
          const SpeakerEntity(
            id: 'sp-2',
            name: 'Juan Pérez',
            profession: 'Docente',
          ),
        ),
      );

      await pumpDetail(
        tester,
        surfaceSize: const Size(390, 844),
        speaker: const SpeakerEntity(
          id: 'sp-2',
          name: 'Juan Pérez',
          profession: 'Docente',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('REDES SOCIALES'), findsNothing);
      expect(find.text('Sin especialidades.'), findsOneWidget);
    });
  });

  group('SpeakerDetailScreen — eventos asignados', () {
    testWidgets('lista los eventos con su fecha', (tester) async {
      when(() => repository.watchEvents(any())).thenAnswer(
        (_) => Stream.value([
          const SpeakerEventEntity(
            id: 'ev-1',
            name: 'Flutter Day',
            date: null,
          ),
        ]),
      );

      await pumpDetail(tester, surfaceSize: const Size(390, 844));
      await tester.pumpAndSettle();

      expect(find.text('EVENTOS ASIGNADOS'), findsOneWidget);
      expect(find.text('Flutter Day'), findsOneWidget);
    });

    testWidgets('avisa cuando no hay eventos asignados', (tester) async {
      await pumpDetail(tester, surfaceSize: const Size(390, 844));
      await tester.pumpAndSettle();

      expect(find.text('Sin eventos asignados.'), findsOneWidget);
    });
  });

  group('SpeakerDetailScreen — errores visibles', () {
    testWidgets('muestra el mensaje si falla el perfil', (tester) async {
      when(() => repository.getById(any()))
          .thenAnswer((_) async => left(const SpeakerNotFound()));

      await pumpDetail(tester, surfaceSize: const Size(390, 844));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Speaker no encontrado.'),
        findsOneWidget,
      );
      expect(find.text('Nara María Ortiz'), findsOneWidget);
    });

    testWidgets('muestra el mensaje si fallan los eventos', (tester) async {
      when(() => repository.watchEvents(any()))
          .thenAnswer((_) => Stream.error(Exception('sin permisos')));

      await pumpDetail(tester, surfaceSize: const Size(390, 844));
      await tester.pumpAndSettle();

      expect(
        find.text('No se pudieron cargar los eventos asignados.'),
        findsOneWidget,
      );
    });
  });

  group('SpeakerDetailScreen — responsive', () {
    testWidgets('en pantalla angosta apila las secciones', (tester) async {
      await pumpDetail(tester, surfaceSize: const Size(390, 844));
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('EVENTOS ASIGNADOS'), findsOneWidget);
    });

    testWidgets('en pantalla ancha las muestra en dos columnas',
        (tester) async {
      await pumpDetail(tester, surfaceSize: const Size(1200, 800));
      await tester.pumpAndSettle();

      expect(find.byType(Row), findsWidgets);
      expect(find.text('ESPECIALIDADES'), findsOneWidget);
      expect(find.text('EVENTOS ASIGNADOS'), findsOneWidget);
    });
  });
}
