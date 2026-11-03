import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/atoms/app_page_title.dart';
import '../../../events/domain/entities/event_entity.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../../events/presentation/screens/event_detail_screen.dart';
import '../../domain/entities/event_map_place.dart';
import '../providers/map_providers.dart';
import '../widgets/event_place_sheet.dart';

const _defaultCenter = LatLng(7.1193, -73.1227);

class EventsMapScreen extends ConsumerStatefulWidget {
  const EventsMapScreen({super.key});

  @override
  ConsumerState<EventsMapScreen> createState() => _EventsMapScreenState();
}

class _EventsMapScreenState extends ConsumerState<EventsMapScreen> {
  GoogleMapController? _mapController;

  Set<String> _framedPlaceIds = const {};

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _frame(List<EventMapPlace> places) async {
    final controller = _mapController;
    if (controller == null || places.isEmpty) return;
    final points = [
      for (final place in places)
        LatLng(place.organization.latitude, place.organization.longitude),
    ];
    if (points.length == 1) {
      await controller.animateCamera(CameraUpdate.newLatLngZoom(points[0], 15));
      return;
    }
    final bounds = LatLngBounds(
      southwest: LatLng(
        points.map((p) => p.latitude).reduce(math.min),
        points.map((p) => p.longitude).reduce(math.min),
      ),
      northeast: LatLng(
        points.map((p) => p.latitude).reduce(math.max),
        points.map((p) => p.longitude).reduce(math.max),
      ),
    );
    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 64));
  }

  void _frameIfChanged(List<EventMapPlace> places) {
    final ids = {for (final p in places) p.organization.id};
    if (_mapController == null || _sameIds(ids, _framedPlaceIds)) return;
    _framedPlaceIds = ids;
    WidgetsBinding.instance.addPostFrameCallback((_) => _frame(places));
  }

  static bool _sameIds(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  double _hueFor(EventTiming timing) => switch (timing) {
    EventTiming.live => BitmapDescriptor.hueOrange,
    EventTiming.upcoming => BitmapDescriptor.hueAzure,
    EventTiming.finished => BitmapDescriptor.hueViolet,
  };

  void _openEvent(EventEntity event) {
    Navigator.of(context)
      ..pop()
      ..push(
        MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final placesAsync = ref.watch(eventMapPlacesProvider);
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final places = placesAsync.value ?? const <EventMapPlace>[];
    _frameIfChanged(places);

    final markers = {
      for (final place in places)
        Marker(
          markerId: MarkerId(place.organization.id),
          position: LatLng(
            place.organization.latitude,
            place.organization.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _hueFor(place.highlightedAt(now).timingAt(now)),
          ),
          consumeTapEvents: true,
          onTap: () => EventPlaceSheet.show(
            context,
            place: place,
            now: now,
            onOpenEvent: _openEvent,
          ),
        ),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: const SizedBox(
                    width: double.infinity,
                    child: AppPageTitle('Mapa'),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: _defaultCenter,
                      zoom: 12,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _framedPlaceIds = {
                        for (final p in places) p.organization.id,
                      };
                      _frame(places);
                    },
                    markers: markers,
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    mapToolbarEnabled: false,
                    // Deja libre la zona del menú flotante inferior.
                    padding: const EdgeInsets.only(bottom: 110),
                  ),
                  Positioned(
                    top: 12,
                    left: 16,
                    right: 16,
                    child: placesAsync.when(
                      loading: () => const _InfoChip(
                        icon: Icons.hourglass_empty,
                        text: 'Cargando eventos…',
                      ),
                      error: (_, _) => const _InfoChip(
                        icon: Icons.error_outline,
                        text: 'No se pudieron cargar los eventos.',
                        color: AppColors.error,
                      ),
                      data: (places) => _InfoChip(
                        icon: Icons.location_on_outlined,
                        text: places.isEmpty
                            ? 'Aún no hay eventos con ubicación.'
                            : 'Toca un pin para ver los eventos del lugar.',
                      ),
                    ),
                  ),
                  if (places.length > 1)
                    Positioned(
                      right: 16,
                      bottom: 124,
                      child: _FrameButton(onPressed: () => _frame(places)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.text,
    this.color = AppColors.textSecondary,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 4)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                style: AppTextStyles.cardSubtitle.copyWith(
                  fontSize: 12,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrameButton extends StatelessWidget {
  const _FrameButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const Tooltip(
          message: 'Ver todos los eventos',
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Icon(Icons.zoom_out_map, size: 20, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
