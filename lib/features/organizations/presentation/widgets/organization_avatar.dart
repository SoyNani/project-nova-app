import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class OrganizationAvatar extends StatelessWidget {
  const OrganizationAvatar({
    super.key,
    required this.name,
    required this.initials,
    this.size = 44,
  });

  final String name;
  final String initials;
  final double size;

  static const List<Color> _palette = [
    AppColors.primary,
    AppColors.institutionsColor,
    AppColors.speakersColor,
    AppColors.gradientEnd,
    AppColors.primaryLight,
    AppColors.socialInstagram,
    AppColors.socialLinkedin,
  ];

  Color get _color {
    final index = name.hashCode.abs() % _palette.length;
    return _palette[index];
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}
