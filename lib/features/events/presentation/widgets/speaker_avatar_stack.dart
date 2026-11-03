import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SpeakerAvatarStack extends StatelessWidget {
  const SpeakerAvatarStack({
    super.key,
    required this.names,
    this.maxVisible = 2,
    this.size = 32,
  });

  final List<String> names;
  final int maxVisible;
  final double size;

  static String initialsOf(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (names.isEmpty) return const SizedBox.shrink();

    final visible = names.take(maxVisible).toList();
    final rest = names.length - visible.length;
    final circles = <Widget>[
      for (final name in visible) _circle(Text(initialsOf(name))),
      if (rest > 0) _circle(Text('+$rest')),
    ];
    final step = size * 0.68;

    return SizedBox(
      height: size,
      width: size + step * (circles.length - 1),
      child: Stack(
        children: [
          for (var i = 0; i < circles.length; i++)
            Positioned(left: step * i, child: circles[i]),
        ],
      ),
    );
  }

  Widget _circle(Text label) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.eventHeroMid,
        border: Border.all(color: AppColors.glassBorderOnGradient, width: 1.5),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w700,
          color: AppColors.onPrimary,
        ),
        child: label,
      ),
    );
  }
}
