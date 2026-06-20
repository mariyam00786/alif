/**
 * COMPLETE API DOCUMENTATION
 * Alif Online Moral School - Backend REST API
 * 
 * Base URL: http://localhost:3000/api
 * Version: 1.0.0
 * Last Updated: March 2026
 */

// ============================================================================
// AUTHENTICATION ENDPOINTS
// ============================================================================

/**
 * POST /api/auth/request-otp
 * Request One-Time Password for phone authentication
 * 
 * Request Body:
 * {
 *   "phone": "+966501234567"  // International format required
 * }
 * 
 * Response (200 OK):
 * {
 *   "success": true,
 *   "message": "OTP sent to phone",
 *   "data": {
 *     "phone": "+966501234567",
 *     "expiresIn": 600,           // seconds
 *     "otpLength": 6
 *   },
 *   "timestamp": "2026-03-15T10:30:00Z"
 * }
 * 
 * Response (400 Bad Request):
 * {
 *   "success": false,
 *   "error": "INVALID_PHONE",
 *   "message": "Phone number is invalid",
 *   "statusCode": 400,
 *   "timestamp": "2026-03-15T10:30:00Z"
 * }
 * 
 * Validation Rules:
 * - Phone must start with '+'
 * - Phone must be 12-15 characters
 * - Phone format: +[country_code][number]
 * 
 * Rate Limit: 3 attempts per phone per hour
 * Auth Required: No
 */

/**
 * POST /api/auth/supabase-signin
 * Exchange a Supabase Google access token for an Alif app JWT.
 *
 * Request Body:
 * {
 *   "accessToken": "supabase-access-token"
 * }
 *
 * Response (200 OK):
 * {
 *   "success": true,
 *   "message": "Google sign-in successful.",
 *   "token": "eyJhbGciOiJIUzI1NiIs...",
 *   "data": {
 *     "token": "eyJhbGciOiJIUzI1NiIs...",
 *     "user": {
 *       "id": "supabase-auth-user-id",
 *       "phone": "+966501234567",
 *       "role": "student|parent|teacher|admin",
 *       "name": "Ahmed Ali",
 *       "profile_id": "profile-uuid"
 *     },
 *     "profile": {
 *       "id": "profile-uuid",
 *       "phone": "+966501234567",
 *       "google_email": "user@gmail.com",
 *       "firebase_uid": null,
 *       "role": "student|parent|teacher|admin"
 *     }
 *   }
 * }
 *
 * Response (403 Forbidden):
 * {
 *   "success": false,
 *   "message": "No profile is linked to this Google account. Assign a matching profile before login."
 * }
 *
 * Auth Required: No
 */

/**
 * POST /api/auth/verify-otp
 * Verify OTP and receive JWT access token
 * 
 * Request Body:
 * {
 *   "phone": "+966501234567",
 *   "otp": "123456"
 * }
 * 
 * Response (200 OK):
 * {
 *   "success": true,
 *   "message": "Authentication successful",
 *   "data": {
 *     "accessToken": "eyJhbGciOiJIUzI1NiIs...",  // JWT token
 *     "refreshToken": "refresh_token_here",        // Optional
 *     "expiresIn": 3600,                           // seconds
 *     "user": {
 *       "id": "user-001",
 *       "phone": "+966501234567",
 *       "role": "student|parent|teacher|admin",
 *       "name": "Ahmed Ali",
 *       "batch": "Class A"
 *     }
 *   },
 *   "timestamp": "2026-03-15T10:30:00Z"
 * }
 * 
 * Response (401 Unauthorized):
 * {
 *   "success": false,
 *   "error": "INVALID_OTP",
 *   "message": "OTP is invalid or expired",
 *   "statusCode": 401,
 *   "timestamp": "2026-03-15T10:30:00Z"
 * }
 * 
 * Validation Rules:
 * - OTP must be exactly 6 digits
 * - OTP expires after 10 minutes
 * - Max 3 invalid attempts then timeout 15 minutes
 * 
 * Rate Limit: 5 attempts per phone per minute
 * Auth Required: No
 */

