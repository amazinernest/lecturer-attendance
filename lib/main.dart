import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/supabase_config.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseConfig.initialize();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialisation notice (offline mode active): $e');
  }

  runApp(
    const ProviderScope(
      child: LecturerAttendanceApp(),
    ),
  );
}

class LecturerAttendanceApp extends ConsumerWidget {
  const LecturerAttendanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Lecturer Attendance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
