import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class AppFab extends StatelessWidget {
  const AppFab({
    super.key,
    this.onPressed,
    this.tooltip = 'Crear',
  });

  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        tooltip: tooltip,
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: AppColors.transparent,
        foregroundColor: AppColors.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.add,
          size: 28,
        ),
      ),
    );
  }
}
