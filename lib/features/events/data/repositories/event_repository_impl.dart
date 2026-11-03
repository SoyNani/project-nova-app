import 'package:fpdart/fpdart.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/entities/event_failure.dart';
import '../../domain/repositories/event_repository.dart';
import '../datasources/event_firestore_datasource.dart';
import '../models/event_model.dart';

/// Traduce excepciones de `data/` en [EventFailure] de `domain/`.
class EventRepositoryImpl implements EventRepository {
  const EventRepositoryImpl(this._datasource);

  final EventFirestoreDatasource _datasource;

  @override
  Stream<List<EventEntity>> watchAll() => _datasource.watchAll();

  @override
  Future<Either<EventFailure, EventEntity>> create(EventEntity event) async {
    try {
      final created = await _datasource.create(EventModel.fromEntity(event));
      return right(created);
    } catch (e) {
      return left(EventUnknownError(e.toString()));
    }
  }

  @override
  Future<Either<EventFailure, void>> cancel(EventEntity event) =>
      _setCancelled(event, cancelled: true);

  @override
  Future<Either<EventFailure, void>> restore(EventEntity event) =>
      _setCancelled(event, cancelled: false);

  Future<Either<EventFailure, void>> _setCancelled(
    EventEntity event, {
    required bool cancelled,
  }) async {
    try {
      await _datasource.setCancelled(
        EventModel.fromEntity(event),
        cancelled: cancelled,
      );
      return right(null);
    } catch (e) {
      return left(EventUnknownError(e.toString()));
    }
  }
}
