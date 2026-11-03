import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/monitoring/app_monitoring.dart';
import '../../../../core/utils/firebase_debug.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';

class FirebaseAuthDatasource {
  FirebaseAuthDatasource({
    fb.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final fb.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;
  bool _googleSignInInitialized = false;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    await _googleSignIn.initialize();
    _googleSignInInitialized = true;
  }

  /// Lanza [GoogleSignInCancelledException] si el usuario cierra el
  /// picker de cuentas de Google sin elegir ninguna.
  Future<UserModel> signInWithGoogle() =>
      AppMonitoring.trace('login_google', _signInWithGoogle);

  Future<UserModel> _signInWithGoogle() async {
    await _ensureGoogleSignInInitialized();

    late final GoogleSignInAccount googleUser;
    try {
      FirebaseDebug.step('Solicitando credenciales a Google...');
      googleUser = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (error, stackTrace) {
      FirebaseDebug.log('GoogleSignInException code: ${error.code}');
      if (error.code == GoogleSignInExceptionCode.canceled ||
          error.code == GoogleSignInExceptionCode.interrupted) {
        FirebaseDebug.step('Login cancelado por el usuario');
        throw GoogleSignInCancelledException();
      }
      FirebaseDebug.error('Falló Google SignIn', error, stackTrace);
      rethrow;
    }

    final googleAuth = googleUser.authentication;
    FirebaseDebug.data('Respuesta de Google', {
      'uid': googleUser.id,
      'email': googleUser.email,
      'displayName': googleUser.displayName,
      'photoUrl': googleUser.photoUrl,
      'idToken (parcial)': _preview(googleAuth.idToken),
    });

    if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
      FirebaseDebug.log('Sin idToken: se trata como cancelación');
      throw GoogleSignInCancelledException();
    }

    final credential = fb.GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    FirebaseDebug.step('Canjeando idToken por sesión de Firebase Auth...');
    final fb.UserCredential userCredential;
    try {
      userCredential = await _firebaseAuth.signInWithCredential(credential);
    } catch (error, stackTrace) {
      FirebaseDebug.error('Firebase Auth rechazó la credencial', error, stackTrace);
      rethrow;
    }

    final fbUser = userCredential.user!;
    await _debugDumpFirebaseUser(fbUser);

    final model = await _syncUserDocument(fbUser);
    FirebaseDebug.data('Rol resuelto por la app', {
      'uid': model.uid,
      'email': model.email,
      'displayName': model.displayName,
      'role': model.role.name,
      'isAdmin': model.isAdmin,
    });
    FirebaseDebug.log('SIGN IN WITH GOOGLE · correcto');
    return model;
  }

  Future<void> _debugDumpFirebaseUser(fb.User fbUser) async {
    FirebaseDebug.section('FIREBASE AUTH · respuesta');
    FirebaseDebug.data('User', {
      'uid': fbUser.uid,
      'email': fbUser.email,
      'displayName': fbUser.displayName,
      'photoURL': fbUser.photoURL,
      'phoneNumber': fbUser.phoneNumber,
      'isAnonymous': fbUser.isAnonymous,
      'emailVerified': fbUser.emailVerified,
      'providerData': fbUser.providerData
          .map((p) => {
                'providerId': p.providerId,
                'uid': p.uid,
                'email': p.email,
                'displayName': p.displayName,
              })
          .toList(),
      'metadata': {
        'creationTime': fbUser.metadata.creationTime?.toIso8601String(),
        'lastSignInTime': fbUser.metadata.lastSignInTime?.toIso8601String(),
      },
    });

    try {
      final tokenResult = await fbUser.getIdTokenResult();
      FirebaseDebug.data('ID token (claims / permisos)', tokenResult.claims);
      final payload = FirebaseDebug.decodeJwtPayload(tokenResult.token);
      FirebaseDebug.data('ID token (payload decodificado)', payload);
    } catch (error, stackTrace) {
      FirebaseDebug.error('No se pudieron leer los claims', error, stackTrace);
    }
  }

  static String _preview(String? token) {
    if (token == null || token.isEmpty) return '(vacío)';
    return token.length <= 24 ? token : '${token.substring(0, 24)}…';
  }

  /// Crea el documento `users/{uid}` la primera vez (rol por defecto
  /// "usuario" — la promoción a admin la hace otro admin desde el
  /// panel, nunca el propio usuario).
  Future<UserModel> _syncUserDocument(fb.User fbUser) async {
    final docRef = _firestore.collection('users').doc(fbUser.uid);
    FirebaseDebug.step('Leyendo users/${fbUser.uid} en Firestore...');

    final snapshot = await docRef.get();
    FirebaseDebug.data('Firestore users/${fbUser.uid}', {
      'exists': snapshot.exists,
      'data': snapshot.data(),
    });

    if (!snapshot.exists) {
      final newUser = UserModel(
        uid: fbUser.uid,
        email: fbUser.email ?? '',
        displayName: fbUser.displayName ?? '',
        photoUrl: fbUser.photoURL,
        role: UserRole.usuario,
      );
      await docRef.set(newUser.toFirestore());
      FirebaseDebug.step('Documento creado con role=usuario (sin permisos aún)');
      return newUser;
    }

    return UserModel.fromFirestore(snapshot.data()!, fbUser.uid);
  }

  Future<void> signOut() async {
    FirebaseDebug.section('SIGN OUT');
    await _ensureGoogleSignInInitialized();
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
    FirebaseDebug.log('Sesión de Firebase y Google cerradas');
  }

  Stream<UserModel?> authStateChanges() {
    return _firebaseAuth.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) {
        FirebaseDebug.log('authStateChanges → sin usuario');
        return null;
      }
      final doc = await _firestore.collection('users').doc(fbUser.uid).get();
      if (!doc.exists) {
        FirebaseDebug.log('authStateChanges → ${fbUser.uid} sin documento');
        return null;
      }
      final model = UserModel.fromFirestore(doc.data()!, fbUser.uid);
      FirebaseDebug.log(
        'authStateChanges → ${model.uid} · role=${model.role.name}',
      );
      return model;
    });
  }
}

class GoogleSignInCancelledException implements Exception {}
