import 'package:uuid/uuid.dart';
import '../../shared/models/course.dart';
import '../../shared/models/student.dart';
import '../../shared/models/attendance_session.dart';
import '../../shared/models/attendance_record.dart';
import '../../data/database/app_database.dart';

class SampleDataSeeder {
  SampleDataSeeder._();

  static const _uuid = Uuid();

  static Future<void> seedIfEmpty(AppDatabase db, String lecturerId) async {
    final existingCourses = await db.getCoursesForLecturer(lecturerId);
    if (existingCourses.isNotEmpty) return;

    final now = DateTime.now();
    final courseId = _uuid.v4();

    final sampleCourse = Course(
      id: courseId,
      lecturerId: lecturerId,
      courseCode: 'GCE 202',
      courseTitle: 'Adolescence Psychology and Teenage Counselling',
      department: 'Educational Foundations',
      level: '200 Level',
      semester: 'First Semester',
      academicSession: '2026/2027',
      expectedClasses: 15,
      status: CourseStatus.active,
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
      synced: true,
    );

    await db.upsertCourse(sampleCourse);

    // Seed 42 Realistic Nigerian University Students
    final sampleStudentNames = [
      'Adebowale Babatunde', 'Adewale Blessing', 'Aina Oluwaseun', 'Akanbi Chinedu',
      'Akpan Emmanuel', 'Amaechi Grace', 'Bello Farouk', 'Chukwu Ifeanyi',
      'Dada Ayomide', 'Eze Precious', 'Ibrahim Zainab', 'Igwe Chukwudi',
      'Jimoh Aminat', 'Kalu Victor', 'Mustapha Halima', 'Nnaji Promise',
      'Nwachukwu Kevin', 'Obi Chioma', 'Odeh Sunday', 'Ogunleye Femi',
      'Okafor David', 'Okeke Mary', 'Okoro Samuel', 'Oladipo Kehinde',
      'Olanrewaju Taiwo', 'Olorunfemi Daniel', 'Omah Stanley', 'Oni Rebecca',
      'Orakpo Miracle', 'Osei Michael', 'Salami Ruth', 'Suleiman Yusuf',
      'Taiwo Gabriel', 'Ubah Angela', 'Uche Jessica', 'Umar Abubakar',
      'Usman Fatima', 'Utomi Christopher', 'Williams Sarah', 'Yusuf Ibrahim',
      'Yakubu Joy', 'Zachariah Paul'
    ];

    final students = <Student>[];
    for (int i = 0; i < sampleStudentNames.length; i++) {
      final matricNumber = '2024/${(i + 1).toString().padLeft(3, '0')}';
      students.add(Student(
        id: _uuid.v4(),
        courseId: courseId,
        name: sampleStudentNames[i],
        matricNumber: matricNumber,
        createdAt: now.subtract(const Duration(days: 25)),
        updatedAt: now,
        synced: true,
      ));
    }

    await db.batchInsertStudents(students);

    // Seed 8 Completed Classes (out of 15 expected)
    final sessionTopics = [
      'Introduction to Adolescence & Lifespan Development',
      'Adolescent Cognitive Development & Piaget Theory',
      'Identity Formation & Erikson Psychosocial Stages',
      'Peer Dynamics & Social Relations in Secondary Schools',
      'Teenage Emotional Regulation & Substance Abuse Prevention',
      'Counseling Techniques for At-Risk Adolescents',
      'Career Guidance & Academic Mentorship Strategies',
      'Mid-Semester Continuous Assessment & Practical Review',
    ];

    for (int sIndex = 0; sIndex < sessionTopics.length; sIndex++) {
      final sessionId = _uuid.v4();
      final sessionDate = now.subtract(Duration(days: 28 - (sIndex * 3)));

      final session = AttendanceSession(
        id: sessionId,
        courseId: courseId,
        classNumber: sIndex + 1,
        date: sessionDate,
        topic: sessionTopics[sIndex],
        createdAt: sessionDate,
        synced: true,
      );

      final records = <AttendanceRecord>[];
      for (int stIndex = 0; stIndex < students.length; stIndex++) {
        // Create realistic attendance pattern (approx 86% average attendance)
        final isAbsent = (stIndex + sIndex) % 7 == 0;
        records.add(AttendanceRecord(
          id: _uuid.v4(),
          attendanceSessionId: sessionId,
          studentId: students[stIndex].id,
          status: isAbsent ? AttendanceStatus.absent : AttendanceStatus.present,
          createdAt: sessionDate,
          updatedAt: sessionDate,
          synced: true,
        ));
      }

      await db.saveAttendanceSessionTransaction(
        session: session,
        recordsList: records,
      );
    }
  }
}
