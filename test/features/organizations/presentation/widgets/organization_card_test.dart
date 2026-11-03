import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/features/organizations/domain/entities/organization_entity.dart';
import 'package:nova_app/features/organizations/presentation/widgets/organization_avatar.dart';
import 'package:nova_app/features/organizations/presentation/widgets/organization_card.dart';

void main() {
  const organization = OrganizationEntity(
    id: 'org-1',
    name: 'Hotel Bari Central',
    city: 'Bucaramanga',
    department: 'Santander',
    address: 'Cra 27 # 45-12',
    latitude: 7.1,
    longitude: -73.1,
    eventsCount: 4,
  );

  testWidgets(
    'renderiza nombre, iniciales, ciudad/departamento, eventos y botones compactos',
    (tester) async {
      var editCalled = false;
      var deleteCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrganizationCard(
              organization: organization,
              onTap: () {},
              onEdit: () => editCalled = true,
              onDelete: () => deleteCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('Hotel Bari Central'), findsOneWidget);
      expect(find.text('HB'), findsOneWidget);
      expect(find.byType(OrganizationAvatar), findsOneWidget);
      expect(find.text('Bucaramanga, Santander'), findsOneWidget);
      expect(find.text('4 eventos'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      expect(editCalled, isTrue);

      await tester.tap(find.byIcon(Icons.delete_outline));
      expect(deleteCalled, isTrue);
    },
  );
}
