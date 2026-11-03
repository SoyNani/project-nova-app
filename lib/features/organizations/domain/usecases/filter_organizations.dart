import '../entities/organization_entity.dart';

class FilterOrganizations {
  const FilterOrganizations();

  List<OrganizationEntity> call({
    required List<OrganizationEntity> organizations,
    String query = '',
  }) {
    final normalized = _normalize(query);
    if (normalized.isEmpty) return organizations;

    return organizations.where((org) {
      return _normalize(org.name).contains(normalized);
    }).toList();
  }

  static String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
