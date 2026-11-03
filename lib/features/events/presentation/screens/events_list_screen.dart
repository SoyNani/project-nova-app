import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/atoms/app_fab.dart';
import '../../../../core/widgets/molecules/app_more_menu.dart';
import '../../../../core/widgets/molecules/app_top_bar.dart';
import '../../domain/entities/event_entity.dart';
import '../providers/event_providers.dart';
import '../widgets/event_schedule_timeline.dart';
import 'cancelled_events_screen.dart';
import 'event_detail_screen.dart';
import 'event_form_screen.dart';

class EventsListScreen extends ConsumerWidget {
  const EventsListScreen({super.key, this.createdBy});

  final String? createdBy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(fullScheduleProvider);
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final cancelledCount =
        ref.watch(cancelledEventsProvider).value?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'Cronograma',
        actions: [
          AppMoreMenu(
            actions: [
              AppMenuAction(
                label: cancelledCount > 0
                    ? 'Ver cancelados ($cancelledCount)'
                    : 'Ver cancelados',
                icon: Icons.event_busy_outlined,
                onSelected: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CancelledEventsScreen(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: AppFab(
        tooltip: 'Nuevo evento',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EventFormScreen(createdBy: createdBy),
          ),
        ),
      ),
      body: SafeArea(
        child: scheduleAsync.when(
          data: (days) {
            if (days.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Aún no hay eventos registrados.\nToca "+" para crear el primero.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              );
            }
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  children: [
                    EventScheduleTimeline(
                      days: days,
                      now: now,
                      onTapEvent: (event) => _openDetail(context, event),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, EventEntity event) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)));
  }
}
