import 'package:fpdart/fpdart.dart';
import '../../domain/entities/speaker_entity.dart';
import '../../domain/entities/speaker_event_entity.dart';
import '../../domain/entities/speaker_failure.dart';
import '../../domain/repositories/speaker_repository.dart';
import '../datasources/speaker_firestore_datasource.dart';
import '../models/speaker_model.dart';

class SpeakerRepositoryImpl implements SpeakerRepository {
  const SpeakerRepositoryImpl(this._datasource);

  final SpeakerFirestoreDatasource _datasource;

  @override
  Stream<List<SpeakerEntity>> watchAll() => _datasource.watchAll();

  @override
  Future<Either<SpeakerFailure, SpeakerEntity>> getById(String id) async {
    try {
      final speaker = await _datasource.getById(id);
      return right(speaker);
    } on SpeakerNotFoundException {
      return left(const SpeakerNotFound());
    } catch (e) {
      return left(SpeakerUnknownError(e.toString()));
    }
  }

  @override
  Future<Either<SpeakerFailure, SpeakerEntity>> create(
    SpeakerEntity speaker,
  ) async {
    try {
      final created =
          await _datasource.create(SpeakerModel.fromEntity(speaker));
      return right(created);
    } catch (e) {
      return left(SpeakerUnknownError(e.toString()));
    }
  }

  @override
  Stream<SpeakerEntity?> watchByEmail(String email) =>
      _datasource.watchByEmail(email);

  @override
  Future<Either<SpeakerFailure, SpeakerEntity>> update(
    SpeakerEntity speaker,
  ) async {
    try {
      final updated =
          await _datasource.update(SpeakerModel.fromEntity(speaker));
      return right(updated);
    } on SpeakerNotFoundException {
      return left(const SpeakerNotFound());
    } catch (e) {
      return left(SpeakerUnknownError(e.toString()));
    }
  }

  @override
  Stream<List<SpeakerEventEntity>> watchEvents(String speakerId) =>
      _datasource.watchEvents(speakerId);
}
