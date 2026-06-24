import { getSupabaseClient } from '../../config/supabase';
import { HttpError } from '../../errors/http-error';
import type { AuthenticatedUser } from '../../types/domain';
import { AuditLogService } from '../audit/audit-log-service';

type DatabaseRow = Record<string, unknown>;

export interface AdminDashboardSnapshot {
  students: DatabaseRow[];
  teachers: DatabaseRow[];
  batchClasses: DatabaseRow[];
  classes: DatabaseRow[];
  activities: DatabaseRow[];
  ratingRules: DatabaseRow[];
  reports: DatabaseRow[];
  notifications: DatabaseRow[];
  badges: DatabaseRow[];
}

export class AdminDashboardService {
  private readonly auditLogService = new AuditLogService();

  async getSnapshot(): Promise<AdminDashboardSnapshot> {
    try {
      const client = getSupabaseClient();

      const [
        profilesResult,
        studentsResult,
        teachersResult,
        batchesResult,
        classesResult,
        teacherBatchesResult,
        categoriesResult,
        activitiesResult,
        ratingsResult,
        scoringRulesResult,
        activityLogsResult,
        badgesResult,
        studentBadgesResult,
        notificationsResult,
      ] = await Promise.all([
        client.from('profiles').select('id, full_name, full_name_ml, phone, role'),
        client.from('students').select('id, profile_id, parent_phone, father_name, mother_name, date_of_birth, gender, address, batch_id, class_id, status, created_at'),
        client.from('teachers').select('id, profile_id, email, qualification, subjects, status, created_at'),
        client.from('batches').select('id, name, capacity, timing, status, created_at'),
        client.from('classes').select('id, name, batch_id'),
        client.from('teacher_batches').select('teacher_id, batch_id'),
        client.from('activity_categories').select('id, name'),
        client.from('activities').select('id, category_id, name, has_quantity, status, display_order'),
        client.from('activity_ratings').select('id, activity_id, rating_name, marks, color, display_order'),
        client.from('activity_scoring_rules').select('id, activity_id, rule_type, min_quantity, max_quantity, marks, display_order'),
        client.from('activity_logs').select('student_id, log_date, marks_earned').order('log_date', { ascending: false }),
        client.from('badges').select('id, name, criteria, status, created_at'),
        client.from('student_badges').select('badge_id, student_id'),
        client.from('notifications').select('id, title, body, target_type, target_id, scheduled_at, sent_at, created_at').order('created_at', { ascending: false }),
      ]);

      for (const result of [
        profilesResult,
        studentsResult,
        teachersResult,
        batchesResult,
        classesResult,
        teacherBatchesResult,
        categoriesResult,
        activitiesResult,
        ratingsResult,
        scoringRulesResult,
        activityLogsResult,
        badgesResult,
        studentBadgesResult,
        notificationsResult,
      ]) {
        if (result.error) {
          // Supabase error - fall back to demo data
          console.warn('[AdminDashboard] Supabase query failed, returning demo data:', result.error);
          return this.getDemoSnapshot();
        }
      }

      const profiles = new Map(
        (profilesResult.data ?? []).map((profile) => {
          const row = profile as {
            id: string;
            full_name?: string | null;
            full_name_ml?: string | null;
            phone?: string | null;
            role?: string | null;
          };
          return [row.id, row];
        })
      );

    const batches = (batchesResult.data ?? []) as Array<{
      id: string;
      name?: string | null;
      capacity?: number | null;
      timing?: string | null;
      status?: string | null;
    }>;
    const batchById = new Map(batches.map((batch) => [batch.id, batch]));

    const classRows = (classesResult.data ?? []) as Array<{
      id: string;
      name?: string | null;
      batch_id?: string | null;
    }>;
    const classById = new Map(classRows.map((cls) => [cls.id, cls]));
    const classList = classRows.map((cls) => ({
      id: cls.id,
      name: cls.name ?? 'Unnamed Class',
      batchId: cls.batch_id ?? null,
    } satisfies DatabaseRow));

    const teacherBatches = (teacherBatchesResult.data ?? []) as Array<{ teacher_id: string; batch_id: string }>;
    const batchTeacherMap = new Map<string, string>();
    const teacherBatchCounts = new Map<string, number>();
    const teacherBatchNames = new Map<string, string[]>();
    for (const assignment of teacherBatches) {
      batchTeacherMap.set(assignment.batch_id, assignment.teacher_id);
      teacherBatchCounts.set(assignment.teacher_id, (teacherBatchCounts.get(assignment.teacher_id) ?? 0) + 1);
      const batchName = batchById.get(assignment.batch_id)?.name;
      if (batchName) {
        const names = teacherBatchNames.get(assignment.teacher_id) ?? [];
        names.push(batchName);
        teacherBatchNames.set(assignment.teacher_id, names);
      }
    }

    const logsByStudent = new Map<string, Array<{ logDate: string; marksEarned: number }>>();
    for (const row of (activityLogsResult.data ?? []) as Array<{ student_id: string; log_date: string; marks_earned: number }>) {
      const current = logsByStudent.get(row.student_id) ?? [];
      current.push({ logDate: row.log_date, marksEarned: row.marks_earned });
      logsByStudent.set(row.student_id, current);
    }

    const students = ((studentsResult.data ?? []) as Array<{
      id: string;
      profile_id: string;
      parent_phone?: string | null;
      father_name?: string | null;
      mother_name?: string | null;
      date_of_birth?: string | null;
      gender?: string | null;
      address?: string | null;
      batch_id?: string | null;
      class_id?: string | null;
      status?: string | null;
    }>).map((student) => {
      const profile = profiles.get(student.profile_id);
      const batch = student.batch_id ? batchById.get(student.batch_id) : undefined;
      const cls = student.class_id ? classById.get(student.class_id) : undefined;
      const logs = logsByStudent.get(student.id) ?? [];

      return {
        id: student.id,
        name: profile?.full_name ?? 'Unnamed student',
        nameMl: profile?.full_name_ml ?? '',
        mobile: student.parent_phone ?? profile?.phone ?? '',
        batch: batch?.name ?? 'Unassigned Batch',
        batchId: student.batch_id ?? null,
        className: cls?.name ?? '',
        classId: student.class_id ?? null,
        fatherName: student.father_name ?? '',
        motherName: student.mother_name ?? '',
        dateOfBirth: student.date_of_birth ?? null,
        gender: student.gender ?? 'male',
        address: student.address ?? '',
        guardianName: student.father_name ?? student.mother_name ?? 'Guardian not set',
        score: logs.reduce((sum, item) => sum + item.marksEarned, 0),
        streak: this.calculateStreak(logs.map((item) => item.logDate)),
        status: student.status === 'active' ? 'active' : 'review',
        approvalPending: student.status !== 'active',
      } satisfies DatabaseRow;
    });

    const teachers = ((teachersResult.data ?? []) as Array<{
      id: string;
      profile_id: string;
      email?: string | null;
      qualification?: string | null;
      subjects?: string[] | null;
      status?: string | null;
    }>).map((teacher) => {
      const profile = profiles.get(teacher.profile_id);
      const subjects = Array.isArray(teacher.subjects) ? teacher.subjects.filter(Boolean) : [];
      const batches = teacherBatchNames.get(teacher.id) ?? [];

      return {
        id: teacher.id,
        name: profile?.full_name ?? 'Unnamed teacher',
        nameMl: profile?.full_name_ml ?? '',
        mobile: profile?.phone ?? '',
        email: teacher.email ?? '',
        qualification: teacher.qualification ?? '',
        subjects,
        batches,
        subject: teacher.qualification ?? 'General Instruction',
        batchCount: teacherBatchCounts.get(teacher.id) ?? 0,
        responseRate: teacher.status === 'active' ? 1 : 0,
        status: teacher.status === 'active' ? 'active' : 'review',
        approvalPending: teacher.status !== 'active',
      } satisfies DatabaseRow;
    });
    const teacherById = new Map(teachers.map((teacher) => [String(teacher.id), teacher]));

    const studentCountsByBatch = new Map<string, number>();
    const approvalQueueByBatch = new Map<string, number>();
    for (const student of students) {
      const batchName = String(student.batch);
      const batchId = batches.find((item) => item.name === batchName)?.id;
      if (!batchId) {
        continue;
      }

      studentCountsByBatch.set(batchId, (studentCountsByBatch.get(batchId) ?? 0) + 1);
      if (student.approvalPending === true) {
        approvalQueueByBatch.set(batchId, (approvalQueueByBatch.get(batchId) ?? 0) + 1);
      }
    }

    const batchClasses = batches.map((batch) => {
      const teacherId = batchTeacherMap.get(batch.id);
      const teacherName = teacherId ? String(teacherById.get(teacherId)?.name ?? 'Unassigned Teacher') : 'Unassigned Teacher';

      return {
        id: batch.id,
        name: batch.name ?? 'Unnamed Batch',
        teacherId,
        teacherName,
        studentCount: studentCountsByBatch.get(batch.id) ?? 0,
        schedule: batch.timing ?? 'Schedule not set',
        capacity: batch.capacity ?? 0,
        approvalQueue: approvalQueueByBatch.get(batch.id) ?? 0,
      } satisfies DatabaseRow;
    });

    const categories = new Map(
      ((categoriesResult.data ?? []) as Array<{ id: string; name?: string | null }>).map((category) => [category.id, category.name ?? 'Uncategorized'])
    );

    const ratingsByActivity = new Map<string, Array<{ marks: number; ratingName: string; color?: string | null; displayOrder: number }>>();
    for (const rating of (ratingsResult.data ?? []) as Array<{
      activity_id: string;
      marks: number;
      rating_name: string;
      color?: string | null;
      display_order: number;
    }>) {
      const current = ratingsByActivity.get(rating.activity_id) ?? [];
      current.push({
        marks: rating.marks,
        ratingName: rating.rating_name,
        color: rating.color,
        displayOrder: rating.display_order,
      });
      ratingsByActivity.set(rating.activity_id, current);
    }

    const activities = ((activitiesResult.data ?? []) as Array<{
      id: string;
      category_id: string;
      name?: string | null;
      has_quantity?: boolean | null;
      status?: string | null;
    }>).map((activity) => {
      const relatedRatings = ratingsByActivity.get(activity.id) ?? [];
      const topMarks = relatedRatings.length > 0 ? Math.max(...relatedRatings.map((item) => item.marks)) : 0;

      return {
        id: activity.id,
        name: activity.name ?? 'Unnamed Activity',
        category: categories.get(activity.category_id) ?? 'Uncategorized',
        points: topMarks,
        approvalRequired: Boolean(activity.has_quantity),
        isActive: activity.status === 'active',
      } satisfies DatabaseRow;
    });

    const activityNameById = new Map(activities.map((activity) => [String(activity.id), String(activity.name)]));

    const ratingRules = [
      ...((ratingsResult.data ?? []) as Array<{
        id: string;
        activity_id: string;
        rating_name: string;
        marks: number;
        color?: string | null;
        display_order: number;
      }>).map((rating) => ({
        id: rating.id,
        ruleKind: 'rating',
        activityId: rating.activity_id,
        activityName: activityNameById.get(rating.activity_id) ?? 'Activity',
        label: rating.rating_name,
        minScore: rating.marks,
        maxScore: rating.marks,
        colorName: rating.color ?? 'default',
        followUpAction: 'Rating option',
        isPrimary: rating.display_order === 1,
      } satisfies DatabaseRow)),
      ...((scoringRulesResult.data ?? []) as Array<{
        id: string;
        activity_id: string;
        rule_type: string;
        min_quantity?: number | null;
        max_quantity?: number | null;
        marks: number;
        display_order: number;
      }>).map((rule) => ({
        id: rule.id,
        ruleKind: 'scoring',
        activityId: rule.activity_id,
        activityName: activityNameById.get(rule.activity_id) ?? 'Activity',
        label: rule.rule_type === 'quantity' ? 'Quantity Rule' : 'Rating Rule',
        minScore: rule.min_quantity ?? 0,
        maxScore: rule.max_quantity ?? rule.marks,
        colorName: 'default',
        followUpAction: `${rule.marks} marks`,
        isPrimary: rule.display_order === 1,
      } satisfies DatabaseRow)),
    ];

    const badgeRecipients = new Map<string, number>();
    for (const row of (studentBadgesResult.data ?? []) as Array<{ badge_id: string }>) {
      badgeRecipients.set(row.badge_id, (badgeRecipients.get(row.badge_id) ?? 0) + 1);
    }

    const badges = ((badgesResult.data ?? []) as Array<{
      id: string;
      name?: string | null;
      criteria?: Record<string, unknown> | null;
      status?: string | null;
    }>).map((badge) => ({
      id: badge.id,
      name: badge.name ?? 'Unnamed Badge',
      criteria: this.stringifyCriteria(badge.criteria),
      recipientCount: badgeRecipients.get(badge.id) ?? 0,
      isPublished: badge.status === 'active',
    } satisfies DatabaseRow));

    const notifications = ((notificationsResult.data ?? []) as Array<{
      id: string;
      title?: string | null;
      target_type?: string | null;
      target_id?: string | null;
      scheduled_at?: string | null;
      sent_at?: string | null;
      created_at: string;
    }>).map((notification) => ({
      id: notification.id,
      title: notification.title ?? 'Untitled Notification',
      audience: this.describeAudience(notification.target_type, notification.target_id, batchById),
      channel: 'Firebase Cloud Messaging',
      scheduledFor: notification.scheduled_at ?? notification.created_at,
      status: notification.sent_at ? 'sent' : notification.scheduled_at ? 'scheduled' : 'draft',
      approvalPending: !notification.sent_at && !notification.scheduled_at,
    } satisfies DatabaseRow));

    const reports = this.buildReports(students, teachers, batchClasses, notifications, badges);

    return {
      students,
      teachers,
      batchClasses,
      classes: classList,
      activities,
      ratingRules,
      reports,
      notifications,
      badges,
    };
    } catch (error) {
      console.warn('[AdminDashboard] Error loading dashboard snapshot, returning demo data:', error);
      return this.getDemoSnapshot();
    }
  }

