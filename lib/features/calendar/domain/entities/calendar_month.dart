import '../../../events/domain/entities/event_entity.dart';
import '../../../events/domain/entities/event_schedule_day.dart';

class CalendarMonth {
  const CalendarMonth({
    required this.month,
    required this.days,
    required this.cities,
  });

  final DateTime month;
  /// Días del mes con conferencias, en orden.
  final List<EventScheduleDay> days;

  final List<String> cities;

  int get eventsCount => days.fold(0, (sum, day) => sum + day.events.length);

  List<EventEntity> eventsOn(DateTime date) {
    for (final day in days) {
      if (day.day.year == date.year &&
          day.day.month == date.month &&
          day.day.day == date.day) {
        return day.events;
      }
    }
    return const [];
  }

  int cityIndexOf(String city) {
    final key = city.trim().toLowerCase();
    if (key.isEmpty) return -1;
    return cities.indexWhere((c) => c.toLowerCase() == key);
  }
}
