import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_date_format.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/entities/featured_event.dart';
import 'event_timing_badge.dart';
import 'speaker_avatar_stack.dart';

class EventHeroCard extends StatelessWidget {
  const EventHeroCard({
    super.key,
    required this.featured,
    required this.now,
    required this.onOpen,
  });

  final FeaturedEvent featured;
  final DateTime now;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final event = featured.event;
    final isLive = featured.timing == EventTiming.live;
    final muted = AppColors.onPrimary.withValues(alpha: 0.78);

    return EventHeroSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              EventTimingBadge(timing: featured.timing, onDark: true),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppDateFormat.timeRange(event.startAt, event.endAt),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            event.name,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.heroTitle.copyWith(fontSize: 22, height: 1.3),
          ),
          if (event.placeLabel.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoLine(
              icon: Icons.location_on_outlined,
              text: event.placeLabel,
              color: muted,
            ),
          ],
          if (!isLive) ...[
            const SizedBox(height: 6),
            _InfoLine(
              icon: Icons.calendar_today_outlined,
              text: AppDateFormat.relativeDay(event.startAt, now),
              color: muted,
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              SpeakerAvatarStack(names: event.speakerNames),
              const Spacer(),
              _DetailButton(onPressed: onOpen),
            ],
          ),
        ],
      ),
    );
  }
}

class EventHeroSurface extends StatelessWidget {
  const EventHeroSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        gradient: AppColors.eventHeroGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: AppColors.eventHeroShadow,
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class EventHeroEmpty extends StatelessWidget {
  const EventHeroEmpty({super.key, required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return EventHeroSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aún no hay eventos',
            style: AppTextStyles.heroTitle.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea el primero y aquí verás su estado en tiempo real.',
            style: AppTextStyles.heroSubtitle,
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: _DetailButton(
              label: 'Crear evento',
              icon: Icons.add,
              onPressed: onCreate,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailButton extends StatelessWidget {
  const _DetailButton({
    required this.onPressed,
    this.label = 'Ver detalle',
    this.icon = Icons.chevron_right,
  });

  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, size: 18, color: AppColors.textPrimary),
            ],
          ),
        ),
      ),
    );
  }
}
