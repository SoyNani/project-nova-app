import '../../../events/domain/entities/event_entity.dart';
import '../../../organizations/domain/entities/organization_entity.dart';
import '../entities/event_map_place.dart';

class GroupEventsByPlace {
  const GroupEventsByPlace();

  List<EventMapPlace> call({
    required List<EventEntity> events,
    required List<OrganizationEntity> organizations,
  }) {
    final byId = {for (final org in organizations) org.id: org};
    final grouped = <String, List<EventEntity>>{};
    for (final event in events) {
      if (!byId.containsKey(event.organizationId)) continue;
      grouped.putIfAbsent(event.organizationId, () => []).add(event);
    }
    return [
      for (final entry in grouped.entries)
        EventMapPlace(
          organization: byId[entry.key]!,
          events: entry.value..sort((a, b) => a.startAt.compareTo(b.startAt)),
        ),
    ];
  }
}
