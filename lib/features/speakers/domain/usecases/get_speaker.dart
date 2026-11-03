import 'package:fpdart/fpdart.dart';
import '../entities/speaker_entity.dart';
import '../entities/speaker_failure.dart';
import '../repositories/speaker_repository.dart';

class GetSpeaker {
  const GetSpeaker(this._repository);

  final SpeakerRepository _repository;

  Future<Either<SpeakerFailure, SpeakerEntity>> call(String id) =>
      _repository.getById(id);
}
