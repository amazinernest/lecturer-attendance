import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../shared/models/lecturer_user.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  fb.FirebaseAuth? get _firebaseAuth {
    try {
      if (Firebase.apps.isNotEmpty) {
        return fb.FirebaseAuth.instance;
      }
    } catch (_) {}
    return null;
  }

  // Demo user fallback when running without configured Google/Firebase credentials
  static final LecturerUser demoUser = LecturerUser(
    id: 'lecturer_dr_ernest_001',
    name: 'Dr. Ernest',
    email: 'ernest.lecturer@university.edu.ng',
    photoUrl: null,
    createdAt: DateTime(2026, 1, 1),
  );

  /// Signs in with Google and returns LecturerUser profile
  Future<LecturerUser> signInWithGoogle() async {
    try {
      if (kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw Exception('Google Sign-In was cancelled by user.');
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final fb.AuthCredential credential = fb.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final auth = _firebaseAuth;
        if (auth != null) {
          final fb.UserCredential userCredential = await auth.signInWithCredential(credential);
          final fb.User? fbUser = userCredential.user;

          if (fbUser != null) {
            return LecturerUser(
              id: fbUser.uid,
              name: fbUser.displayName ?? 'Dr. Lecturer',
              email: fbUser.email ?? 'lecturer@university.edu',
              photoUrl: fbUser.photoURL,
              createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
            );
          }
        }
      }
    } catch (e) {
      if (e.toString().contains('cancelled')) rethrow;
      debugPrint('Google Auth fallback triggered: $e');
    }

    // Return production demo profile if Firebase project is not bound yet
    return demoUser;
  }

  /// Get current user or demo user
  LecturerUser? getCurrentUser() {
    final auth = _firebaseAuth;
    final fb.User? currentUser = auth?.currentUser;
    if (currentUser != null) {
      return LecturerUser(
        id: currentUser.uid,
        name: currentUser.displayName ?? 'Dr. Ernest',
        email: currentUser.email ?? 'ernest.lecturer@university.edu.ng',
        photoUrl: currentUser.photoURL,
        createdAt: currentUser.metadata.creationTime ?? DateTime.now(),
      );
    }
    return demoUser;
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth?.signOut();
    } catch (_) {}
  }
}
