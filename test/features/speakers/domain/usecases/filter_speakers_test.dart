import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/features/speakers/domain/entities/speaker_entity.dart';
import 'package:nova_app/features/speakers/domain/usecases/filter_speakers.dart';

const _naraOrtiz = SpeakerEntity(
  id: 'sp-1',
  name: 'Nara Ortiz',
  profession: 'Ingeniera de software',
  specialties: ['Flutter'],
  organizationIds: ['org-1'],
);

const _naraGomez = SpeakerEntity(
  id: 'sp-2',
  name: 'Nara Gómez',
  profession: 'Diseñadora UX',
  specialties: ['UX'],
  organizationIds: ['org-2'],
);

const _juan = SpeakerEntity(
  id: 'sp-3',
  name: 'Juan Pérez',
  profession: 'Docente',
  specialties: [],
  organizationIds: [],
);

void main() {
  const filter = FilterSpeakers();
  const speakers = [_naraOrtiz, _naraGomez, _juan];

  group('FilterSpeakers — búsqueda por nombre', () {
    test('sin query devuelve la lista completa', () {
      expect(filter(speakers: speakers).length, 3);
    });

    test('filtra por nombre ignorando mayúsculas y espacios', () {
      final result = filter(speakers: speakers, query: '  nara  ');

      expect(result.map((s) => s.id), ['sp-1', 'sp-2']);
    });

    test('busca por subcadena sin distinguir mayúsculas', () {
      final result = filter(speakers: speakers, query: 'PÉREZ');

      expect(result.single.id, 'sp-3');
    });

    test('devuelve vacío si nadie coincide', () {
      expect(filter(speakers: speakers, query: 'zzzz'), isEmpty);
    });
  });

  group('FilterSpeakers — filtro por organización', () {
    test('con organización seleccionada filtra por organizationIds', () {
      final result = filter(speakers: speakers, organizationId: 'org-2');

      expect(result.single.id, 'sp-2');
    });

    test('combina búsqueda y organización', () {
      final result = filter(
        speakers: speakers,
        query: 'nara',
        organizationId: 'org-1',
      );

      expect(result.single.id, 'sp-1');
    });

    test('organizationId null no filtra', () {
      expect(filter(speakers: speakers, organizationId: null).length, 3);
    });
  });
}
