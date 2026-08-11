import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecturer_attendance/core/utils/class_list_parser.dart';

void main() {
  group('ClassListParser Tests', () {
    test('Valid CSV parses students correctly', () {
      const csvData = '''Student Name,Matric Number
John Doe,2024/001
Jane Smith,2024/002
Chinedu Okafor,2024/003''';

      final bytes = Uint8List.fromList(csvData.codeUnits);
      final result = ClassListParser.parseFile(
        bytes: bytes,
        fileName: 'classlist.csv',
        courseId: 'course_123',
      );

      expect(result.validCount, equals(3));
      expect(result.hasErrors, isFalse);
      expect(result.validStudents[0].name, equals('John Doe'));
      expect(result.validStudents[0].matricNumber, equals('2024/001'));
    });

    test('Duplicate matric numbers in CSV are detected as errors', () {
      const csvData = '''Student Name,Matric Number
John Doe,2024/001
Jane Smith,2024/001''';

      final bytes = Uint8List.fromList(csvData.codeUnits);
      final result = ClassListParser.parseFile(
        bytes: bytes,
        fileName: 'classlist.csv',
        courseId: 'course_123',
      );

      expect(result.validCount, equals(1));
      expect(result.errorCount, equals(1));
      expect(result.errors[0].issueDescription, contains('Duplicate matric number'));
    });

    test('Missing name or matric number is detected as error', () {
      const csvData = '''Student Name,Matric Number
,2024/001
Jane Smith,''';

      final bytes = Uint8List.fromList(csvData.codeUnits);
      final result = ClassListParser.parseFile(
        bytes: bytes,
        fileName: 'classlist.csv',
        courseId: 'course_123',
      );

      expect(result.validCount, equals(0));
      expect(result.errorCount, equals(2));
    });

    test('PDF stream text extraction parses students correctly', () {
      const pdfMockData = '''
stream
BT
(1. Alex Turner 2024/010) Tj
(2. Beatrice Kiddo 2024/011) Tj
ET
endstream
''';

      final bytes = Uint8List.fromList(pdfMockData.codeUnits);
      final result = ClassListParser.parseFile(
        bytes: bytes,
        fileName: 'classlist.pdf',
        courseId: 'course_123',
      );

      expect(result.validCount, equals(2));
      expect(result.validStudents[0].name, equals('Alex Turner'));
      expect(result.validStudents[0].matricNumber, equals('2024/010'));
      expect(result.validStudents[1].name, equals('Beatrice Kiddo'));
      expect(result.validStudents[1].matricNumber, equals('2024/011'));
    });

    test('DOC text line extraction parses students correctly', () {
      const docMockText = '''
DEPARTMENT OF COMPUTER ENGINEERING
1. Emeka Nnamdi ENG/20/001
2. Fatima Bello ENG/20/002
''';

      final bytes = Uint8List.fromList(docMockText.codeUnits);
      final result = ClassListParser.parseFile(
        bytes: bytes,
        fileName: 'classlist.doc',
        courseId: 'course_123',
      );

      expect(result.validCount, equals(2));
      expect(result.validStudents[0].name, equals('Emeka Nnamdi'));
      expect(result.validStudents[0].matricNumber, equals('ENG/20/001'));
      expect(result.validStudents[1].name, equals('Fatima Bello'));
      expect(result.validStudents[1].matricNumber, equals('ENG/20/002'));
    });
  });
}
