import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_date_format.dart';
import '../../../events/domain/entities/event_entity.dart';
import '../../../events/presentation/widgets/event_timing_badge.dart';
import '../../../organizations/presentation/widgets/organization_avatar.dart';
import '../../domain/entities/event_map_place.dart';

class EventPlaceSheet extends StatelessWidget {
  const EventPlaceSheet({
    super.key,
    required this.place,
    required this.now,
    required this.onOpenEvent,
  });

  final EventMapPlace place;
  final DateTime now;
  final ValueChanged<EventEntity> onOpenEvent;

  static Future<void> show(
    BuildContext context, {
    required EventMapPlace place,
    required DateTime now,
    required ValueChanged<EventEntity> onOpenEvent,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) =>
          EventPlaceSheet(place: place, now: now, onOpenEvent: onOpenEvent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final org = place.organization;
    final location = [
      org.address,
      org.city,
    ].where((p) => p.trim().isNotEmpty).join(' · ');

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                OrganizationAvatar(name: org.name, initials: org.initials),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(org.name, style: AppTextStyles.cardTitle),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                style: AppTextStyles.cardSubtitle,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              place.events.length == 1
                  ? '1 EVENTO EN ESTE LUGAR'
                  : '${place.events.length} EVENTOS EN ESTE LUGAR',
              style: AppTextStyles.label,
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              itemCount: place.events.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final event = place.events[index];
                return _EventTile(
                  event: event,
                  timing: event.timingAt(now),
                  now: now,
                  onTap: () => onOpenEvent(event),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.event,
    required this.timing,
    required this.now,
    required this.onTap,
  });

  final EventEntity event;
  final EventTiming timing;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final when =
        '${AppDateFormat.relativeDay(event.startAt, now)} · '
        '${AppDateFormat.timeRange(event.startAt, event.endAt)}';

    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.name,
                            style: AppTextStyles.itemTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        EventTimingBadge(timing: timing),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(when, style: AppTextStyles.cardSubtitle),
                        ),
                      ],
                    ),
                    if (event.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        event.description.trim(),
                        style: AppTextStyles.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
