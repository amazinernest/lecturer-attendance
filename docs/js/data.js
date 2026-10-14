/**
 * Data Service for Lecturer Attendance Portal
 * Handles Courses, Students, Sessions, and Attendance Records
 * Operates at high speed locally via localStorage with optional Supabase cloud synchronization.
 */

import { supabase, AuthService } from './auth.js';

const LOCAL_STORAGE_COURSES = 'lecturer_app_courses';
const LOCAL_STORAGE_STUDENTS = 'lecturer_app_students';
const LOCAL_STORAGE_SESSIONS = 'lecturer_app_sessions';
const LOCAL_STORAGE_RECORDS = 'lecturer_app_records';

/**
 * Ensures cloud network calls fail fast if network is down or lagging
 */
async function withTimeout(promise, ms = 2500) {
  let timer;
  const timeoutPromise = new Promise((_, reject) => {
    timer = setTimeout(() => reject(new Error('Cloud timeout')), ms);
  });
  return Promise.race([promise, timeoutPromise]).finally(() => clearTimeout(timer));
}

export class DataService {
  static listeners = [];

  // ==========================================
  // COURSES
  // ==========================================

  static async getCourses() {
    const user = AuthService.currentUser;
    if (!user) return [];

    let courses = [];
    if (AuthService.isCloudActive() && supabase) {
      try {
        const { data, error } = await withTimeout(
          supabase
            .from('courses')
            .select('*')
            .eq('lecturer_id', user.id)
            .order('created_at', { ascending: false })
        );

        if (!error && data && data.length > 0) {
          courses = data.map(this._mapCourseFromDb);
        }
      } catch (e) {
        console.warn('Error fetching courses from Supabase, falling back to local storage', e);
      }
    }

    if (courses.length === 0) {
      const local = localStorage.getItem(`${LOCAL_STORAGE_COURSES}_${user.id}`);
      if (local) {
        try {
          courses = JSON.parse(local);
        } catch (e) {
          courses = [];
        }
      }
      if (!courses || courses.length === 0) {
        // Seed default courses for fresh lecturer experience
        courses = this._getSeedCourses(user.id);
        this.saveLocalCourses(courses);
      }
    }

    // Deduplicate courses
    const seen = new Set();
    courses = courses.filter(c => {
      const key = (c.id || '') + '_' + (c.courseCode || '');
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    });

    return courses;
  }

