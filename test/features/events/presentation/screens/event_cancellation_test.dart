import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_app/app/screens/home_screen.dart';
import 'package:nova_app/features/auth/domain/entities/user_entity.dart';
import 'package:nova_app/features/events/domain/entities/event_entity.dart';
import 'package:nova_app/features/events/domain/repositories/event_repository.dart';
import 'package:nova_app/features/events/presentation/providers/event_providers.dart';
import 'package:nova_app/features/events/presentation/screens/cancelled_events_screen.dart';
import 'package:nova_app/features/events/presentation/screens/event_detail_screen.dart';
import 'package:nova_app/features/events/presentation/screens/events_list_screen.dart';

class _MockEventRepository extends Mock implements EventRepository {}

final _now = DateTime(2026, 10, 7, 10);

EventEntity _event(String id, String name, {bool cancelled = false}) {
  final start = _now.add(const Duration(days: 2));
  return EventEntity(
    id: id,
    name: name,
    startAt: start,
    endAt: start.add(const Duration(hours: 1)),
    organizationId: 'org-1',
    organizationName: 'Colegio San Pedro Claver',
    city: 'Bucaramanga',
    isCancelled: cancelled,
    cancelledAt: cancelled ? DateTime(2026, 10, 6) : null,
  );
}

final _active = _event('ev-1', 'Innovación educativa');
final _cancelled = _event('ev-2', 'Emprendimiento social', cancelled: true);

void main() {
  late _MockEventRepository repository;

  setUpAll(() => registerFallbackValue(_active));

  setUp(() {
    repository = _MockEventRepository();
    when(() => repository.cancel(any())).thenAnswer((_) async => right(null));
    when(() => repository.restore(any())).thenAnswer((_) async => right(null));
  });

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventRepositoryProvider.overrideWithValue(repository),
          eventsListProvider.overrideWith(
            (ref) => Stream.value([_active, _cancelled]),
          ),
          clockProvider.overrideWith((ref) => Stream.value(_now)),
        ],
        child: MaterialApp(home: home),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('el home y el cronograma ignoran los eventos cancelados', (
    tester,
  ) async {
    await pump(
      tester,
      const HomeScreen(
        user: UserEntity(
          uid: 'u',
          email: 'e',
          displayName: 'Nara',
          role: UserRole.usuario,
        ),
      ),
    );

    expect(find.text('Innovación educativa'), findsWidgets);
    expect(find.text('Emprendimiento social'), findsNothing);
  });

  testWidgets('cancela desde el detalle tras confirmar y ofrece deshacer', (
    tester,
  ) async {
    await pump(tester, const EventsListScreen());
    await tester.tap(find.text('Innovación educativa'));
    await tester.pumpAndSettle();

    final button = find.text('Ya no asistiré · Cancelar evento');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancelar evento'));
    await tester.pumpAndSettle();

    verify(() => repository.cancel(any())).called(1);
    expect(find.byType(EventDetailScreen), findsNothing);
    expect(find.text('Evento cancelado.'), findsOneWidget);

    await tester.tap(find.text('Deshacer'));
    await tester.pump();
    verify(() => repository.restore(any())).called(1);
  });

  testWidgets('"Volver" en la confirmación no cancela nada', (tester) async {
    await pump(tester, EventDetailScreen(event: _active));

    await tester.tap(find.byTooltip('Más opciones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar evento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();

    verifyNever(() => repository.cancel(any()));
    expect(find.byType(EventDetailScreen), findsOneWidget);
  });

  testWidgets('los tres puntos del cronograma llevan a los cancelados', (
    tester,
  ) async {
    await pump(tester, const EventsListScreen());

    // El cancelado no está en el cronograma.
    expect(find.text('Emprendimiento social'), findsNothing);

    await tester.tap(find.byTooltip('Más opciones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver cancelados (1)'));
    await tester.pumpAndSettle();

    expect(find.byType(CancelledEventsScreen), findsOneWidget);
    expect(find.text('Emprendimiento social'), findsOneWidget);
    expect(find.text('CANCELADO'), findsOneWidget);
    expect(find.text('Cancelado el 6 oct 2026'), findsOneWidget);
    expect(find.text('Innovación educativa'), findsNothing);
  });

  testWidgets('restaura un evento desde la lista de cancelados', (
    tester,
  ) async {
    await pump(tester, const CancelledEventsScreen());

    await tester.tap(find.text('Restaurar'));
    await tester.pump();

    final restored =
        verify(() => repository.restore(captureAny())).captured.single
            as EventEntity;
    expect(restored.id, 'ev-2');
  });

  testWidgets('el detalle de un cancelado permite restaurarlo', (tester) async {
    await pump(tester, EventDetailScreen(event: _cancelled));

    expect(find.text('CANCELADO'), findsOneWidget);
    expect(find.text('Ya no asistiré · Cancelar evento'), findsNothing);

    final button = find.text('Restaurar evento');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();

    verify(() => repository.restore(any())).called(1);
  });
}
