import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_app/features/speakers/domain/entities/speaker_entity.dart';
import 'package:nova_app/features/speakers/domain/repositories/speaker_repository.dart';
import 'package:nova_app/features/speakers/domain/usecases/watch_speaker_by_email.dart';

class _MockSpeakerRepository extends Mock implements SpeakerRepository {}

const _speaker = SpeakerEntity(
  id: 'sp-1',
  name: 'Nara Ortiz',
  profession: 'Ingeniera',
  email: 'nara@correo.com',
);

void main() {
  late _MockSpeakerRepository repository;
  late WatchSpeakerByEmail usecase;

  setUp(() {
    repository = _MockSpeakerRepository();
    usecase = WatchSpeakerByEmail(repository);
  });

  test('normaliza el correo (espacios y mayúsculas) antes de buscar', () {
    when(() => repository.watchByEmail(any()))
        .thenAnswer((_) => Stream.value(_speaker));

    expect(usecase('  Nara@Correo.COM '), emits(_speaker));
    verify(() => repository.watchByEmail('nara@correo.com')).called(1);
  });

  test('emite null sin consultar si el correo está vacío', () {
    expect(usecase('   '), emits(isNull));
    verifyNever(() => repository.watchByEmail(any()));
  });

  test('emite el speaker cuando se crea después de empezar a observar', () {
    when(() => repository.watchByEmail(any()))
        .thenAnswer((_) => Stream.fromIterable([null, _speaker]));

    expect(usecase('nara@correo.com'), emitsInOrder([isNull, _speaker]));
  });

  test('propaga el error del repositorio', () {
    when(() => repository.watchByEmail(any()))
        .thenAnswer((_) => Stream.error(Exception('sin conexión')));

    expect(usecase('nara@correo.com'), emitsError(isA<Exception>()));
  });
}
