import 'package:fpdart/fpdart.dart';
import '../../domain/entities/organization_entity.dart';
import '../../domain/entities/organization_failure.dart';
import '../../domain/repositories/organization_repository.dart';
import '../datasources/organization_firestore_datasource.dart';
import '../models/organization_model.dart';

class OrganizationRepositoryImpl implements OrganizationRepository {
  const OrganizationRepositoryImpl(this._datasource);

  final OrganizationFirestoreDatasource _datasource;

  @override
  Stream<List<OrganizationEntity>> watchAll() => _datasource.watchAll();

  @override
  Future<Either<OrganizationFailure, OrganizationEntity>> getById(
    String id,
  ) async {
    try {
      final organization = await _datasource.getById(id);
      return right(organization);
    } on OrganizationNotFoundException {
      return left(const OrganizationNotFound());
    } catch (e) {
      return left(OrganizationUnknownError(e.toString()));
    }
  }

  @override
  Future<Either<OrganizationFailure, OrganizationEntity>> create(
    OrganizationEntity organization,
  ) async {
    try {
      final created = await _datasource.create(
        OrganizationModel.fromEntity(organization),
      );
      return right(created);
    } catch (e) {
      return left(OrganizationUnknownError(e.toString()));
    }
  }

  @override
  Future<Either<OrganizationFailure, void>> update(
    OrganizationEntity organization,
  ) async {
    try {
      await _datasource.update(OrganizationModel.fromEntity(organization));
      return right(null);
    } catch (e) {
      return left(OrganizationUnknownError(e.toString()));
    }
  }

  @override
  Future<Either<OrganizationFailure, void>> delete(String id) async {
    try {
      await _datasource.delete(id);
      return right(null);
    } on OrganizationHasEventsException {
      return left(const OrganizationHasActiveEvents());
    } catch (e) {
      return left(OrganizationUnknownError(e.toString()));
    }
  }
}
