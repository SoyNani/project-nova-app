import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/event_entity.dart';

/// Model = Entity + serialización. Vive en la colección `conferences`,
/// la misma que lee speakers para "eventos asignados": `date` es el
/// inicio y `endDate` el fin, ambos como Timestamp.
class EventModel extends EventEntity {
  static const statusScheduled = 'scheduled';
  static const statusCancelled = 'cancelled';

  const EventModel({
    required super.id,
    required super.name,
    required super.startAt,
    required super.endAt,
    required super.organizationId,
    super.description,
    super.organizationName,
    super.city,
    super.address,
    super.speakerIds,
    super.speakerNames,
    super.createdBy,
    super.isCancelled,
    super.cancelledAt,
  });

  factory EventModel.fromFirestore(Map<String, dynamic> json, String id) {
    final startAt = parseDate(json['date']) ?? DateTime(1970);
    final endAt = parseDate(json['endDate']) ?? startAt;
    return EventModel(
      id: id,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      startAt: startAt,
      endAt: endAt,
      organizationId: json['organizationId'] as String? ?? '',
      organizationName: json['organizationName'] as String? ?? '',
      city: json['city'] as String? ?? '',
      address: json['address'] as String? ?? '',
      speakerIds: _toStringList(json['speakerIds']),
      speakerNames: _toStringList(json['speakerNames']),
      createdBy: json['createdBy'] as String?,
      isCancelled: json['status'] == statusCancelled,
      cancelledAt: parseDate(json['cancelledAt']),
    );
  }

  factory EventModel.fromEntity(EventEntity entity) {
    return EventModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      startAt: entity.startAt,
      endAt: entity.endAt,
      organizationId: entity.organizationId,
      organizationName: entity.organizationName,
      city: entity.city,
      address: entity.address,
      speakerIds: entity.speakerIds,
      speakerNames: entity.speakerNames,
      createdBy: entity.createdBy,
      isCancelled: entity.isCancelled,
      cancelledAt: entity.cancelledAt,
    );
  }

  EventModel copyWithId(String newId) {
    return EventModel(
      id: newId,
      name: name,
      description: description,
      startAt: startAt,
      endAt: endAt,
      organizationId: organizationId,
      organizationName: organizationName,
      city: city,
      address: address,
      speakerIds: speakerIds,
      speakerNames: speakerNames,
      createdBy: createdBy,
      isCancelled: isCancelled,
      cancelledAt: cancelledAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'date': Timestamp.fromDate(startAt),
      'endDate': Timestamp.fromDate(endAt),
      'organizationId': organizationId,
      'organizationName': organizationName,
      'city': city,
      'address': address,
      'speakerIds': speakerIds,
      'speakerNames': speakerNames,
      'createdBy': createdBy,
      'status': isCancelled ? statusCancelled : statusScheduled,
    };
  }

  Map<String, dynamic> toFirestoreCreate() {
    return {...toFirestore(), 'createdAt': FieldValue.serverTimestamp()};
  }

  /// `date` puede venir como Timestamp (lo que escribe la app), como ISO
  /// String o como milisegundos.
  static DateTime? parseDate(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String && raw.trim().isNotEmpty) {
      return DateTime.tryParse(raw.trim())?.toLocal();
    }
    if (raw is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        raw.toInt(),
        isUtc: true,
      ).toLocal();
    }
    return null;
  }

  static List<String> _toStringList(Object? raw) {
    if (raw is! List) return const [];
    return raw.map((item) => item.toString()).toList();
  }
}
