import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/atoms/app_fab.dart';
import '../../../../core/widgets/molecules/app_top_bar.dart';
import '../../domain/entities/speaker_entity.dart';
import '../providers/speaker_providers.dart';
import '../widgets/speaker_card.dart';
import '../widgets/speaker_filter_bar.dart';
import '../widgets/speaker_filter_panel.dart';
import 'speaker_detail_screen.dart';
import 'speaker_form_screen.dart';

class SpeakersListScreen extends ConsumerWidget {
  const SpeakersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speakersAsync = ref.watch(filteredSpeakersProvider);
    final hasFilters = ref.watch(speakerSearchQueryProvider).isNotEmpty ||
        ref.watch(speakerOrganizationFilterProvider) != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: 'Speakers'),
      endDrawer: const SpeakerFilterPanel(),
      floatingActionButton: AppFab(
        onPressed: () => _openForm(context),
        tooltip: 'Nuevo speaker',
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: SpeakerFilterBar(),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: speakersAsync.when(
                data: (speakers) {
                  if (speakers.isEmpty) {
                    return _EmptyState(hasFilters: hasFilters);
                  }
                  return AdaptiveBuilder(
                    mobile: (_) => _SpeakersListView(
                      speakers: speakers,
                      onTap: (speaker) => _openDetail(context, speaker),
                    ),
                    tablet: (_) => _SpeakersGridView(
                      speakers: speakers,
                      crossAxisCount: 2,
                      onTap: (speaker) => _openDetail(context, speaker),
                    ),
                    desktop: (_) => _SpeakersGridView(
                      speakers: speakers,
                      crossAxisCount: 3,
                      onTap: (speaker) => _openDetail(context, speaker),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, SpeakerEntity speaker) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SpeakerDetailScreen(speaker: speaker),
      ),
    );
  }

  void _openForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SpeakerFormScreen(),
      ),
    );
  }
}

class _SpeakersListView extends StatelessWidget {
  const _SpeakersListView({required this.speakers, required this.onTap});

  final List<SpeakerEntity> speakers;
  final void Function(SpeakerEntity) onTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
      itemCount: speakers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final speaker = speakers[index];
        return SpeakerCard(
          speaker: speaker,
          onTap: () => onTap(speaker),
        );
      },
    );
  }
}

class _SpeakersGridView extends StatelessWidget {
  const _SpeakersGridView({
    required this.speakers,
    required this.crossAxisCount,
    required this.onTap,
  });

  final List<SpeakerEntity> speakers;
  final int crossAxisCount;
  final void Function(SpeakerEntity) onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.4,
      ),
      itemCount: speakers.length,
      itemBuilder: (context, index) {
        final speaker = speakers[index];
        return SpeakerCard(
          speaker: speaker,
          onTap: () => onTap(speaker),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilters});

  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.record_voice_over_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              hasFilters
                  ? 'No hay speakers que coincidan con la búsqueda.'
                  : 'Aún no hay speakers registrados.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
