import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/monitoring/app_monitoring.dart';
import '../models/organization_model.dart';

class OrganizationFirestoreDatasource {
  OrganizationFirestoreDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('organizations');

  Stream<List<OrganizationModel>> watchAll() {
    return AppMonitoring.traceFirstEvent(
      'organizations_load',
      _collection.orderBy('name').snapshots().map(
            (snapshot) => snapshot.docs
                .map((doc) => OrganizationModel.fromFirestore(doc.data(), doc.id))
                .toList(),
          ),
      itemCount: (organizations) => organizations.length,
    );
  }

  Future<OrganizationModel> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) {
      throw OrganizationNotFoundException();
    }
    return OrganizationModel.fromFirestore(doc.data()!, doc.id);
  }

  Future<OrganizationModel> create(OrganizationModel organization) async {
    final docRef = await _collection.add(organization.toFirestoreCreate());
    return OrganizationModel(
      id: docRef.id,
      name: organization.name,
      city: organization.city,
      department: organization.department,
      address: organization.address,
      latitude: organization.latitude,
      longitude: organization.longitude,
    );
  }

  Future<void> update(OrganizationModel organization) {
    return _collection.doc(organization.id).update(
          organization.toFirestoreUpdate(),
        );
  }

  Future<void> delete(String id) async {
    final eventsSnapshot = await _firestore
        .collection('conferences')
        .where('organizationId', isEqualTo: id)
        .limit(1)
        .get();

    if (eventsSnapshot.docs.isNotEmpty) {
      throw OrganizationHasEventsException();
    }

    await _collection.doc(id).delete();
  }
}

class OrganizationNotFoundException implements Exception {}

class OrganizationHasEventsException implements Exception {}
