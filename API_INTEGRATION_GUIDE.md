## Backend API Integration Guide

This document outlines the API endpoints needed for the attendance app to function with a backend server.

### Base Configuration

```dart
// TODO: Set these in your environment configuration
const String API_BASE_URL = 'https://your-api-domain.com/api';
const String API_VERSION = 'v1';
const Duration API_TIMEOUT = Duration(seconds: 30);
```

---

### Authentication

All endpoints require an `Authorization` header with Bearer token:

```
Authorization: Bearer {authToken}
```

---

### Class Management Endpoints

#### 1. Get All Classes
**Endpoint:** `GET /api/v1/classes`

**Description:** Fetch all available classes for the logged-in user

**Response:**
```json
{
  "status": "success",
  "data": [
    {
      "id": "class_001",
      "name": "Acculekhaa",
      "grade": "XII-A",
      "studentCount": 7,
      "students": [
        {
          "id": "student_001",
          "name": "Ramesh",
          "rollNumber": "9999999999",
          "profileImageUrl": "https://...",
          "enrollmentStatus": "no_photo",
          "enrolledPhotosCount": 0
        },
        {
          "id": "student_002",
          "name": "Swathi",
          "rollNumber": "10021002",
          "profileImageUrl": "https://...",
          "enrollmentStatus": "enrolled",
          "enrolledPhotosCount": 5
        }
      ]
    },
    {
      "id": "class_002",
      "name": "II-A",
      "grade": "XI-A",
      "studentCount": 4,
      "students": [...]
    }
  ]
}
```

**Error Responses:**
- `401` - Unauthorized (invalid/expired token)
- `500` - Server error

---

### Period/Time Slot Endpoints

#### 1. Get Available Periods
**Endpoint:** `GET /api/v1/periods`

**Description:** Fetch all available periods for attendance

**Response:**
```json
{
  "status": "success",
  "data": [
    { "id": "period_01", "name": "Period-1", "startTime": "09:00", "endTime": "10:00" },
    { "id": "period_02", "name": "Period-2", "startTime": "10:00", "endTime": "11:00" },
    { "id": "period_03", "name": "Period-3", "startTime": "11:00", "endTime": "12:00" },
    { "id": "period_04", "name": "Period-4", "startTime": "12:00", "endTime": "13:00" },
    { "id": "period_05", "name": "Period-5", "startTime": "13:30", "endTime": "14:30" },
    { "id": "period_06", "name": "Period-6", "startTime": "14:30", "endTime": "15:30" },
    { "id": "period_07", "name": "Period-7", "startTime": "15:30", "endTime": "16:30" },
    { "id": "period_08", "name": "Period-8", "startTime": "16:30", "endTime": "17:30" },
    { "id": "period_09", "name": "Period-9", "startTime": "17:30", "endTime": "18:30" },
    { "id": "period_10", "name": "Period-10", "startTime": "18:30", "endTime": "19:30" },
    { "id": "period_11", "name": "Hostel-11", "startTime": "19:30", "endTime": "20:30" },
    { "id": "period_12", "name": "Mess-12", "startTime": "20:30", "endTime": "21:30" }
  ]
}
```

---

### Attendance Session Endpoints

#### 1. Start Attendance Session
**Endpoint:** `POST /api/v1/attendance/session/start`

**Description:** Initialize an attendance session for one or more classes in a specific period

**Request Body:**
```json
{
  "classIds": ["class_001", "class_002"],
  "periodId": "period_01",
  "remarks": "Assembly",
  "timestamp": "2025-02-18T09:30:00Z"
}
```

**Response:**
```json
{
  "status": "success",
  "data": {
    "sessionId": "session_0001",
    "classIds": ["class_001", "class_002"],
    "periodId": "period_01",
    "startTime": "2025-02-18T09:30:00Z",
    "totalStudents": 11,
    "presentCount": 0,
    "status": "active"
  }
}
```

**Error Responses:**
- `400` - Invalid class IDs or period ID
- `409` - Attendance already taken for this period
- `500` - Server error

---

#### 2. Record Student Detection
**Endpoint:** `POST /api/v1/attendance/student-detected`

**Description:** Send face detection result when a student is detected

**Request Body:**
```json
{
  "sessionId": "session_0001",
  "studentId": "student_002",
  "classId": "class_001",
  "confidence": 0.95,
  "detectionTime": "2025-02-18T09:35:20Z",
  "photoUrl": "https://..."
}
```

**Response:**
```json
{
  "status": "success",
  "data": {
    "recordId": "record_001",
    "studentId": "student_002",
    "markedPresent": true,
    "sessionId": "session_0001"
  }
}
```

**Note:** This is called in real-time every time a face is detected and matched.

---

#### 3. Submit Attendance
**Endpoint:** `POST /api/v1/attendance/submit`

**Description:** Finalize and submit attendance session

**Request Body:**
```json
{
  "sessionId": "session_0001",
  "classIds": ["class_001", "class_002"],
  "periodId": "period_01",
  "remarks": "Assembly held",
  "studentAttendance": {
    "class_001": {
      "student_001": false,
      "student_002": true,
      "student_003": true,
      "student_004": false,
      "student_005": true,
      "student_006": true,
      "student_007": false
    },
    "class_002": {
      "student_010": true,
      "student_011": false
    }
  },
  "submissionTime": "2025-02-18T09:50:00Z"
}
```

