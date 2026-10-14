/**
 * Data Service for Lecturer Attendance Portal
 * Handles Courses, Students, Sessions, and Attendance Records
 * Synchronizes with Supabase using active JWT authentication
 */

import { supabase, AuthService } from './auth.js';

const LOCAL_STORAGE_COURSES = 'lecturer_app_courses';
const LOCAL_STORAGE_STUDENTS = 'lecturer_app_students';
const LOCAL_STORAGE_SESSIONS = 'lecturer_app_sessions';
const LOCAL_STORAGE_RECORDS = 'lecturer_app_records';

export class DataService {
  static listeners = [];

  // ==========================================
  // COURSES
  // ==========================================

  static async getCourses() {
    const user = AuthService.currentUser;
    if (!user) return [];

    let courses = [];
    if (supabase && user.role !== 'demo') {
      try {
        const { data, error } = await supabase
          .from('courses')
          .select('*')
          .eq('lecturer_id', user.id)
          .order('created_at', { ascending: false });

        if (!error && data) {
          courses = data.map(this._mapCourseFromDb);
        }
      } catch (e) {
        console.warn('Error fetching courses from Supabase, falling back to local storage', e);
      }
    }

    if (courses.length === 0) {
      const local = localStorage.getItem(`${LOCAL_STORAGE_COURSES}_${user.id}`);
      if (local) {
        courses = JSON.parse(local);
      } else {
        // Seed default courses for fresh lecturer experience
        courses = this._getSeedCourses(user.id);
        this.saveLocalCourses(courses);
      }
    }

    return courses;
  }

