import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/atoms/app_button.dart';
import '../providers/auth_providers.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  static const _features = [
    _Feature(
      icon: Icons.calendar_month_outlined,
      color: AppColors.calendarColor,
      title: 'Calendario de conferencias',
      subtitle: 'Toda la agenda del mes en un vistazo',
    ),
    _Feature(
      icon: Icons.location_on_outlined,
      color: AppColors.mapColor,
      title: 'Mapa de eventos',
      subtitle: 'Encuentra cada sede por ciudad',
    ),
    _Feature(
      icon: Icons.mic_none_rounded,
      color: AppColors.speakersColor,
      title: 'Speakers',
      subtitle: 'Perfiles y eventos asignados',
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else if (_entrance.isDismissed) {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  void _handleGoogleSignIn() {
    ref.read(loginControllerProvider.notifier).signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);
    final isLoading = loginState is LoginLoading;

    ref.listen<LoginState>(loginControllerProvider, (previous, next) {
      if (next is LoginError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.message),
              backgroundColor: AppColors.error,
            ),
          );
      }
    });

    var slot = 0;
    Widget staggered(Widget child) =>
        _StaggeredEntrance(animation: _entrance, index: slot++, child: child);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        staggered(const Text('Bienvenido', style: AppTextStyles.cardTitle)),
        const SizedBox(height: 6),
        staggered(
          const Text(
            'Ingresa con tu cuenta de Google para gestionar conferencias, '
            'speakers y eventos.',
            style: AppTextStyles.cardSubtitle,
          ),
        ),
        const SizedBox(height: 24),
        for (final feature in _features) ...[
          staggered(_FeatureTile(feature: feature)),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 16),
        staggered(
          AppButton(
            label: 'Continuar con Google',
            isLoading: isLoading,
            icon: const _GoogleBadge(),
            onPressed: _handleGoogleSignIn,
          ),
        ),
        const SizedBox(height: 16),
        staggered(
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 14, color: AppColors.textMuted),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Solo cuentas autorizadas pueden acceder',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StaggeredEntrance extends StatelessWidget {
  const _StaggeredEntrance({
    required this.animation,
    required this.index,
    required this.child,
  });

  final Animation<double> animation;
  final int index;
  final Widget child;

  static const double _step = 0.09;
  static const double _span = 0.45;

  @override
  Widget build(BuildContext context) {
    final start = math.min(index * _step, 1 - _span);
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(start, start + _span, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.25),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

class _Feature {
  const _Feature({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.feature});

  final _Feature feature;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: feature.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(feature.icon, color: feature.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: AppTextStyles.itemTitle.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(feature.subtitle, style: AppTextStyles.cardSubtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleBadge extends StatelessWidget {
  const _GoogleBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      padding: const EdgeInsets.all(5),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
      ),
      child: const CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.22;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    Paint arc(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    const deg = math.pi / 180;
    // Ángulos en sentido horario desde las 3 en punto.
    canvas
      ..drawArc(rect, -40 * deg, 85 * deg, false, arc(_blue))
      ..drawArc(rect, 45 * deg, 90 * deg, false, arc(_green))
      ..drawArc(rect, 135 * deg, 90 * deg, false, arc(_yellow))
      ..drawArc(rect, 225 * deg, 95 * deg, false, arc(_red))
      // Barra horizontal de la "G".
      ..drawRect(
        Rect.fromLTWH(
          size.width / 2,
          size.height / 2 - stroke / 2,
          size.width / 2,
          stroke,
        ),
        Paint()..color = _blue,
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
