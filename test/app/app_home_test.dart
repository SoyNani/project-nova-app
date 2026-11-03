import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/app/screens/home_screen.dart';
import 'package:nova_app/core/theme/app_colors.dart';
import 'package:nova_app/core/theme/app_text_styles.dart';
import 'package:nova_app/features/auth/domain/entities/user_entity.dart';
import 'package:nova_app/features/events/domain/entities/event_entity.dart';
import 'package:nova_app/features/events/presentation/providers/event_providers.dart';
import 'package:nova_app/features/events/presentation/screens/event_detail_screen.dart';

const _user = UserEntity(
  uid: 'uid-1',
  email: 'nani@ejemplo.edu.co',
  displayName: 'Nani',
  role: UserRole.usuario,
);

/// Miércoles 7 de octubre de 2026, 10:00.
final _now = DateTime(2026, 10, 7, 10);

EventEntity _event({
  required String id,
  required String name,
  required DateTime start,
  Duration length = const Duration(hours: 1, minutes: 30),
  String city = 'Bucaramanga',
  String organization = 'Colegio San Pedro Claver',
}) {
  return EventEntity(
    id: id,
    name: name,
    startAt: start,
    endAt: start.add(length),
    organizationId: 'org-$id',
    organizationName: organization,
    city: city,
  );
}

