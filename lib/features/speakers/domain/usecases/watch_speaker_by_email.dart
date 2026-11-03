import '../entities/speaker_entity.dart';
import '../repositories/speaker_repository.dart';
import 'speaker_field_cleaner.dart';

class WatchSpeakerByEmail {
  const WatchSpeakerByEmail(this._repository);

  final SpeakerRepository _repository;

  Stream<SpeakerEntity?> call(String email) {
    final normalized = SpeakerFieldCleaner.email(email);
    if (normalized == null) return Stream.value(null);
    return _repository.watchByEmail(normalized);
  }
}
