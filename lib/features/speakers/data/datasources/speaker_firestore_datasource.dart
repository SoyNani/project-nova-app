import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/monitoring/app_monitoring.dart';
import '../../../../core/utils/firebase_debug.dart';
import '../models/speaker_event_model.dart';
import '../models/speaker_model.dart';

/// Única capa de speakers que habla con Firestore. Lee de `speakers` y, para los eventos asignados, de `conferences` filtrando por el array `speakerIds`.
class SpeakerFirestoreDatasource {
  SpeakerFirestoreDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _speakers =>
      _firestore.collection('speakers');

  Stream<List<SpeakerModel>> watchAll() {
    return AppMonitoring.traceFirstEvent(
      'speakers_load',
      _speakers.orderBy('name').snapshots().map(
            (snapshot) => snapshot.docs
                .map((doc) => SpeakerModel.fromFirestore(doc.data(), doc.id))
                .toList(),
          ),
      itemCount: (speakers) => speakers.length,
    );
  }

  Future<SpeakerModel> getById(String id) async {
    final doc = await _speakers.doc(id).get();
    if (!doc.exists) {
      throw SpeakerNotFoundException();
    }
    return SpeakerModel.fromFirestore(doc.data()!, doc.id);
  }

  Future<SpeakerModel> create(SpeakerModel speaker) async {
    final docRef = await _speakers.add(speaker.toFirestoreCreate());
    return SpeakerModel(
      id: docRef.id,
      name: speaker.name,
      profession: speaker.profession,
      specialties: speaker.specialties,
      organizationIds: speaker.organizationIds,
      email: speaker.email,
      instagram: speaker.instagram,
      linkedin: speaker.linkedin,
      tiktok: speaker.tiktok,
    );
  }

  Stream<SpeakerModel?> watchByEmail(String email) {
    return _speakers.where('email', isEqualTo: email).limit(1).snapshots().map(
      (snapshot) {
        if (snapshot.docs.isEmpty) return null;
        final doc = snapshot.docs.first;
        return SpeakerModel.fromFirestore(doc.data(), doc.id);
      },
    );
  }

  Future<SpeakerModel> update(SpeakerModel speaker) async {
    try {
      await _speakers.doc(speaker.id).update(speaker.toFirestore());
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') throw SpeakerNotFoundException();
      rethrow;
    }
    return speaker;
  }

  Stream<List<SpeakerEventModel>> watchEvents(String speakerId) {
    return _firestore
        .collection('conferences')
        .where('speakerIds', arrayContains: speakerId)
        .snapshots()
        .map((snapshot) {
      final events = snapshot.docs
          // Los eventos cancelados no cuentan como asignados.
          .where((doc) => doc.data()['status'] != 'cancelled')
          .map((doc) => SpeakerEventModel.fromFirestore(doc.data(), doc.id))
          .toList()
        ..sort((a, b) {
          final left = a.date;
          final right = b.date;
          if (left == null) return 1;
          if (right == null) return -1;
          return left.compareTo(right);
        });
      FirebaseDebug.log(
        'Speaker $speakerId → ${events.length} evento(s) asignado(s)',
      );
      return events;
    });
  }
}

class SpeakerNotFoundException implements Exception {}
