import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/speaker_firestore_datasource.dart';
import '../../data/repositories/speaker_repository_impl.dart';
import '../../domain/entities/speaker_entity.dart';
import '../../domain/entities/speaker_event_entity.dart';
import '../../domain/repositories/speaker_repository.dart';
import '../../domain/usecases/filter_speakers.dart';
import '../../domain/usecases/create_speaker.dart';
import '../../domain/usecases/get_speaker.dart';
import '../../domain/usecases/update_speaker.dart';
import '../../domain/usecases/watch_speaker_by_email.dart';
import '../../domain/usecases/watch_speaker_events.dart';
import '../../domain/usecases/watch_speakers.dart';
import '../../../organizations/presentation/providers/organization_providers.dart';

final speakerDatasourceProvider = Provider<SpeakerFirestoreDatasource>((ref) {
  return SpeakerFirestoreDatasource();
});

final speakerRepositoryProvider = Provider<SpeakerRepository>((ref) {
  return SpeakerRepositoryImpl(ref.watch(speakerDatasourceProvider));
});

final watchSpeakersProvider = Provider<WatchSpeakers>((ref) {
  return WatchSpeakers(ref.watch(speakerRepositoryProvider));
});

final getSpeakerProvider = Provider<GetSpeaker>((ref) {
  return GetSpeaker(ref.watch(speakerRepositoryProvider));
});

final createSpeakerProvider = Provider<CreateSpeaker>((ref) {
  return CreateSpeaker(ref.watch(speakerRepositoryProvider));
});

final updateSpeakerProvider = Provider<UpdateSpeaker>((ref) {
  return UpdateSpeaker(ref.watch(speakerRepositoryProvider));
});

final watchSpeakerByEmailProvider = Provider<WatchSpeakerByEmail>((ref) {
  return WatchSpeakerByEmail(ref.watch(speakerRepositoryProvider));
});

final watchSpeakerEventsProvider = Provider<WatchSpeakerEvents>((ref) {
  return WatchSpeakerEvents(ref.watch(speakerRepositoryProvider));
});

final filterSpeakersProvider = Provider<FilterSpeakers>((ref) {
  return const FilterSpeakers();
});
final speakersListProvider = StreamProvider<List<SpeakerEntity>>((ref) {
  return ref.watch(watchSpeakersProvider)();
});

final speakerSearchQueryProvider =
    NotifierProvider<SpeakerSearchQueryController, String>(
  SpeakerSearchQueryController.new,
);

class SpeakerSearchQueryController extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;

  void clear() => state = '';
}

final speakerOrganizationFilterProvider =
    NotifierProvider<SpeakerOrganizationFilterController, String?>(
  SpeakerOrganizationFilterController.new,
);

class SpeakerOrganizationFilterController extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? organizationId) => state = organizationId;

  void clear() => state = null;
}

final filteredSpeakersProvider = Provider<AsyncValue<List<SpeakerEntity>>>((ref) {
  final listAsync = ref.watch(speakersListProvider);
  final query = ref.watch(speakerSearchQueryProvider);
  final organizationId = ref.watch(speakerOrganizationFilterProvider);
  final filter = ref.watch(filterSpeakersProvider);

  return listAsync.whenData(
    (speakers) => filter(
      speakers: speakers,
      query: query,
      organizationId: organizationId,
    ),
  );
});

final speakerFilterOrganizationsProvider =
    Provider<AsyncValue<List<SpeakerOrganizationOption>>>((ref) {
  return ref.watch(organizationsListProvider).whenData(
        (organizations) => organizations
            .map(
              (org) => SpeakerOrganizationOption(
                id: org.id,
                name: org.name,
                city: org.city,
              ),
            )
            .toList(),
      );
});

class SpeakerOrganizationOption {
  const SpeakerOrganizationOption({
    required this.id,
    required this.name,
    this.city = '',
  });

  final String id;
  final String name;
  final String city;
}

final speakerByIdProvider =
    FutureProvider.autoDispose.family<SpeakerEntity, String>((ref, id) async {
  final result = await ref.watch(getSpeakerProvider)(id);
  return result.match(
    (failure) => throw SpeakerNotLoaded(failure.message),
    (entity) => entity,
  );
});

final speakerEventsProvider = StreamProvider.autoDispose
    .family<List<SpeakerEventEntity>, String>((ref, speakerId) {
  return ref.watch(watchSpeakerEventsProvider)(speakerId);
});

class SpeakerNotLoaded implements Exception {
  const SpeakerNotLoaded(this.message);

  final String message;

  @override
  String toString() => message;
}

final speakerByEmailProvider =
    StreamProvider.autoDispose.family<SpeakerEntity?, String>(
  (ref, email) => ref.watch(watchSpeakerByEmailProvider)(email),
);

final speakerSelectedOrganizationsProvider = NotifierProvider.autoDispose
    .family<SpeakerSelectedOrganizationsController, Set<String>,
        SpeakerEntity?>(SpeakerSelectedOrganizationsController.new);

class SpeakerSelectedOrganizationsController extends Notifier<Set<String>> {
  SpeakerSelectedOrganizationsController(this.speaker);

  final SpeakerEntity? speaker;

  @override
  Set<String> build() => {...?speaker?.organizationIds};

  void toggle(String organizationId) {
    final next = {...state};
    if (!next.remove(organizationId)) next.add(organizationId);
    state = next;
  }

  void clear() => state = const {};
}

sealed class SpeakerFormState {
  const SpeakerFormState();
}

class SpeakerFormIdle extends SpeakerFormState {
  const SpeakerFormIdle();
}

class SpeakerFormLoading extends SpeakerFormState {
  const SpeakerFormLoading();
}

class SpeakerFormSuccess extends SpeakerFormState {
  const SpeakerFormSuccess(this.speaker);
  final SpeakerEntity speaker;
}

class SpeakerFormError extends SpeakerFormState {
  const SpeakerFormError(this.message);
  final String message;
}

final speakerFormControllerProvider = NotifierProvider.autoDispose
    .family<SpeakerFormController, SpeakerFormState, SpeakerEntity?>(
  SpeakerFormController.new,
);

class SpeakerFormController extends Notifier<SpeakerFormState> {
  SpeakerFormController(this.speaker);

  final SpeakerEntity? speaker;

  @override
  SpeakerFormState build() => const SpeakerFormIdle();

  Future<void> submit({
    required String name,
    required String profession,
    required List<String> specialties,
    required List<String> organizationIds,
    String? email,
    String? instagram,
    String? linkedin,
    String? tiktok,
  }) async {
    state = const SpeakerFormLoading();
    final current = speaker;
    final result = current == null
        ? await ref.read(createSpeakerProvider)(
            name: name,
            profession: profession,
            specialties: specialties,
            organizationIds: organizationIds,
            email: email,
            instagram: instagram,
            linkedin: linkedin,
            tiktok: tiktok,
          )
        : await ref.read(updateSpeakerProvider)(
            current: current,
            name: name,
            profession: profession,
            specialties: specialties,
            organizationIds: organizationIds,
            instagram: instagram,
            linkedin: linkedin,
            tiktok: tiktok,
          );
    if (!ref.mounted) return;
    result.match(
      (failure) => state = SpeakerFormError(failure.message),
      (saved) => state = SpeakerFormSuccess(saved),
    );
  }
}
