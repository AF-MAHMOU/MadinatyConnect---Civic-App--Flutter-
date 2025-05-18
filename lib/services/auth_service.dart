import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AppUser?> login(String email, String password) async {
    UserCredential userCred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userCred.user!.uid).get();

    return AppUser.fromMap(userDoc.data() as Map<String, dynamic>, userDoc.id);
  }

  Future<AppUser?> signup(String name, String email, String password, String role) async {
    UserCredential userCred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _firestore.collection('users').doc(userCred.user!.uid).set({
      'name': name,
      'email': email,
      'role': role,
    });

    return AppUser(
      uid: userCred.user!.uid,
      name: name,
      email: email,
      role: role,
    );
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> updateUserRole(String uid, String newRole) async {
    await _firestore.collection('users').doc(uid).update({'role': newRole});
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
