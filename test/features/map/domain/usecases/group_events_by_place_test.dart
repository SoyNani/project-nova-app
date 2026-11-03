import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/features/events/domain/entities/event_entity.dart';
import 'package:nova_app/features/map/domain/usecases/group_events_by_place.dart';
import 'package:nova_app/features/organizations/domain/entities/organization_entity.dart';

void main() {
  const group = GroupEventsByPlace();

  OrganizationEntity org(String id) => OrganizationEntity(
    id: id,
    name: 'Org $id',
    city: 'Bucaramanga',
    department: 'Santander',
    address: 'Cra 27 # 45-12',
    latitude: 7.1,
    longitude: -73.1,
  );

  EventEntity event(String id, String orgId, DateTime start) => EventEntity(
    id: id,
    name: 'Evento $id',
    startAt: start,
    endAt: start.add(const Duration(hours: 2)),
    organizationId: orgId,
  );

  test('agrupa los eventos por organización, ordenados por inicio', () {
    final places = group(
      events: [
        event('b', 'o1', DateTime(2026, 10, 20)),
        event('a', 'o1', DateTime(2026, 10, 10)),
        event('c', 'o2', DateTime(2026, 10, 15)),
      ],
      organizations: [org('o1'), org('o2')],
    );

    expect(places, hasLength(2));
    final first = places.firstWhere((p) => p.organization.id == 'o1');
    expect(first.events.map((e) => e.id), ['a', 'b']);
  });

  test('omite eventos cuya organización no existe', () {
    final places = group(
      events: [event('a', 'borrada', DateTime(2026, 10, 10))],
      organizations: [org('o1')],
    );

    expect(places, isEmpty);
  });

  test('destaca el evento en curso o próximo antes que uno finalizado', () {
    final places = group(
      events: [
        event('pasado', 'o1', DateTime(2026, 10, 1)),
        event('proximo', 'o1', DateTime(2026, 10, 20)),
      ],
      organizations: [org('o1')],
    );

    expect(places.single.highlightedAt(DateTime(2026, 10, 8)).id, 'proximo');
  });
}
