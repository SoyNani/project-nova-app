import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/atoms/app_status_badge.dart';
import '../../domain/entities/event_entity.dart';

class EventTimingBadge extends StatelessWidget {
  const EventTimingBadge({
    super.key,
    required this.timing,
    this.onDark = false,
  });

  final EventTiming timing;
  final bool onDark;

  static String labelOf(EventTiming timing, {required bool onDark}) {
    switch (timing) {
      case EventTiming.live:
        return onDark ? 'EN VIVO AHORA' : 'EN VIVO';
      case EventTiming.upcoming:
        return 'POR INICIAR';
      case EventTiming.finished:
        return 'FINALIZADO';
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = labelOf(timing, onDark: onDark);

    if (onDark) {
      return AppStatusBadge(
        label: label,
        color: AppColors.onPrimary,
        backgroundColor: AppColors.glassOnGradient,
        borderColor: AppColors.glassBorderOnGradient,
        dotColor: switch (timing) {
          EventTiming.live => AppColors.liveDot,
          EventTiming.upcoming => AppColors.institutionsColor,
          EventTiming.finished => null,
        },
      );
    }

    switch (timing) {
      case EventTiming.live:
        return AppStatusBadge(
          label: label,
          color: AppColors.liveBadge,
          backgroundColor: AppColors.liveBadgeBackground,
        );
      case EventTiming.finished:
        return AppStatusBadge(
          label: label,
          color: AppColors.textMuted,
          backgroundColor: AppColors.background,
        );
      case EventTiming.upcoming:
        return const SizedBox.shrink();
    }
  }
}

class EventCancelledBadge extends StatelessWidget {
  const EventCancelledBadge({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    if (onDark) {
      return const AppStatusBadge(
        label: 'CANCELADO',
        color: AppColors.onPrimary,
        backgroundColor: AppColors.glassOnGradient,
        borderColor: AppColors.glassBorderOnGradient,
        dotColor: AppColors.error,
      );
    }
    return AppStatusBadge(
      label: 'CANCELADO',
      color: AppColors.error,
      backgroundColor: AppColors.error.withValues(alpha: 0.08),
    );
  }
}
