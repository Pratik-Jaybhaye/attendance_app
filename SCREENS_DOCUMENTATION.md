## Attendance App - New Screens Documentation

This document describes the new screens and models created for the attendance taking feature.

### Project Structure

```
lib/
├── models/                      # Data models for the app
│   ├── student.dart            # Student model with enrollment status
│   ├── class.dart              # Class model with student list
│   ├── period.dart             # Period/time slot model
│   └── attendance_record.dart   # Attendance record with tracking
│
├── screens/
│   ├── select_classes_screen.dart       # Select 1-2 classes for attendance
│   ├── class_list_screen.dart          # View class details and students
│   ├── select_period_screen.dart       # Select time period and add remarks
│   ├── take_attendance_screen.dart     # Main attendance capture screen
│   └── view_attendance_screen.dart     # Review attendance before submission
│
└── main.dart                    # Updated with routing configuration
```

---

### Data Models

#### 1. **Student Model** (`models/student.dart`)
Represents a student with face enrollment data.

**Key Properties:**
- `id` - Unique student identifier
- `name` - Student full name
- `rollNumber` - Student roll number
- `enrollmentStatus` - Status of face enrollment:
  - `"enrolled"` - Face data successfully trained
  - `"pending"` - Face enrollment in progress
  - `"no_photo"` - No face data yet
- `enrolledPhotosCount` - Number of photos enrolled for ML training
- `isPresent` - Current attendance status

**Methods:**
- `fromJson()` - Create from API response
- `toJson()` - Convert to JSON for API

#### 2. **ClassModel** (`models/class.dart`)
Represents a class/section with its students.

**Key Properties:**
- `id` - Unique class identifier
- `name` - Class name (e.g., "Acculekhaa", "II-A")
- `grade` - Class grade level
- `students` - List of Student objects

**Helper Methods:**
- `enrolledStudentsCount` - Count of enrolled students
- `pendingStudentsCount` - Count of pending enrollments
- `noPhotoStudentsCount` - Count of students without photos

#### 3. **Period Model** (`models/period.dart`)
Represents a class period/time slot.

**Key Properties:**
- `id` - Unique period identifier
- `name` - Period name (e.g., "Period-1", "Hostel-11")
- `remarks` - Optional remarks (max 12 characters)

#### 4. **AttendanceRecord Model** (`models/attendance_record.dart`)
Tracks attendance for a class in a specific period.

**Key Properties:**
- `id` - Unique record identifier
- `classId` - Associated class ID
- `periodId` - Associated period ID
- `dateTime` - Attendance date and time
- `studentAttendance` - Map of `studentId -> isPresent`
- `remarks` - Session remarks
- `isSubmitted` - Whether submitted to backend

---

### Navigation Flow

```
LoginScreen
    ↓
HomeScreen
    ↓ (Take Student Attendance)
SelectClassesScreen [Select 1-2 classes]
    ↓
SelectPeriodScreen [Choose period & add remarks]
    ↓
TakeAttendanceScreen [Capture attendance via camera]
    ↓
(Optional) ViewAttendanceScreen [Review & adjust]
    ↓
Submit to Backend
```

---

### Screen Descriptions

#### **1. Select Classes Screen**
**File:** `screens/select_classes_screen.dart`  
**Purpose:** Allow users to select which classes to take attendance for

**Features:**
- Radio/Checkbox selection (1-2 classes max)
- Display student count per class
- Validation to ensure at least one class is selected
- Highlight selected classes

**UI Elements:**
- Instruction text: "Select Classes (X/2)"
- Class cards with:
  - Class name
  - Student count
  - Selection indicator
- "Next: Select Period" button

**Backend Integration Points:**
- `GET /api/classes` - Fetch all available classes
- `POST /api/attendance/start` - Initiate attendance session

---

#### **2. Class List Screen**
**File:** `screens/class_list_screen.dart`  
**Purpose:** Display detailed view of a class with all students

**Features:**
- Class statistics card (Total, With Face Data, Pending)
- Student list with enrollment status badges
- Color-coded status indicators:
  - Green (✓) - Enrolled with face data
  - Orange (⏱) - Pending enrollment
  - Red (✗) - No photo
- "Take Attendance" button

**UI Elements:**
- Statistics card with counts
- Student cards showing:
  - Student avatar/icon
  - Name and roll number
  - Enrollment status badge
- Action buttons

**Backend Integration Points:**
- `GET /api/classes/{id}/students` - Fetch class students

---

#### **3. Select Period Screen**
**File:** `screens/select_period_screen.dart`  
**Purpose:** Allow users to select which period/time slot and add remarks

