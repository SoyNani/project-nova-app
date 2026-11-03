import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/theme/app_colors.dart';
import 'package:nova_app/core/widgets/organisms/app_bottom_nav.dart';

const _destinations = [
  AppNavDestination(
    label: 'Inicio',
    icon: Icons.home_outlined,
    builder: _empty,
  ),
  AppNavDestination(
    label: 'Calendario',
    icon: Icons.calendar_month_outlined,
    builder: _empty,
  ),
  // AppNavDestination(
  //   label: 'Galería',
  //   icon: Icons.photo_library_outlined,
  //   builder: _empty,
  // ),
  AppNavDestination(label: 'Mapa', icon: Icons.map_outlined, builder: _empty),
];

Widget _empty(BuildContext context) => const SizedBox.shrink();

void main() {
  Future<void> pumpNav(
    WidgetTester tester, {
    required int currentIndex,
    required ValueChanged<int> onSelected,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          extendBody: true,
          body: const SizedBox.shrink(),
          bottomNavigationBar: AppBottomNav(
            destinations: _destinations,
            currentIndex: currentIndex,
            onDestinationSelected: onSelected,
          ),
        ),
      ),
    );
  }

  testWidgets('muestra los 4 íconos de los destinos', (tester) async {
    await pumpNav(tester, currentIndex: 0, onSelected: (_) {});

    for (final destination in _destinations) {
      expect(find.byIcon(destination.icon), findsOneWidget);
    }
  });

  testWidgets('la barra usa el fondo 232A6B', (tester) async {
    await pumpNav(tester, currentIndex: 0, onSelected: (_) {});

    final decoration =
        tester.widget<DecoratedBox>(find.byKey(barKey)).decoration
            as BoxDecoration;

    expect(decoration.color, AppColors.navBackground);
    expect(decoration.color, const Color(0xFF232A6B));
  });

  testWidgets('queda pegada al final, 20 px arriba del borde', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await pumpNav(tester, currentIndex: 0, onSelected: (_) {});

    final barRect = tester.getRect(find.byKey(barKey));

    expect(844 - barRect.bottom, 20);
  });

  testWidgets(
    'solo el activo lleva el círculo con degradado y el ícono blanco',
    (tester) async {
      await pumpNav(tester, currentIndex: 2, onSelected: (_) {});

      BoxDecoration tileOf(IconData icon) {
        final container = tester.widget<AnimatedContainer>(
          find
              .ancestor(
                of: find.byIcon(icon),
                matching: find.byType(AnimatedContainer),
              )
              .first,
        );
        return container.decoration as BoxDecoration;
      }

      expect(tileOf(Icons.map_outlined).gradient, AppColors.navCenterGradient);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.map_outlined)).color,
        AppColors.onPrimary,
      );

      expect(tileOf(Icons.home_outlined).gradient, isNull);
      expect(tileOf(Icons.home_outlined).color, AppColors.transparent);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.home_outlined)).color,
        AppColors.navIconInactive,
      );
    },
  );

  testWidgets('el degradado se mueve al destino seleccionado', (
    tester,
  ) async {
    await pumpNav(tester, currentIndex: 0, onSelected: (_) {});

    Gradient? gradientOf(IconData icon) =>
        (tester
                    .widget<AnimatedContainer>(
                      find
                          .ancestor(
                            of: find.byIcon(icon),
                            matching: find.byType(AnimatedContainer),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration)
            .gradient;

    expect(gradientOf(Icons.home_outlined), isNotNull);
    expect(gradientOf(Icons.map_outlined), isNull);
  });

  testWidgets('reporta el índice del destino tocado', (tester) async {
    final tapped = <int>[];
    await pumpNav(tester, currentIndex: 0, onSelected: tapped.add);

    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pumpAndSettle();

    expect(tapped, [2, 1]);
  });

  testWidgets('solo ocupa su propia altura (no tapa la pantalla)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          extendBody: true,
          bottomNavigationBar: AppBottomNav(
            destinations: _destinations,
            currentIndex: 0,
            onDestinationSelected: (_) {},
          ),
        ),
      ),
    );

    final barRect = tester.getRect(find.byKey(barKey));
    expect(barRect.height, lessThan(100));
    expect(barRect.top, greaterThan(700));
  });

  testWidgets('respeta el margen lateral en móvil', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await pumpNav(tester, currentIndex: 0, onSelected: (_) {});

    final barRect = tester.getRect(find.byKey(barKey));

    expect(barRect.left, 50);
    expect(390 - barRect.right, 50);
  });

  testWidgets('no se estira de lado a lado en pantallas anchas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await pumpNav(tester, currentIndex: 0, onSelected: (_) {});

    expect(tester.getRect(find.byKey(barKey)).width, lessThanOrEqualTo(460));
  });
}
