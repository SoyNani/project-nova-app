import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_app/features/events/domain/entities/event_entity.dart';
import 'package:nova_app/features/events/domain/entities/event_failure.dart';
import 'package:nova_app/features/events/domain/repositories/event_repository.dart';
import 'package:nova_app/features/events/domain/usecases/create_event.dart';

class _MockEventRepository extends Mock implements EventRepository {}

final _start = DateTime(2026, 10, 12, 15);
final _end = DateTime(2026, 10, 12, 16, 30);

void main() {
  late _MockEventRepository repository;
  late CreateEvent usecase;

  setUpAll(() {
    registerFallbackValue(
      EventEntity(
        id: '',
        name: '',
        startAt: _start,
        endAt: _end,
        organizationId: '',
      ),
    );
  });

  setUp(() {
    repository = _MockEventRepository();
    usecase = CreateEvent(repository);
    when(() => repository.create(any())).thenAnswer(
      (invocation) async =>
          right(invocation.positionalArguments.first as EventEntity),
    );
  });

  test('limpia los textos y quita speakers repetidos', () async {
    await usecase(
      name: '  Innovación educativa  ',
      description: ' Charla ',
      startAt: _start,
      endAt: _end,
      organizationId: 'org-1',
      organizationName: ' Colegio San Pedro Claver ',
      city: ' Bucaramanga ',
      speakerIds: ['sp-1', 'sp-2', 'sp-1'],
      speakerNames: ['Laura', 'Juan', 'Laura'],
    );

    final captured =
        verify(() => repository.create(captureAny())).captured.single
            as EventEntity;

    expect(captured.name, 'Innovación educativa');
    expect(captured.description, 'Charla');
    expect(captured.organizationName, 'Colegio San Pedro Claver');
    expect(captured.city, 'Bucaramanga');
    expect(captured.speakerIds, ['sp-1', 'sp-2']);
    expect(captured.speakerNames, ['Laura', 'Juan']);
  });

  test('rechaza un evento que termina antes de empezar', () async {
    final result = await usecase(
      name: 'Evento',
      startAt: _end,
      endAt: _start,
      organizationId: 'org-1',
    );

    expect(result.getLeft().toNullable(), isA<EventInvalid>());
    verifyNever(() => repository.create(any()));
  });

  test('exige nombre y organización', () async {
    final noName = await usecase(
      name: '   ',
      startAt: _start,
      endAt: _end,
      organizationId: 'org-1',
    );
    final noOrg = await usecase(
      name: 'Evento',
      startAt: _start,
      endAt: _end,
      organizationId: '',
    );

    expect(noName.isLeft(), isTrue);
    expect(noOrg.isLeft(), isTrue);
    verifyNever(() => repository.create(any()));
  });
}
