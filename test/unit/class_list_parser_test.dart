import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecturer_attendance/core/utils/class_list_parser.dart';
import 'package:lecturer_attendance/shared/models/student.dart';

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

    test('Parses CSV with multi-row institution headers at the top', () {
      const csvData = '''UNIVERSITY OF BENIN, FACULTY OF PHYSICAL SCIENCES
DEPARTMENT OF COMPUTER SCIENCE
2024/2025 ACADEMIC SESSION - CSC 311 CLASS LIST
S/N,Reg No,Full Name,Department
1,CSC/2021/045,Osahon Osasere,Computer Science
2,CSC/2021/089,Aminu Kabir,Computer Science
3,CSC/2021/112,Grace Bassey,Computer Science''';

      final bytes = Uint8List.fromList(csvData.codeUnits);
      final result = ClassListParser.parseFile(
        bytes: bytes,
        fileName: 'uniben_csc311.csv',
        courseId: 'course_123',
      );

      expect(result.validCount, equals(3));
      expect(result.validStudents[0].matricNumber, equals('CSC/2021/045'));
      expect(result.validStudents[0].name, equals('Osahon Osasere'));
      expect(result.validStudents[1].matricNumber, equals('CSC/2021/089'));
      expect(result.validStudents[2].name, equals('Grace Bassey'));
    });

    test('Parses semicolon-delimited CSV with Matric before Name (inverted)', () {
      const csvData = '''Matric No;Student Name;Level
2021/ENG/012;Okonkwo Chukwudi;300L
2021/ENG/045;Aisha Mohammed;300L''';

      final bytes = Uint8List.fromList(csvData.codeUnits);
      final result = ClassListParser.parseFile(
        bytes: bytes,
        fileName: 'engineering.csv',
        courseId: 'course_123',
      );

      expect(result.validCount, equals(2));
      expect(result.validStudents[0].matricNumber, equals('2021/ENG/012'));
      expect(result.validStudents[0].name, equals('Okonkwo Chukwudi'));
      expect(result.validStudents[1].matricNumber, equals('2021/ENG/045'));
      expect(result.validStudents[1].name, equals('Aisha Mohammed'));
    });

    test('Combines split Surname and First Name / Other names columns', () {
      const csvData = '''S/N,Reg Number,Surname,First Name,Other Names
1,U2021/5570001,ADEBAYO,Samuel,Oluwaseun
2,U2021/5570002,DANJUMA,Fatima,Zainab''';

      final bytes = Uint8List.fromList(csvData.codeUnits);
      final result = ClassListParser.parseFile(
        bytes: bytes,
        fileName: 'split_names.csv',
        courseId: 'course_123',
      );

      expect(result.validCount, equals(2));
      expect(result.validStudents[0].name, equals('ADEBAYO Samuel Oluwaseun'));
      expect(result.validStudents[0].matricNumber, equals('U2021/5570001'));
      expect(result.validStudents[1].name, equals('DANJUMA Fatima Zainab'));
    });

    test('Re-importing updates existing students instead of failing as duplicate', () {
      final existingStudent = Student(
        id: 'existing_id_999',
        courseId: 'course_123',
        name: 'Okafor Emeka (Old Name)',
        matricNumber: '2024/001',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        synced: true,
      );

      const csvData = '''Matric No,Student Name
2024/001,Okafor Emeka Chukwu (Updated)
2024/002,New Student B''';

      final bytes = Uint8List.fromList(csvData.codeUnits);
      final result = ClassListParser.parseFile(
        bytes: bytes,
        fileName: 'updated_roster.csv',
        courseId: 'course_123',
        existingMatricNumbers: ['2024/001'],
        existingStudents: [existingStudent],
      );

      expect(result.validCount, equals(2));
      expect(result.hasErrors, isFalse);
      // Preserved ID so attendance records are kept intact
      expect(result.validStudents[0].id, equals('existing_id_999'));
      expect(result.validStudents[0].name, equals('Okafor Emeka Chukwu (Updated)'));
      expect(result.validStudents[1].name, equals('New Student B'));
    });
  });
}
