import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_date_format.dart';
import '../../../../core/widgets/molecules/app_top_bar.dart';
import '../../domain/entities/event_entity.dart';
import '../providers/event_providers.dart';
import '../widgets/event_cancel_actions.dart';
import '../widgets/event_schedule_timeline.dart';
import 'event_detail_screen.dart';

/// Eventos cancelados. No aparece en la navegación principal: se llega desde el menú de tres puntos del cronograma. Cada evento se puede abrir o restaurar.
class CancelledEventsScreen extends ConsumerWidget {
  const CancelledEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cancelledAsync = ref.watch(cancelledEventsProvider);
    final now = ref.watch(clockProvider).value ?? DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: 'Eventos cancelados'),
      body: SafeArea(
        child: cancelledAsync.when(
          data: (events) {
            if (events.isEmpty) return const _EmptyState();
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) =>
                      _CancelledEventItem(event: events[index], now: now),
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
}

class _CancelledEventItem extends ConsumerWidget {
  const _CancelledEventItem({required this.event, required this.now});

  final EventEntity event;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cancelledAt = event.cancelledAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            '${AppDateFormat.longDate(event.startAt)} · '
            '${AppDateFormat.timeRange(event.startAt, event.endAt)}',
            style: AppTextStyles.label,
          ),
        ),
        EventScheduleCard(
          event: event,
          timing: event.timingAt(now),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  cancelledAt == null
                      ? ''
                      : 'Cancelado el ${AppDateFormat.dayMonthYear(cancelledAt)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardSubtitle.copyWith(fontSize: 12),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => restoreCancelledEvent(context, ref, event),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryLight,
              ),
              icon: const Icon(Icons.restore, size: 18),
              label: const Text(
                'Restaurar',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            SizedBox(height: 12),
            Text(
              'No tienes eventos cancelados.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
