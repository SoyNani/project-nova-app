import 'package:fpdart/fpdart.dart';
import '../entities/event_entity.dart';
import '../entities/event_failure.dart';

abstract interface class EventRepository {
  Stream<List<EventEntity>> watchAll();

  Future<Either<EventFailure, EventEntity>> create(EventEntity event);

  Future<Either<EventFailure, void>> cancel(EventEntity event);

  Future<Either<EventFailure, void>> restore(EventEntity event);
}
