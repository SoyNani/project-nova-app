import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../../organizations/presentation/providers/organization_providers.dart';
import '../../domain/entities/event_map_place.dart';
import '../../domain/usecases/group_events_by_place.dart';

final groupEventsByPlaceProvider = Provider<GroupEventsByPlace>((ref) {
  return const GroupEventsByPlace();
});

final eventMapPlacesProvider = Provider<AsyncValue<List<EventMapPlace>>>((ref) {
  final group = ref.watch(groupEventsByPlaceProvider);
  final events = ref.watch(activeEventsProvider);
  final organizations = ref.watch(organizationsListProvider);

  if (events.hasError) {
    return AsyncValue.error(events.error!, events.stackTrace!);
  }
  if (organizations.hasError) {
    return AsyncValue.error(organizations.error!, organizations.stackTrace!);
  }
  if (!events.hasValue || !organizations.hasValue) {
    return const AsyncValue.loading();
  }
  return AsyncValue.data(
    group(events: events.value!, organizations: organizations.value!),
  );
});
