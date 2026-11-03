import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/features/organizations/data/models/organization_model.dart';

void main() {
  group('OrganizationModel', () {
    test('fromFirestore mapea lat/lng y usa 0 por defecto si faltan', () {
      final json = {
        'name': 'Colegio San José',
        'city': 'Bucaramanga',
        'department': 'Santander',
        'address': 'Cra 27 # 45-12',
        'lat': 7.1193,
        'lng': -73.1227,
      };

      final model = OrganizationModel.fromFirestore(json, 'org-1');

      expect(model.id, 'org-1');
      expect(model.latitude, 7.1193);
      expect(model.longitude, -73.1227);
      expect(model.eventsCount, 0);
    });

    test('toFirestoreCreate siempre envía eventsCount en 0', () {
      const model = OrganizationModel(
        id: '',
        name: 'Test',
        city: 'Test',
        department: 'Test',
        address: 'Test',
        latitude: 1,
        longitude: 2,
        eventsCount: 99, // no debería importar, create siempre manda 0
      );

      final json = model.toFirestoreCreate();

      expect(json['eventsCount'], 0);
    });

    test('toFirestoreUpdate no incluye eventsCount (no se edita a mano)', () {
      const model = OrganizationModel(
        id: 'org-1',
        name: 'Test',
        city: 'Test',
        department: 'Test',
        address: 'Test',
        latitude: 1,
        longitude: 2,
      );

      final json = model.toFirestoreUpdate();

      expect(json.containsKey('eventsCount'), false);
    });
  });
}
