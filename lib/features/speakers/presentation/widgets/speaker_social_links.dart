import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/atoms/app_section_header.dart';

class SpeakerSocialLinks extends StatelessWidget {
  const SpeakerSocialLinks({
    super.key,
    this.instagram,
    this.linkedin,
    this.tiktok,
  });

  final String? instagram;
  final String? linkedin;
  final String? tiktok;

  @override
  Widget build(BuildContext context) {
    final links = <_SocialLink>[
      _SocialLink(
        label: 'Instagram',
        value: instagram,
        icon: Icons.camera_alt_outlined,
        color: AppColors.socialInstagram,
      ),
      _SocialLink(
        label: 'LinkedIn',
        value: linkedin,
        icon: Icons.work_outline,
        color: AppColors.socialLinkedin,
      ),
      _SocialLink(
        label: 'TikTok',
        value: tiktok,
        icon: Icons.music_note_outlined,
        color: AppColors.socialTikTok,
      ),
    ].where((link) => link.value != null && link.value!.isNotEmpty).toList();

    if (links.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(title: 'REDES SOCIALES'),
        const SizedBox(height: 12),
        for (final link in links)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _SocialRow(link: link),
          ),
      ],
    );
  }
}

class _SocialLink {
  const _SocialLink({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String? value;
  final IconData icon;
  final Color color;
}

class _SocialRow extends StatelessWidget {
  const _SocialRow({required this.link});

  final _SocialLink link;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(link.icon, size: 18, color: link.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(link.label, style: AppTextStyles.label),
                const SizedBox(height: 2),
                Text(
                  link.value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
