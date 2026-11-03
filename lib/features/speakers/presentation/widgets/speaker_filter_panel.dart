import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/speaker_providers.dart';

class SpeakerFilterPanel extends ConsumerWidget {
  const SpeakerFilterPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(speakerOrganizationFilterProvider);
    final organizationsAsync = ref.watch(speakerFilterOrganizationsProvider);
    final width = MediaQuery.sizeOf(context).width;

    void select(String? id) {
      ref.read(speakerOrganizationFilterProvider.notifier).select(id);
      Navigator.of(context).maybePop();
    }

    return Drawer(
      width: width < 400 ? width * 0.85 : 360,
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filtrar por lugar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Cerrar filtros',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: organizationsAsync.when(
                data: (organizations) => ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _PlaceTile(
                      title: 'Todos los lugares',
                      selected: selectedId == null,
                      onTap: () => select(null),
                    ),
                    for (final org in organizations)
                      _PlaceTile(
                        title: org.name,
                        subtitle: org.city.isEmpty ? null : org.city,
                        selected: selectedId == org.id,
                        onTap: () => select(org.id),
                      ),
                  ],
                ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No se pudieron cargar los lugares.',
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: selected,
      selectedTileColor: AppColors.chipBackground,
      selectedColor: AppColors.primary,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? AppColors.primary : AppColors.textMuted,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
      onTap: onTap,
    );
  }
}