// ============================================================================
// STUDENT ENDPOINTS
// ============================================================================

/**
 * GET /api/students
 * List all students with pagination, search, and filtering
 * 
 * Query Parameters:
 * - page=1              // Page number (default: 1)
 * - limit=20            // Items per page (default: 20, max: 100)
 * - search=ahmed        // Search by name or phone
 * - batch_id=batch-001  // Filter by batch
 * - status=active       // Filter by status (active|archived)
 * - sort=name           // Sort field (name|created_at|status)
 * - order=asc           // Sort order (asc|desc)
 * 
 * Example:
 * GET /api/students?page=1&limit=20&search=ahmed&batch_id=batch-001
 * 
 * Response (200 OK):
 * {
 *   "success": true,
 *   "data": {
 *     "students": [
 *       {
 *         "id": "student-001",
 *         "name": "Ahmed Ali",
 *         "phone": "+966501234567",
 *         "email": "ahmed@school.com",
 *         "batch_id": "batch-001",
 *         "batch_name": "Class A",
 *         "status": "active",
 *         "created_at": "2026-03-01T00:00:00Z",
 *         "last_marking": "2026-03-15T10:30:00Z"
 *       },
 *       // ... more students
 *     ],
 *     "pagination": {
 *       "page": 1,
 *       "limit": 20,
 *       "total": 1250,
 *       "totalPages": 63
 *     }
 *   },
 *   "timestamp": "2026-03-15T10:30:00Z"
 * }
 * 
 * Auth Required: Yes (admin, teacher)
 * Roles Allowed: admin, teacher
 */

/**
 * POST /api/students
 * Create a new student
 * 
 * Request Body:
 * {
 *   "name": "Ahmed Ali",
 *   "phone": "+966501234567",
 *   "email": "ahmed@school.com",
 *   "batch_id": "batch-001"
 * }
 * 
 * Response (201 Created):
 * {
 *   "success": true,
 *   "message": "Student created successfully",
 *   "data": {
 *     "id": "student-001",
 *     "name": "Ahmed Ali",
 *     "phone": "+966501234567",
 *     "email": "ahmed@school.com",
 *     "batch_id": "batch-001",
 *     "status": "active",
 *     "created_at": "2026-03-15T10:30:00Z"
 *   },
 *   "timestamp": "2026-03-15T10:30:00Z"
 * }
 * 
 * Validation:
 * - name: Required, 2-100 characters
 * - phone: Required, valid international format
 * - email: Optional, must be valid email if provided
 * - batch_id: Required, must exist in database
 * 
 * Auth Required: Yes (admin only)
 * Roles Allowed: admin
 */

/**
 * GET /api/students/:id
 * Get student details including progress summary
 * 
 * URL Parameters:
 * - id: Student ID (required)
 * 
 * Response (200 OK):
 * {
 *   "success": true,
 *   "data": {
 *     "id": "student-001",
 *     "name": "Ahmed Ali",
 *     "phone": "+966501234567",
 *     "email": "ahmed@school.com",
 *     "batch": {
 *       "id": "batch-001",
 *       "name": "Class A",
 *       "code": "A-2026-Q1"
 *     },
 *     "status": "active",
 *     "totalMarks": 850,
 *     "averageMarks": 27.4,
 *     "completionPercentage": 98.5,
 *     "rankInBatch": 5,
 *     "totalBatchStudents": 45,
 *     "created_at": "2026-03-01T00:00:00Z"
 *   },
 *   "timestamp": "2026-03-15T10:30:00Z"
 * }
 * 
 * Auth Required: Yes
 * Roles Allowed: admin, teacher (own student), student (self)
 */

