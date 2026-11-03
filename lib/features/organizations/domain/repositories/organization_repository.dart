import 'package:fpdart/fpdart.dart';
import '../entities/organization_entity.dart';
import '../entities/organization_failure.dart';

abstract interface class OrganizationRepository {
  Stream<List<OrganizationEntity>> watchAll();

  Future<Either<OrganizationFailure, OrganizationEntity>> getById(String id);

  Future<Either<OrganizationFailure, OrganizationEntity>> create(
    OrganizationEntity organization,
  );

  Future<Either<OrganizationFailure, void>> update(
    OrganizationEntity organization,
  );

  Future<Either<OrganizationFailure, void>> delete(String id);
}
