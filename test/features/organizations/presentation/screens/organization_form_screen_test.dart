import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_app/features/organizations/domain/entities/organization_entity.dart';
import 'package:nova_app/features/organizations/domain/repositories/organization_repository.dart';
import 'package:nova_app/features/organizations/domain/usecases/create_organization.dart';
import 'package:nova_app/features/organizations/domain/usecases/update_organization.dart';
import 'package:nova_app/features/organizations/presentation/providers/organization_providers.dart';
import 'package:nova_app/features/organizations/presentation/screens/organization_form_screen.dart';

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

void main() {
  late _MockOrganizationRepository repository;

  setUpAll(() {
    registerFallbackValue(
      const OrganizationEntity(
        id: '',
        name: '',
        city: '',
        department: '',
        address: '',
        latitude: 0,
        longitude: 0,
      ),
    );
  });

  setUp(() {
    repository = _MockOrganizationRepository();
  });

  Future<void> pumpForm(
    WidgetTester tester, {
    required Size surfaceSize,
    OrganizationEntity? existing,
  }) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          createOrganizationProvider.overrideWithValue(
            CreateOrganization(repository),
          ),
          updateOrganizationProvider.overrideWithValue(
            UpdateOrganization(repository),
          ),
        ],
        child: MaterialApp(home: OrganizationFormScreen(existing: existing)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'renderiza campos de departamento y ciudad en pantalla angosta y ancha',
    (tester) async {
      await pumpForm(tester, surfaceSize: const Size(400, 800));

      expect(find.text('DEPARTAMENTO'), findsOneWidget);
      expect(find.text('CIUDAD'), findsOneWidget);
      expect(find.text('NOMBRE DE LA ORGANIZACIÓN'), findsOneWidget);
      expect(find.text('DIRECCIÓN'), findsOneWidget);
    },
  );

  testWidgets('renderiza correctamente en pantalla ancha', (tester) async {
    await pumpForm(tester, surfaceSize: const Size(1200, 900));

    expect(find.text('DEPARTAMENTO'), findsOneWidget);
    expect(find.text('CIUDAD'), findsOneWidget);
  });
}
