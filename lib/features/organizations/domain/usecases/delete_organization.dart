import 'package:fpdart/fpdart.dart';
import '../entities/organization_failure.dart';
import '../repositories/organization_repository.dart';

class DeleteOrganization {
  const DeleteOrganization(this._repository);

  final OrganizationRepository _repository;

  Future<Either<OrganizationFailure, void>> call(String id) {
    return _repository.delete(id);
  }
}