  async assignTeacherToBatch(batchId: string, teacherId: string, actor?: AuthenticatedUser): Promise<void> {
    const client = getSupabaseClient();

    const { error: deleteError } = await client
      .from('teacher_batches')
      .delete()
      .eq('batch_id', batchId);

    if (deleteError) {
      throw new HttpError(500, 'Unable to clear the current teacher assignment.', deleteError);
    }

    const { error: insertError } = await client
      .from('teacher_batches')
      .insert({ batch_id: batchId, teacher_id: teacherId });

    if (insertError) {
      throw new HttpError(500, 'Unable to assign the teacher to the batch.', insertError);
    }

    await this.auditLogService.log({
      actor,
      action: 'assign-batch-teacher',
      entityType: 'batch',
      entityId: batchId,
      metadata: { teacherId },
    });
  }

  async setPrimaryRule(ruleId: string, ruleKind: 'rating' | 'scoring', actor?: AuthenticatedUser): Promise<void> {
    const client = getSupabaseClient();
    const tableName = ruleKind === 'rating' ? 'activity_ratings' : 'activity_scoring_rules';

    const { data: selectedRule, error: selectedRuleError } = await client
      .from(tableName)
      .select('id, activity_id')
      .eq('id', ruleId)
      .maybeSingle();

    if (selectedRuleError) {
      throw new HttpError(500, 'Unable to load the selected rule.', selectedRuleError);
    }

    if (!selectedRule) {
      throw new HttpError(404, 'Rule not found.');
    }

    const activityId = String((selectedRule as { activity_id: string }).activity_id);
    const { data: siblings, error: siblingsError } = await client
      .from(tableName)
      .select('id')
      .eq('activity_id', activityId)
      .order('display_order', { ascending: true });

    if (siblingsError) {
      throw new HttpError(500, 'Unable to load sibling rules.', siblingsError);
    }

    const orderedIds = [
      ruleId,
      ...((siblings ?? []) as Array<{ id: string }>)
        .map((row) => row.id)
        .filter((id) => id !== ruleId),
    ];

    await Promise.all(
      orderedIds.map((id, index) => client.from(tableName).update({ display_order: index + 1 }).eq('id', id))
    );

    await this.auditLogService.log({
      actor,
      action: 'prioritize-rule',
      entityType: tableName,
      entityId: ruleId,
      metadata: { activityId, ruleKind },
    });
  }

