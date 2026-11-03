import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/widgets/atoms/app_search_field.dart';

void main() {
  testWidgets('muestra el hint y el icono de búsqueda', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppSearchField(
            controller: controller,
            hintText: 'Buscar organizaciones',
          ),
        ),
      ),
    );

    expect(find.text('Buscar organizaciones'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('muestra el botón de limpiar y borra el texto al pulsarlo', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'hotel');
    addTearDown(controller.dispose);

    String? changedValue;
    var clearCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppSearchField(
            controller: controller,
            onChanged: (val) => changedValue = val,
            onClear: () => clearCalled = true,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.close), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    expect(controller.text, isEmpty);
    expect(changedValue, '');
    expect(clearCalled, isTrue);
    expect(find.byIcon(Icons.close), findsNothing);
  });
}
