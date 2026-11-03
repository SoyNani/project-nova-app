import 'package:fpdart/fpdart.dart';
import '../entities/speaker_entity.dart';
import '../entities/speaker_event_entity.dart';
import '../entities/speaker_failure.dart';

abstract interface class SpeakerRepository {
  Stream<List<SpeakerEntity>> watchAll();

  Future<Either<SpeakerFailure, SpeakerEntity>> getById(String id);

  Future<Either<SpeakerFailure, SpeakerEntity>> create(SpeakerEntity speaker);

  Stream<SpeakerEntity?> watchByEmail(String email);

  Future<Either<SpeakerFailure, SpeakerEntity>> update(SpeakerEntity speaker);

  Stream<List<SpeakerEventEntity>> watchEvents(String speakerId);
}
