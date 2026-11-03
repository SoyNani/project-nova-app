import '../../domain/entities/organization_entity.dart';

class OrganizationModel extends OrganizationEntity {
  const OrganizationModel({
    required super.id,
    required super.name,
    required super.city,
    required super.department,
    required super.address,
    required super.latitude,
    required super.longitude,
    super.eventsCount,
  });

  factory OrganizationModel.fromFirestore(
    Map<String, dynamic> json,
    String id,
  ) {
    return OrganizationModel(
      id: id,
      name: json['name'] as String? ?? '',
      city: json['city'] as String? ?? '',
      department: json['department'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: (json['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['lng'] as num?)?.toDouble() ?? 0.0,
      eventsCount: (json['eventsCount'] as num?)?.toInt() ?? 0,
    );
  }

  factory OrganizationModel.fromEntity(OrganizationEntity entity) {
    return OrganizationModel(
      id: entity.id,
      name: entity.name,
      city: entity.city,
      department: entity.department,
      address: entity.address,
      latitude: entity.latitude,
      longitude: entity.longitude,
      eventsCount: entity.eventsCount,
    );
  }

  Map<String, dynamic> toFirestoreCreate() {
    return {
      'name': name,
      'city': city,
      'department': department,
      'address': address,
      'lat': latitude,
      'lng': longitude,
      'eventsCount': 0,
    };
  }

  Map<String, dynamic> toFirestoreUpdate() {
    return {
      'name': name,
      'city': city,
      'department': department,
      'address': address,
      'lat': latitude,
      'lng': longitude,
    };
  }
}