**Features:**
- Period list with radio button selection
- Available periods: Period-1 through Period-10, Hostel-11, Mess-12
- Remarks text input (max 12 characters)
- Character counter
- Pre-selects first period by default

**UI Elements:**
- Periods list (scrollable if many)
- Each period is a selectable card
- Remarks input field with:
  - Placeholder text
  - Character counter (X/12)
  - Validation
- "Proceed" button

**Data Flow:**
- Selected period + remarks stored in Period model
- Passed to next screen via navigation

**Backend Integration Points:**
- `GET /api/periods` - Fetch available periods
- `POST /api/attendance/session/start` - Create attendance session

---

#### **4. Take Attendance Screen** ⭐ (Main Screen)
**File:** `screens/take_attendance_screen.dart`  
**Purpose:** Main interface for capturing attendance via face recognition

**Features:**
- Quick Start guide section
- Two camera modes:
  1. **Standard Mode** - Regular face detection
  2. **Hijab Mode** - Optimized for hijab/head coverings
- Real-time class overview showing:
  - Total students
  - Present count (green)
  - Remaining count (red)
- View and Submit buttons
- Face detection integration with ML Kit

**UI Elements:**
- Info card with quick start steps
- Camera button section with two options:
  - "Live Camera - Standard" (filled button)
  - "Live Camera - Hijab" (outline button)
- Class Overview card with statistics
- "View Attendance" link
- Action buttons: "View Attendance" and "Submit"

**Attendance Logic:**
1. User opens camera (Standard or Hijab mode)
2. App detects faces in real-time
3. Matches detected faces with enrolled student faces
4. Auto-updates attendance when match found
5. User can review before submission

**Backend Integration Points:**
- `POST /api/attendance/student-detected` - Send detected student
- `POST /api/attendance/submit` - Submit final attendance
- Camera integrations with face detection ML models

**TODO/Future Features:**
- Integrate camera package for real-time video
- Connect Google ML Kit face detection
- Implement face matching algorithm
- Add camera screen for live preview

---

#### **5. View Attendance Screen**
**File:** `screens/view_attendance_screen.dart`  
**Purpose:** Review and manually adjust attendance before final submission

**Features:**
- Session information display
- Students grouped by class
- Per-class attendance counter
- Checkbox-based attendance toggle
- Color-coded rows (green = present)
- Manual adjustment capability

**UI Elements:**
- Session info card (Period, Classes, Date)
- Per-class sections with:
  - Class name and attendance count
  - Student list with checkboxes
  - Color coding for status
- Navigation back button

**Use Cases:**
- Verify attendance accuracy
- Manually mark/unmark students
- Review before final submission

**Backend Integration Points:**
- `POST /api/attendance/adjust` - Manual attendance adjustments

---

### Important Comments & TODO Items

Throughout the code, you'll find important comments about:

1. **Backend API Endpoints** - TODO comments showing expected API structure
2. **Face Detection Integration** - ML Kit setup instructions
3. **Camera Integration** - Steps to connect camera package
4. **Error Handling** - Recommendations for error scenarios
5. **Data Validation** - Input validation rules

### Key API Endpoints Structure

```
GET /api/classes
  Returns: [
    {
      id, name, grade,
      students: [{id, name, rollNumber, enrollmentStatus, enrolledPhotosCount}]
    }
  ]

GET /api/periods
  Returns: [{id, name}]

POST /api/attendance/start
  Body: {selectedClassIds, periodId}
  Returns: {attendanceSessionId}

POST /api/attendance/student-detected
  Body: {sessionId, studentId, confidence}

POST /api/attendance/submit
  Body: {
    sessionId, periodId, classIds,
    studentAttendance: {studentId: isPresent},
    remarks
  }
```

### Color Scheme

- **Primary Color:** Purple (#6B5B95)
- **Success:** Green
- **Warning:** Orange
- **Error:** Red
- **Background:** Light Gray/Purple

### Testing Checklist

- [ ] Navigation flow works correctly
- [ ] Class selection validation (1-2 classes)
- [ ] Period selection with remarks (max 12 chars)
- [ ] Attendance counter updates correctly
- [ ] Submit button enables/disables appropriately
- [ ] Back navigation works on all screens
- [ ] API integration tested with backend

### Future Enhancements

1. Camera real-time video feed integration
2. Face detection and matching algorithm
3. Batch attendance submission
4. Attendance history and reports
5. Sync with server (offline mode support)
6. Student search functionality
7. Export attendance to CSV/Excel
8. Biometric authentication

---

**Last Updated:** February 18, 2025  
**Version:** 1.0.0
