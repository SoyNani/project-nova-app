import 'package:fpdart/fpdart.dart';
import '../entities/organization_entity.dart';
import '../entities/organization_failure.dart';
import '../repositories/organization_repository.dart';

class UpdateOrganization {
  const UpdateOrganization(this._repository);

  final OrganizationRepository _repository;

  Future<Either<OrganizationFailure, void>> call(
    OrganizationEntity organization,
  ) {
    return _repository.update(organization);
  }
}
