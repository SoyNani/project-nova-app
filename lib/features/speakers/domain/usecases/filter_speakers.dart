import '../entities/speaker_entity.dart';

class FilterSpeakers {
  const FilterSpeakers();

  List<SpeakerEntity> call({
    required List<SpeakerEntity> speakers,
    String query = '',
    String? organizationId,
  }) {
    final normalized = _normalize(query);
    return speakers.where((speaker) {
      final matchesQuery =
          normalized.isEmpty || _normalize(speaker.name).contains(normalized);
      final matchesOrganization = organizationId == null ||
          speaker.organizationIds.contains(organizationId);
      return matchesQuery && matchesOrganization;
    }).toList();
  }

  static String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
