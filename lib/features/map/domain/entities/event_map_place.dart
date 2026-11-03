import '../../../events/domain/entities/event_entity.dart';
import '../../../organizations/domain/entities/organization_entity.dart';

class EventMapPlace {
  const EventMapPlace({required this.organization, required this.events});

  final OrganizationEntity organization;

  final List<EventEntity> events;

  EventEntity highlightedAt(DateTime now) {
    for (final event in events) {
      if (event.timingAt(now) != EventTiming.finished) return event;
    }
    return events.last;
  }
}
