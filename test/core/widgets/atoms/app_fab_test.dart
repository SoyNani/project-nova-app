import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/theme/app_colors.dart';
import 'package:nova_app/core/widgets/atoms/app_fab.dart';

void main() {
  Future<void> pumpFab(WidgetTester tester, {VoidCallback? onPressed}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(floatingActionButton: AppFab(onPressed: onPressed)),
      ),
    );
  }

  testWidgets('muestra solo el ícono "+", sin texto', (tester) async {
    await pumpFab(tester);

    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('usa el gradiente de marca y el ícono en blanco', (tester) async {
    await pumpFab(tester);

    final decorated = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(AppFab),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final box = decorated.decoration as BoxDecoration;

    expect(box.gradient, AppColors.heroGradient);
    expect(
      tester.widget<FloatingActionButton>(find.byType(FloatingActionButton))
          .foregroundColor,
      AppColors.onPrimary,
    );
  });

  testWidgets('dispara el onPressed al tocarlo', (tester) async {
    var taps = 0;
    await pumpFab(tester, onPressed: () => taps++);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    expect(taps, 1);
  });
}
