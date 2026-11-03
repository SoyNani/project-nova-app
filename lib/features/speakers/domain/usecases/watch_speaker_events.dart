import '../entities/speaker_event_entity.dart';
import '../repositories/speaker_repository.dart';

class WatchSpeakerEvents {
  const WatchSpeakerEvents(this._repository);

  final SpeakerRepository _repository;

  Stream<List<SpeakerEventEntity>> call(String speakerId) =>
      _repository.watchEvents(speakerId);
}
