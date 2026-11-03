import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nova_app/features/organizations/presentation/widgets/organization_location_picker.dart';

void main() {
  Future<void> pumpPicker(
    WidgetTester tester, {
    required ValueChanged<LatLng> onLocationChanged,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrganizationLocationPicker(
            position: const LatLng(7.1193, -73.1227),
            onLocationChanged: onLocationChanged,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renderiza el mapa con el marcador y el botón de recentrado', (
    tester,
  ) async {
    await pumpPicker(tester, onLocationChanged: (_) {});

    expect(find.byType(GoogleMap), findsOneWidget);
    expect(find.byIcon(Icons.my_location), findsOneWidget);
    expect(find.text('Toca o arrastra el pin para ajustar'), findsOneWidget);
  });

  testWidgets('notifica la nueva posición al tocar el mapa', (tester) async {
    LatLng? reportedPosition;
    await pumpPicker(
      tester,
      onLocationChanged: (position) => reportedPosition = position,
    );

    final mapWidget = tester.widget<GoogleMap>(find.byType(GoogleMap));
    mapWidget.onTap?.call(const LatLng(4.6097, -74.0817));
    await tester.pump();

    expect(reportedPosition, const LatLng(4.6097, -74.0817));
  });
}
