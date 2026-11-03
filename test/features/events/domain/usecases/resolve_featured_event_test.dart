import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/features/events/domain/entities/event_entity.dart';
import 'package:nova_app/features/events/domain/usecases/resolve_featured_event.dart';

final _now = DateTime(2026, 10, 7, 10);

EventEntity _event(String id, DateTime start, {int minutes = 90}) {
  return EventEntity(
    id: id,
    name: id,
    startAt: start,
    endAt: start.add(Duration(minutes: minutes)),
    organizationId: 'org',
  );
}

void main() {
  const resolve = ResolveFeaturedEvent();

  test('sin eventos devuelve null', () {
    expect(resolve(events: const [], now: _now), isNull);
  });

  test('prioriza el evento en curso sobre el próximo', () {
    final result = resolve(
      events: [
        _event('next', _now.add(const Duration(hours: 1))),
        _event('live', _now.subtract(const Duration(minutes: 20))),
      ],
      now: _now,
    )!;

    expect(result.event.id, 'live');
    expect(result.timing, EventTiming.live);
  });

  test('si nada está en curso, elige el próximo más cercano', () {
    final result = resolve(
      events: [
        _event('far', _now.add(const Duration(days: 3))),
        _event('past', _now.subtract(const Duration(days: 1))),
        _event('soon', _now.add(const Duration(hours: 2))),
      ],
      now: _now,
    )!;

    expect(result.event.id, 'soon');
    expect(result.timing, EventTiming.upcoming);
  });

  test('si todos terminaron, devuelve el último como finalizado', () {
    final result = resolve(
      events: [
        _event('older', _now.subtract(const Duration(days: 4))),
        _event('latest', _now.subtract(const Duration(hours: 3))),
      ],
      now: _now,
    )!;

    expect(result.event.id, 'latest');
    expect(result.timing, EventTiming.finished);
  });

  test('el instante exacto de fin ya cuenta como finalizado', () {
    final event = _event('e', _now.subtract(const Duration(minutes: 90)));

    expect(event.timingAt(_now), EventTiming.finished);
    expect(
      event.timingAt(_now.subtract(const Duration(minutes: 1))),
      EventTiming.live,
    );
  });
}
