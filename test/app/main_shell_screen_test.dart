import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/app/main_shell_screen.dart';
import 'package:nova_app/app/screens/home_screen.dart';
import 'package:nova_app/core/widgets/atoms/app_page_title.dart';
import 'package:nova_app/core/widgets/molecules/app_nav_item.dart';
import 'package:nova_app/core/widgets/organisms/app_bottom_nav.dart';
import 'package:nova_app/features/auth/domain/entities/user_entity.dart';
import 'package:nova_app/features/auth/presentation/screens/profile_screen.dart';
import 'package:nova_app/features/calendar/presentation/screens/conferences_calendar_screen.dart';
import 'package:nova_app/features/events/domain/entities/event_entity.dart';
import 'package:nova_app/features/events/presentation/providers/event_providers.dart';
import 'package:nova_app/features/organizations/domain/entities/organization_entity.dart';
import 'package:nova_app/features/organizations/presentation/providers/organization_providers.dart';

const _user = UserEntity(
  uid: 'uid-1',
  email: 'nara@ejemplo.edu.co',
  displayName: 'Nara',
  role: UserRole.usuario,
);

void main() {
  Future<void> pumpShell(
    WidgetTester tester, {
    required Size surfaceSize,
  }) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventsListProvider.overrideWith(
            (ref) => Stream.value(const <EventEntity>[]),
          ),
          organizationsListProvider.overrideWith(
            (ref) => Stream.value(const <OrganizationEntity>[]),
          ),
          clockProvider.overrideWith(
            (ref) => Stream.value(DateTime(2026, 10, 7)),
          ),
        ],
        child: const MaterialApp(home: MainShellScreen(user: _user)),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  /// Ícono dentro del menú flotante (los accesos rápidos del home
  /// repiten algunos íconos).
  Finder navIcon(IconData icon) => find.descendant(
    of: find.byType(AppBottomNav),
    matching: find.byIcon(icon),
  );

  testWidgets('arranca en Inicio con el home del usuario', (tester) async {
    await pumpShell(tester, surfaceSize: const Size(390, 844));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Hola, Nara 👋', findRichText: true), findsOneWidget);
    expect(find.byType(AppBottomNav), findsOneWidget);
  });

  testWidgets('el menú flotante ofrece los 3 módulos y el perfil', (
    tester,
  ) async {
    await pumpShell(tester, surfaceSize: const Size(390, 844));

    expect(navIcon(Icons.home_outlined), findsOneWidget);
    expect(navIcon(Icons.calendar_today_outlined), findsOneWidget);
    expect(navIcon(Icons.location_on_outlined), findsOneWidget);
    expect(navIcon(Icons.image_outlined), findsNothing);
    expect(navIcon(Icons.person_outline), findsOneWidget);
  });

  testWidgets('el mapa va al centro y el degradado sigue a la pestaña activa', (
    tester,
  ) async {
    await pumpShell(tester, surfaceSize: const Size(390, 844));

    List<AppNavItem> items() =>
        tester.widgetList<AppNavItem>(find.byType(AppNavItem)).toList();

    expect(items()[2].label, 'Mapa');
    expect(items()[0].isActive, isTrue);
    expect(items().where((item) => item.isActive), hasLength(1));

    await tester.tap(navIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    expect(items().last.isActive, isTrue);
    expect(items()[2].isActive, isFalse);
    expect(items().where((item) => item.isActive), hasLength(1));
  });

  testWidgets('el ícono de perfil va a la derecha del de mapa', (tester) async {
    await pumpShell(tester, surfaceSize: const Size(390, 844));

    final mapX = tester.getCenter(navIcon(Icons.location_on_outlined)).dx;
    final profileX = tester.getCenter(navIcon(Icons.person_outline)).dx;

    expect(profileX, greaterThan(mapX));
  });

  testWidgets('cambia de módulo al tocar cada destino', (tester) async {
    await pumpShell(tester, surfaceSize: const Size(390, 844));

    await tester.tap(navIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(ConferencesCalendarScreen), findsOneWidget);
    expect(find.text('Conferencias'), findsOneWidget);

    await tester.tap(navIcon(Icons.location_on_outlined));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppPageTitle, 'Mapa'), findsOneWidget);

    await tester.tap(navIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Hola, Nara 👋', findRichText: true), findsOneWidget);
  });

  testWidgets('el acceso rápido de Mapa cambia a la pestaña del mapa', (
    tester,
  ) async {
    await pumpShell(tester, surfaceSize: const Size(390, 844));

    await tester.tap(
      find.descendant(of: find.byType(HomeScreen), matching: find.text('Mapa')),
    );
    await tester.pumpAndSettle();

    final nav = tester.widget<AppBottomNav>(find.byType(AppBottomNav));
    expect(nav.currentIndex, 2);
  });

  testWidgets('el home conserva padding inferior para la barra flotante', (
    tester,
  ) async {
    await pumpShell(tester, surfaceSize: const Size(390, 844));

    final list = tester.widget<ListView>(find.byType(ListView).first);
    final padding = list.padding as EdgeInsets;

    expect(padding.bottom, greaterThanOrEqualTo(100));
  });

  testWidgets(
    'el perfil se abre desde el menú y no está el logout en el home',
    (tester) async {
      await pumpShell(tester, surfaceSize: const Size(390, 844));

      expect(find.byType(ProfileScreen), findsNothing);
      expect(find.byIcon(Icons.logout), findsNothing);

      await tester.tap(navIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
    },
  );

  testWidgets('funciona en pantalla ancha', (tester) async {
    await pumpShell(tester, surfaceSize: const Size(1280, 900));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
