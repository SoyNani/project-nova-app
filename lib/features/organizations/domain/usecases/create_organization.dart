import 'package:fpdart/fpdart.dart';
import '../entities/organization_entity.dart';
import '../entities/organization_failure.dart';
import '../repositories/organization_repository.dart';

class CreateOrganization {
  const CreateOrganization(this._repository);

  final OrganizationRepository _repository;

  Future<Either<OrganizationFailure, OrganizationEntity>> call({
    required String name,
    required String city,
    required String department,
    required String address,
    required double latitude,
    required double longitude,
  }) {
    return _repository.create(
      OrganizationEntity(
        id: '',
        name: name.trim(),
        city: city.trim(),
        department: department.trim(),
        address: address.trim(),
        latitude: latitude,
        longitude: longitude,
      ),
    );
  }
}
