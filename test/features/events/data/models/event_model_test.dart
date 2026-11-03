import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/features/events/data/models/event_model.dart';

void main() {
  final start = DateTime(2026, 10, 12, 15);
  final end = DateTime(2026, 10, 12, 16, 30);

  test('lee las fechas guardadas como Timestamp', () {
    final model = EventModel.fromFirestore({
      'name': 'Innovación educativa',
      'date': Timestamp.fromDate(start),
      'endDate': Timestamp.fromDate(end),
      'organizationId': 'org-1',
      'organizationName': 'Colegio San Pedro Claver',
      'city': 'Bucaramanga',
      'speakerIds': ['sp-1'],
      'speakerNames': ['Laura'],
    }, 'ev-1');

    expect(model.id, 'ev-1');
    expect(model.startAt, start);
    expect(model.endAt, end);
    expect(model.speakerNames, ['Laura']);
  });

  test('sin endDate usa el inicio para no romper documentos viejos', () {
    final model = EventModel.fromFirestore({
      'name': 'Evento',
      'date': start.toIso8601String(),
    }, 'ev-2');

    expect(model.endAt, model.startAt);
    expect(model.organizationId, isEmpty);
  });

  test('escribe date/endDate como Timestamp y speakerIds para speakers', () {
    final json = EventModel(
      id: 'ev-1',
      name: 'Evento',
      startAt: start,
      endAt: end,
      organizationId: 'org-1',
      speakerIds: const ['sp-1'],
      speakerNames: const ['Laura'],
    ).toFirestore();

    expect(json['date'], Timestamp.fromDate(start));
    expect(json['endDate'], Timestamp.fromDate(end));
    expect(json['speakerIds'], ['sp-1']);
    expect(json['organizationId'], 'org-1');
    expect(json['status'], 'scheduled');
  });

  test('lee el estado cancelado y la fecha de cancelación', () {
    final cancelledAt = DateTime(2026, 10, 8, 9);
    final model = EventModel.fromFirestore({
      'name': 'Evento',
      'date': Timestamp.fromDate(start),
      'status': 'cancelled',
      'cancelledAt': Timestamp.fromDate(cancelledAt),
    }, 'ev-3');

    expect(model.isCancelled, isTrue);
    expect(model.cancelledAt, cancelledAt);
  });

  test('documentos sin status cuentan como activos', () {
    final model = EventModel.fromFirestore({
      'name': 'Evento',
      'date': Timestamp.fromDate(start),
    }, 'ev-4');

    expect(model.isCancelled, isFalse);
  });
}
