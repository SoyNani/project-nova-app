import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/features/calendar/presentation/screens/conferences_calendar_screen.dart';
import 'package:nova_app/features/events/domain/entities/event_entity.dart';
import 'package:nova_app/features/events/presentation/providers/event_providers.dart';

void main() {
  final now = DateTime.now();
  final thisMonth = DateTime(now.year, now.month, 10, 9);
  final nextMonth = DateTime(now.year, now.month + 1, 5, 9);

  EventEntity event(String id, DateTime start, {bool cancelled = false}) =>
      EventEntity(
        id: id,
        name: 'Conferencia $id',
        startAt: start,
        endAt: start.add(const Duration(hours: 1)),
        organizationId: 'org',
        organizationName: 'Colegio San Pedro',
        city: 'Bucaramanga',
        isCancelled: cancelled,
      );

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventsListProvider.overrideWith(
            (ref) => Stream.value([
              event('1', thisMonth),
              event('2', thisMonth.add(const Duration(hours: 3))),
              event('3', nextMonth),
              event('4', thisMonth, cancelled: true),
            ]),
          ),
          clockProvider.overrideWith((ref) => Stream.value(now)),
        ],
        child: const MaterialApp(home: ConferencesCalendarScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('muestra el título y el contador del mes visible', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Conferencias'), findsOneWidget);
    expect(find.text('2 conferencias este mes'), findsOneWidget);
    expect(find.text('Conferencia 1'), findsOneWidget);
    expect(find.text('Conferencia 3'), findsNothing);
    expect(find.byIcon(Icons.search), findsNothing);
  });

  testWidgets('al pasar de mes cambia el contador y el cronograma', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('Mes siguiente'));
    await tester.pumpAndSettle();

    expect(find.text('1 conferencia este mes'), findsOneWidget);
    expect(find.text('Conferencia 3'), findsOneWidget);

    await tester.tap(find.text('Hoy'));
    await tester.pumpAndSettle();
    expect(find.text('2 conferencias este mes'), findsOneWidget);
  });
}
