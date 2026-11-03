import 'event_entity.dart';

class EventScheduleDay {
  const EventScheduleDay({required this.day, required this.events});

  final DateTime day;
  final List<EventEntity> events;
}