/**
 * PUT /api/students/:id
 * Update student information
 * 
 * Request Body (all fields optional):
 * {
 *   "name": "Ahmed Ali Khan",
 *   "email": "newemail@school.com",
 *   "batch_id": "batch-002",
 *   "status": "active|archived"
 * }
 * 
 * Response (200 OK):
 * {
 *   "success": true,
 *   "message": "Student updated successfully",
 *   "data": {
 *     "id": "student-001",
 *     "name": "Ahmed Ali Khan",
 *     "batch_id": "batch-002",
 *     "updated_at": "2026-03-15T10:30:00Z"
 *   },
 *   "timestamp": "2026-03-15T10:30:00Z"
 * }
 * 
 * Auth Required: Yes (admin only)
 * Roles Allowed: admin
 */

/**
 * DELETE /api/students/:id
 * Soft delete (archive) a student
 * 
 * Note: Uses soft delete (status = 'archived'), not hard delete
 * 
 * Response (200 OK):
 * {
 *   "success": true,
 *   "message": "Student archived successfully",
 *   "data": {
 *     "id": "student-001",
 *     "status": "archived",
 *     "archived_at": "2026-03-15T10:30:00Z"
 *   },
 *   "timestamp": "2026-03-15T10:30:00Z"
 * }
 * 
 * Auth Required: Yes (admin only)
 * Roles Allowed: admin
 */

// ============================================================================
// BATCH ENDPOINTS
// ============================================================================

/**
 * GET /api/batches
 * List all batches
 * 
 * Query Parameters:
 * - page=1           // Page number
 * - limit=20         // Items per page
 * - status=active    // Filter (active|archived)
 * - search=class     // Search by name
 * 
 * Response (200 OK):
 * {
 *   "success": true,
 *   "data": {
 *     "batches": [
 *       {
 *         "id": "batch-001",
 *         "name": "Class A - 2026",
 *         "code": "A-2026-Q1",
 *         "description": "Primary Islamic studies",
 *         "teacher_count": 3,
 *         "student_count": 45,
 *         "status": "active",
 *         "created_at": "2026-01-01T00:00:00Z"
 *       }
 *     ],
 *     "pagination": {
 *       "total": 45,
 *       "totalPages": 3
 *     }
 *   },
 *   "timestamp": "2026-03-15T10:30:00Z"
 * }
 * 
 * Auth Required: Yes (admin, teacher)
 * Roles Allowed: admin, teacher
 */

/**
 * POST /api/batches
 * Create a new batch
 * 
 * Request Body:
 * {
 *   "name": "Class B - 2026",
 *   "code": "B-2026-Q1",
 *   "description": "Islamic teachings"
 * }
 * 
 * Response (201 Created):
 * {
 *   "success": true,
 *   "message": "Batch created successfully",
 *   "data": {
 *     "id": "batch-002",
 *     "name": "Class B - 2026",
 *     "code": "B-2026-Q1",
 *     "status": "active",
 *     "created_at": "2026-03-15T10:30:00Z"
 *   },
 *   "timestamp": "2026-03-15T10:30:00Z"
 * }
 * 
 * Auth Required: Yes (admin only)
 * Roles Allowed: admin
 */

/**
 * GET /api/batches/:id/students
 * Get all students in a batch
 * 
 * Response (200 OK):
 * {
 *   "success": true,
 *   "data": {
 *     "batch": {
 *       "id": "batch-001",
 *       "name": "Class A",
 *       "code": "A-2026-Q1"
 *     },
 *     "students": [
 *       {
 *         "id": "student-001",
 *         "name": "Ahmed Ali",
 *         "phone": "+966501234567",
 *         "status": "active"
 *       }
 *     ],
 *     "totalStudents": 45
 *   },
 *   "timestamp": "2026-03-15T10:30:00Z"
 * }
 * 
 * Auth Required: Yes
 * Roles Allowed: admin, teacher
 */

// ============================================================================
// ACTIVITY ENDPOINTS
// ============================================================================

