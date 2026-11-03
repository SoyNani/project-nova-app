class OrganizationEntity {
  const OrganizationEntity({
    required this.id,
    required this.name,
    required this.city,
    required this.department,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.eventsCount = 0,
  });

  final String id;
  final String name;
  final String city;
  final String department;
  final String address;
  final double latitude;
  final double longitude;
  final int eventsCount;

  String get initials {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      final word = words.first;
      return word.length >= 2
          ? word.substring(0, 2).toUpperCase()
          : word.toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }
}
