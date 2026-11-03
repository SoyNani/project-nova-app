import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/organization_entity.dart';

class OrganizationPickerField extends StatelessWidget {
  const OrganizationPickerField({
    super.key,
    required this.organizations,
    required this.selectedIds,
    required this.onToggle,
    this.multiple = false,
    this.errorText,
    this.hintText = 'Selecciona una organización',
  });

  final List<OrganizationEntity> organizations;
  final Iterable<String> selectedIds;
  final ValueChanged<String> onToggle;

  final bool multiple;
  final String? errorText;
  final String hintText;

  Future<void> _openSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _OrganizationPickerSheet(
        organizations: organizations,
        initialSelection: selectedIds.toSet(),
        multiple: multiple,
        onToggle: onToggle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = organizations
        .where((org) => selectedIds.contains(org.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selected.isEmpty)
          _PickerCard(
            onTap: () => _openSheet(context),
            hasError: errorText != null,
            child: Row(
              children: [
                const Icon(
                  Icons.apartment_outlined,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hintText,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          for (final org in selected)
            Padding(
              padding: EdgeInsets.only(bottom: org == selected.last ? 0 : 8),
              child: _PickerCard(
                selected: true,
                onTap: () => _openSheet(context),
                child: _OrganizationRow(organization: org),
              ),
            ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText!,
            style: const TextStyle(fontSize: 12, color: AppColors.error),
          ),
        ],
      ],
    );
  }
}

class _PickerCard extends StatelessWidget {
  const _PickerCard({
    required this.child,
    required this.onTap,
    this.selected = false,
    this.hasError = false,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool selected;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? AppColors.error
        : selected
        ? AppColors.institutionsColor
        : AppColors.border;

    return Material(
      color: selected ? AppColors.selectedTealBackground : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: selected ? 1.2 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Row(
            children: [
              Expanded(child: child),
              const SizedBox(width: 8),
              const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrganizationRow extends StatelessWidget {
  const _OrganizationRow({required this.organization});

  final OrganizationEntity organization;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      organization.city,
      organization.department,
    ].where((p) => p.trim().isNotEmpty).join(', ');

    return Row(
      children: [
        OrganizationGradientAvatar(initials: organization.initials),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                organization.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.itemTitle,
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardSubtitle.copyWith(fontSize: 12),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class OrganizationGradientAvatar extends StatelessWidget {
  const OrganizationGradientAvatar({
    super.key,
    required this.initials,
    this.size = 40,
  });

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: AppColors.eventHeroGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w800,
          color: AppColors.onPrimary,
        ),
      ),
    );
  }
}

class _OrganizationPickerSheet extends StatefulWidget {
  const _OrganizationPickerSheet({
    required this.organizations,
    required this.initialSelection,
    required this.multiple,
    required this.onToggle,
  });

  final List<OrganizationEntity> organizations;
  final Set<String> initialSelection;
  final bool multiple;
  final ValueChanged<String> onToggle;

  @override
  State<_OrganizationPickerSheet> createState() =>
      _OrganizationPickerSheetState();
}

class _OrganizationPickerSheetState extends State<_OrganizationPickerSheet> {
  late final Set<String> _selected = {...widget.initialSelection};

  void _tap(String id) {
    if (!widget.multiple) {
      if (!_selected.contains(id)) widget.onToggle(id);
      Navigator.of(context).pop();
      return;
    }
    widget.onToggle(id);
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.7;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                widget.multiple ? 'Organizaciones' : 'Organización',
                style: AppTextStyles.sectionTitle,
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: widget.organizations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final org = widget.organizations[index];
                  final isSelected = _selected.contains(org.id);
                  return _PickerOption(
                    organization: org,
                    selected: isSelected,
                    onTap: () => _tap(org.id),
                  );
                },
              ),
            ),
            if (widget.multiple)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navBackground,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Listo', style: AppTextStyles.button),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  const _PickerOption({
    required this.organization,
    required this.selected,
    required this.onTap,
  });

  final OrganizationEntity organization;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.selectedTealBackground : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppColors.institutionsColor : AppColors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(child: _OrganizationRow(organization: organization)),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected
                    ? AppColors.institutionsColor
                    : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
