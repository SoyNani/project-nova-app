import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_date_format.dart';
import '../../../events/domain/entities/event_entity.dart';
import '../../../events/domain/entities/event_schedule_day.dart';
import '../../../events/presentation/widgets/event_timing_badge.dart';
import '../../../events/presentation/widgets/speaker_avatar_stack.dart';
import '../../domain/entities/calendar_month.dart';
import 'calendar_city_palette.dart';

/// Organismo: cronograma del mes visible en el calendario. A la izquierda
/// el día (resaltado si es el elegido) y a la derecha las tarjetas de sus
/// conferencias, con el borde del color de la ciudad.
/// Cada día recibe la key de [dayKeys] para que la pantalla pueda hacer
/// scroll hasta él al tocarlo en el calendario.
class CalendarSchedule extends StatelessWidget {
  const CalendarSchedule({
    super.key,
    required this.month,
    required this.selectedDay,
    required this.now,
    required this.dayKeys,
    required this.onTapEvent,
  });

  final CalendarMonth month;
  final DateTime? selectedDay;
  final DateTime now;
  final Map<DateTime, GlobalKey> dayKeys;
  final ValueChanged<EventEntity> onTapEvent;

  @override
  Widget build(BuildContext context) {
    if (month.days.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.event_busy_outlined,
              size: 32,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 8),
            Text(
              'No hay conferencias en '
              '${AppDateFormat.monthNameLower(month.month)}.',
              textAlign: TextAlign.center,
              style: AppTextStyles.cardSubtitle,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final day in month.days)
          Padding(
            key: dayKeys.putIfAbsent(day.day, GlobalKey.new),
            padding: const EdgeInsets.only(bottom: 18),
            child: _DayRow(
              day: day,
              month: month,
              now: now,
              isSelected: selectedDay == day.day,
              onTapEvent: onTapEvent,
            ),
          ),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.month,
    required this.now,
    required this.isSelected,
    required this.onTapEvent,
  });

  final EventScheduleDay day;
  final CalendarMonth month;
  final DateTime now;
  final bool isSelected;
  final ValueChanged<EventEntity> onTapEvent;

  @override
  Widget build(BuildContext context) {
    final isToday =
        day.day.year == now.year &&
        day.day.month == now.month &&
        day.day.day == now.day;
    final weekday = AppDateFormat.weekdayShort(day.day);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.heroGradient : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${day.day.day}',
                    style: AppTextStyles.cardTitle.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? AppColors.onPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isToday ? '$weekday ·\nHOY' : weekday,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.badge.copyWith(
                    fontSize: 10,
                    color: isSelected || isToday
                        ? AppColors.primaryLight
                        : AppColors.textMuted,
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
                      bottom: i == day.events.length - 1 ? 0 : 12,
                    ),
                    child: CalendarEventCard(
                      event: day.events[i],
                      timing: day.events[i].timingAt(now),
                      accent: CalendarCityPalette.colorOf(
                        month,
                        day.events[i].city,
                      ),
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

/// Tarjeta de una conferencia en el cronograma del calendario.
class CalendarEventCard extends StatelessWidget {
  const CalendarEventCard({
    super.key,
    required this.event,
    required this.timing,
    required this.accent,
    required this.onTap,
  });

  final EventEntity event;
  final EventTiming timing;

  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final place = event.organizationName.isNotEmpty
        ? event.organizationName
        : event.address;
    final radius = BorderRadius.circular(16);

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 14, color: accent),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              AppDateFormat.timeRange(
                                event.startAt,
                                event.endAt,
                              ),
                              style: AppTextStyles.badge.copyWith(
                                fontSize: 12,
                                letterSpacing: 0,
                                color: accent,
                              ),
                            ),
                          ),
                          if (timing != EventTiming.upcoming)
                            EventTimingBadge(timing: timing),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        event.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.itemTitle,
                      ),
                      if (place.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                place,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.cardSubtitle.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          SpeakerAvatarStack(
                            names: event.speakerNames,
                            size: 26,
                          ),
                          const Spacer(),
                          if (event.city.trim().isNotEmpty)
                            Text(
                              event.city.trim().toUpperCase(),
                              style: AppTextStyles.badge.copyWith(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