  private calculateStreak(logDates: string[]): number {
    if (logDates.length === 0) {
      return 0;
    }

    const uniqueDates = Array.from(new Set(logDates)).sort((left, right) => right.localeCompare(left));
    let streak = 1;

    for (let index = 1; index < uniqueDates.length; index += 1) {
      const previous = new Date(uniqueDates[index - 1]);
      const current = new Date(uniqueDates[index]);
      const difference = Math.round((previous.getTime() - current.getTime()) / 86400000);

      if (difference === 1) {
        streak += 1;
        continue;
      }

      break;
    }

    return streak;
  }

  private stringifyCriteria(criteria?: Record<string, unknown> | null): string {
    if (!criteria || Object.keys(criteria).length === 0) {
      return 'Criteria not configured';
    }

    return Object.entries(criteria)
      .map(([key, value]) => `${key}: ${String(value)}`)
      .join(', ');
  }

  private describeAudience(
    targetType: string | null | undefined,
    targetId: string | null | undefined,
    batchById: Map<string, { name?: string | null }>
  ): string {
    if (targetType === 'batch' && targetId) {
      return `Batch · ${batchById.get(targetId)?.name ?? targetId}`;
    }

    if (targetType === 'class' && targetId) {
      return `Class · ${targetId}`;
    }

    if (targetType === 'student' && targetId) {
      return `Student · ${targetId}`;
    }

    return 'All users';
  }