  static async createCourse(courseData) {
    const user = AuthService.currentUser;
    if (!user) throw new Error('Authentication required');

    const newCourse = {
      id: 'crs_' + Math.random().toString(36).substring(2, 10),
      lecturer_id: user.id,
      course_code: courseData.courseCode.trim().toUpperCase(),
      course_title: courseData.courseTitle.trim(),
      department: courseData.department || 'Computer Science',
      level: courseData.level || '300L',
      semester: courseData.semester || 'First',
      academic_session: courseData.academicSession || '2024/2025',
      expected_classes: parseInt(courseData.expectedClasses) || 15,
      status: 'active',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    if (supabase && user.role !== 'demo') {
      try {
        await supabase.from('courses').insert(newCourse);
      } catch (e) {
        console.warn('Remote course insert warning', e);
      }
    }

    // Save locally
    const existing = await this.getCourses();
    existing.unshift(this._mapCourseFromDb(newCourse));
    this.saveLocalCourses(existing);

    return this._mapCourseFromDb(newCourse);
  }

  static async getCourseById(courseId) {
    const courses = await this.getCourses();
    return courses.find(c => c.id === courseId) || null;
  }

  static async deleteCourse(courseId) {
    const user = AuthService.currentUser;
    if (!user) return;

    if (supabase) {
      try {
        await supabase.from('courses').delete().eq('id', courseId);
      } catch (e) {
        console.warn('Remote delete warning', e);
      }
    }

    const courses = (await this.getCourses()).filter(c => c.id !== courseId);
    this.saveLocalCourses(courses);
  }

  // ==========================================
  // STUDENTS
  // ==========================================

  static async getStudentsForCourse(courseId) {
    let students = [];
    if (supabase) {
      try {
        const { data, error } = await supabase
          .from('students')
          .select('*')
          .eq('course_id', courseId)
          .order('matric_number', { ascending: true });

        if (!error && data && data.length > 0) {
          students = data.map(this._mapStudentFromDb);
        }
      } catch (e) {
        console.warn('Remote fetch students error', e);
      }
    }

    if (students.length === 0) {
      const local = localStorage.getItem(`${LOCAL_STORAGE_STUDENTS}_${courseId}`);
      if (local) {
        students = JSON.parse(local);
      }
    }

    return students;
  }

  static async batchAddStudents(courseId, newStudentsList) {
    const now = new Date().toISOString();
    const studentsToSave = newStudentsList.map(s => ({
      id: s.id || 'std_' + Math.random().toString(36).substring(2, 10),
      course_id: courseId,
      name: s.name.trim(),
      matric_number: s.matricNumber.trim().toUpperCase(),
      created_at: now,
      updated_at: now
    }));

    if (supabase) {
      try {
        await supabase.from('students').upsert(studentsToSave);
      } catch (e) {
        console.warn('Remote batch student upsert warning', e);
      }
    }

    // Merge with local
    const existing = await this.getStudentsForCourse(courseId);
    const existingMap = new Map(existing.map(s => [s.matricNumber.toUpperCase(), s]));

    for (const s of studentsToSave) {
      existingMap.set(s.matric_number.toUpperCase(), this._mapStudentFromDb(s));
    }

    const merged = Array.from(existingMap.values());
    localStorage.setItem(`${LOCAL_STORAGE_STUDENTS}_${courseId}`, JSON.stringify(merged));
    return merged;
  }

  // ==========================================
  // ATTENDANCE SESSIONS & RECORDS
  // ==========================================

  static async getSessionsForCourse(courseId) {
    let sessions = [];
    if (supabase) {
      try {
        const { data, error } = await supabase
          .from('attendance_sessions')
          .select('*')
          .eq('course_id', courseId)
          .order('class_number', { ascending: true });

        if (!error && data) {
          sessions = data;
        }
      } catch (e) {
        console.warn('Remote sessions error', e);
      }
    }

    if (sessions.length === 0) {
      const local = localStorage.getItem(`${LOCAL_STORAGE_SESSIONS}_${courseId}`);
      if (local) sessions = JSON.parse(local);
    }

    return sessions;
  }

  static async getRecordsForSession(sessionId) {
    let records = [];
    if (supabase) {
      try {
        const { data, error } = await supabase
          .from('attendance_records')
          .select('*')
          .eq('attendance_session_id', sessionId);

        if (!error && data) {
          records = data;
        }
      } catch (e) {
        console.warn('Remote records error', e);
      }
    }

    if (records.length === 0) {
      const local = localStorage.getItem(`${LOCAL_STORAGE_RECORDS}_${sessionId}`);
      if (local) records = JSON.parse(local);
    }

    return records;
  }

  static async saveAttendanceSession({
    courseId,
    sessionId,
    classNumber,
    topic,
    date,
    statusMap
  }) {
    const sId = sessionId || 'sess_' + Math.random().toString(36).substring(2, 10);
    const now = new Date().toISOString();

    const sessionRow = {
      id: sId,
      course_id: courseId,
      class_number: classNumber,
      topic: topic || 'Regular Lecture Session',
      date: date || now,
      created_at: now
    };

    const recordRows = Object.entries(statusMap).map(([studentId, status]) => ({
      id: 'rec_' + Math.random().toString(36).substring(2, 10),
      attendance_session_id: sId,
      student_id: studentId,
      status: status, // 'present' or 'absent'
      created_at: now,
      updated_at: now
    }));

    if (supabase) {
      try {
        await supabase.from('attendance_sessions').upsert(sessionRow);
        if (recordRows.length > 0) {
          await supabase.from('attendance_records').upsert(recordRows);
        }
      } catch (e) {
        console.warn('Remote attendance save warning', e);
      }
    }

    // Save locally
    const existingSessions = await this.getSessionsForCourse(courseId);
    const filteredSessions = existingSessions.filter(s => s.id !== sId);
    filteredSessions.push(sessionRow);
    localStorage.setItem(`${LOCAL_STORAGE_SESSIONS}_${courseId}`, JSON.stringify(filteredSessions));
    localStorage.setItem(`${LOCAL_STORAGE_RECORDS}_${sId}`, JSON.stringify(recordRows));

    return { session: sessionRow, records: recordRows };
  }

  /**
   * Real-Time Check-In Listener: Listens for students checking in via mobile
   */
  static subscribeToLiveSessionCheckIns(sessionId, onNewRecord) {
    if (!supabase) return () => {};

    const channel = supabase
      .channel(`live_attendance_${sessionId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'attendance_records',
          filter: `attendance_session_id=eq.${sessionId}`
        },
        payload => {
          if (payload.new) {
            onNewRecord(payload.new);
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }

  // ==========================================
  // HELPERS & MAPPERS
  // ==========================================

  static saveLocalCourses(courses) {
    const user = AuthService.currentUser;
    if (user) {
      localStorage.setItem(`${LOCAL_STORAGE_COURSES}_${user.id}`, JSON.stringify(courses));
    }
  }

  static _mapCourseFromDb(row) {
    return {
      id: row.id,
      lecturerId: row.lecturer_id,
      courseCode: row.course_code,
      courseTitle: row.course_title,
      department: row.department,
      level: row.level,
      semester: row.semester,
      academicSession: row.academic_session,
      expectedClasses: row.expected_classes || 15,
      status: row.status || 'active',
      createdAt: row.created_at
    };
  }

  static _mapStudentFromDb(row) {
    return {
      id: row.id,
      courseId: row.course_id,
      name: row.name,
      matricNumber: row.matric_number,
      createdAt: row.created_at
    };
  }

  static _getSeedCourses(userId) {
    return [
      {
        id: 'crs_csc401',
        lecturerId: userId,
        courseCode: 'CSC 401',
        courseTitle: 'Software Architecture & System Design',
        department: 'Computer Science',
        level: '400L',
        semester: 'First',
        academicSession: '2024/2025',
        expectedClasses: 15,
        status: 'active',
        createdAt: new Date().toISOString()
      },
      {
        id: 'crs_csc311',
        lecturerId: userId,
        courseCode: 'CSC 311',
        courseTitle: 'Algorithms & Data Structures',
        department: 'Computer Science',
        level: '300L',
        semester: 'First',
        academicSession: '2024/2025',
        expectedClasses: 12,
        status: 'active',
        createdAt: new Date().toISOString()
      }
    ];
  }
}
