import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_app/features/speakers/domain/entities/speaker_event_entity.dart';
import 'package:nova_app/features/speakers/domain/repositories/speaker_repository.dart';
import 'package:nova_app/features/speakers/domain/usecases/watch_speaker_events.dart';

class _MockSpeakerRepository extends Mock implements SpeakerRepository {}

void main() {
  late _MockSpeakerRepository repository;

  const event = SpeakerEventEntity(id: 'ev-1', name: 'Flutter Day');

  setUp(() {
    repository = _MockSpeakerRepository();
  });

  test('pide los eventos del speaker y los emite', () async {
    when(() => repository.watchEvents('sp-1'))
        .thenAnswer((_) => Stream.value([event]));

    final result = await WatchSpeakerEvents(repository)('sp-1').first;

    verify(() => repository.watchEvents('sp-1')).called(1);
    expect(result.single.name, 'Flutter Day');
  });
}
