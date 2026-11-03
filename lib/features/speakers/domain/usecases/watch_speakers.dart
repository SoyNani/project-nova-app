import '../entities/speaker_entity.dart';
import '../repositories/speaker_repository.dart';

class WatchSpeakers {
  const WatchSpeakers(this._repository);

  final SpeakerRepository _repository;

  Stream<List<SpeakerEntity>> call() => _repository.watchAll();
}
