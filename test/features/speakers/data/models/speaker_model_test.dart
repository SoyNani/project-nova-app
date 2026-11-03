import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/features/speakers/data/models/speaker_event_model.dart';
import 'package:nova_app/features/speakers/data/models/speaker_model.dart';

void main() {
  group('SpeakerModel', () {
    test('fromFirestore mapea especialidades, organizaciones y redes', () {
      final json = {
        'name': 'Nara Ortiz',
        'profession': 'Ingeniera de software',
        'specialties': ['Flutter', 'Dart'],
        'organizationIds': ['org-1'],
        'photoUrl': 'https://example.com/nara.png',
        'instagram': '@nara',
        'linkedin': 'linkedin.com/in/nara',
        'tiktok': '',
      };

      final model = SpeakerModel.fromFirestore(json, 'sp-1');

      expect(model.id, 'sp-1');
      expect(model.specialties, ['Flutter', 'Dart']);
      expect(model.organizationIds, ['org-1']);
      expect(model.instagram, '@nara');
      expect(model.linkedin, 'linkedin.com/in/nara');
    });

    test('fromFirestore deja en null las redes vacías o ausentes', () {
      final json = {
        'name': 'Nara Ortiz',
        'profession': 'Ingeniera',
        'tiktok': '   ',
      };

      final model = SpeakerModel.fromFirestore(json, 'sp-1');

      expect(model.instagram, isNull);
      expect(model.linkedin, isNull);
      expect(model.tiktok, isNull);
      expect(model.hasPhoto, false);
    });

    test('fromFirestore tolera documentos incompletos', () {
      final model = SpeakerModel.fromFirestore({}, 'sp-1');

      expect(model.name, '');
      expect(model.profession, '');
      expect(model.specialties, isEmpty);
      expect(model.organizationIds, isEmpty);
    });

    test('toFirestore escribe los tres campos fijos de redes', () {
      const model = SpeakerModel(
        id: 'sp-1',
        name: 'Nara Ortiz',
        profession: 'Ingeniera',
        instagram: '@nara',
        linkedin: 'nara',
        tiktok: 'nara',
      );

      final json = model.toFirestore();

      expect(json['instagram'], '@nara');
      expect(json['linkedin'], 'nara');
      expect(json['tiktok'], 'nara');
      expect(json['specialties'], isEmpty);
    });

    test('fromFirestore lee el correo en minúsculas y toFirestore lo escribe',
        () {
      final model = SpeakerModel.fromFirestore(
        {'name': 'Nara', 'profession': 'Ingeniera', 'email': ' Nara@Correo.com '},
        'sp-1',
      );

      expect(model.email, 'nara@correo.com');
      expect(model.toFirestore()['email'], 'nara@correo.com');
      expect(SpeakerModel.fromFirestore({}, 'sp-2').email, isNull);
    });

    test('toFirestoreCreate ignora la foto porque hoy no se sube imagen', () {
      const model = SpeakerModel(
        id: 'sp-1',
        name: 'Nara Ortiz',
        profession: 'Ingeniera',
        photoUrl: 'https://example.com/nara.png',
      );

      final json = model.toFirestoreCreate();

      expect(json['photoUrl'], isNull);
      expect(json['name'], 'Nara Ortiz');
    });

    test('initials toma la primera letra de los dos primeros nombres', () {
      const model = SpeakerModel(
        id: 'sp-1',
        name: 'Nara María Ortiz',
        profession: 'Ingeniera',
      );

      expect(model.initials, 'NM');
    });

    test('initials de un solo nombre toma una letra', () {
      const model = SpeakerModel(
        id: 'sp-1',
        name: 'Cher',
        profession: 'Artista',
      );

      expect(model.initials, 'C');
    });
  });

  group('SpeakerEventModel', () {
    test('mapea name y date ISO', () {
      final model = SpeakerEventModel.fromFirestore(
        {'name': 'Flutter Day', 'date': '2026-05-14T15:00:00.000Z'},
        'ev-1',
      );

      expect(model.name, 'Flutter Day');
      expect(model.date, DateTime.utc(2026, 5, 14, 15));
    });

    test('date ausente queda en null', () {
      final model = SpeakerEventModel.fromFirestore({'name': 'Sin fecha'}, 'ev-1');

      expect(model.date, isNull);
    });
  });
}
