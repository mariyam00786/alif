/**
 * Database Types and Interfaces
 * 
 * Type definitions for all database tables
 * Generated from Supabase schema
 */

// User Profile (Extended with role and profile info)
export interface Profile {
  id: string;
  phone: string;
  google_email?: string;
  firebase_uid?: string;
  full_name: string;
  full_name_ml?: string;
  role: 'student' | 'parent' | 'teacher' | 'admin';
  profile_photo?: string;
  created_at: string;
  updated_at: string;
}

// Student Information
export interface Student {
  id: string;
  profile_id: string;
  parent_phone: string;
  father_name: string;
  mother_name: string;
  date_of_birth: string;
  gender: 'male' | 'female';
  batch_id: string;
  class_id: string;
  address?: string;
  enrollment_date: string;
  status: 'active' | 'inactive';
  created_at: string;
  updated_at: string;
}

// Teacher Information
export interface Teacher {
  id: string;
  profile_id: string;
  email?: string;
  qualification?: string;
  status: 'active' | 'inactive';
  created_at: string;
}

// Batch (Class Group)
export interface Batch {
  id: string;
  name: string;
  name_ml?: string;
  description?: string;
  capacity?: number;
  timing?: string;
  status: 'active' | 'inactive';
  created_at: string;
}

// Class
export interface Class {
  id: string;
  name: string;
  name_ml?: string;
  level?: 'beginner' | 'intermediate' | 'advanced';
  batch_id: string;
  status: 'active' | 'inactive';
  created_at: string;
}

// Activity Category (e.g., Prayer, Daily Routine)
export interface ActivityCategory {
  id: string;
  name: string;
  name_ml?: string;
  icon?: string;
  display_order: number;
  status: 'active' | 'inactive';
  created_at: string;
}

// Activity (Sub-category of Activity Category)
export interface Activity {
  id: string;
  category_id: string;
  name: string;
  name_ml?: string;
  display_order: number;
  has_quantity: boolean;
  status: 'active' | 'inactive';
  created_at: string;
}

// Rating Option for Activity (excellent, satisfactory, needs improvement)
export interface ActivityRating {
  id: string;
  activity_id: string;
  rating_name: string;
  rating_name_ml?: string;
  marks: number;
  color?: string;
  display_order: number;
  created_at: string;
}

export interface ActivityScoringRule {
  id: string;
  activity_id: string;
  rule_type: 'rating' | 'quantity';
  min_quantity?: number;
  max_quantity?: number;
  marks: number;
  display_order: number;
  created_at: string;
}

// Daily Activity Log
export interface ActivityLog {
  id: string;
  student_id: string;
  activity_id: string;
  rating_id?: string | null;
  log_date: string;
  quantity?: number;
  marks_earned: number;
  parent_approved: boolean;
  notes?: string;
  created_at: string;
  updated_at: string;
}

// Badge/Achievement
export interface Badge {
  id: string;
  name: string;
  name_ml?: string;
  description?: string;
  icon?: string;
  criteria: Record<string, any>;
  bonus_points: number;
  status: 'active' | 'inactive';
  created_at: string;
}

// Student Badge (Earned Badge)
export interface StudentBadge {
  id: string;
  student_id: string;
  badge_id: string;
  earned_at: string;
}

// Notification
export interface Notification {
  id: string;
  title: string;
  body?: string;
  target_type: 'all' | 'batch' | 'class' | 'student';
  target_id?: string;
  scheduled_at?: string;
  sent_at?: string;
  created_by: string;
  created_at: string;
}

// Parent-Student Relationship
export interface ParentStudent {
  id: string;
  parent_profile_id: string;
  student_id: string;
  relationship: string;
}

// Teacher-Batch Assignment
export interface TeacherBatch {
  id: string;
  teacher_id: string;
  batch_id: string;
}

// Report Data (View)
export interface DailyStudentSummary {
  student_id: string;
  log_date: string;
  total_marks: number;
  activities_completed: number;
  batch_id: string;
}

export interface WeeklyLeaderboard {
  student_id: string;
  full_name: string;
  batch_name: string;
  total_marks: number;
  rank: number;
}

export interface AuditLog {
  id: string;
  actor_profile_id?: string | null;
  action: string;
  entity_type: string;
  entity_id?: string | null;
  metadata?: Record<string, unknown>;
  created_at: string;
}

/**
 * Daily Record Types (Phase 1 Ihthisab Model)
 * 
 * Represents a single day's activity tracking for a student
 * Maps to the paper Ihthisab chart (Islamic accountability chart)
 */

export interface DailyRecordItem {
  /**
   * Activity being tracked
   */
  activity_id: string;
  
  /**
   * Selected rating (excellent, satisfactory, needs improvement, not done)
   * Null if activity not completed
   */
  rating_id?: string | null;
  
  /**
   * Quantity (for activities that track volume: pages, minutes, times, etc.)
   */
  quantity?: number;
  
  /**
   * Marks earned based on rating and/or quantity
   * Calculated by scoring service
   */
  marks_earned: number;
  
  /**
   * Optional notes (e.g., "Read Quran with tajweed", "Prayed with concentration")
   */
  notes?: string;
}

export interface DailyRecord {
  /**
   * Unique identifier
   */
  id: string;
  
  /**
   * Student who created this record
   */
  student_id: string;
  
  /**
   * Date of the record (YYYY-MM-DD)
   */
  log_date: string;
  
  /**
   * All activities logged for this day
   * Key: activity_id, Value: DailyRecordItem
   */
  items: Record<string, DailyRecordItem>;
  
  /**
   * Total marks earned for the entire day
   * Sum of all item.marks_earned
   */
  total_marks: number;
  
  /**
   * Number of activities completed (count of non-null rating_ids)
   */
  activities_completed: number;
  
  /**
   * Total number of activities available to complete
   */
  total_activities: number;
  
  /**
   * Completion percentage (activities_completed / total_activities * 100)
   */
  completion_percentage: number;
  
  /**
   * Whether record was submitted/locked (no edits allowed after this)
   */
  is_submitted: boolean;
  
  /**
   * Parent approval status (optional feature)
   */
  parent_approved?: boolean;
  
  /**
   * When the record was submitted
   */
  submitted_at?: string;
  
  /**
   * Timestamps
   */
  created_at: string;
  updated_at: string;
}

/**
 * Activity Score Type
 * Result of scoring calculation
 */
export interface ActivityScore {
  activity_id: string;
  rating_id?: string | null;
  quantity?: number;
  marks: number;
  description: string; // e.g., "Excellent: 10 marks"
}

/**
 * Scoring Rule Type
 * Defines how marks are calculated for an activity
 */
export interface ScoringRule {
  rating_id: string;
  rating_name: string;
  base_marks: number;
  quantity_multiplier?: number; // Marks per unit (e.g., per page)
  max_quantity?: number;        // Maximum quantity bonus
}

/**
 * API Request/Response Types
 */

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

export interface PaginationParams {
  page: number;
  limit: number;
  offset: number;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}
