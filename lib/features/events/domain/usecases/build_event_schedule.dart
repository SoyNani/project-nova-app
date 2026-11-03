import '../entities/event_entity.dart';
import '../entities/event_schedule_day.dart';

/// Arma el cronograma: agrupa los eventos por día y los ordena por hora.
/// Por defecto deja fuera los que ya terminaron (el home muestra lo que viene); el listado completo pasa `includeFinished: true`.
class BuildEventSchedule {
  const BuildEventSchedule();

  List<EventScheduleDay> call({
    required List<EventEntity> events,
    required DateTime now,
    String? city,
    bool includeFinished = false,
  }) {
    final visible = events.where((event) {
      final matchesCity = city == null || _sameCity(event.city, city);
      final isVisible =
          includeFinished || event.timingAt(now) != EventTiming.finished;
      return matchesCity && isVisible;
    }).toList()..sort((a, b) => a.startAt.compareTo(b.startAt));

    final days = <EventScheduleDay>[];
    for (final event in visible) {
      final day = DateTime(
        event.startAt.year,
        event.startAt.month,
        event.startAt.day,
      );
      if (days.isNotEmpty && days.last.day == day) {
        days.last.events.add(event);
      } else {
        days.add(EventScheduleDay(day: day, events: [event]));
      }
    }
    return days;
  }

  /// Ciudades de los eventos visibles, sin repetir y en orden alfabético.
  List<String> citiesOf({
    required List<EventEntity> events,
    required DateTime now,
    bool includeFinished = false,
  }) {
    final cities = <String>[];
    for (final event in events) {
      final city = event.city.trim();
      if (city.isEmpty) continue;
      if (!includeFinished && event.timingAt(now) == EventTiming.finished) {
        continue;
      }
      if (!cities.any((c) => _sameCity(c, city))) cities.add(city);
    }
    return cities..sort();
  }

  static bool _sameCity(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();
}
