import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class AppNavItem extends StatelessWidget {
  const AppNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  static const double _iconTile = 48;
  static const double _iconSize = 24;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isActive,
      label: label,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: _iconTile,
                height: _iconTile,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isActive ? AppColors.navCenterGradient : null,
                  color: isActive ? null : AppColors.transparent,
                  border: isActive
                      ? Border.all(color: AppColors.glassBorderOnGradient)
                      : null,
                  boxShadow: isActive
                      ? const [
                          BoxShadow(
                            color: Color(0x665ED0F7),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  size: _iconSize,
                  color: isActive
                      ? AppColors.onPrimary
                      : AppColors.navIconInactive,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
