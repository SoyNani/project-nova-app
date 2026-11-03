import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_app/features/events/domain/entities/event_entity.dart';
import 'package:nova_app/features/events/domain/entities/event_failure.dart';
import 'package:nova_app/features/events/domain/repositories/event_repository.dart';
import 'package:nova_app/features/events/domain/usecases/cancel_event.dart';

class _MockEventRepository extends Mock implements EventRepository {}

EventEntity _event({bool cancelled = false}) => EventEntity(
  id: 'ev-1',
  name: 'Evento',
  startAt: DateTime(2026, 10, 12, 15),
  endAt: DateTime(2026, 10, 12, 16),
  organizationId: 'org-1',
  isCancelled: cancelled,
);

void main() {
  late _MockEventRepository repository;

  setUpAll(() => registerFallbackValue(_event()));

  setUp(() {
    repository = _MockEventRepository();
    when(() => repository.cancel(any())).thenAnswer((_) async => right(null));
    when(() => repository.restore(any())).thenAnswer((_) async => right(null));
  });

  test('cancela un evento activo', () async {
    final result = await CancelEvent(repository)(_event());

    expect(result.isRight(), isTrue);
    verify(() => repository.cancel(any())).called(1);
  });

  test('no vuelve a cancelar uno ya cancelado', () async {
    final result = await CancelEvent(repository)(_event(cancelled: true));

    expect(result.getLeft().toNullable(), isA<EventInvalid>());
    verifyNever(() => repository.cancel(any()));
  });

  test('restaura un evento cancelado', () async {
    final result = await RestoreEvent(repository)(_event(cancelled: true));

    expect(result.isRight(), isTrue);
    verify(() => repository.restore(any())).called(1);
  });

  test('no restaura uno que no está cancelado', () async {
    final result = await RestoreEvent(repository)(_event());

    expect(result.isLeft(), isTrue);
    verifyNever(() => repository.restore(any()));
  });

  test('propaga el error del repositorio', () async {
    when(
      () => repository.cancel(any()),
    ).thenAnswer((_) async => left(const EventUnknownError('sin permiso')));

    final result = await CancelEvent(repository)(_event());

    expect(result.getLeft().toNullable()?.message, 'sin permiso');
  });
}