  static async createCourse(courseData) {
    const user = AuthService.currentUser;
    if (!user) throw new Error('Authentication required. Please sign in or use Quick Demo Access.');

    const newCourse = {
      id: 'crs_' + Math.random().toString(36).substring(2, 10),
      lecturer_id: user.id,
      course_code: (courseData.courseCode || 'CSC 101').trim().toUpperCase(),
      course_title: (courseData.courseTitle || 'Course Lecture').trim(),
      department: courseData.department || 'Computer Science',
      level: courseData.level || '300L',
      semester: courseData.semester || 'First',
      academic_session: courseData.academicSession || '2024/2025',
      expected_classes: parseInt(courseData.expectedClasses) || 15,
      status: 'active',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    // If live custom Supabase is configured, sync in background non-blockingly
    if (AuthService.isCloudActive() && supabase) {
      withTimeout(supabase.from('courses').insert(newCourse)).catch(e => {
        console.warn('Remote course insert warning', e);
      });
    }

    // Save locally immediately
    const existing = await this.getCourses();
    const mapped = this._mapCourseFromDb(newCourse);
    existing.unshift(mapped);
    this.saveLocalCourses(existing);

    return mapped;
  }

  static async getCourseById(courseId) {
    const courses = await this.getCourses();
    return courses.find(c => c.id === courseId) || null;
  }

  static async deleteCourse(courseId) {
    const user = AuthService.currentUser;
    if (!user) return;

    if (AuthService.isCloudActive() && supabase) {
      withTimeout(supabase.from('courses').delete().eq('id', courseId)).catch(e => {
        console.warn('Remote delete warning', e);
      });
    }

    const courses = (await this.getCourses()).filter(c => c.id !== courseId);
    this.saveLocalCourses(courses);

    // Clean up local students and sessions for this course
    localStorage.removeItem(`${LOCAL_STORAGE_STUDENTS}_${courseId}`);
    localStorage.removeItem(`${LOCAL_STORAGE_SESSIONS}_${courseId}`);
  }

  // ==========================================
  // STUDENTS
  // ==========================================

  static async getStudentsForCourse(courseId) {
    let students = [];
    if (AuthService.isCloudActive() && supabase) {
      try {
        const { data, error } = await withTimeout(
          supabase
            .from('students')
            .select('*')
            .eq('course_id', courseId)
            .order('matric_number', { ascending: true })
        );

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
        try {
          students = JSON.parse(local);
        } catch (e) {
          students = [];
        }
      }
      if (!students || students.length === 0) {
        // Initial institutional class roster
        students = [
          { id: 'std_1', courseId, name: 'ADEBAYO, Kehinde Oluwaseun', matricNumber: '2021/1/10001' },
          { id: 'std_2', courseId, name: 'CHUKWUMA, Emeka Peter', matricNumber: '2021/1/10002' },
          { id: 'std_3', courseId, name: 'IBRAHIM, Zainab Aisha', matricNumber: '2021/1/10003' },
          { id: 'std_4', courseId, name: 'NWOSU, Chioma Mary', matricNumber: '2021/1/10004' },
          { id: 'std_5', courseId, name: 'OGUNLEWE, Babatunde Joseph', matricNumber: '2021/1/10005' },
          { id: 'std_6', courseId, name: 'OKON, Aniefiok Daniel', matricNumber: '2021/1/10006' },
          { id: 'std_7', courseId, name: 'YUSUF, Farouk Aliyu', matricNumber: '2021/1/10007' }
        ];
        localStorage.setItem(`${LOCAL_STORAGE_STUDENTS}_${courseId}`, JSON.stringify(students));
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

    if (AuthService.isCloudActive() && supabase) {
      withTimeout(supabase.from('students').upsert(studentsToSave)).catch(e => {
        console.warn('Remote batch student upsert warning', e);
      });
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
    if (AuthService.isCloudActive() && supabase) {
      try {
        const { data, error } = await withTimeout(
          supabase
            .from('attendance_sessions')
            .select('*')
            .eq('course_id', courseId)
            .order('class_number', { ascending: true })
        );

        if (!error && data) {
          sessions = data;
        }
      } catch (e) {
        console.warn('Remote sessions error', e);
      }
    }

    if (sessions.length === 0) {
      const local = localStorage.getItem(`${LOCAL_STORAGE_SESSIONS}_${courseId}`);
      if (local) {
        try {
          sessions = JSON.parse(local);
        } catch (e) {
          sessions = [];
        }
      }
    }

    return sessions;
  }

  static async getRecordsForSession(sessionId) {
    let records = [];
    if (AuthService.isCloudActive() && supabase) {
      try {
        const { data, error } = await withTimeout(
          supabase
            .from('attendance_records')
            .select('*')
            .eq('attendance_session_id', sessionId)
        );

        if (!error && data) {
          records = data;
        }
      } catch (e) {
        console.warn('Remote records error', e);
      }
    }

    if (records.length === 0) {
      const local = localStorage.getItem(`${LOCAL_STORAGE_RECORDS}_${sessionId}`);
      if (local) {
        try {
          records = JSON.parse(local);
        } catch (e) {
          records = [];
        }
      }
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

    if (AuthService.isCloudActive() && supabase) {
      withTimeout(
        supabase.from('attendance_sessions').upsert(sessionRow).then(() => {
          if (recordRows.length > 0) {
            return supabase.from('attendance_records').upsert(recordRows);
          }
        })
      ).catch(e => {
        console.warn('Remote attendance save warning', e);
      });
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
   * Supports both localStorage events (local offline) and Supabase Postgres changes (cloud)
   */
  static subscribeToLiveSessionCheckIns(sessionId, onNewRecord) {
    if (!sessionId) return () => {};

    // 1. Local Storage Event Listener (Instant offline support across tabs / mobile hotspot)
    const storageHandler = (e) => {
      if (e.key === `local_student_checkin_${sessionId}` && e.newValue) {
        try {
          const payload = JSON.parse(e.newValue);
          if (onNewRecord && payload.student_id) {
            onNewRecord(payload);
          }
        } catch (err) {}
      }
    };
    window.addEventListener('storage', storageHandler);

    // 2. Supabase Cloud Realtime Channel (if custom cloud is configured)
    let channel = null;
    if (AuthService.isCloudActive() && supabase) {
      try {
        channel = supabase
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
              if (payload.new && onNewRecord) {
                onNewRecord(payload.new);
              }
            }
          )
          .subscribe();
      } catch (err) {
        console.warn('Realtime channel error:', err);
      }
    }

    return () => {
      window.removeEventListener('storage', storageHandler);
      if (channel && supabase) {
        try {
          supabase.removeChannel(channel);
        } catch (err) {}
      }
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
      lecturerId: row.lecturer_id || row.lecturerId,
      courseCode: row.course_code || row.courseCode,
      courseTitle: row.course_title || row.courseTitle,
      department: row.department,
      level: row.level,
      semester: row.semester,
      academicSession: row.academic_session || row.academicSession,
      expectedClasses: row.expected_classes || row.expectedClasses || 15,
      status: row.status || 'active',
      createdAt: row.created_at || row.createdAt
    };
  }

  static _mapStudentFromDb(row) {
    return {
      id: row.id,
      courseId: row.course_id || row.courseId,
      name: row.name,
      matricNumber: row.matric_number || row.matricNumber,
      createdAt: row.created_at || row.createdAt
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
