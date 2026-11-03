import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/atoms/app_filter_chip.dart';
import '../../core/widgets/atoms/app_square_icon_button.dart';
import '../../core/widgets/organisms/module_placeholder_screen.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/events/domain/entities/event_entity.dart';
import '../../features/events/presentation/providers/event_providers.dart';
import '../../features/events/presentation/screens/event_detail_screen.dart';
import '../../features/events/presentation/screens/event_form_screen.dart';
import '../../features/events/presentation/screens/events_list_screen.dart';
import '../../features/events/presentation/widgets/event_hero_card.dart';
import '../../features/events/presentation/widgets/event_schedule_timeline.dart';
import '../../features/organizations/presentation/screens/organizations_list_screen.dart';
import '../../features/speakers/presentation/screens/speakers_list_screen.dart';

const _homeScheduleDays = 5;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    required this.user,
    this.onOpenMap,
    this.onOpenGallery,
  });

  final UserEntity user;

  final VoidCallback? onOpenMap;
  final VoidCallback? onOpenGallery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                children: [
                  _Header(
                    user: user,
                    onCreateEvent: () =>
                        _push(context, EventFormScreen(createdBy: user.uid)),
                  ),
                  const SizedBox(height: 24),
                  _FeaturedEvent(
                    onOpen: (event) =>
                        _push(context, EventDetailScreen(event: event)),
                    onCreate: () =>
                        _push(context, EventFormScreen(createdBy: user.uid)),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Accesos rápidos',
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: 14),
                  _QuickAccessGrid(
                    items: [
                      _QuickAccess(
                        label: 'Calendario',
                        icon: Icons.calendar_today_outlined,
                        color: AppColors.calendarColor,
                        onTap: () => _openSchedule(context),
                      ),
                      _QuickAccess(
                        label: 'Instituciones',
                        icon: Icons.account_balance_outlined,
                        color: AppColors.institutionsColor,
                        onTap: () =>
                            _push(context, const OrganizationsListScreen()),
                      ),
                      _QuickAccess(
                        label: 'Speakers',
                        icon: Icons.person_outline,
                        color: AppColors.speakersColor,
                        onTap: () => _push(context, const SpeakersListScreen()),
                      ),
                      _QuickAccess(
                        label: 'Mapa',
                        icon: Icons.location_on_outlined,
                        color: AppColors.mapColor,
                        onTap: onOpenMap ?? () {},
                      ),
                      if (user.isAdmin)
                        _QuickAccess(
                          label: 'Panel admin',
                          icon: Icons.settings_outlined,
                          color: AppColors.navBackground,
                          filled: true,
                          onTap: () => _push(
                            context,
                            const ModulePlaceholderScreen(
                              title: 'Panel admin',
                              icon: Icons.settings_outlined,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Cronograma',
                          style: AppTextStyles.sectionTitle,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _openSchedule(context),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryLight,
                          textStyle: AppTextStyles.badge.copyWith(fontSize: 12),
                        ),
                        child: const Text('VER TODO'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const _CityFilter(),
                  const SizedBox(height: 16),
                  _Schedule(
                    onTapEvent: (event) =>
                        _push(context, EventDetailScreen(event: event)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openSchedule(BuildContext context) =>
      _push(context, EventsListScreen(createdBy: user.uid));

  static void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user, required this.onCreateEvent});

  final UserEntity user;
  final VoidCallback onCreateEvent;

  String get _firstName {
    final words = user.displayName.trim().split(RegExp(r'\s+'));
    return words.isEmpty || words.first.isEmpty ? 'de nuevo' : words.first;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('NOVA APP', style: AppTextStyles.brand),
              const SizedBox(height: 4),
              RichText(
                key: const Key('home-greeting'),
                text: TextSpan(
                  style: AppTextStyles.greeting.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  children: [
                    const TextSpan(text: 'Hola, '),
                    TextSpan(
                      text: _firstName,
                      style: const TextStyle(color: AppColors.primaryLight),
                    ),
                    const TextSpan(text: ' 👋'),
                  ],
                ),
              ),
            ],
          ),
        ),
        AppSquareIconButton(
          icon: Icons.add,
          tooltip: 'Nuevo evento',
          onPressed: onCreateEvent,
        ),
      ],
    );
  }
}

class _FeaturedEvent extends ConsumerWidget {
  const _FeaturedEvent({required this.onOpen, required this.onCreate});

  final ValueChanged<EventEntity> onOpen;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider).value ?? DateTime.now();

    return ref
        .watch(featuredEventProvider)
        .when(
          data: (featured) {
            if (featured == null) return EventHeroEmpty(onCreate: onCreate);
            return EventHeroCard(
              featured: featured,
              now: now,
              onOpen: () => onOpen(featured.event),
            );
          },
          loading: () => const EventHeroSurface(
            child: SizedBox(
              height: 150,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.onPrimary),
              ),
            ),
          ),
          error: (error, _) => EventHeroSurface(
            child: Text(
              'No se pudieron cargar los eventos.\n$error',
              style: AppTextStyles.heroSubtitle,
            ),
          ),
        );
  }
}

class _QuickAccess {
  const _QuickAccess({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  final bool filled;
}

class _QuickAccessGrid extends StatelessWidget {
  const _QuickAccessGrid({required this.items});

  final List<_QuickAccess> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 6 : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 96,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => _QuickAccessTile(item: items[index]),
        );
      },
    );
  }
}

class _QuickAccessTile extends StatelessWidget {
  const _QuickAccessTile({required this.item});

  final _QuickAccess item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: item.onTap,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.filled
                      ? item.color
                      : item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.icon,
                  size: 19,
                  color: item.filled ? AppColors.onPrimary : item.color,
                ),
              ),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CityFilter extends ConsumerWidget {
  const _CityFilter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cities = ref.watch(scheduleCitiesProvider);
    if (cities.isEmpty) return const SizedBox.shrink();

    final selected = ref.watch(scheduleCityFilterProvider);
    final effective = cities.contains(selected) ? selected : null;
    final notifier = ref.read(scheduleCityFilterProvider.notifier);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          AppFilterChip(
            label: 'Todas',
            selected: effective == null,
            onSelected: () => notifier.select(null),
          ),
          for (final city in cities) ...[
            const SizedBox(width: 8),
            AppFilterChip(
              label: city,
              selected: effective == city,
              onSelected: () => notifier.select(city),
            ),
          ],
        ],
      ),
    );
  }
}

class _Schedule extends ConsumerWidget {
  const _Schedule({required this.onTapEvent});

  final ValueChanged<EventEntity> onTapEvent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider).value ?? DateTime.now();

    return ref
        .watch(upcomingScheduleProvider)
        .when(
          data: (days) {
            if (days.isEmpty) {
              return const _EmptySchedule();
            }
            return EventScheduleTimeline(
              days: days.take(_homeScheduleDays).toList(),
              now: now,
              onTapEvent: onTapEvent,
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const Text(
            'No se pudo cargar el cronograma.',
            style: TextStyle(color: AppColors.error),
          ),
        );
  }
}

class _EmptySchedule extends StatelessWidget {
  const _EmptySchedule();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.event_available_outlined, color: AppColors.textMuted),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No hay eventos próximos en el cronograma.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
