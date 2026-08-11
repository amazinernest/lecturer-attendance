import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/lecturer_user.dart';

class AuthService {

  SupabaseClient? get _supabaseClient {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // Demo user fallback when running in offline demo mode
  static final LecturerUser demoUser = LecturerUser(
    id: 'lecturer_dr_ernest_001',
    name: 'Dr. Ernest',
    email: 'ernest.lecturer@university.edu.ng',
    photoUrl: null,
    createdAt: DateTime(2026, 1, 1),
  );

  /// Auth state changes stream from Supabase
  Stream<AuthState>? get authStateChanges => _supabaseClient?.auth.onAuthStateChange;

  /// Register new user with email & password via Supabase
  Future<AuthResponse> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final client = _supabaseClient;
    if (client == null) {
      throw Exception('Supabase service is not initialized.');
    }

    final response = await client.auth.signUp(
      email: email.trim(),
      password: password.trim(),
      data: {
        'full_name': fullName.trim(),
        'name': fullName.trim(),
      },
      emailRedirectTo: kIsWeb ? null : 'io.supabase.lecturerattendance://login-callback',
    );

    return response;
  }

  /// Resends email confirmation link
  Future<void> resendConfirmationEmail(String email) async {
    final client = _supabaseClient;
    if (client == null) {
      throw Exception('Supabase service is not initialized.');
    }

    await client.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
      emailRedirectTo: kIsWeb ? null : 'io.supabase.lecturerattendance://login-callback',
    );
  }

  /// Sign in existing user with email & password via Supabase
  Future<LecturerUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final client = _supabaseClient;
    if (client == null) {
      throw Exception('Supabase service is not initialized.');
    }

    final response = await client.auth.signInWithPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Sign in failed. Please check your credentials.');
    }

    return _mapSupabaseUserToLecturerUser(user);
  }

  /// Send password reset link to user email via Supabase
  Future<void> sendPasswordReset(String email) async {
    final client = _supabaseClient;
    if (client == null) {
      throw Exception('Supabase service is not initialized.');
    }

    await client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: kIsWeb ? null : 'io.supabase.lecturerattendance://reset-callback/',
    );
  }

  /// Get current authenticated user
  LecturerUser? getCurrentUser() {
    final client = _supabaseClient;
    final User? currentUser = client?.auth.currentUser;
    if (currentUser != null) {
      return _mapSupabaseUserToLecturerUser(currentUser);
    }
    return null;
  }

  /// Maps Supabase User object to domain LecturerUser profile
  LecturerUser _mapSupabaseUserToLecturerUser(User user) {
    final metaName = user.userMetadata?['full_name'] ?? user.userMetadata?['name'];
    return LecturerUser(
      id: user.id,
      name: metaName as String? ?? user.email?.split('@').first ?? 'Dr. Lecturer',
      email: user.email ?? '',
      photoUrl: user.userMetadata?['avatar_url'] as String?,
      createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
    );
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _supabaseClient?.auth.signOut();
    } catch (_) {}
  }
}
