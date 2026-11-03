import '../../domain/entities/speaker_entity.dart';

class SpeakerModel extends SpeakerEntity {
  const SpeakerModel({
    required super.id,
    required super.name,
    required super.profession,
    super.specialties,
    super.organizationIds,
    super.email,
    super.photoUrl,
    super.instagram,
    super.linkedin,
    super.tiktok,
  });

  factory SpeakerModel.fromFirestore(Map<String, dynamic> json, String id) {
    return SpeakerModel(
      id: id,
      name: json['name'] as String? ?? '',
      profession: json['profession'] as String? ?? '',
      specialties: _toStringList(json['specialties']),
      organizationIds: _toStringList(json['organizationIds']),
      email: _toNullableString(json['email'])?.toLowerCase(),
      photoUrl: _toNullableString(json['photoUrl']),
      instagram: _toNullableString(json['instagram']),
      linkedin: _toNullableString(json['linkedin']),
      tiktok: _toNullableString(json['tiktok']),
    );
  }

  factory SpeakerModel.fromEntity(SpeakerEntity entity) {
    return SpeakerModel(
      id: entity.id,
      name: entity.name,
      profession: entity.profession,
      specialties: entity.specialties,
      organizationIds: entity.organizationIds,
      email: entity.email,
      photoUrl: entity.photoUrl,
      instagram: entity.instagram,
      linkedin: entity.linkedin,
      tiktok: entity.tiktok,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'profession': profession,
      'specialties': specialties,
      'organizationIds': organizationIds,
      'email': email,
      'photoUrl': photoUrl,
      'instagram': instagram,
      'linkedin': linkedin,
      'tiktok': tiktok,
    };
  }

  Map<String, dynamic> toFirestoreCreate() {
    return {
      ...toFirestore(),
      'photoUrl': null,
    };
  }

  static List<String> _toStringList(Object? raw) {
    if (raw is! List) return const [];
    return raw.map((item) => item.toString()).toList();
  }

  static String? _toNullableString(Object? raw) {
    if (raw is! String) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
