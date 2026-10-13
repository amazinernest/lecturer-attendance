-- ==============================================================================
-- Lecturer Attendance App - Production Multi-Tenant Schema & Row Level Security
-- Guarantees complete data isolation & restore for 100+ (to thousands of) Lecturers
-- ==============================================================================

-- 1. COURSES TABLE
CREATE TABLE IF NOT EXISTS public.courses (
    id TEXT PRIMARY KEY,
    lecturer_id TEXT NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    course_code TEXT NOT NULL,
    course_title TEXT NOT NULL,
    department TEXT NOT NULL DEFAULT '',
    level TEXT NOT NULL DEFAULT '',
    semester TEXT NOT NULL DEFAULT '',
    academic_session TEXT NOT NULL DEFAULT '',
    expected_classes INTEGER NOT NULL DEFAULT 15,
    status TEXT NOT NULL DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Index for fast lecturer lookups
CREATE INDEX IF NOT EXISTS idx_courses_lecturer_id ON public.courses(lecturer_id);

-- Enable Row Level Security (RLS) on courses
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Lecturers can view only their own courses"
    ON public.courses FOR SELECT
    USING (auth.uid()::text = lecturer_id);

CREATE POLICY "Lecturers can insert their own courses"
    ON public.courses FOR INSERT
    WITH CHECK (auth.uid()::text = lecturer_id);

CREATE POLICY "Lecturers can update their own courses"
    ON public.courses FOR UPDATE
    USING (auth.uid()::text = lecturer_id);

CREATE POLICY "Lecturers can delete their own courses"
    ON public.courses FOR DELETE
    USING (auth.uid()::text = lecturer_id);


-- 2. STUDENTS TABLE
CREATE TABLE IF NOT EXISTS public.students (
    id TEXT PRIMARY KEY,
    course_id TEXT NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    matric_number TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Indexes for fast course roster lookups
CREATE INDEX IF NOT EXISTS idx_students_course_id ON public.students(course_id);
CREATE INDEX IF NOT EXISTS idx_students_matric ON public.students(matric_number);

-- Enable RLS on students
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Lecturers can view students of their courses"
    ON public.students FOR SELECT
    USING (course_id IN (SELECT id FROM public.courses WHERE lecturer_id = auth.uid()::text));

CREATE POLICY "Lecturers can insert students for their courses"
    ON public.students FOR INSERT
    WITH CHECK (course_id IN (SELECT id FROM public.courses WHERE lecturer_id = auth.uid()::text));

CREATE POLICY "Lecturers can update students for their courses"
    ON public.students FOR UPDATE
    USING (course_id IN (SELECT id FROM public.courses WHERE lecturer_id = auth.uid()::text));

CREATE POLICY "Lecturers can delete students for their courses"
    ON public.students FOR DELETE
    USING (course_id IN (SELECT id FROM public.courses WHERE lecturer_id = auth.uid()::text));


-- 3. ATTENDANCE SESSIONS TABLE
CREATE TABLE IF NOT EXISTS public.attendance_sessions (
    id TEXT PRIMARY KEY,
    course_id TEXT NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
    class_number INTEGER NOT NULL DEFAULT 1,
    date TIMESTAMP WITH TIME ZONE NOT NULL,
    topic TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Index for sessions
CREATE INDEX IF NOT EXISTS idx_sessions_course_id ON public.attendance_sessions(course_id);

-- Enable RLS on attendance sessions
ALTER TABLE public.attendance_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Lecturers can view sessions of their courses"
    ON public.attendance_sessions FOR SELECT
    USING (course_id IN (SELECT id FROM public.courses WHERE lecturer_id = auth.uid()::text));

CREATE POLICY "Lecturers can insert sessions for their courses"
    ON public.attendance_sessions FOR INSERT
    WITH CHECK (course_id IN (SELECT id FROM public.courses WHERE lecturer_id = auth.uid()::text));

CREATE POLICY "Lecturers can update sessions for their courses"
    ON public.attendance_sessions FOR UPDATE
    USING (course_id IN (SELECT id FROM public.courses WHERE lecturer_id = auth.uid()::text));

CREATE POLICY "Lecturers can delete sessions for their courses"
    ON public.attendance_sessions FOR DELETE
    USING (course_id IN (SELECT id FROM public.courses WHERE lecturer_id = auth.uid()::text));


-- 4. ATTENDANCE RECORDS TABLE
CREATE TABLE IF NOT EXISTS public.attendance_records (
    id TEXT PRIMARY KEY,
    attendance_session_id TEXT NOT NULL REFERENCES public.attendance_sessions(id) ON DELETE CASCADE,
    student_id TEXT NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'absent',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Indexes for records
CREATE INDEX IF NOT EXISTS idx_records_session_id ON public.attendance_records(attendance_session_id);
CREATE INDEX IF NOT EXISTS idx_records_student_id ON public.attendance_records(student_id);

-- Enable RLS on attendance records
ALTER TABLE public.attendance_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Lecturers can view attendance records of their courses"
    ON public.attendance_records FOR SELECT
    USING (attendance_session_id IN (
        SELECT s.id FROM public.attendance_sessions s
        JOIN public.courses c ON s.course_id = c.id
        WHERE c.lecturer_id = auth.uid()::text
    ));

CREATE POLICY "Lecturers can insert attendance records for their courses"
    ON public.attendance_records FOR INSERT
    WITH CHECK (attendance_session_id IN (
        SELECT s.id FROM public.attendance_sessions s
        JOIN public.courses c ON s.course_id = c.id
        WHERE c.lecturer_id = auth.uid()::text
    ));

CREATE POLICY "Lecturers can update attendance records for their courses"
    ON public.attendance_records FOR UPDATE
    USING (attendance_session_id IN (
        SELECT s.id FROM public.attendance_sessions s
        JOIN public.courses c ON s.course_id = c.id
        WHERE c.lecturer_id = auth.uid()::text
    ));


-- 5. STORAGE BUCKET POLICIES (lecturers-attendance-files)
-- Files are stored under path: {userId}/{category}/{timestamp}_{fileName}
-- The policy below ensures lecturers can only access files within their own folder.

CREATE POLICY "Allow authenticated users to read their own files"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (bucket_id = 'lecturers-attendance-files' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Allow authenticated users to upload to their own folder"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'lecturers-attendance-files' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Allow authenticated users to delete their own files"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (bucket_id = 'lecturers-attendance-files' AND (storage.foldername(name))[1] = auth.uid()::text);
