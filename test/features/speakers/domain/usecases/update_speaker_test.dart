import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_app/features/speakers/domain/entities/speaker_entity.dart';
import 'package:nova_app/features/speakers/domain/entities/speaker_failure.dart';
import 'package:nova_app/features/speakers/domain/repositories/speaker_repository.dart';
import 'package:nova_app/features/speakers/domain/usecases/update_speaker.dart';

class _MockSpeakerRepository extends Mock implements SpeakerRepository {}

const _current = SpeakerEntity(
  id: 'sp-1',
  name: 'Nara Ortiz',
  profession: 'Ingeniera',
  email: 'nara@correo.com',
  photoUrl: 'https://example.com/nara.png',
  organizationIds: ['org-1'],
);

void main() {
  late _MockSpeakerRepository repository;
  late UpdateSpeaker usecase;

  setUpAll(() {
    registerFallbackValue(
      const SpeakerEntity(id: '', name: '', profession: ''),
    );
  });

  setUp(() {
    repository = _MockSpeakerRepository();
    usecase = UpdateSpeaker(repository);
  });

  void stubUpdate() {
    when(() => repository.update(any())).thenAnswer(
      (invocation) async =>
          right(invocation.positionalArguments.first as SpeakerEntity),
    );
  }

  SpeakerEntity captured() =>
      verify(() => repository.update(captureAny())).captured.single
          as SpeakerEntity;

  test('limpia los campos y conserva id, correo y foto', () async {
    stubUpdate();

    await usecase(
      current: _current,
      name: '  Nara Ortiz Ruiz ',
      profession: ' Arquitecta de software ',
      specialties: [' Flutter ', '', 'Flutter', 'Dart'],
      organizationIds: ['org-2', ' org-2 '],
      instagram: '  @nara ',
      linkedin: '   ',
    );

    final speaker = captured();
    expect(speaker.id, 'sp-1');
    expect(speaker.email, 'nara@correo.com');
    expect(speaker.photoUrl, 'https://example.com/nara.png');
    expect(speaker.name, 'Nara Ortiz Ruiz');
    expect(speaker.profession, 'Arquitecta de software');
    expect(speaker.specialties, ['Flutter', 'Dart']);
    expect(speaker.organizationIds, ['org-2']);
    expect(speaker.instagram, '@nara');
    expect(speaker.linkedin, isNull);
  });

  test('sin id no llama al repositorio y retorna SpeakerNotFound', () async {
    final result = await usecase(
      current: const SpeakerEntity(id: '', name: 'X', profession: 'Y'),
      name: 'X',
      profession: 'Y',
    );

    expect(result.getLeft().toNullable(), isA<SpeakerNotFound>());
    verifyNever(() => repository.update(any()));
  });

  test('propaga el fallo del repositorio', () async {
    when(() => repository.update(any())).thenAnswer(
      (_) async => left(const SpeakerUnknownError('sin permiso')),
    );

    final result = await usecase(
      current: _current,
      name: 'Nara',
      profession: 'Ingeniera',
    );

    expect(result.isLeft(), true);
  });
}
