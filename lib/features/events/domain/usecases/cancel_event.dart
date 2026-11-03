import 'package:fpdart/fpdart.dart';
import '../entities/event_entity.dart';
import '../entities/event_failure.dart';
import '../repositories/event_repository.dart';

/// Marca el evento como cancelado. No lo borra: queda en la lista de cancelados y se puede restaurar con [RestoreEvent].
class CancelEvent {
  const CancelEvent(this._repository);

  final EventRepository _repository;

  Future<Either<EventFailure, void>> call(EventEntity event) async {
    if (event.isCancelled) {
      return left(const EventInvalid('El evento ya está cancelado.'));
    }
    return _repository.cancel(event);
  }
}

/// devuelve un evento cancelado al cronograma.
class RestoreEvent {
  const RestoreEvent(this._repository);

  final EventRepository _repository;

  Future<Either<EventFailure, void>> call(EventEntity event) async {
    if (!event.isCancelled) {
      return left(const EventInvalid('El evento no está cancelado.'));
    }
    return _repository.restore(event);
  }
}