/**
 * GET /api/activities
 * List all activities (master data, cached)
 * 
 * Response (200 OK):
 * {
 *   "success": true,
 *   "data": {
 *     "activities": [
 *       {
 *         "id": "act-001",
 *         "name": "Subhi Prayer (صلاة الصبح)",
 *         "category": "prayers",
 *         "description": "Dawn prayer",
 *         "maxMarks": 10,
 *         "icon": "prayer"
 *       },
 *       // ... 18 more activities
 *     ],
 *     "totalActivities": 19,
 *     "cachedAt": "2026-03-15T10:00:00Z",
 *     "cacheExpires": "2026-03-15T10:05:00Z"
 *   },
 *   "timestamp": "2026-03-15T10:30:00Z"
 * }
 * 
 * Caching: 5-minute TTL in memory
 * Auth Required: No
 * Roles Allowed: All
 */

/**
 * GET /api/activities/categories
 * List activity categories
 * 
 * Response (200 OK):
 * {
 *   "success": true,
 *   "data": {
 *     "categories": [
 *       {
 *         "id": "cat-001",
 *         "name": "Prayers (الصلوات)",
 *         "icon": "prayer",
 *         "order": 1,
 *         "activities": 5
 *       },
 *       {
 *         "id": "cat-002",
 *         "name": "Quran Reading",
 *         "icon": "quran",
 *         "order": 2,
 *         "activities": 2
 *       },
 *       // ... 4 more categories
 *     ],
 *     "totalCategories": 6
 *   },
 *   "timestamp": "2026-03-15T10:30:00Z"
 * }
 * 
 * Auth Required: No
 * Roles Allowed: All
 */

/**
 * GET /api/activities/structure/daily
 * Get daily activity structure (organized by category)
 * 
 * Response (200 OK):
 * {
 *   "success": true,
 *   "data": {
 *     "date": "2026-03-15",
 *     "categories": [
 *       {
 *         "id": "cat-001",
 *         "name": "Prayers",
 *         "activities": [
 *           {
 *             "id": "act-001",
 *             "name": "Subhi Prayer",
 *             "rating": null,
 *             "quantity": 0
 *           },
 *           // ... more activities
 *         ]
 *       },
 *       // ... more categories
 *     ],
 *     "ratings": [
 *       {
 *         "level": "Excellent",
 *         "marks": 10,
 *         "color": "#4CAF50"
 *       },
 *       // ... 3 more ratings
 *     ]
 *   },
 *   "timestamp": "2026-03-15T10:30:00Z"
 * }
 * 
 * Auth Required: No
 * Roles Allowed: All
 */

// ============================================================================
// DAILY RECORD ENDPOINTS
// ============================================================================

/**
 * POST /api/daily-records
 * Create a new daily record
 * 
 * Request Body:
 * {
 *   "student_id": "student-001",
 *   "date": "2026-03-15",
 *   "activities": [
 *     {
 *       "activity_id": "act-001",
 *       "rating": 10,
 *       "quantity": 1
 *     },
 *     // ... more activities
 *   ]
 * }
 * 
 * Response (201 Created):
 * {
 *   "success": true,
 *   "message": "Daily record created successfully",
 *   "data": {
 *     "id": "record-001",
 *     "student_id": "student-001",
 *     "date": "2026-03-15",
 *     "totalMarks": 32,
 *     "status": "draft",
 *     "created_at": "2026-03-15T10:30:00Z"
 *   },
 *   "timestamp": "2026-03-15T10:30:00Z"
 * }
 * 
 * Auth Required: Yes
 * Roles Allowed: student (own record), teacher, admin
 */

