import '../entities/event_entity.dart';
import '../entities/featured_event.dart';

class ResolveFeaturedEvent {
  const ResolveFeaturedEvent();

  FeaturedEvent? call({
    required List<EventEntity> events,
    required DateTime now,
  }) {
    if (events.isEmpty) return null;

    final sorted = [...events]..sort((a, b) => a.startAt.compareTo(b.startAt));

    for (final event in sorted) {
      if (event.timingAt(now) == EventTiming.live) {
        return FeaturedEvent(event: event, timing: EventTiming.live);
      }
    }

    for (final event in sorted) {
      if (event.timingAt(now) == EventTiming.upcoming) {
        return FeaturedEvent(event: event, timing: EventTiming.upcoming);
      }
    }

    final lastFinished = sorted.reduce(
      (a, b) => b.endAt.isAfter(a.endAt) ? b : a,
    );
    return FeaturedEvent(event: lastFinished, timing: EventTiming.finished);
  }
}
