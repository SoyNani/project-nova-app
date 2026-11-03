import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/features/organizations/domain/entities/organization_entity.dart';
import 'package:nova_app/features/organizations/domain/usecases/filter_organizations.dart';

void main() {
  const organizations = [
    OrganizationEntity(
      id: '1',
      name: 'Hotel Bari Central',
      city: 'Bucaramanga',
      department: 'Santander',
      address: 'Cra 27',
      latitude: 7.1,
      longitude: -73.1,
    ),
    OrganizationEntity(
      id: '2',
      name: 'NEOMUNDO',
      city: 'Bucaramanga',
      department: 'Santander',
      address: 'Calle 56',
      latitude: 7.2,
      longitude: -73.2,
    ),
    OrganizationEntity(
      id: '3',
      name: 'Colegio San José',
      city: 'Bucaramanga',
      department: 'Santander',
      address: 'Calle 10',
      latitude: 7.3,
      longitude: -73.3,
    ),
  ];

  const filter = FilterOrganizations();

  test('retorna todas las organizaciones cuando la búsqueda está vacía', () {
    expect(filter(organizations: organizations), organizations);
    expect(filter(organizations: organizations, query: '   '), organizations);
  });

  test('filtra por nombre ignorando mayúsculas y espacios extras', () {
    final result = filter(
      organizations: organizations,
      query: '  bari central  ',
    );
    expect(result.length, 1);
    expect(result.first.name, 'Hotel Bari Central');
  });

  test('calcula correctamente las iniciales según las reglas', () {
    expect(organizations[0].initials, 'HB');
    expect(organizations[1].initials, 'NE');
    expect(organizations[2].initials, 'CS');

    const singleLetterOrg = OrganizationEntity(
      id: '4',
      name: 'U',
      city: 'Bucaramanga',
      department: 'Santander',
      address: 'Cra 1',
      latitude: 0,
      longitude: 0,
    );
    expect(singleLetterOrg.initials, 'U');
  });
}
