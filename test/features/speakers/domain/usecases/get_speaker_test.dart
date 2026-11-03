import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_app/features/speakers/domain/entities/speaker_entity.dart';
import 'package:nova_app/features/speakers/domain/entities/speaker_failure.dart';
import 'package:nova_app/features/speakers/domain/repositories/speaker_repository.dart';
import 'package:nova_app/features/speakers/domain/usecases/get_speaker.dart';

class _MockSpeakerRepository extends Mock implements SpeakerRepository {}

void main() {
  late _MockSpeakerRepository repository;
  late GetSpeaker usecase;

  const speaker = SpeakerEntity(
    id: 'sp-1',
    name: 'Nara Ortiz',
    profession: 'Ingeniera de software',
  );

  setUp(() {
    repository = _MockSpeakerRepository();
    usecase = GetSpeaker(repository);
  });

  test('delega el id al repositorio y devuelve el speaker', () async {
    when(() => repository.getById('sp-1'))
        .thenAnswer((_) async => right(speaker));

    final result = await usecase('sp-1');

    verify(() => repository.getById('sp-1')).called(1);
    expect(result.isRight(), true);
    result.match(
      (_) => fail('se esperaba un speaker'),
      (entity) => expect(entity.id, 'sp-1'),
    );
  });

  test('propaga SpeakerNotFound como Left', () async {
    when(() => repository.getById('missing'))
        .thenAnswer((_) async => left(const SpeakerNotFound()));

    final result = await usecase('missing');

    expect(result.isLeft(), true);
    result.match(
      (failure) => expect(failure.message, 'Speaker no encontrado.'),
      (_) => fail('se esperaba un fallo'),
    );
  });

  test('propaga un error desconocido como Left', () async {
    when(() => repository.getById('sp-1'))
        .thenAnswer((_) async => left(const SpeakerUnknownError('boom')));

    final result = await usecase('sp-1');

    expect(result.isLeft(), true);
  });
}
