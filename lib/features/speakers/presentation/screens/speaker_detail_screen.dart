import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/atoms/app_chip.dart';
import '../../../../core/widgets/atoms/app_section_header.dart';
import '../../../../core/widgets/molecules/app_top_bar.dart';
import '../../domain/entities/speaker_entity.dart';
import '../../domain/entities/speaker_event_entity.dart';
import '../providers/speaker_providers.dart';
import '../widgets/speaker_avatar.dart';
import '../widgets/speaker_social_links.dart';

class SpeakerDetailScreen extends ConsumerWidget {
  const SpeakerDetailScreen({super.key, required this.speaker});

  final SpeakerEntity speaker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(speakerByIdProvider(speaker.id));
    final current = profileAsync.value ?? speaker;
    final eventsAsync = ref.watch(speakerEventsProvider(speaker.id));

    final profileSections = <Widget>[
      if (profileAsync.hasError) ...[
        _InlineMessage(
          message: 'No se pudo leer el speaker: ${_reason(profileAsync.error)}',
          color: AppColors.error,
        ),
        const SizedBox(height: 20),
      ],
      _Section(
        title: 'ESPECIALIDADES',
        child: current.specialties.isEmpty
            ? const _InlineMessage(message: 'Sin especialidades.')
            : Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final specialty in current.specialties)
                    AppChip(label: specialty),
                ],
              ),
      ),
      const SizedBox(height: 24),
      SpeakerSocialLinks(
        instagram: current.instagram,
        linkedin: current.linkedin,
        tiktok: current.tiktok,
      ),
    ];

    final eventsSection = _Section(
      title: 'EVENTOS ASIGNADOS',
      child: eventsAsync.when(
        data: (events) => _EventsList(events: events),
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const _InlineMessage(
          message: 'No se pudieron cargar los eventos asignados.',
          color: AppColors.error,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: 'Perfil del speaker'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _Header(speaker: current),
            const SizedBox(height: 28),
            AdaptiveBuilder(
              mobile: (_) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...profileSections,
                  const SizedBox(height: 24),
                  eventsSection,
                ],
              ),
              tablet: (_) => IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: profileSections,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [eventsSection],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _reason(Object? error) {
    if (error is SpeakerNotLoaded) return error.message;
    return 'error inesperado.';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.speaker});

  final SpeakerEntity speaker;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          SpeakerAvatar(
            initials: speaker.initials,
            photoUrl: speaker.photoUrl,
            size: 96,
          ),
          const SizedBox(height: 14),
          Text(
            speaker.name,
            textAlign: TextAlign.center,
            style: AppTextStyles.cardTitle,
          ),
          const SizedBox(height: 4),
          Text(
            speaker.profession,
            textAlign: TextAlign.center,
            style: AppTextStyles.cardSubtitle,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: title),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _EventsList extends StatelessWidget {
  const _EventsList({required this.events});

  final List<SpeakerEventEntity> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const _InlineMessage(message: 'Sin eventos asignados.');
    }
    return Column(
      children: [for (final event in events) _EventRow(event: event)],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final SpeakerEventEntity event;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_outlined, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              event.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (event.date != null)
            Text(_formatDate(event.date!), style: AppTextStyles.cardSubtitle),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message, this.color});

  final String message;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: TextStyle(fontSize: 14, color: color ?? AppColors.textSecondary),
    );
  }
}
