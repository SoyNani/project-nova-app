import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/monitoring/app_monitoring.dart';
import '../../../../core/utils/firebase_debug.dart';
import '../models/event_model.dart';

/// Única capa de eventos que habla con Firestore (colección `conferences`).
class EventFirestoreDatasource {
  EventFirestoreDatasource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _events =>
      _firestore.collection('conferences');

  Stream<List<EventModel>> watchAll() {
    final events = _events.orderBy('date').snapshots().map((snapshot) {
      final events = snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc.data(), doc.id))
          .toList();
      FirebaseDebug.log('Eventos → ${events.length} en conferences');
      return events;
    });
    return AppMonitoring.traceFirstEvent(
      'events_load',
      events,
      itemCount: (events) => events.length,
    );
  }

  /// Crea el evento y, en la misma escritura atómica, suma 1 al contador
  /// `eventsCount` de la organización.
  Future<EventModel> create(EventModel event) async {
    final docRef = _events.doc();
    final batch = _firestore.batch()
      ..set(docRef, event.toFirestoreCreate())
      ..update(
        _firestore.collection('organizations').doc(event.organizationId),
        {'eventsCount': FieldValue.increment(1)},
      );
    await AppMonitoring.trace('event_create', batch.commit);
    FirebaseDebug.log('Evento creado → ${docRef.id}');
    return event.copyWithId(docRef.id);
  }

  /// Cancela o restaura el evento. El contador `eventsCount` de la
  /// organización refleja solo los eventos activos, así que se ajusta en
  /// la misma escritura atómica.
  Future<void> setCancelled(EventModel event, {required bool cancelled}) {
    final batch = _firestore.batch()
      ..update(_events.doc(event.id), {
        'status': cancelled
            ? EventModel.statusCancelled
            : EventModel.statusScheduled,
        'cancelledAt': cancelled ? FieldValue.serverTimestamp() : null,
      });
    if (event.organizationId.isNotEmpty) {
      batch.update(
        _firestore.collection('organizations').doc(event.organizationId),
        {'eventsCount': FieldValue.increment(cancelled ? -1 : 1)},
      );
    }
    FirebaseDebug.log(
      'Evento ${event.id} → ${cancelled ? 'cancelado' : 'restaurado'}',
    );
    return AppMonitoring.trace(
      cancelled ? 'event_cancel' : 'event_restore',
      batch.commit,
    );
  }
}
