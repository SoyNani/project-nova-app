import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../atoms/app_square_icon_button.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, required this.title, this.actions = const []});

  final String title;
  final List<Widget> actions;

  static const double _height = 64;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return AppBar(
      toolbarHeight: _height,
      backgroundColor: AppColors.background,
      automaticallyImplyLeading: false,
      leadingWidth: 68,
      leading: canPop
          ? Center(
              child: AppSquareIconButton(
                icon: Icons.chevron_left,
                tooltip: 'Volver',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            )
          : null,
      title: Text(title),
      actions: [...actions, const SizedBox(width: 12)],
    );
  }
}

class AppTopBarTextAction extends StatelessWidget {
  const AppTopBarTextAction({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        textStyle: AppTextStyles.link.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: Text(label),
    );
  }
}
