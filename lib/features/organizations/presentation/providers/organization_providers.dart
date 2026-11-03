import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/organization_firestore_datasource.dart';
import '../../data/repositories/organization_repository_impl.dart';
import '../../domain/entities/organization_entity.dart';
import '../../domain/repositories/organization_repository.dart';
import '../../domain/usecases/create_organization.dart';
import '../../domain/usecases/delete_organization.dart';
import '../../domain/usecases/filter_organizations.dart';
import '../../domain/usecases/update_organization.dart';
import '../../domain/usecases/watch_organizations.dart';

final organizationDatasourceProvider =
    Provider<OrganizationFirestoreDatasource>((ref) {
      return OrganizationFirestoreDatasource();
    });

final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  return OrganizationRepositoryImpl(ref.watch(organizationDatasourceProvider));
});

final createOrganizationProvider = Provider<CreateOrganization>((ref) {
  return CreateOrganization(ref.watch(organizationRepositoryProvider));
});

final updateOrganizationProvider = Provider<UpdateOrganization>((ref) {
  return UpdateOrganization(ref.watch(organizationRepositoryProvider));
});

final deleteOrganizationProvider = Provider<DeleteOrganization>((ref) {
  return DeleteOrganization(ref.watch(organizationRepositoryProvider));
});

final watchOrganizationsProvider = Provider<WatchOrganizations>((ref) {
  return WatchOrganizations(ref.watch(organizationRepositoryProvider));
});

final filterOrganizationsProvider = Provider<FilterOrganizations>((ref) {
  return const FilterOrganizations();
});

final organizationsListProvider = StreamProvider<List<OrganizationEntity>>((
  ref,
) {
  return ref.watch(watchOrganizationsProvider)();
});

final organizationSearchQueryProvider =
    NotifierProvider<OrganizationSearchQueryController, String>(
      OrganizationSearchQueryController.new,
    );

class OrganizationSearchQueryController extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;

  void clear() => state = '';
}

final filteredOrganizationsProvider =
    Provider<AsyncValue<List<OrganizationEntity>>>((ref) {
      final listAsync = ref.watch(organizationsListProvider);
      final query = ref.watch(organizationSearchQueryProvider);
      final filter = ref.watch(filterOrganizationsProvider);

      return listAsync.whenData(
        (organizations) => filter(organizations: organizations, query: query),
      );
    });

sealed class OrganizationFormState {
  const OrganizationFormState();
}

class OrganizationFormIdle extends OrganizationFormState {
  const OrganizationFormIdle();
}

class OrganizationFormLoading extends OrganizationFormState {
  const OrganizationFormLoading();
}

class OrganizationFormSuccess extends OrganizationFormState {
  const OrganizationFormSuccess();
}

class OrganizationFormError extends OrganizationFormState {
  const OrganizationFormError(this.message);
  final String message;
}

final organizationFormControllerProvider =
    NotifierProvider.autoDispose<
      OrganizationFormController,
      OrganizationFormState
    >(OrganizationFormController.new);

class OrganizationFormController extends Notifier<OrganizationFormState> {
  late final CreateOrganization _create;
  late final UpdateOrganization _update;

  @override
  OrganizationFormState build() {
    _create = ref.watch(createOrganizationProvider);
    _update = ref.watch(updateOrganizationProvider);
    return const OrganizationFormIdle();
  }

  Future<void> submitCreate({
    required String name,
    required String city,
    required String department,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    state = const OrganizationFormLoading();
    final result = await _create(
      name: name,
      city: city,
      department: department,
      address: address,
      latitude: latitude,
      longitude: longitude,
    );
    result.match(
      (failure) => state = OrganizationFormError(failure.message),
      (_) => state = const OrganizationFormSuccess(),
    );
  }

  Future<void> submitUpdate(OrganizationEntity organization) async {
    state = const OrganizationFormLoading();
    final result = await _update(organization);
    result.match(
      (failure) => state = OrganizationFormError(failure.message),
      (_) => state = const OrganizationFormSuccess(),
    );
  }
}
