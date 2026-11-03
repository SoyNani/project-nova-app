import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/features/calendar/domain/usecases/build_calendar_month.dart';
import 'package:nova_app/features/events/domain/entities/event_entity.dart';

void main() {
  const build = BuildCalendarMonth();

  EventEntity event(String id, DateTime start, {String city = ''}) =>
      EventEntity(
        id: id,
        name: 'Evento $id',
        startAt: start,
        endAt: start.add(const Duration(hours: 1)),
        organizationId: 'org',
        city: city,
      );

  final events = [
    event('a', DateTime(2026, 10, 8, 9), city: 'Bucaramanga'),
    event('b', DateTime(2026, 10, 8, 15), city: 'Floridablanca'),
    event('c', DateTime(2026, 10, 21, 10), city: 'bucaramanga'),
    event('d', DateTime(2026, 9, 30, 10), city: 'Girón'),
    event('e', DateTime(2026, 11, 2, 10), city: 'Girón'),
  ];

  test('cuenta solo las conferencias del mes pedido', () {
    final month = build(events: events, month: DateTime(2026, 10, 15));

    expect(month.month, DateTime(2026, 10));
    expect(month.eventsCount, 3);
    expect(month.days.map((d) => d.day), [
      DateTime(2026, 10, 8),
      DateTime(2026, 10, 21),
    ]);
  });

  test('agrupa por día y ordena por hora', () {
    final month = build(events: events, month: DateTime(2026, 10));

    expect(month.eventsOn(DateTime(2026, 10, 8)).map((e) => e.id), ['a', 'b']);
    expect(month.eventsOn(DateTime(2026, 10, 9)), isEmpty);
  });

  test('ordena las ciudades por cantidad sin distinguir mayúsculas', () {
    final month = build(events: events, month: DateTime(2026, 10));

    expect(month.cities, ['Bucaramanga', 'Floridablanca']);
    expect(month.cityIndexOf('BUCARAMANGA'), 0);
    expect(month.cityIndexOf(''), -1);
  });

  test('un mes sin eventos queda vacío', () {
    final month = build(events: events, month: DateTime(2027, 1));

    expect(month.eventsCount, 0);
    expect(month.days, isEmpty);
    expect(month.cities, isEmpty);
  });
}
