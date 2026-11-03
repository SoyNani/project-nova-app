import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_app/features/speakers/domain/entities/speaker_entity.dart';
import 'package:nova_app/features/speakers/domain/repositories/speaker_repository.dart';
import 'package:nova_app/features/speakers/domain/usecases/watch_speakers.dart';

class _MockSpeakerRepository extends Mock implements SpeakerRepository {}

void main() {
  late _MockSpeakerRepository repository;

  const speaker = SpeakerEntity(
    id: 'sp-1',
    name: 'Nara Ortiz',
    profession: 'Ingeniera de software',
  );

  setUp(() {
    repository = _MockSpeakerRepository();
  });

  test('devuelve el stream de speakers del repositorio', () async {
    when(() => repository.watchAll())
        .thenAnswer((_) => Stream.value([speaker]));

    final result = await WatchSpeakers(repository)().first;

    expect(result.single.id, 'sp-1');
  });
}
