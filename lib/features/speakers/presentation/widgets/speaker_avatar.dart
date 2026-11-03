import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SpeakerAvatar extends StatelessWidget {
  const SpeakerAvatar({
    super.key,
    required this.initials,
    this.photoUrl,
    this.size = 56,
  });

  final String initials;
  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final photo = photoUrl;
    final hasPhoto = photo != null && photo.trim().isNotEmpty;

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.avatarBackground,
      ),
      child: hasPhoto
          ? Image.network(
              photo,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initials(),
            )
          : _initials(),
    );
  }

  Widget _initials() {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
