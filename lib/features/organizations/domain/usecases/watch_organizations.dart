import '../entities/organization_entity.dart';
import '../repositories/organization_repository.dart';


class WatchOrganizations {
  const WatchOrganizations(this._repository);

  final OrganizationRepository _repository;

  Stream<List<OrganizationEntity>> call() => _repository.watchAll();
}
