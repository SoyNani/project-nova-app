import 'package:fpdart/fpdart.dart';
import '../entities/speaker_entity.dart';
import '../entities/speaker_failure.dart';
import '../repositories/speaker_repository.dart';
import 'speaker_field_cleaner.dart';

class UpdateSpeaker {
  const UpdateSpeaker(this._repository);

  final SpeakerRepository _repository;

  Future<Either<SpeakerFailure, SpeakerEntity>> call({
    required SpeakerEntity current,
    required String name,
    required String profession,
    List<String> specialties = const [],
    List<String> organizationIds = const [],
    String? instagram,
    String? linkedin,
    String? tiktok,
  }) async {
    if (current.id.isEmpty) return left(const SpeakerNotFound());
    return _repository.update(
      SpeakerEntity(
        id: current.id,
        name: name.trim(),
        profession: profession.trim(),
        specialties: SpeakerFieldCleaner.list(specialties),
        organizationIds: SpeakerFieldCleaner.list(organizationIds),
        email: current.email,
        photoUrl: current.photoUrl,
        instagram: SpeakerFieldCleaner.optional(instagram),
        linkedin: SpeakerFieldCleaner.optional(linkedin),
        tiktok: SpeakerFieldCleaner.optional(tiktok),
      ),
    );
  }
}
