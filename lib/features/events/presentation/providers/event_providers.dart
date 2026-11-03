import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/event_firestore_datasource.dart';
import '../../data/repositories/event_repository_impl.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/entities/event_schedule_day.dart';
import '../../domain/entities/featured_event.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/usecases/build_event_schedule.dart';
import '../../domain/usecases/cancel_event.dart';
import '../../domain/usecases/create_event.dart';
import '../../domain/usecases/resolve_featured_event.dart';
import '../../domain/usecases/watch_events.dart';

final eventDatasourceProvider = Provider<EventFirestoreDatasource>((ref) {
  return EventFirestoreDatasource();
});

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepositoryImpl(ref.watch(eventDatasourceProvider));
});

final watchEventsProvider = Provider<WatchEvents>((ref) {
  return WatchEvents(ref.watch(eventRepositoryProvider));
});

final createEventProvider = Provider<CreateEvent>((ref) {
  return CreateEvent(ref.watch(eventRepositoryProvider));
});

final resolveFeaturedEventProvider = Provider<ResolveFeaturedEvent>((ref) {
  return const ResolveFeaturedEvent();
});

final buildEventScheduleProvider = Provider<BuildEventSchedule>((ref) {
  return const BuildEventSchedule();
});

final eventsListProvider = StreamProvider<List<EventEntity>>((ref) {
  return ref.watch(watchEventsProvider)();
});

final activeEventsProvider = Provider<AsyncValue<List<EventEntity>>>((ref) {
  return ref
      .watch(eventsListProvider)
      .whenData((events) => events.where((e) => !e.isCancelled).toList());
});

final cancelledEventsProvider = Provider<AsyncValue<List<EventEntity>>>((ref) {
  return ref.watch(eventsListProvider).whenData((events) {
    final cancelled = events.where((e) => e.isCancelled).toList()
      ..sort((a, b) {
        final left = a.cancelledAt ?? a.startAt;
        final right = b.cancelledAt ?? b.startAt;
        return right.compareTo(left);
      });
    return cancelled;
  });
});

final cancelEventProvider = Provider<CancelEvent>((ref) {
  return CancelEvent(ref.watch(eventRepositoryProvider));
});

final restoreEventProvider = Provider<RestoreEvent>((ref) {
  return RestoreEvent(ref.watch(eventRepositoryProvider));
});

final clockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 30), (_) => DateTime.now());
});

DateTime _now(Ref ref) => ref.watch(clockProvider).value ?? DateTime.now();

final featuredEventProvider = Provider<AsyncValue<FeaturedEvent?>>((ref) {
  final now = _now(ref);
  final resolve = ref.watch(resolveFeaturedEventProvider);
  return ref
      .watch(activeEventsProvider)
      .whenData((events) => resolve(events: events, now: now));
});

final scheduleCityFilterProvider =
    NotifierProvider<ScheduleCityFilterController, String?>(
      ScheduleCityFilterController.new,
    );

class ScheduleCityFilterController extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? city) => state = city;
}

final scheduleCitiesProvider = Provider<List<String>>((ref) {
  final now = _now(ref);
  final build = ref.watch(buildEventScheduleProvider);
  final events = ref.watch(activeEventsProvider).value ?? const [];
  return build.citiesOf(events: events, now: now);
});

final upcomingScheduleProvider = Provider<AsyncValue<List<EventScheduleDay>>>((
  ref,
) {
  final now = _now(ref);
  final build = ref.watch(buildEventScheduleProvider);
  final selected = ref.watch(scheduleCityFilterProvider);
  final city = ref.watch(scheduleCitiesProvider).contains(selected)
      ? selected
      : null;
  return ref
      .watch(activeEventsProvider)
      .whenData((events) => build(events: events, now: now, city: city));
});

final fullScheduleProvider = Provider<AsyncValue<List<EventScheduleDay>>>((
  ref,
) {
  final now = _now(ref);
  final build = ref.watch(buildEventScheduleProvider);
  return ref
      .watch(activeEventsProvider)
      .whenData(
        (events) => build(events: events, now: now, includeFinished: true),
      );
});

class EventDraft {
  const EventDraft({
    this.organizationId,
    this.speakerIds = const [],
    this.date,
    this.startTime,
    this.endTime,
  });

  final String? organizationId;
  final List<String> speakerIds;
  final DateTime? date;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;

  DateTime? get startAt => _combine(date, startTime);
  DateTime? get endAt => _combine(date, endTime);

  static DateTime? _combine(DateTime? date, TimeOfDay? time) {
    if (date == null || time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  EventDraft copyWith({
    String? organizationId,
    List<String>? speakerIds,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) {
    return EventDraft(
      organizationId: organizationId ?? this.organizationId,
      speakerIds: speakerIds ?? this.speakerIds,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

final eventDraftProvider =
    NotifierProvider.autoDispose<EventDraftController, EventDraft>(
      EventDraftController.new,
    );

class EventDraftController extends Notifier<EventDraft> {
  @override
  EventDraft build() => const EventDraft();

  void selectOrganization(String id) =>
      state = state.copyWith(organizationId: id);

  void toggleSpeaker(String id) {
    final next = [...state.speakerIds];
    if (!next.remove(id)) next.add(id);
    state = state.copyWith(speakerIds: next);
  }

  void setDate(DateTime date) => state = state.copyWith(date: date);

  void setStartTime(TimeOfDay time) {
    var next = state.copyWith(startTime: time);
    // Sugerir 1 h de duración si aún no hay hora de fin.
    if (state.endTime == null) {
      final minutes = time.hour * 60 + time.minute + 60;
      if (minutes < 24 * 60) {
        next = next.copyWith(
          endTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
        );
      }
    }
    state = next;
  }

  void setEndTime(TimeOfDay time) => state = state.copyWith(endTime: time);
}

sealed class EventFormState {
  const EventFormState();
}

class EventFormIdle extends EventFormState {
  const EventFormIdle();
}

class EventFormLoading extends EventFormState {
  const EventFormLoading();
}

class EventFormSuccess extends EventFormState {
  const EventFormSuccess(this.event);
  final EventEntity event;
}

class EventFormError extends EventFormState {
  const EventFormError(this.message);
  final String message;
}

final eventFormControllerProvider =
    NotifierProvider.autoDispose<EventFormController, EventFormState>(
      EventFormController.new,
    );

class EventFormController extends Notifier<EventFormState> {
  @override
  EventFormState build() => const EventFormIdle();

  Future<void> submit({
    required String name,
    required String description,
    required DateTime startAt,
    required DateTime endAt,
    required String organizationId,
    required String organizationName,
    required String city,
    required String address,
    required List<String> speakerIds,
    required List<String> speakerNames,
    String? createdBy,
  }) async {
    state = const EventFormLoading();
    final result = await ref.read(createEventProvider)(
      name: name,
      description: description,
      startAt: startAt,
      endAt: endAt,
      organizationId: organizationId,
      organizationName: organizationName,
      city: city,
      address: address,
      speakerIds: speakerIds,
      speakerNames: speakerNames,
      createdBy: createdBy,
    );
    result.match(
      (failure) => state = EventFormError(failure.message),
      (event) => state = EventFormSuccess(event),
    );
  }
}
