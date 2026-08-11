import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://loinljaeiqxknnfjaqfd.supabase.co';
  static const String anonKey = 'sb_publishable_-E5fFgUO7vCf69oOJ5TUBg_74kmAKcT';

  /// Initializes Supabase SDK
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: url,
        publishableKey: anonKey,
        debug: kDebugMode,
      );
    } catch (e) {
      debugPrint('Supabase initialisation notice: $e');
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}
