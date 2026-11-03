import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_app/features/speakers/domain/entities/speaker_entity.dart';
import 'package:nova_app/features/speakers/domain/entities/speaker_failure.dart';
import 'package:nova_app/features/speakers/domain/repositories/speaker_repository.dart';
import 'package:nova_app/features/speakers/domain/usecases/create_speaker.dart';

class _MockSpeakerRepository extends Mock implements SpeakerRepository {}

void main() {
  late _MockSpeakerRepository repository;
  late CreateSpeaker usecase;

  setUpAll(() {
    registerFallbackValue(
      const SpeakerEntity(id: '', name: '', profession: ''),
    );
  });

  setUp(() {
    repository = _MockSpeakerRepository();
    usecase = CreateSpeaker(repository);
  });

  void stubCreate() {
    when(() => repository.create(any())).thenAnswer(
      (invocation) async =>
          right(invocation.positionalArguments.first as SpeakerEntity),
    );
  }

  test('recorta espacios de nombre y profesión', () async {
    stubCreate();

    await usecase(
      name: '  Nara Ortiz  ',
      profession: ' Ingeniera de software ',
    );

    final captured =
        verify(() => repository.create(captureAny())).captured.single
            as SpeakerEntity;

    expect(captured.name, 'Nara Ortiz');
    expect(captured.profession, 'Ingeniera de software');
    expect(captured.id, '');
  });

  test('limpia especialidades: recorta, quita vacíos y duplicados', () async {
    stubCreate();

    await usecase(
      name: 'Nara Ortiz',
      profession: 'Ingeniera',
      specialties: [' Flutter ', '', 'Dart', 'Flutter'],
    );

    final captured =
        verify(() => repository.create(captureAny())).captured.single
            as SpeakerEntity;

    expect(captured.specialties, ['Flutter', 'Dart']);
  });

  test('deja en null las redes vacías y guarda las que vienen', () async {
    stubCreate();

    await usecase(
      name: 'Nara Ortiz',
      profession: 'Ingeniera',
      instagram: '  @nara  ',
      linkedin: '   ',
    );

    final captured =
        verify(() => repository.create(captureAny())).captured.single
            as SpeakerEntity;

    expect(captured.instagram, '@nara');
    expect(captured.linkedin, isNull);
    expect(captured.tiktok, isNull);
  });

  test('guarda el correo en minúsculas y sin espacios, o null si viene vacío',
      () async {
    stubCreate();

    await usecase(
      name: 'Nara Ortiz',
      profession: 'Ingeniera',
      email: '  Nara@Correo.COM ',
    );
    await usecase(name: 'Juan', profession: 'Docente', email: '   ');

    final captured = verify(() => repository.create(captureAny()))
        .captured
        .cast<SpeakerEntity>();

    expect(captured[0].email, 'nara@correo.com');
    expect(captured[1].email, isNull);
  });

  test('retorna Left cuando el repositorio falla', () async {
    when(() => repository.create(any()))
        .thenAnswer((_) async => left(const SpeakerUnknownError('sin permiso')));

    final result = await usecase(
      name: 'Nara Ortiz',
      profession: 'Ingeniera',
    );

    expect(result.isLeft(), true);
  });
}
