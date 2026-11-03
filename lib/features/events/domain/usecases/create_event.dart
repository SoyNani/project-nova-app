import 'package:fpdart/fpdart.dart';
import '../entities/event_entity.dart';
import '../entities/event_failure.dart';
import '../repositories/event_repository.dart';

class CreateEvent {
  const CreateEvent(this._repository);

  final EventRepository _repository;

  Future<Either<EventFailure, EventEntity>> call({
    required String name,
    required DateTime startAt,
    required DateTime endAt,
    required String organizationId,
    String description = '',
    String organizationName = '',
    String city = '',
    String address = '',
    List<String> speakerIds = const [],
    List<String> speakerNames = const [],
    String? createdBy,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      return left(const EventInvalid('El evento necesita un nombre.'));
    }
    if (organizationId.trim().isEmpty) {
      return left(const EventInvalid('Selecciona una organización.'));
    }
    if (!endAt.isAfter(startAt)) {
      return left(
        const EventInvalid('La hora de fin debe ser posterior a la de inicio.'),
      );
    }
    if (speakerIds.length != speakerNames.length) {
      return left(const EventInvalid('Speakers inconsistentes.'));
    }

    final ids = <String>[];
    final names = <String>[];
    for (var i = 0; i < speakerIds.length; i++) {
      final id = speakerIds[i].trim();
      if (id.isEmpty || ids.contains(id)) continue;
      ids.add(id);
      names.add(speakerNames[i].trim());
    }

    return _repository.create(
      EventEntity(
        id: '',
        name: cleanName,
        description: description.trim(),
        startAt: startAt,
        endAt: endAt,
        organizationId: organizationId.trim(),
        organizationName: organizationName.trim(),
        city: city.trim(),
        address: address.trim(),
        speakerIds: ids,
        speakerNames: names,
        createdBy: createdBy,
      ),
    );
  }
}
