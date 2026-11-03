import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class AppPageTitle extends StatelessWidget {
  const AppPageTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        title,
        style: AppTextStyles.greeting.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}
