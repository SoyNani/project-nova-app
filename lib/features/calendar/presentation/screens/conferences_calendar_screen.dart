import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/atoms/app_fab.dart';
import '../../../../core/widgets/atoms/app_page_title.dart';
import '../../../events/domain/entities/event_entity.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../../events/presentation/screens/event_detail_screen.dart';
import '../../../events/presentation/screens/event_form_screen.dart';
import '../providers/calendar_providers.dart';
import '../widgets/calendar_schedule.dart';
import '../widgets/conference_calendar_card.dart';

/// Pestaña "Calendario": calendario mensual con puntos por ciudad y, debajo,
/// el cronograma de las conferencias del mes visible con su contador.
/// Es `ConsumerStatefulWidget` porque el mes visible, el día elegido y el
/// scroll son estado puramente de UI.
class ConferencesCalendarScreen extends ConsumerStatefulWidget {
  const ConferencesCalendarScreen({super.key, this.createdBy});

  final String? createdBy;

  @override
  ConsumerState<ConferencesCalendarScreen> createState() =>
      _ConferencesCalendarScreenState();
}

class _ConferencesCalendarScreenState
    extends ConsumerState<ConferencesCalendarScreen> {
  final _dayKeys = <DateTime, GlobalKey>{};
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    _focusedDay = _today();
    _selectedDay = _focusedDay;
  }

  void _onMonthChanged(DateTime day) {
    if (day.year == _focusedDay.year && day.month == _focusedDay.month) {
      return;
    }
    setState(() {
      _focusedDay = day;
      _dayKeys.clear();
    });
  }

  void _onDaySelected(DateTime day) {
    setState(() {
      _selectedDay = day;
      _focusedDay = day;
    });
    _scrollToDay(day);
  }

  void _goToToday() {
    final today = _today();
    setState(() {
      if (today.month != _focusedDay.month || today.year != _focusedDay.year) {
        _dayKeys.clear();
      }
      _focusedDay = today;
      _selectedDay = today;
    });
  }

  /// Lleva el cronograma al día tocado, si tiene conferencias.
  void _scrollToDay(DateTime day) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dayContext = _dayKeys[day]?.currentContext;
      if (dayContext == null) return;
      Scrollable.ensureVisible(
        dayContext,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        alignment: 0.05,
      );
    });
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(activeEventsProvider);
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final month = ref.watch(buildCalendarMonthProvider)(
      events: eventsAsync.value ?? const <EventEntity>[],
      month: _focusedDay,
    );
    final count = month.eventsCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: Padding(
        // Por encima del menú flotante.
        padding: const EdgeInsets.only(bottom: 96),
        child: AppFab(
          tooltip: 'Nueva conferencia',
          onPressed: () => _push(EventFormScreen(createdBy: widget.createdBy)),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.7, -1.1),
            radius: 0.9,
            colors: [Color(0x2E5ED0F7), Color(0x005ED0F7)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 200),
                children: [
                  const AppPageTitle('Conferencias'),
                  const SizedBox(height: 18),
                  ConferenceCalendarCard(
                    month: month,
                    focusedDay: _focusedDay,
                    selectedDay: _selectedDay,
                    today: _today(),
                    onDaySelected: _onDaySelected,
                    onMonthChanged: _onMonthChanged,
                    onToday: _goToToday,
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Cronograma',
                          style: AppTextStyles.sectionTitle,
                        ),
                      ),
                      Container(
                        key: const Key('calendar-month-count'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.chipBackground,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          count == 1
                              ? '1 conferencia este mes'
                              : '$count conferencias este mes',
                          style: AppTextStyles.badge.copyWith(
                            fontSize: 12,
                            letterSpacing: 0,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (eventsAsync.isLoading && !eventsAsync.hasValue)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (eventsAsync.hasError)
                    Text(
                      'No se pudieron cargar las conferencias.',
                      style: AppTextStyles.cardSubtitle.copyWith(
                        color: AppColors.error,
                      ),
                    )
                  else
                    CalendarSchedule(
                      month: month,
                      selectedDay: _selectedDay,
                      now: now,
                      dayKeys: _dayKeys,
                      onTapEvent: (event) =>
                          _push(EventDetailScreen(event: event)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
