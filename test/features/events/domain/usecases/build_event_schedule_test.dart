import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/features/events/domain/entities/event_entity.dart';
import 'package:nova_app/features/events/domain/usecases/build_event_schedule.dart';

final _now = DateTime(2026, 10, 7, 10);

EventEntity _event(String id, DateTime start, {String city = 'Bucaramanga'}) {
  return EventEntity(
    id: id,
    name: id,
    startAt: start,
    endAt: start.add(const Duration(hours: 1)),
    organizationId: 'org',
    city: city,
  );
}

void main() {
  const build = BuildEventSchedule();

  final events = [
    _event('b', DateTime(2026, 10, 12, 17)),
    _event('past', DateTime(2026, 10, 1, 9)),
    _event('a', DateTime(2026, 10, 12, 9), city: 'Floridablanca'),
    _event('c', DateTime(2026, 10, 14, 8)),
  ];

  test('agrupa por día en orden y oculta los finalizados', () {
    final days = build(events: events, now: _now);

    expect(days.map((d) => d.day), [
      DateTime(2026, 10, 12),
      DateTime(2026, 10, 14),
    ]);
    expect(days.first.events.map((e) => e.id), ['a', 'b']);
  });

  test('incluye los finalizados si se pide', () {
    final days = build(events: events, now: _now, includeFinished: true);

    expect(days.first.day, DateTime(2026, 10, 1));
    expect(days, hasLength(3));
  });

  test('filtra por ciudad sin importar mayúsculas', () {
    final days = build(events: events, now: _now, city: 'floridablanca');

    expect(days, hasLength(1));
    expect(days.single.events.single.id, 'a');
  });

  test('lista las ciudades de eventos por venir, sin repetir', () {
    final cities = build.citiesOf(
      events: [
        ...events,
        _event('d', DateTime(2026, 10, 20), city: 'bucaramanga'),
        _event('old', DateTime(2026, 9, 1), city: 'Girón'),
      ],
      now: _now,
    );

    expect(cities, ['Bucaramanga', 'Floridablanca']);
  });
}
