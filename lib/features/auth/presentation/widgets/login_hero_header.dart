import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class LoginHeroHeader extends StatefulWidget {
  const LoginHeroHeader({super.key, required this.height});

  final double height;

  @override
  State<LoginHeroHeader> createState() => _LoginHeroHeaderState();
}

class _LoginHeroHeaderState extends State<LoginHeroHeader>
    with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Con "reducir movimiento" activo se muestra estático.
    if (MediaQuery.disableAnimationsOf(context)) {
      _loop.stop();
      _entrance.value = 1;
    } else {
      if (!_loop.isAnimating) _loop.repeat();
      if (_entrance.isDismissed) _entrance.forward();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoScale = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0, 0.7, curve: Curves.easeOutBack),
    );
    final textFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.35, 1, curve: Curves.easeOut),
    );

    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _loop,
              builder: (context, _) =>
                  CustomPaint(painter: _OrbsPainter(t: _loop.value)),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: logoScale,
                child: _PulsingLogo(animation: _loop),
              ),
              const SizedBox(height: 18),
              FadeTransition(
                opacity: textFade,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.4),
                    end: Offset.zero,
                  ).animate(textFade),
                  child: const Column(
                    children: [
                      Text('Nova', style: AppTextStyles.heroTitle),
                      SizedBox(height: 4),
                      Text(
                        'Gestión de conferencias y eventos',
                        style: AppTextStyles.heroSubtitle,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulsingLogo extends StatelessWidget {
  const _PulsingLogo({required this.animation});

  final Animation<double> animation;

  static const double _size = 64;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size * 1.8,
      height: _size * 1.8,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final phase = (animation.value * 3) % 1;
          return Stack(
            alignment: Alignment.center,
            children: [
              for (final offset in const [0.0, 0.5])
                _ring((phase + offset) % 1),
              child!,
            ],
          );
        },
        child: Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.glassOnGradient,
            border: Border.all(color: AppColors.glassBorderOnGradient),
          ),
          child: const Icon(
            Icons.bolt_rounded,
            color: AppColors.onPrimary,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _ring(double progress) {
    final scale = 1 + progress * 0.75;
    return Opacity(
      opacity: (1 - progress) * 0.5,
      child: Container(
        width: _size * scale,
        height: _size * scale,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.onPrimary, width: 1.5),
        ),
      ),
    );
  }
}

class _OrbsPainter extends CustomPainter {
  _OrbsPainter({required this.t});

  final double t;

  static const _orbs = [
    (0.15, 0.25, 0.32, 0.06, 0.0, Color(0x335ED0F7)),
    (0.85, 0.20, 0.26, 0.05, 0.33, Color(0x2E8B5CF6)),
    (0.70, 0.85, 0.36, 0.07, 0.66, Color(0x264F6BF5)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final base = math.min(size.width, size.height);
    for (final (x, y, r, amp, phase, color) in _orbs) {
      final angle = (t + phase) * 2 * math.pi;
      final center = Offset(
        size.width * (x + amp * math.cos(angle)),
        size.height * (y + amp * math.sin(angle)),
      );
      final radius = base * r;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbsPainter oldDelegate) => oldDelegate.t != t;
}