void main() {
  Future<void> pumpHome(
    WidgetTester tester, {
    List<EventEntity> events = const [],
    UserEntity user = _user,
    Size surfaceSize = const Size(390, 844),
  }) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventsListProvider.overrideWith((ref) => Stream.value(events)),
          clockProvider.overrideWith((ref) => Stream.value(_now)),
        ],
        child: MaterialApp(home: HomeScreen(user: user)),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  TextSpan greetingSpan(WidgetTester tester) {
    final richText = tester.widget<RichText>(
      find.byKey(const Key('home-greeting')),
    );
    return richText.text as TextSpan;
  }

  group('HomeScreen — cabecera', () {
    testWidgets('muestra la marca y saluda con el nombre en primaryLight', (
      tester,
    ) async {
      await pumpHome(tester);

      final span = greetingSpan(tester);
      final name = span.children![1] as TextSpan;

      expect(find.text('NOVA APP'), findsOneWidget);
      expect(span.toPlainText(), 'Hola, Nani 👋');
      expect(name.style!.color, AppColors.primaryLight);
      expect(span.style!.color, AppColors.textPrimary);
      expect(span.style!.fontFamily, AppTextStyles.fontFamily);
    });

    testWidgets('usa solo el primer nombre', (tester) async {
      await pumpHome(
        tester,
        user: const UserEntity(
          uid: 'u',
          email: 'e',
          displayName: 'Laura López',
          role: UserRole.usuario,
        ),
      );

      expect(greetingSpan(tester).toPlainText(), 'Hola, Laura 👋');
    });
  });

  group('HomeScreen — evento destacado', () {
    testWidgets('sin eventos invita a crear el primero', (tester) async {
      await pumpHome(tester);

      expect(find.text('Aún no hay eventos'), findsOneWidget);
      expect(find.text('Crear evento'), findsOneWidget);
    });

    testWidgets('un evento en curso dice EN VIVO AHORA', (tester) async {
      await pumpHome(
        tester,
        events: [
          _event(
            id: 'live',
            name: 'Innovación educativa',
            start: _now.subtract(const Duration(minutes: 30)),
          ),
          _event(
            id: 'next',
            name: 'Ciencia de datos',
            start: _now.add(const Duration(days: 1)),
          ),
        ],
      );

      expect(find.text('EN VIVO AHORA'), findsOneWidget);
      expect(find.text('Ver detalle'), findsOneWidget);
      // El título aparece en la tarjeta y en el cronograma.
      expect(find.text('Innovación educativa'), findsNWidgets(2));
    });

    testWidgets('si nada está en curso muestra el próximo POR INICIAR', (
      tester,
    ) async {
      await pumpHome(
        tester,
        events: [
          _event(
            id: 'past',
            name: 'Evento pasado',
            start: _now.subtract(const Duration(days: 2)),
          ),
          _event(
            id: 'next',
            name: 'Liderazgo y trabajo en equipo',
            start: _now.add(const Duration(hours: 3)),
          ),
        ],
      );

      expect(find.text('POR INICIAR'), findsOneWidget);
      expect(find.text('Hoy'), findsOneWidget);
      expect(find.text('Liderazgo y trabajo en equipo'), findsNWidgets(2));
      expect(find.text('Evento pasado'), findsNothing);
    });

    testWidgets('si todos pasaron muestra el último como FINALIZADO', (
      tester,
    ) async {
      await pumpHome(
        tester,
        events: [
          _event(
            id: 'old',
            name: 'Evento antiguo',
            start: _now.subtract(const Duration(days: 5)),
          ),
          _event(
            id: 'last',
            name: 'Emprendimiento social',
            start: _now.subtract(const Duration(days: 1)),
          ),
        ],
      );

      expect(find.text('FINALIZADO'), findsOneWidget);
      expect(find.text('Emprendimiento social'), findsOneWidget);
      expect(
        find.text('No hay eventos próximos en el cronograma.'),
        findsOneWidget,
      );
    });

    testWidgets('Ver detalle abre el detalle del evento', (tester) async {
      await pumpHome(
        tester,
        events: [
          _event(
            id: 'live',
            name: 'Innovación educativa',
            start: _now.subtract(const Duration(minutes: 10)),
          ),
        ],
      );

      await tester.tap(find.text('Ver detalle'));
      await tester.pumpAndSettle();

      expect(find.byType(EventDetailScreen), findsOneWidget);
      expect(find.text('Detalle del evento'), findsOneWidget);
    });
  });

  group('HomeScreen — accesos rápidos', () {
    testWidgets('muestra los módulos; Panel admin solo para admin', (
      tester,
    ) async {
      await pumpHome(tester);

      for (final label in ['Calendario', 'Instituciones', 'Speakers']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('Panel admin'), findsNothing);
    });

    testWidgets('el admin ve el Panel admin', (tester) async {
      await pumpHome(
        tester,
        user: const UserEntity(
          uid: 'a',
          email: 'a',
          displayName: 'Admin',
          role: UserRole.admin,
        ),
      );

      expect(find.text('Panel admin'), findsOneWidget);
    });
  });

  group('HomeScreen — cronograma', () {
    final events = [
      _event(
        id: '1',
        name: 'Innovación educativa',
        start: DateTime(2026, 10, 12, 15),
      ),
      _event(
        id: '2',
        name: 'Ciencia de datos',
        start: DateTime(2026, 10, 12, 17, 30),
        city: 'Floridablanca',
        organization: 'Instituto Técnico Dámaso Zapata',
      ),
      _event(
        id: '3',
        name: 'Emprendimiento social',
        start: DateTime(2026, 10, 16, 14),
      ),
    ];

    testWidgets('agrupa por fecha con día y hora de cada evento', (
      tester,
    ) async {
      await pumpHome(tester, events: events);
      await tester.scrollUntilVisible(
        find.text('Emprendimiento social'),
        200,
        scrollable: _mainScroll,
      );

      expect(find.text('12'), findsOneWidget);
      expect(find.text('LUN'), findsOneWidget);
      expect(find.text('16'), findsOneWidget);
      expect(find.text('VIE'), findsOneWidget);
      expect(find.text('3:00 PM'), findsOneWidget);
      expect(find.text('5:30 PM'), findsOneWidget);
    });

    testWidgets('filtra por ciudad con los chips', (tester) async {
      await pumpHome(tester, events: events);
      await tester.scrollUntilVisible(
        find.text('Floridablanca'),
        200,
        scrollable: _mainScroll,
      );

      expect(find.text('Todas'), findsOneWidget);
      expect(find.text('Bucaramanga'), findsOneWidget);

      await tester.tap(find.text('Floridablanca'));
      await tester.pump();

      expect(find.text('5:30 PM'), findsOneWidget);
      expect(find.text('3:00 PM'), findsNothing);
      expect(find.text('Emprendimiento social'), findsNothing);
    });

    testWidgets('marca EN VIVO en el cronograma el evento en curso', (
      tester,
    ) async {
      await pumpHome(
        tester,
        events: [
          _event(
            id: 'live',
            name: 'Innovación educativa',
            start: _now.subtract(const Duration(minutes: 30)),
          ),
        ],
      );
      await tester.scrollUntilVisible(
        find.text('EN VIVO'),
        200,
        scrollable: _mainScroll,
      );

      expect(find.text('EN VIVO'), findsOneWidget);
    });
  });

  testWidgets('funciona en pantalla ancha', (tester) async {
    await pumpHome(tester, surfaceSize: const Size(1280, 900));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

/// La lista vertical del home (hay otros Scrollable: chips y grid).
final _mainScroll = find
    .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
    .first;
