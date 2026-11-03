import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_app/features/organizations/domain/entities/organization_entity.dart';
import 'package:nova_app/features/organizations/domain/entities/organization_failure.dart';
import 'package:nova_app/features/organizations/domain/repositories/organization_repository.dart';
import 'package:nova_app/features/organizations/domain/usecases/create_organization.dart';

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

void main() {
  late _MockOrganizationRepository repository;
  late CreateOrganization usecase;

  setUpAll(() {
    registerFallbackValue(
      const OrganizationEntity(
        id: '',
        name: '',
        city: '',
        department: '',
        address: '',
        latitude: 0,
        longitude: 0,
      ),
    );
  });

  setUp(() {
    repository = _MockOrganizationRepository();
    usecase = CreateOrganization(repository);
  });

  test('recorta espacios en blanco antes de enviar al repositorio', () async {
    when(() => repository.create(any())).thenAnswer(
      (invocation) async => right(
        invocation.positionalArguments.first as OrganizationEntity,
      ),
    );

    await usecase(
      name: '  Colegio San José  ',
      city: ' Bucaramanga ',
      department: 'Santander',
      address: 'Cra 27 # 45-12',
      latitude: 7.1193,
      longitude: -73.1227,
    );

    final captured =
        verify(() => repository.create(captureAny())).captured.single
            as OrganizationEntity;

    expect(captured.name, 'Colegio San José');
    expect(captured.city, 'Bucaramanga');
  });

  test('retorna Left cuando el repositorio falla', () async {
    when(() => repository.create(any())).thenAnswer(
      (_) async => left(OrganizationUnknownError('firestore error')),
    );

    final result = await usecase(
      name: 'Test',
      city: 'Test',
      department: 'Test',
      address: 'Test',
      latitude: 0,
      longitude: 0,
    );

    expect(result.isLeft(), true);
  });
}
