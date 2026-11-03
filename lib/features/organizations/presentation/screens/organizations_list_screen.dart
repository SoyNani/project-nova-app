import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/atoms/app_fab.dart';
import '../../../../core/widgets/atoms/app_search_field.dart';
import '../../../../core/widgets/molecules/app_top_bar.dart';
import '../../domain/entities/organization_entity.dart';
import '../providers/organization_providers.dart';
import '../widgets/organization_card.dart';
import 'organization_form_screen.dart';

class OrganizationsListScreen extends ConsumerStatefulWidget {
  const OrganizationsListScreen({super.key});

  @override
  ConsumerState<OrganizationsListScreen> createState() =>
      _OrganizationsListScreenState();
}

class _OrganizationsListScreenState
    extends ConsumerState<OrganizationsListScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(organizationSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final organizationsAsync = ref.watch(filteredOrganizationsProvider);
    final hasFilters = ref.watch(organizationSearchQueryProvider).isNotEmpty;

    ref.listen<String>(organizationSearchQueryProvider, (previous, next) {
      if (next != _searchController.text) _searchController.text = next;
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: 'Organizaciones'),
      floatingActionButton: AppFab(
        onPressed: () => _openForm(context),
        tooltip: 'Nueva organización',
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: AppSearchField(
                controller: _searchController,
                hintText: 'Buscar por nombre',
                semanticsLabel: 'Buscar organización por nombre',
                onChanged: (value) => ref
                    .read(organizationSearchQueryProvider.notifier)
                    .update(value),
                onClear: () =>
                    ref.read(organizationSearchQueryProvider.notifier).clear(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: organizationsAsync.when(
                data: (organizations) {
                  if (organizations.isEmpty) {
                    return _EmptyState(hasFilters: hasFilters);
                  }
                  return AdaptiveBuilder(
                    mobile: (_) => _OrganizationsListView(
                      organizations: organizations,
                      onEdit: (org) => _openForm(context, existing: org),
                      onDelete: (org) => _confirmDelete(context, ref, org),
                    ),
                    tablet: (_) => _OrganizationsGridView(
                      organizations: organizations,
                      crossAxisCount: 2,
                      onEdit: (org) => _openForm(context, existing: org),
                      onDelete: (org) => _confirmDelete(context, ref, org),
                    ),
                    desktop: (_) => _OrganizationsGridView(
                      organizations: organizations,
                      crossAxisCount: 3,
                      onEdit: (org) => _openForm(context, existing: org),
                      onDelete: (org) => _confirmDelete(context, ref, org),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openForm(BuildContext context, {OrganizationEntity? existing}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrganizationFormScreen(existing: existing),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    OrganizationEntity organization,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar organización'),
        content: Text(
          '¿Eliminar "${organization.name}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final result = await ref.read(deleteOrganizationProvider)(organization.id);
    if (!context.mounted) return;

    result.match(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.message),
          backgroundColor: AppColors.error,
        ),
      ),
      (_) {},
    );
  }
}

class _OrganizationsListView extends StatelessWidget {
  const _OrganizationsListView({
    required this.organizations,
    required this.onEdit,
    required this.onDelete,
  });

  final List<OrganizationEntity> organizations;
  final void Function(OrganizationEntity) onEdit;
  final void Function(OrganizationEntity) onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
      itemCount: organizations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final org = organizations[index];
        return OrganizationCard(
          organization: org,
          onTap: () {},
          onEdit: () => onEdit(org),
          onDelete: () => onDelete(org),
        );
      },
    );
  }
}

class _OrganizationsGridView extends StatelessWidget {
  const _OrganizationsGridView({
    required this.organizations,
    required this.crossAxisCount,
    required this.onEdit,
    required this.onDelete,
  });

  final List<OrganizationEntity> organizations;
  final int crossAxisCount;
  final void Function(OrganizationEntity) onEdit;
  final void Function(OrganizationEntity) onDelete;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.1,
      ),
      itemCount: organizations.length,
      itemBuilder: (context, index) {
        final org = organizations[index];
        return OrganizationCard(
          organization: org,
          onTap: () {},
          onEdit: () => onEdit(org),
          onDelete: () => onDelete(org),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilters});

  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_city_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              hasFilters
                  ? 'No hay organizaciones que coincidan con la búsqueda.'
                  : 'Aún no hay organizaciones registradas.\nToca "+" para crear la primera.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
