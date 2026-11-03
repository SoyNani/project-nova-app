/// Momento de un evento respecto a "ahora".
enum EventTiming { upcoming, live, finished }

/// Entidad pura de dominio: un evento/conferencia. Guarda copia del nombre, ciudad y dirección de la organización y de los
/// nombres de los speakers para que el home pinte la tarjeta y el
/// cronograma sin consultar otras colecciones.
class EventEntity {
  const EventEntity({
    required this.id,
    required this.name,
    required this.startAt,
    required this.endAt,
    required this.organizationId,
    this.description = '',
    this.organizationName = '',
    this.city = '',
    this.address = '',
    this.speakerIds = const [],
    this.speakerNames = const [],
    this.createdBy,
    this.isCancelled = false,
    this.cancelledAt,
  });

  final String id;
  final String name;
  final String description;
  final DateTime startAt;
  final DateTime endAt;

  final String organizationId;
  final String organizationName;
  final String city;
  final String address;

  final List<String> speakerIds;

  final List<String> speakerNames;

  final String? createdBy;
  final bool isCancelled;
  final DateTime? cancelledAt;

  Duration get duration => endAt.difference(startAt);

  EventTiming timingAt(DateTime now) {
    if (now.isBefore(startAt)) return EventTiming.upcoming;
    if (now.isBefore(endAt)) return EventTiming.live;
    return EventTiming.finished;
  }

  String get placeLabel {
    final parts = [organizationName, city].where((p) => p.trim().isNotEmpty);
    return parts.join(' · ');
  }
}
