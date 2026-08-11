import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecturer_attendance/main.dart';

void main() {
  testWidgets('App renders test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LecturerAttendanceApp(),
      ),
    );
    expect(find.byType(LecturerAttendanceApp), findsOneWidget);
  });
}
