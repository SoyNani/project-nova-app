import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/features/auth/data/models/user_model.dart';
import 'package:nova_app/features/auth/domain/entities/user_entity.dart';

void main() {
  group('UserModel', () {
    test('fromFirestore mapea role "admin" correctamente', () {
      final json = {
        'email': 'admin@ejemplo.edu.co',
        'displayName': 'Admin Nova',
        'photoUrl': null,
        'role': 'admin',
      };

      final model = UserModel.fromFirestore(json, 'uid-admin');

      expect(model.uid, 'uid-admin');
      expect(model.role, UserRole.admin);
      expect(model.isAdmin, true);
    });

    test('fromFirestore usa "usuario" por defecto si role no es "admin"', () {
      final json = {
        'email': 'user@ejemplo.edu.co',
        'displayName': 'Usuario Nova',
        'role': 'usuario',
      };

      final model = UserModel.fromFirestore(json, 'uid-user');

      expect(model.role, UserRole.usuario);
      expect(model.isAdmin, false);
    });

    test('toFirestore serializa el role como string', () {
      const model = UserModel(
        uid: 'uid-1',
        email: 'nani@ejemplo.edu.co',
        displayName: 'Nani',
        role: UserRole.admin,
      );

      final json = model.toFirestore();

      expect(json['role'], 'admin');
      expect(json['email'], 'nani@ejemplo.edu.co');
      expect(
        json.containsKey('uid'),
        false,
      ); // uid es la key del doc, no un campo
    });
  });
}
