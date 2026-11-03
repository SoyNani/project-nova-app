import '../../../events/domain/entities/event_entity.dart';
import '../../../events/domain/usecases/build_event_schedule.dart';
import '../entities/calendar_month.dart';

class BuildCalendarMonth {
  const BuildCalendarMonth({this.schedule = const BuildEventSchedule()});

  final BuildEventSchedule schedule;

  CalendarMonth call({
    required List<EventEntity> events,
    required DateTime month,
  }) {
    final first = DateTime(month.year, month.month);
    final inMonth = events
        .where(
          (e) => e.startAt.year == first.year && e.startAt.month == first.month,
        )
        .toList();

    final days = schedule(events: inMonth, now: first, includeFinished: true);

    final counts = <String, int>{};
    final names = <String, String>{};
    for (final event in inMonth) {
      final name = event.city.trim();
      if (name.isEmpty) continue;
      final key = name.toLowerCase();
      names.putIfAbsent(key, () => name);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final keys = counts.keys.toList()
      ..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        return byCount != 0 ? byCount : a.compareTo(b);
      });

    return CalendarMonth(
      month: first,
      days: days,
      cities: [for (final key in keys) names[key]!],
    );
  }
}
