import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_date_format.dart';
import '../../../../core/widgets/atoms/app_button.dart';
import '../../../../core/widgets/atoms/app_outline_button.dart';
import '../../../../core/widgets/atoms/app_section_header.dart';
import '../../../../core/widgets/molecules/app_more_menu.dart';
import '../../../../core/widgets/molecules/app_top_bar.dart';
import '../../domain/entities/event_entity.dart';
import '../providers/event_providers.dart';
import '../widgets/event_cancel_actions.dart';
import '../widgets/event_hero_card.dart';
import '../widgets/event_timing_badge.dart';
import '../widgets/speaker_avatar_stack.dart';

/// Detalle de un evento: estado actual, cuándo, dónde, descripción y speakers asignados.
class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.event});

  final EventEntity event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final timing = event.timingAt(now);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'Detalle del evento',
        actions: [
          AppMoreMenu(
            actions: [
              if (event.isCancelled)
                AppMenuAction(
                  label: 'Restaurar evento',
                  icon: Icons.restore,
                  onSelected: () => _restore(context, ref),
                )
              else
                AppMenuAction(
                  label: 'Cancelar evento',
                  icon: Icons.event_busy_outlined,
                  destructive: true,
                  onSelected: () => _cancel(context, ref),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                EventHeroSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (event.isCancelled)
                        const EventCancelledBadge(onDark: true)
                      else
                        EventTimingBadge(timing: timing, onDark: true),
                      const SizedBox(height: 16),
                      Text(
                        event.name,
                        style: AppTextStyles.heroTitle.copyWith(
                          fontSize: 22,
                          height: 1.3,
                        ),
                      ),
                      if (event.speakerNames.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        SpeakerAvatarStack(
                          names: event.speakerNames,
                          maxVisible: 4,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const AppSectionHeader(title: 'CUÁNDO'),
                const SizedBox(height: 12),
                _InfoCard(
                  rows: [
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      color: AppColors.calendarColor,
                      title: AppDateFormat.longDate(event.startAt),
                      subtitle: '${event.startAt.year}',
                    ),
                    _InfoRow(
                      icon: Icons.schedule,
                      color: AppColors.institutionsColor,
                      title: AppDateFormat.timeRange(
                        event.startAt,
                        event.endAt,
                      ),
                      subtitle:
                          'Duración: '
                          '${AppDateFormat.duration(event.duration)}',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const AppSectionHeader(title: 'DÓNDE'),
                const SizedBox(height: 12),
                _InfoCard(
                  rows: [
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      color: AppColors.mapColor,
                      title: event.organizationName.isEmpty
                          ? 'Sin organización'
                          : event.organizationName,
                      subtitle: [
                        event.address,
                        event.city,
                      ].where((p) => p.trim().isNotEmpty).join(' · '),
                    ),
                  ],
                ),
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const AppSectionHeader(title: 'DESCRIPCIÓN'),
                  const SizedBox(height: 12),
                  Text(
                    event.description,
                    style: AppTextStyles.body.copyWith(height: 1.5),
                  ),
                ],
                const SizedBox(height: 24),
                const AppSectionHeader(title: 'SPEAKERS'),
                const SizedBox(height: 12),
                if (event.speakerNames.isEmpty)
                  const Text(
                    'Sin speakers asignados.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  _InfoCard(
                    rows: [
                      for (final name in event.speakerNames)
                        _InfoRow(
                          initials: SpeakerAvatarStack.initialsOf(name),
                          color: AppColors.speakersColor,
                          title: name,
                        ),
                    ],
                  ),
                const SizedBox(height: 32),
                if (event.isCancelled)
                  AppButton(
                    label: 'Restaurar evento',
                    icon: const Icon(
                      Icons.restore,
                      size: 20,
                      color: AppColors.onPrimary,
                    ),
                    onPressed: () => _restore(context, ref),
                  )
                else
                  AppOutlineButton(
                    label: 'Ya no asistiré · Cancelar evento',
                    borderColor: AppColors.error,
                    textColor: AppColors.error,
                    leading: const Icon(
                      Icons.event_busy_outlined,
                      size: 18,
                      color: AppColors.error,
                    ),
                    onPressed: () => _cancel(context, ref),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final cancelled = await confirmAndCancelEvent(context, ref, event);
    if (cancelled && context.mounted) Navigator.of(context).pop();
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final restored = await restoreCancelledEvent(context, ref, event);
    if (restored && context.mounted) Navigator.of(context).pop();
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(indent: 64),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.color,
    required this.title,
    this.icon,
    this.initials,
    this.subtitle = '',
  });

  final IconData? icon;
  final String? initials;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: icon != null
                ? Icon(icon, size: 18, color: color)
                : Text(
                    initials ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.itemTitle),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.cardSubtitle),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