/**
 * GET /api/daily-records/:id
 * Get daily record details
 * 
 * Response (200 OK):
 * {
 *   "success": true,
 *   "data": {
 *     "id": "record-001",
 *     "student": {
 *       "id": "student-001",
 *       "name": "Ahmed Ali"
 *     },
 *     "date": "2026-03-15",
 *     "activities": [
 *       {
 *         "activity_id": "act-001",
 *         "activity_name": "Subhi Prayer",
 *         "rating": 10,
 *         "quantity": 1,
 *         "marks": 10
 *       }
 *     ],
 *     "totalMarks": 32,
 *     "completionPercentage": 89.0,
 *     "status": "submitted",
 *     "submitted_at": "2026-03-15T20:00:00Z"
 *   },
 *   "timestamp": "2026-03-15T10:30:00Z"
 * }
 * 
 * Auth Required: Yes
 * Roles Allowed: student (own), parent (child), teacher, admin
 */

/**
 * PUT /api/daily-records/:id
 * Update daily record (before submission)
 * 
 * Request Body:
 * {
 *   "activities": [
 *     {
 *       "activity_id": "act-001",
 *       "rating": 5,
 *       "quantity": 2
 *     }
 *   ]
 * }
 * 
 * Response (200 OK):
 * {
 *   "success": true,
 *   "message": "Record updated successfully",
 *   "data": {
 *     "id": "record-001",
 *     "totalMarks": 27,
 *     "updated_at": "2026-03-15T10:30:00Z"
 *   },
 *   "timestamp": "2026-03-15T10:30:00Z"
 * }
 * 
 * Note: Cannot update submitted records
 * Auth Required: Yes (student, admin)
 * Roles Allowed: student (own), admin
 */

/**
 * POST /api/daily-records/:id/submit
 * Submit and lock daily record
 * 
 * Request Body:
 * {}
 * 
 * Response (200 OK):
 * {
 *   "success": true,
 *   "message": "Record submitted successfully",
 *   "data": {
 *     "id": "record-001",
 *     "status": "submitted",
 *     "submitted_at": "2026-03-15T20:30:00Z"
 *   },
 *   "timestamp": "2026-03-15T10:30:00Z"
 * }
 * 
 * Effect: Record becomes read-only, locked from further edits
 * Auth Required: Yes (student, admin)
 * Roles Allowed: student (own), admin
 */

/**
 * POST /api/daily-records/:id/approve
 * Approve daily record (parent/teacher)
 * 
 * Request Body:
 * {
 *   "feedback": "Great effort!"  // Optional
 * }
 * 
 * Response (200 OK):
 * {
 *   "success": true,
 *   "message": "Record approved successfully",
 *   "data": {
 *     "id": "record-001",
 *     "status": "approved",
 *     "approved_by": "parent-001",
 *     "approved_at": "2026-03-15T21:00:00Z"
 *   },
 *   "timestamp": "2026-03-15T10:30:00Z"
 * }
 * 
 * Auth Required: Yes (parent, teacher, admin)
 * Roles Allowed: parent (child), teacher, admin
 */

// ============================================================================
// PROGRESS & ANALYTICS ENDPOINTS
// ============================================================================

/**
 * GET /api/students/:id/progress/daily
 * Get daily progress metrics for a student
 * 
 * Query Parameters:
 * - date=2026-03-15  // Specific date (default: today)
 * 
 * Response (200 OK):
 * {
 *   "success": true,
 *   "data": {
 *     "date": "2026-03-15",
 *     "student": {
 *       "id": "student-001",
 *       "name": "Ahmed Ali"
 *     },
 *     "metrics": {
 *       "totalMarks": 32,
 *       "maxMarks": 40,
 *       "completionPercentage": 89.0,
 *       "activitiesCompleted": 9,
 *       "totalActivities": 9,
 *       "rankInBatch": 3
 *     },
 *     "trend": {
 *       "direction": "improving|declining|neutral",
 *       "change": 5      // percentage change from yesterday
 *     },
 *     "activities": [
 *       {
 *         "name": "Subhi Prayer",
 *         "rating": 10,
 *         "marks": 10
 *       }
 *     ]
 *   },
 *   "timestamp": "2026-03-15T10:30:00Z"
 * }
 * 
 * Auth Required: Yes
 * Roles Allowed: student (self), parent (child), teacher, admin
 */

