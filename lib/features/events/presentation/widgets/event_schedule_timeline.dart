import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_date_format.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/entities/event_schedule_day.dart';
import 'event_timing_badge.dart';

class EventScheduleTimeline extends StatelessWidget {
  const EventScheduleTimeline({
    super.key,
    required this.days,
    required this.now,
    required this.onTapEvent,
  });

  final List<EventScheduleDay> days;
  final DateTime now;
  final ValueChanged<EventEntity> onTapEvent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final day in days)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: _DayRow(day: day, now: now, onTapEvent: onTapEvent),
          ),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.now,
    required this.onTapEvent,
  });

  final EventScheduleDay day;
  final DateTime now;
  final ValueChanged<EventEntity> onTapEvent;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                const SizedBox(height: 6),
                Text(
                  '${day.day.day}',
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  AppDateFormat.weekdayShort(day.day),
                  style: AppTextStyles.badge.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  AppDateFormat.monthShort(day.day),
                  style: AppTextStyles.badge.copyWith(
                    fontSize: 9,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(child: Container(width: 1.5, color: AppColors.border)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                for (var i = 0; i < day.events.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == day.events.length - 1 ? 0 : 10,
                    ),
                    child: EventScheduleCard(
                      event: day.events[i],
                      timing: day.events[i].timingAt(now),
                      accentIndex: i,
                      onTap: () => onTapEvent(day.events[i]),
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

class EventScheduleCard extends StatelessWidget {
  const EventScheduleCard({
    super.key,
    required this.event,
    required this.timing,
    required this.onTap,
    this.accentIndex = 0,
  });

  final EventEntity event;
  final EventTiming timing;
  final VoidCallback onTap;

  final int accentIndex;

  @override
  Widget build(BuildContext context) {
    final accent = accentIndex.isEven
        ? AppColors.primaryLight
        : AppColors.institutionsColor;
    final place = event.organizationName.isNotEmpty
        ? event.organizationName
        : event.city;

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppDateFormat.time(event.startAt),
                  style: AppTextStyles.badge.copyWith(
                    fontSize: 12,
                    letterSpacing: 0,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.itemTitle,
                    ),
                    if (place.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              place,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.cardSubtitle.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (event.isCancelled) ...[
                const SizedBox(width: 8),
                const EventCancelledBadge(),
              ] else if (timing != EventTiming.upcoming) ...[
                const SizedBox(width: 8),
                EventTimingBadge(timing: timing),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
