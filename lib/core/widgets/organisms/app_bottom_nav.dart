import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../molecules/app_nav_item.dart';

class AppNavDestination {
  const AppNavDestination({
    required this.label,
    required this.icon,
    required this.builder,
  });

  final String label;
  final IconData icon;
  final WidgetBuilder builder;
}

const barKey = Key('app-bottom-nav-bar');

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onDestinationSelected,
    this.sideMargin = 50,
    this.bottomMargin = 20,
    this.maxWidth = 460,
  });

  final List<AppNavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  final double sideMargin;

  final double bottomMargin;

  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.fromLTRB(sideMargin, 0, sideMargin, bottomMargin),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: DecoratedBox(
              key: barKey,
              decoration: BoxDecoration(
                color: AppColors.navBackground,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: AppColors.glassOnGradient),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navShadow,
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < destinations.length; i++)
                      Expanded(
                        child: AppNavItem(
                          icon: destinations[i].icon,
                          label: destinations[i].label,
                          isActive: i == currentIndex,
                          onTap: () => onDestinationSelected(i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