/**
 * GET /api/students/:id/progress/weekly
 * Get weekly progress summary
 * 
 * Query Parameters:
 * - week=2026-03-09  // Week start date (default: current week)
 * 
 * Response (200 OK):
 * {
 *   "success": true,
 *   "data": {
 *     "week": {
 *       "start": "2026-03-09",
 *       "end": "2026-03-15"
 *     },
 *     "metrics": {
 *       "totalMarks": 210,
 *       "averageMarks": 30.0,
 *       "daysActive": 7,
 *       "completionPercentage": 98.5,
 *       "bestDay": "2026-03-15",
 *       "bestDayMarks": 32
 *     },
 *     "trend": "improving",
 *     "dailyBreakdown": [
 *       {
 *         "date": "2026-03-09",
 *         "marks": 28,
 *         "completion": 78.0
 *       }
 *     ]
 *   },
 *   "timestamp": "2026-03-15T10:30:00Z"
 * }
 * 
 * Auth Required: Yes
 * Roles Allowed: student (self), parent (child), teacher, admin
 */

/**
 * GET /api/students/:id/progress/monthly
 * Get monthly progress analysis
 * 
 * Query Parameters:
 * - month=2026-03  // Month (default: current month)
 * 
 * Response (200 OK):
 * {
 *   "success": true,
 *   "data": {
 *     "month": "March 2026",
 *     "metrics": {
 *       "totalMarks": 850,
 *       "averageMarks": 27.4,
 *       "daysActive": 31,
 *       "completionPercentage": 96.8,
 *       "bestDay": "2026-03-15",
 *       "bestDayMarks": 38
 *     },
 *     "comparison": {
 *       "previousMonth": {
 *         "totalMarks": 758,
 *         "averageMarks": 24.5
 *       },
 *       "improvement": 12   // percentage
 *     },
 *     "trend": "improving",
 *     "milestones": [
 *       {
 *         "milestone": "7-Day Streak",
 *         "achieved": true,
 *         "date": "2026-03-10"
 *       }
 *     ]
 *   },
 *   "timestamp": "2026-03-15T10:30:00Z"
 * }
 * 
 * Auth Required: Yes
 * Roles Allowed: student (self), parent (child), teacher, admin
 */

/**
 * GET /api/batches/:id/leaderboard
 * Get daily leaderboard for a batch
 * 
 * Query Parameters:
 * - date=2026-03-15  // Specific date (default: today)
 * - limit=50         // Max entries (default: 50)
 * 
 * Response (200 OK):
 * {
 *   "success": true,
 *   "data": {
 *     "batch": {
 *       "id": "batch-001",
 *       "name": "Class A"
 *     },
 *     "date": "2026-03-15",
 *     "rankings": [
 *       {
 *         "rank": 1,
 *         "student": {
 *           "id": "student-001",
 *           "name": "Ahmed Ali",
 *           "avatar": "A"
 *         },
 *         "totalMarks": 38,
 *         "activitiesCompleted": 9,
 *         "completionPercentage": 100.0,
 *         "isCurrentUser": true
 *       },
 *       {
 *         "rank": 2,
 *         "student": {
 *           "id": "student-002",
 *           "name": "Fatima Khan",
 *           "avatar": "F"
 *         },
 *         "totalMarks": 35,
 *         "activitiesCompleted": 8
 *       }
 *     ],
 *     "totalStudents": 45,
 *     "generatedAt": "2026-03-15T21:00:00Z"
 *   },
 *   "timestamp": "2026-03-15T10:30:00Z"
 * }
 * 
 * Note: Top 3 marked with medals (🥇🥈🥉)
 * Auth Required: Yes
 * Roles Allowed: All authenticated users
 */

/**
 * GET /api/batches/:id/leaderboard/weekly
 * Get weekly leaderboard for a batch
 * 
 * Query Parameters:
 * - week=2026-03-09  // Week start date (default: current week)
 * 
 * Response Structure: Similar to daily leaderboard
 * 
 * Auth Required: Yes
 * Roles Allowed: All authenticated users
 */

