import 'package:fpdart/fpdart.dart';
import '../entities/speaker_entity.dart';
import '../entities/speaker_failure.dart';
import '../repositories/speaker_repository.dart';
import 'speaker_field_cleaner.dart';

class CreateSpeaker {
  const CreateSpeaker(this._repository);

  final SpeakerRepository _repository;

  Future<Either<SpeakerFailure, SpeakerEntity>> call({
    required String name,
    required String profession,
    List<String> specialties = const [],
    List<String> organizationIds = const [],
    String? email,
    String? instagram,
    String? linkedin,
    String? tiktok,
  }) {
    return _repository.create(
      SpeakerEntity(
        id: '',
        name: name.trim(),
        profession: profession.trim(),
        specialties: SpeakerFieldCleaner.list(specialties),
        organizationIds: SpeakerFieldCleaner.list(organizationIds),
        email: SpeakerFieldCleaner.email(email),
        instagram: SpeakerFieldCleaner.optional(instagram),
        linkedin: SpeakerFieldCleaner.optional(linkedin),
        tiktok: SpeakerFieldCleaner.optional(tiktok),
      ),
    );
  }
}
