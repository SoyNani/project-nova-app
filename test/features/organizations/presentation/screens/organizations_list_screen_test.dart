import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_app/core/widgets/atoms/app_fab.dart';
import 'package:nova_app/core/widgets/atoms/app_search_field.dart';
import 'package:nova_app/features/organizations/domain/entities/organization_entity.dart';
import 'package:nova_app/features/organizations/domain/entities/organization_failure.dart';
import 'package:nova_app/features/organizations/domain/repositories/organization_repository.dart';
import 'package:nova_app/features/organizations/domain/usecases/create_organization.dart';
import 'package:nova_app/features/organizations/domain/usecases/delete_organization.dart';
import 'package:nova_app/features/organizations/domain/usecases/update_organization.dart';
import 'package:nova_app/features/organizations/domain/usecases/watch_organizations.dart';
import 'package:nova_app/features/organizations/presentation/providers/organization_providers.dart';
import 'package:nova_app/features/organizations/presentation/screens/organization_form_screen.dart';
import 'package:nova_app/features/organizations/presentation/screens/organizations_list_screen.dart';

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

const _organizations = [
  OrganizationEntity(
    id: 'org-1',
    name: 'Hotel Bari Central',
    city: 'Bucaramanga',
    department: 'Santander',
    address: 'Cra 27 # 45-12',
    latitude: 7.1,
    longitude: -73.1,
    eventsCount: 3,
  ),
  OrganizationEntity(
    id: 'org-2',
    name: 'NEOMUNDO',
    city: 'Bucaramanga',
    department: 'Santander',
    address: 'Calle 56 # 10-00',
    latitude: 7.2,
    longitude: -73.2,
    eventsCount: 5,
  ),
];

void main() {
  late _MockOrganizationRepository repository;

  setUp(() {
    repository = _MockOrganizationRepository();
    when(
      () => repository.watchAll(),
    ).thenAnswer((_) => Stream.value(_organizations));
    when(() => repository.delete(any())).thenAnswer((_) async => right(null));
  });

  Future<void> pumpList(
    WidgetTester tester, {
    required Size surfaceSize,
  }) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          watchOrganizationsProvider.overrideWithValue(
            WatchOrganizations(repository),
          ),
          deleteOrganizationProvider.overrideWithValue(
            DeleteOrganization(repository),
          ),
          createOrganizationProvider.overrideWithValue(
            CreateOrganization(repository),
          ),
          updateOrganizationProvider.overrideWithValue(
            UpdateOrganization(repository),
          ),
        ],
        child: const MaterialApp(home: OrganizationsListScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('OrganizationsListScreen — contenido', () {
    testWidgets(
      'muestra el buscador y las cards de organizaciones con sus iniciales',
      (tester) async {
        await pumpList(tester, surfaceSize: const Size(400, 800));

        expect(find.byType(AppSearchField), findsOneWidget);
        expect(find.text('Hotel Bari Central'), findsOneWidget);
        expect(find.text('HB'), findsOneWidget);
        expect(find.text('NEOMUNDO'), findsOneWidget);
        expect(find.text('NE'), findsOneWidget);
      },
    );

    testWidgets('filtra por nombre mientras se escribe en el buscador', (
      tester,
    ) async {
      await pumpList(tester, surfaceSize: const Size(400, 800));

      await tester.enterText(find.byType(TextFormField), 'neomundo');
      await tester.pumpAndSettle();

      expect(find.text('NEOMUNDO'), findsOneWidget);
      expect(find.text('Hotel Bari Central'), findsNothing);
    });

    testWidgets(
      'muestra mensaje vacío cuando la búsqueda no tiene resultados',
      (tester) async {
        await pumpList(tester, surfaceSize: const Size(400, 800));

        await tester.enterText(find.byType(TextFormField), 'inexistente');
        await tester.pumpAndSettle();

        expect(
          find.text('No hay organizaciones que coincidan con la búsqueda.'),
          findsOneWidget,
        );
      },
    );
  });

  group('OrganizationsListScreen — flujo principal', () {
    testWidgets('el botón flotante abre el formulario de creación', (
      tester,
    ) async {
      await pumpList(tester, surfaceSize: const Size(400, 800));

      await tester.tap(find.byType(AppFab));
      await tester.pumpAndSettle();

      expect(find.byType(OrganizationFormScreen), findsOneWidget);
      expect(find.text('Nueva organización'), findsOneWidget);
    });

    testWidgets('confirmar eliminación llama al repositorio', (tester) async {
      await pumpList(tester, surfaceSize: const Size(400, 800));

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      expect(find.text('Eliminar organización'), findsOneWidget);

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      verify(() => repository.delete('org-1')).called(1);
    });
  });

  group('OrganizationsListScreen — errores visibles', () {
    testWidgets('muestra el error si el stream de organizaciones falla', (
      tester,
    ) async {
      when(() => repository.watchAll()).thenAnswer(
        (_) => Stream.error(OrganizationUnknownError('firestore caído')),
      );

      await pumpList(tester, surfaceSize: const Size(400, 800));

      expect(find.textContaining('firestore caído'), findsOneWidget);
    });
  });

  group('OrganizationsListScreen — responsive', () {
    testWidgets('en pantalla angosta usa ListView', (tester) async {
      await pumpList(tester, surfaceSize: const Size(400, 800));

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(GridView), findsNothing);
    });

    testWidgets('en pantalla ancha usa GridView', (tester) async {
      await pumpList(tester, surfaceSize: const Size(1200, 900));

      expect(find.byType(GridView), findsOneWidget);
    });
  });
}