**Response:**
```json
{
  "status": "success",
  "data": {
    "attendanceId": "attendance_20250218_001",
    "sessionId": "session_0001",
    "classIds": ["class_001", "class_002"],
    "periodId": "period_01",
    "submissionTime": "2025-02-18T09:50:00Z",
    "totalStudents": 11,
    "presentCount": 6,
    "absentCount": 5,
    "message": "Attendance submitted successfully"
  }
}
```

**Error Responses:**
- `400` - Invalid session or attendance data
- `404` - Session not found
- `409` - Session already submitted
- `500` - Server error

---

#### 4. Get Attendance History
**Endpoint:** `GET /api/v1/attendance/history?classId={classId}&startDate={date}&endDate={date}`

**Description:** Fetch attendance records for a class within a date range

**Query Parameters:**
- `classId` - (required) Class ID
- `startDate` - ISO 8601 format (optional, defaults to 7 days ago)
- `endDate` - ISO 8601 format (optional, defaults to today)

**Response:**
```json
{
  "status": "success",
  "data": [
    {
      "attendanceId": "attendance_20250217_001",
      "date": "2025-02-17",
      "periodId": "period_01",
      "totalStudents": 7,
      "presentCount": 6,
      "absentCount": 1,
      "remarks": "Assembly",
      "submittedBy": "teacher_001",
      "submissionTime": "2025-02-17T09:50:00Z"
    },
    {
      "attendanceId": "attendance_20250218_001",
      "date": "2025-02-18",
      "periodId": "period_01",
      "totalStudents": 7,
      "presentCount": 5,
      "absentCount": 2,
      "remarks": "Holiday prep",
      "submittedBy": "teacher_001",
      "submissionTime": "2025-02-18T09:50:00Z"
    }
  ]
}
```

---

### Face Detection Endpoints

#### 1. Enroll Face Data for Student
**Endpoint:** `POST /api/v1/student/{studentId}/face/enroll`

**Description:** Upload and train face data for a student

**Request Body:**
```json
{
  "photos": [
    {
      "base64Data": "iVBORw0KGgoAAAANSUhEUgAAA...",
      "angle": "front",
      "lighting": "normal",
      "uploadTime": "2025-02-18T09:30:00Z"
    }
  ],
  "totalPhotosForTraining": 5
}
```

**Response:**
```json
{
  "status": "success",
  "data": {
    "studentId": "student_002",
    "enrollmentStatus": "enrolled",
    "photosEnrolled": 5,
    "modelAccuracy": 0.96,
    "trainingCompletedAt": "2025-02-18T09:35:00Z"
  }
}
```

---

#### 2. Get Face Matching Result
**Endpoint:** `POST /api/v1/face/match`

**Description:** Match a detected face with enrolled student faces

**Request Body:**
```json
{
  "imageBase64": "iVBORw0KGgoAAAANSUhEUgAAA...",
  "classId": "class_001",
  "threshold": 0.85
}
```

**Response:**
```json
{
  "status": "success",
  "data": {
    "matched": true,
    "studentId": "student_002",
    "studentName": "Swathi",
    "confidence": 0.96,
    "enrolledPhotosCount": 5
  }
}
```

**If no match found:**
```json
{
  "status": "success",
  "data": {
    "matched": false,
    "studentId": null,
    "confidence": null,
    "message": "No matching student found"
  }
}
```

---

### User Profile Endpoints

#### 1. Get Current User Profile
**Endpoint:** `GET /api/v1/user/profile`

**Response:**
```json
{
  "status": "success",
  "data": {
    "userId": "teacher_001",
    "name": "Srikanth Kumar",
    "email": "srikanth@school.com",
    "role": "teacher",
    "profileImageUrl": "https://...",
    "assignedClasses": ["class_001", "class_002"]
  }
}
```

---

### Error Response Format

All error responses follow this format:

```json
{
  "status": "error",
  "code": "ERROR_CODE",
  "message": "Human-readable error message",
  "timestamp": "2025-02-18T09:30:00Z"
}
```

**Common Error Codes:**
- `INVALID_REQUEST` - Bad request format
- `UNAUTHORIZED` - Invalid/expired token
- `FORBIDDEN` - User not authorized to access resource
- `NOT_FOUND` - Resource not found
- `CONFLICT` - Resource conflict (e.g., duplicate)
- `VALIDATION_ERROR` - Input validation failed
- `SERVER_ERROR` - Internal server error

---

### Implementation Notes

1. **Offline Mode:** Cache API responses locally for offline functionality
2. **Retry Logic:** Implement exponential backoff for failed requests
3. **Token Refresh:** Handle token expiration and automatic refresh
4. **Error Handling:** Show user-friendly error messages
5. **Image Compression:** Compress photos before upload to reduce bandwidth
6. **Batch Operations:** Consider batch endpoints for bulk operations

---

### Testing the API

Use the provided endpoints with tools like:
- Postman
- cURL
- Thunder Client (VS Code)
- REST Client extension

**Example cURL:**
```bash
curl -X GET https://your-api-domain.com/api/v1/classes \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json"
```

---

**API Version:** v1  
**Last Updated:** February 18, 2025
