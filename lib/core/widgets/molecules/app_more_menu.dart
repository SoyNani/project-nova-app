import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class AppMenuAction {
  const AppMenuAction({
    required this.label,
    required this.icon,
    required this.onSelected,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onSelected;
  final bool destructive;
}

class AppMoreMenu extends StatelessWidget {
  const AppMoreMenu({
    super.key,
    required this.actions,
    this.tooltip = 'Más opciones',
  });

  final List<AppMenuAction> actions;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: tooltip,
      offset: const Offset(0, 48),
      color: AppColors.surface,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      onSelected: (index) => actions[index].onSelected(),
      itemBuilder: (_) => [
        for (var i = 0; i < actions.length; i++)
          PopupMenuItem<int>(
            value: i,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  actions[i].icon,
                  size: 20,
                  color: actions[i].destructive
                      ? AppColors.error
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    actions[i].label,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: actions[i].destructive
                          ? AppColors.error
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(Icons.more_horiz, color: AppColors.textPrimary),
      ),
    );
  }
}