// ============================================================================
// SYSTEM ENDPOINTS
// ============================================================================

/**
 * GET /api/health
 * System health check endpoint
 * 
 * Response (200 OK):
 * {
 *   "success": true,
 *   "message": "System healthy",
 *   "data": {
 *     "database": "connected",
 *     "redis": "connected|disabled",
 *     "server": "running",
 *     "uptime": 86400,              // seconds
 *     "responseTime": 15,           // milliseconds
 *     "timestamp": "2026-03-15T10:30:00Z"
 *   },
 *   "timestamp": "2026-03-15T10:30:00Z"
 * }
 * 
 * Response (503 Service Unavailable):
 * {
 *   "success": false,
 *   "message": "Database connection failed",
 *   "statusCode": 503,
 *   "timestamp": "2026-03-15T10:30:00Z"
 * }
 * 
 * Auth Required: No
 * Roles Allowed: All (public endpoint)
 */

// ============================================================================
// ERROR RESPONSES
// ============================================================================

/**
 * All error responses follow this format:
 * 
 * {
 *   "success": false,
 *   "error": "ERROR_CODE",
 *   "message": "Human-readable message",
 *   "statusCode": 400,
 *   "timestamp": "2026-03-15T10:30:00Z"
 * }
 * 
 * Common Error Codes:
 * - INVALID_INPUT: Request validation failed
 * - INVALID_PHONE: Phone format is invalid
 * - INVALID_OTP: OTP is invalid or expired
 * - UNAUTHORIZED: Missing or invalid JWT token
 * - FORBIDDEN: User lacks required permissions
 * - NOT_FOUND: Resource not found
 * - CONFLICT: Resource already exists
 * - INTERNAL_ERROR: Server error
 * - SERVICE_UNAVAILABLE: Database or service down
 */

// ============================================================================
// AUTHENTICATION HEADER
// ============================================================================

/**
 * For authenticated endpoints, include JWT in header:
 * 
 * Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
 * 
 * The token expires after 1 hour.
 * Include refresh token to get new access token.
 */

// ============================================================================
// RATE LIMITING
// ============================================================================

/**
 * Rate Limits (per user, per minute):
 * - Anonymous: 20 requests/minute
 * - Authenticated: 100 requests/minute
 * - Admin: 500 requests/minute
 * 
 * Headers in response:
 * - X-RateLimit-Limit: 100
 * - X-RateLimit-Remaining: 95
 * - X-RateLimit-Reset: 1678891530 (Unix timestamp)
 */

// ============================================================================
// PAGINATION
// ============================================================================

/**
 * All list endpoints support pagination:
 * 
 * Query Parameters:
 * - page=1           // Page number (1-indexed)
 * - limit=20         // Items per page (1-100)
 * 
 * Response includes:
 * "pagination": {
 *   "page": 1,
 *   "limit": 20,
 *   "total": 1250,
 *   "totalPages": 63,
 *   "hasNextPage": true,
 *   "hasPreviousPage": false
 * }
 */

// ============================================================================
// CACHING
// ============================================================================

/**
 * Some endpoints have caching (5-minute TTL):
 * - GET /api/activities (master data)
 * - GET /api/activities/categories
 * - GET /api/activities/structure/daily
 * 
 * Response includes:
 * "cachedAt": "2026-03-15T10:00:00Z",
 * "cacheExpires": "2026-03-15T10:05:00Z"
 */

// ============================================================================
// DOCUMENTATION
// ============================================================================

/**
 * For more details:
 * - Request/Response Examples: See /backend/docs/EXAMPLES.md
 * - Database Schema: See /backend/docs/SCHEMA.md
 * - Error Handling: See /backend/docs/ERRORS.md
 * - Security: See /backend/docs/SECURITY.md
 */

// End of API Documentation
// Last Updated: March 2026
// Version: 1.0.0
