class SpeakerEntity {
  const SpeakerEntity({
    required this.id,
    required this.name,
    required this.profession,
    this.specialties = const [],
    this.organizationIds = const [],
    this.email,
    this.photoUrl,
    this.instagram,
    this.linkedin,
    this.tiktok,
  });

  final String id;
  final String name;
  final String profession;
  final List<String> specialties;

  final List<String> organizationIds;

  final String? email;

  final String? photoUrl;

  final String? instagram;
  final String? linkedin;
  final String? tiktok;

  String get initials {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return (words.first[0] + words[1][0]).toUpperCase();
  }

  bool get hasPhoto => photoUrl != null && photoUrl!.trim().isNotEmpty;
}
