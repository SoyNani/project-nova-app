import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/speaker_event_entity.dart';

class SpeakerEventModel extends SpeakerEventEntity {
  const SpeakerEventModel({
    required super.id,
    required super.name,
    super.date,
  });

  factory SpeakerEventModel.fromFirestore(Map<String, dynamic> json, String id) {
    return SpeakerEventModel(
      id: id,
      name: json['name'] as String? ?? '',
      date: parseDate(json['date']),
    );
  }

  static DateTime? parseDate(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String && raw.trim().isNotEmpty) {
      return DateTime.tryParse(raw.trim());
    }
    if (raw is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        raw.toInt(),
        isUtc: true,
      ).toLocal();
    }
    return null;
  }
}
