import '../entities/event_entity.dart';
import '../repositories/event_repository.dart';

class WatchEvents {
  const WatchEvents(this._repository);

  final EventRepository _repository;

  Stream<List<EventEntity>> call() => _repository.watchAll();
}