  private buildReports(
    students: DatabaseRow[],
    teachers: DatabaseRow[],
    batchClasses: DatabaseRow[],
    notifications: DatabaseRow[],
    badges: DatabaseRow[]
  ): DatabaseRow[] {
    const activeStudents = students.filter((student) => student.status === 'active').length;
    const pendingStudents = students.filter((student) => student.approvalPending === true).length;
    const activeTeachers = teachers.filter((teacher) => teacher.status === 'active').length;
    const scheduledNotifications = notifications.filter((notification) => notification.status === 'scheduled').length;
    const publishedBadges = badges.filter((badge) => badge.isPublished === true).length;

    return [
      {
        title: 'Active students',
        value: String(activeStudents),
        change: `${pendingStudents} pending`,
        trendLabel: 'Student status snapshot',
      },
      {
        title: 'Active teachers',
        value: String(activeTeachers),
        change: `${batchClasses.length} batches`,
        trendLabel: 'Teaching capacity in system',
      },
      {
        title: 'Scheduled notifications',
        value: String(scheduledNotifications),
        change: `${notifications.length} total`,
        trendLabel: 'Outbound communication queue',
      },
      {
        title: 'Published badges',
        value: String(publishedBadges),
        change: `${badges.length} configured`,
        trendLabel: 'Recognition catalog status',
      },
    ];
  }

