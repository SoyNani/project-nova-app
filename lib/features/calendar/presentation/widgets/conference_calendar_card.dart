import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_date_format.dart';
import '../../domain/entities/calendar_month.dart';
import 'calendar_city_palette.dart';

const _weekdayLetters = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

/// Organismo: tarjeta con el calendario mensual. Cada día con
/// conferencias lleva un punto por evento (hasta tres) del color de su
/// ciudad; abajo va la leyenda de colores.
/// Es `StatelessWidget`: el mes visible y el día elegido los maneja la
/// pantalla y llegan por parámetro.
class ConferenceCalendarCard extends StatelessWidget {
  const ConferenceCalendarCard({
    super.key,
    required this.month,
    required this.focusedDay,
    required this.selectedDay,
    required this.today,
    required this.onDaySelected,
    required this.onMonthChanged,
    required this.onToday,
  });

  final CalendarMonth month;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final DateTime today;
  final ValueChanged<DateTime> onDaySelected;

  final ValueChanged<DateTime> onMonthChanged;
  final VoidCallback onToday;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  void _shiftMonth(int delta) =>
      onMonthChanged(DateTime(focusedDay.year, focusedDay.month + delta));

  @override
  Widget build(BuildContext context) {
    final legend = CalendarCityPalette.legendOf(month);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _MonthHeader(
            month: focusedDay,
            onToday: onToday,
            onPrevious: () => _shiftMonth(-1),
            onNext: () => _shiftMonth(1),
          ),
          const SizedBox(height: 8),
          TableCalendar<void>(
            firstDay: DateTime(2000),
            lastDay: DateTime(2100, 12, 31),
            focusedDay: focusedDay,
            currentDay: today,
            headerVisible: false,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableCalendarFormats: const {CalendarFormat.month: 'Mes'},
            availableGestures: AvailableGestures.horizontalSwipe,
            daysOfWeekHeight: 28,
            rowHeight: 54,
            selectedDayPredicate: (day) =>
                selectedDay != null && isSameDay(day, selectedDay),
            onDaySelected: (selected, _) => onDaySelected(_dateOnly(selected)),
            onPageChanged: (focused) => onMonthChanged(_dateOnly(focused)),
            calendarBuilders: CalendarBuilders(
              dowBuilder: (context, day) => Center(
                child: Text(
                  _weekdayLetters[day.weekday - 1],
                  style: AppTextStyles.badge.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              prioritizedBuilder: (context, day, focused) {
                final isOutside = day.month != focused.month;
                return _DayCell(
                  day: day,
                  isOutside: isOutside,
                  isSelected:
                      selectedDay != null && isSameDay(day, selectedDay),
                  isToday: isSameDay(day, today),
                  dotColors: isOutside
                      ? const []
                      : [
                          for (final event
                              in month.eventsOn(_dateOnly(day)).take(3))
                            CalendarCityPalette.colorOf(month, event.city),
                        ],
                );
              },
            ),
          ),
          if (legend.isNotEmpty) ...[
            const Divider(height: 20, color: AppColors.border),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 6,
              children: [
                for (final (color, label) in legend)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Dot(color: color),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: AppTextStyles.cardSubtitle.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onToday,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onToday;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: AppDateFormat.monthName(month),
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
                ),
                TextSpan(
                  text: ' ${month.year}',
                  style: AppTextStyles.sectionTitle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        Material(
          color: AppColors.chipBackground,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onToday,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(
                'Hoy',
                style: AppTextStyles.badge.copyWith(
                  fontSize: 13,
                  letterSpacing: 0,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _ArrowButton(
          icon: Icons.chevron_left,
          tooltip: 'Mes anterior',
          onPressed: onPrevious,
        ),
        const SizedBox(width: 6),
        _ArrowButton(
          icon: Icons.chevron_right,
          tooltip: 'Mes siguiente',
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(icon, size: 20, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isOutside,
    required this.isSelected,
    required this.isToday,
    required this.dotColors,
  });

  final DateTime day;
  final bool isOutside;
  final bool isSelected;
  final bool isToday;
  final List<Color> dotColors;

  @override
  Widget build(BuildContext context) {
    final textColor = isSelected
        ? AppColors.onPrimary
        : isOutside
        ? AppColors.textMuted.withValues(alpha: 0.6)
        : isToday
        ? AppColors.primary
        : AppColors.textPrimary;

    return Center(
      child: Container(
        width: 46,
        height: 48,
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.heroGradient : null,
          borderRadius: BorderRadius.circular(14),
          border: isToday && !isSelected
              ? Border.all(color: AppColors.primaryLight, width: 1.5)
              : null,
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: AppColors.eventHeroShadow,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: AppTextStyles.itemTitle.copyWith(
                fontWeight: isSelected || isToday
                    ? FontWeight.w800
                    : FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              height: 5,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < dotColors.length; i++) ...[
                    if (i > 0) const SizedBox(width: 3),
                    _Dot(
                      color: isSelected ? AppColors.onPrimary : dotColors[i],
                      size: 5,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, this.size = 7});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
