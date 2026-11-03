abstract final class SpeakerFieldCleaner {
  static List<String> list(List<String> values) {
    final cleaned = <String>[];
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty && !cleaned.contains(trimmed)) {
        cleaned.add(trimmed);
      }
    }
    return cleaned;
  }

  static String? optional(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  static String? email(String? value) => optional(value)?.toLowerCase();
}