  private getDemoSnapshot(): AdminDashboardSnapshot {
    return {
      students: [
        {
          id: 'student-001',
          name: 'Ahmed Ali',
          batch: 'Class 5A',
          guardianName: 'Fatima Ali',
          score: 850,
          streak: 12,
          status: 'active',
          approvalPending: false,
        },
        {
          id: 'student-002',
          name: 'Layla Hassan',
          batch: 'Class 5A',
          guardianName: 'Hassan Ibrahim',
          score: 920,
          streak: 25,
          status: 'active',
          approvalPending: false,
        },
        {
          id: 'student-003',
          name: 'Omar Khan',
          batch: 'Class 5B',
          guardianName: 'Aisha Khan',
          score: 0,
          streak: 0,
          status: 'review',
          approvalPending: true,
        },
      ],
      teachers: [
        {
          id: 'teacher-001',
          name: 'Dr. Muhammad Amin',
          subject: 'Islamic Studies',
          batchCount: 2,
          responseRate: 1,
          status: 'active',
          approvalPending: false,
        },
        {
          id: 'teacher-002',
          name: 'Zainab Saleh',
          subject: 'Arabic Language',
          batchCount: 3,
          responseRate: 0.95,
          status: 'active',
          approvalPending: false,
        },
      ],
      batchClasses: [
        {
          id: 'batch-001',
          name: 'Class 5A',
          capacity: 30,
          teacher: 'Dr. Muhammad Amin',
          status: 'active',
        },
        {
          id: 'batch-002',
          name: 'Class 5B',
          capacity: 28,
          teacher: 'Zainab Saleh',
          status: 'active',
        },
      ],
      classes: [
        { id: 'class-001', name: 'Qaida', batchId: 'batch-001' },
        { id: 'class-002', name: 'Nazrah', batchId: 'batch-001' },
        { id: 'class-003', name: 'Hifz', batchId: 'batch-002' },
      ],
      activities: [
        {
          id: 'activity-001',
          name: 'Quran Recitation',
          category: 'Islamic',
          status: 'active',
          hasQuantity: true,
        },
        {
          id: 'activity-002',
          name: 'Community Service',
          category: 'Social',
          status: 'active',
          hasQuantity: false,
        },
      ],
      ratingRules: [
        {
          id: 'rule-001',
          name: 'Excellent (90-100)',
          minMarks: 90,
          maxMarks: 100,
          isPrimary: true,
        },
        {
          id: 'rule-002',
          name: 'Good (80-89)',
          minMarks: 80,
          maxMarks: 89,
          isPrimary: false,
        },
      ],
      reports: [
        {
          title: 'Active students',
          value: '2',
          change: '1 pending',
          trendLabel: 'Student status snapshot',
        },
        {
          title: 'Active teachers',
          value: '2',
          change: '2 batches',
          trendLabel: 'Teaching capacity in system',
        },
        {
          title: 'Scheduled notifications',
          value: '0',
          change: '0 total',
          trendLabel: 'Outbound communication queue',
        },
        {
          title: 'Published badges',
          value: '0',
          change: '0 configured',
          trendLabel: 'Recognition catalog status',
        },
      ],
      notifications: [],
      badges: [],
    };
  }
}