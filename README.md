# Lecturer Attendance

A production-grade, offline-first **Flutter mobile application** designed for university lecturers to manage student attendance across multiple courses throughout an academic semester.

The UI/UX is built using Material 3 with a modern Google Stitch inspired design system, dynamic color palettes, sleek micro-interactions, and accessible typography.

---

## 🌟 Key Features

- 📊 **Dashboard & Visual Analytics**: Real-time overview of active courses, total enrolled students, total class sessions held, average course attendance percentage, and distribution breakdown (`≥75%`, `50-74%`, `<50%`).
- 📚 **Course Management**: Full CRUD capability for creating, editing, and archiving courses with course codes, titles, academic session tags, and credit units.
- 📂 **Multi-Format Class List Import**: Import student rosters directly from:
  - **PDF (`.pdf`)**
  - **Microsoft Word (`.docx`, `.doc`)**
  - **Microsoft Excel (`.xlsx`, `.xls`)**
  - **CSV / Plain Text (`.csv`, `.txt`)**
  - Automatic column auto-detection, duplicate matriculation number prevention, and error reporting.
- 📝 **Live Attendance Tracking**: Convenient single-tap present/absent toggling during live lectures with topic tracking, date stamping, and class numbering.
- 👤 **Student Profiles & History**: Comprehensive breakdown for individual students showing total classes attended vs. held, exact percentage calculations, and historical session logs.
- 📄 **Departmental Report Export**:
  - Export beautifully styled **PDF reports** ready for printing or sharing.
  - Export detailed **Excel (`.xlsx`) spreadsheets** with complete attendance matrix logs.
- ⚡ **Offline-First Architecture & Cloud Sync**:
  - Instant zero-latency UI powered by a local **Drift (SQLite)** database.
  - Automatic background synchronization with **Firebase Cloud Firestore**.
  - Built-in **Offline Demo Mode** that works out-of-the-box without requiring initial Firebase credentials.

---

## 📐 Attendance Calculation Formula

Attendance percentages strictly follow the exact mathematical formula:

$$\text{Attendance Percentage (\%)} = \left( \frac{\text{Classes Attended}}{\text{Total Classes Held}} \right) \times 100$$

- **Denominator Rule**: The total number of classes held to date is always the dynamic denominator.
- **Edge Case Protection**: When 0 classes have been held, the app safely displays `0.0%` without division-by-zero errors.

---

## 🛠️ Technology Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter (Dart 3.12, Material 3) |
| **State Management** | Riverpod (`flutter_riverpod`, `riverpod_annotation`) |
| **Navigation** | GoRouter (Nested `ShellRoute` Bottom Navigation) |
| **Local Database** | Drift (SQLite) + `sqlite3_flutter_libs` |
| **Cloud Service** | Firebase Authentication, Google Sign-In, Cloud Firestore |
| **File Parsing & Generation** | `archive`, `excel`, `csv`, `pdf`, `printing`, `file_picker` |

---

## 📁 Project Structure

```text
lib/
├── core/
│   ├── routing/          # GoRouter configuration & shell route
│   ├── services/         # Riverpod providers & Auth services
│   ├── theme/            # Material 3 colors, typography & theme definitions
│   └── utils/            # Attendance calculator, class list parser & report exporters
├── data/
│   ├── database/         # Drift SQLite schema & type-safe DAOs
│   └── sync/             # Background Firestore sync service
├── features/
│   ├── attendance/       # Live attendance recording screens
│   ├── authentication/   # Welcome & sign-in screens
│   ├── courses/          # Course lists, dashboard & creation dialogs
│   ├── dashboard/        # Main analytics overview dashboard
│   ├── profile/          # Lecturer profile & settings
│   ├── reports/          # Report generation & export interface
│   └── students/         # Student details & multi-format class list import
├── shared/
│   ├── models/           # Data models (Course, Student, AttendanceSession, etc.)
│   └── widgets/          # Reusable cards, toggle buttons & empty states
└── main.dart             # Application entry point
```

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: `3.44.0` or higher
- **Dart SDK**: `3.12.0` or higher
- **JDK**: Java 17 (OpenJDK 17 recommended)
- **Android Studio** / **Xcode** (for mobile deployment)

### 1. Clone the Repository
```bash
git clone https://github.com/amazinernest/lecturer-attendance.git
cd lecturer-attendance
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Generate Database & Provider Code
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Run Static Analysis & Unit Tests
```bash
flutter analyze
flutter test test/unit/
```

### 5. Launch Application Locally
```bash
flutter run
```

---

## 📦 Building Production APKs

To generate a signed or debug release APK for Android:

```bash
# Debug APK
flutter build apk --debug

# Production Release APK
flutter build apk --release
```

The compiled APK will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 🤝 Contributing & License

Designed and developed for university academic staff management. Feel free to open issues or pull requests to enhance features or report bugs.
