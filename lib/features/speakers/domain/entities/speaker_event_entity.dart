class SpeakerEventEntity {
  const SpeakerEventEntity({
    required this.id,
    required this.name,
    this.date,
  });

  final String id;
  final String name;
  final DateTime? date;
}
