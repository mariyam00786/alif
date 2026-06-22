import 'admin_api_client.dart';
import '../model/app_models.dart';
import 'demo_data.dart';

class AdminRepository {
  AdminRepository(this._client);

  final AdminApiClient _client;

  bool get isConfigured => _client.isConfigured;

  Future<AdminAppState> loadState() async {
    if (!_client.isConfigured) {
      return DemoData.buildState();
    }

    final response = await _client.getJson('/api/admin/overview');
    final data = Map<String, dynamic>.from(
      response['data'] as Map<String, dynamic>,
    );

    return AdminAppState(
      students: _parseStudents(data['students'] as List<dynamic>? ?? const []),
      teachers: _parseTeachers(data['teachers'] as List<dynamic>? ?? const []),
      batchClasses: _parseBatches(
        data['batchClasses'] as List<dynamic>? ?? const [],
      ),
      activities: _parseActivities(
        data['activities'] as List<dynamic>? ?? const [],
      ),
      ratingRules: _parseRatingRules(
        data['ratingRules'] as List<dynamic>? ?? const [],
      ),
      reports: _parseReports(data['reports'] as List<dynamic>? ?? const []),
      notifications: _parseNotifications(
        data['notifications'] as List<dynamic>? ?? const [],
      ),
      badges: _parseBadges(data['badges'] as List<dynamic>? ?? const []),
      classes: _parseClassNames(data['classes'] as List<dynamic>? ?? const []),
    );
  }

  Map<String, dynamic> studentPayload(StudentRecord s) => {
    'full_name': s.name,
    'full_name_ml': s.nameMl,
    'parent_phone': s.mobile,
    'email': s.email,
    'father_name': s.fatherName,
    'mother_name': s.motherName,
    'date_of_birth': s.dateOfBirth?.toIso8601String(),
    'gender': s.gender.name,
    'address': s.address,
    'batch': s.batch,
    'status': s.status.name,
    'batch': s.batch,
    'class': s.className,
  };

  Future<String?> createStudent(StudentRecord student) async {
    if (!_client.isConfigured) return null;
    final response = await _client.postJson(
      '/api/students/',
      body: studentPayload(student),
    );
    final loginEmail = response['login_email'];
    return loginEmail is String ? loginEmail : null;
  }

  Future<void> updateStudentRecord(StudentRecord student) async {
    if (!_client.isConfigured) return;
    await _client.putJson(
      '/api/students/${student.id}',
      body: studentPayload(student),
    );
  }

  Future<void> deleteStudentRecord(String studentId) async {
    if (!_client.isConfigured) return;
    await _client.deleteJson('/api/students/$studentId');
  }

  Map<String, dynamic> teacherPayload(TeacherRecord t) => {
    'full_name': t.name,
    'full_name_ml': t.nameMl,
    'phone': t.mobile,
    'email': t.email,
    'qualification': t.qualification,
    'subjects': t.subjects,
    'batches': t.batches,
    'status': t.status.name,
  };

  Future<String?> createTeacher(TeacherRecord teacher) async {
    if (!_client.isConfigured) return null;
    final response = await _client.postJson(
      '/api/teachers/',
      body: teacherPayload(teacher),
    );
    final loginEmail = response['login_email'];
    return loginEmail is String ? loginEmail : null;
  }

  Future<void> updateTeacherRecord(TeacherRecord teacher) async {
    if (!_client.isConfigured) return;
    await _client.putJson(
      '/api/teachers/${teacher.id}',
      body: teacherPayload(teacher),
    );
  }

  Future<void> deleteTeacherRecord(String teacherId) async {
    if (!_client.isConfigured) return;
    await _client.deleteJson('/api/teachers/$teacherId');
  }

  Map<String, dynamic> batchPayload(BatchClassRecord b) => {
    'name': b.name,
    'class_name': b.className,
    'teacher_id': b.teacherId,
    'schedule': b.schedule,
    'capacity': b.capacity,
    'status': b.status.name,
  };

  Future<void> createBatch(BatchClassRecord batch) async {
    if (!_client.isConfigured) return;
    await _client.postJson('/api/admin/batches', body: batchPayload(batch));
  }

  Future<void> updateBatchRecord(BatchClassRecord batch) async {
    if (!_client.isConfigured) return;
    await _client.putJson(
      '/api/admin/batches/${batch.id}',
      body: batchPayload(batch),
    );
  }

  Future<void> deleteBatchRecord(String batchId) async {
    if (!_client.isConfigured) return;
    await _client.deleteJson('/api/admin/batches/$batchId');
  }

  Map<String, dynamic> activityPayload(ActivityRule a) => {
    'name': a.name,
    'name_ml': a.nameMl,
    'category': a.category,
    'points': a.points,
    'has_quantity': a.hasQuantity,
    'status': a.isActive ? 'active' : 'inactive',
  };

  Future<void> createActivity(ActivityRule activity) async {
    if (!_client.isConfigured) return;
    await _client.postJson(
      '/api/activities/items',
      body: activityPayload(activity),
    );
  }

  Future<void> updateActivityRecord(ActivityRule activity) async {
    if (!_client.isConfigured) return;
    await _client.putJson(
      '/api/activities/items/${activity.id}',
      body: activityPayload(activity),
    );
  }

  Future<void> deleteActivityRecord(String activityId) async {
    if (!_client.isConfigured) return;
    await _client.deleteJson('/api/activities/items/$activityId');
  }

  Map<String, dynamic> ratingPayload(RatingRule r) => {
    'label': r.label,
    'label_ml': r.labelMl,
    'min_score': r.minScore,
    'max_score': r.maxScore,
    'color': r.colorName,
    'is_default': r.isDefault,
  };

  Future<void> createRatingRule(RatingRule rule) async {
    if (!_client.isConfigured) return;
    await _client.postJson(
      '/api/admin/rating-rules',
      body: ratingPayload(rule),
    );
  }

  Future<void> updateRatingRule(RatingRule rule) async {
    if (!_client.isConfigured) return;
    await _client.putJson(
      '/api/admin/rating-rules/${rule.id}',
      body: ratingPayload(rule),
    );
  }

  Future<void> deleteRatingRule(String ruleId) async {
    if (!_client.isConfigured) return;
    await _client.deleteJson('/api/admin/rating-rules/$ruleId');
  }

  Map<String, dynamic> notificationPayload(NotificationCampaign n) => {
    'title': n.title,
    'message': n.message,
    'audience': n.audience,
    'scheduled_for': n.scheduledFor,
    'status': n.status.name,
  };

  Future<void> createNotification(NotificationCampaign campaign) async {
    if (!_client.isConfigured) return;
    await _client.postJson(
      '/api/notifications',
      body: notificationPayload(campaign),
    );
  }

  Future<void> updateNotificationRecord(NotificationCampaign campaign) async {
    if (!_client.isConfigured) return;
    await _client.putJson(
      '/api/notifications/${campaign.id}',
      body: notificationPayload(campaign),
    );
  }

  Future<void> deleteNotificationRecord(String notificationId) async {
    if (!_client.isConfigured) return;
    await _client.deleteJson('/api/notifications/$notificationId');
  }

  Map<String, dynamic> badgePayload(BadgeDefinition b) => {
    'name': b.name,
    'name_ml': b.nameMl,
    'criteria': b.criteria,
    'icon': b.icon,
    'bonus_points': b.bonusPoints,
    'status': b.isActive ? 'active' : 'inactive',
  };

  Future<void> createBadge(BadgeDefinition badge) async {
    if (!_client.isConfigured) return;
    await _client.postJson(
      '/api/achievements/badges',
      body: badgePayload(badge),
    );
  }

  Future<void> updateBadgeRecord(BadgeDefinition badge) async {
    if (!_client.isConfigured) return;
    await _client.putJson(
      '/api/achievements/badges/${badge.id}',
      body: badgePayload(badge),
    );
  }

  Future<void> deleteBadgeRecord(String badgeId) async {
    if (!_client.isConfigured) return;
    await _client.deleteJson('/api/achievements/badges/$badgeId');
  }

  List<StudentRecord> _parseStudents(List<dynamic> rows) => rows.map((row) {
    final data = Map<String, dynamic>.from(row as Map);
    return StudentRecord(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? 'Unnamed student',
      nameMl: data['nameMl']?.toString() ?? '',
      mobile:
          data['mobile']?.toString() ?? data['parentPhone']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      fatherName: data['fatherName']?.toString() ?? '',
      motherName: data['motherName']?.toString() ?? '',
      gender: data['gender']?.toString() == 'female'
          ? Gender.female
          : Gender.male,
      batch: data['batch']?.toString() ?? 'Unassigned Batch',
      className:
          data['className']?.toString() ?? data['class']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
      guardianName: data['guardianName']?.toString() ?? '',
      score: (data['score'] as num?)?.toInt() ?? 0,
      streak: (data['streak'] as num?)?.toInt() ?? 0,
      status: _parseRecordStatus(data['status']?.toString()),
    );
  }).toList();

  List<TeacherRecord> _parseTeachers(List<dynamic> rows) => rows.map((row) {
    final data = Map<String, dynamic>.from(row as Map);
    return TeacherRecord(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? 'Unnamed teacher',
      nameMl: data['nameMl']?.toString() ?? '',
      mobile: data['mobile']?.toString() ?? data['phone']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      qualification: data['qualification']?.toString() ?? '',
      subjects:
          (data['subjects'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      batches:
          (data['batches'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      status: _parseRecordStatus(data['status']?.toString()),
    );
  }).toList();

  List<BatchClassRecord> _parseBatches(List<dynamic> rows) => rows.map((row) {
    final data = Map<String, dynamic>.from(row as Map);
    return BatchClassRecord(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? 'Unnamed batch',
      className:
          data['className']?.toString() ?? data['class']?.toString() ?? '',
      teacherId: data['teacherId']?.toString() ?? '',
      teacherName: data['teacherName']?.toString() ?? 'Unassigned Teacher',
      studentCount: (data['studentCount'] as num?)?.toInt() ?? 0,
      schedule: data['schedule']?.toString() ?? 'Schedule not set',
      capacity: (data['capacity'] as num?)?.toInt() ?? 0,
      status: _parseRecordStatus(data['status']?.toString()),
    );
  }).toList();

  List<String> _parseClassNames(List<dynamic> rows) {
    final names = <String>{};
    for (final row in rows) {
      if (row is Map) {
        final name = row['name']?.toString().trim() ?? '';
        if (name.isNotEmpty) names.add(name);
      } else if (row is String && row.trim().isNotEmpty) {
        names.add(row.trim());
      }
    }
    final list = names.toList()..sort();
    return list;
  }

  List<ActivityRule> _parseActivities(List<dynamic> rows) => rows.map((row) {
    final data = Map<String, dynamic>.from(row as Map);
    return ActivityRule(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? 'Unnamed activity',
      nameMl: data['nameMl']?.toString() ?? '',
      category: data['category']?.toString() ?? 'Uncategorized',
      points: (data['points'] as num?)?.toInt() ?? 0,
      hasQuantity: data['hasQuantity'] == true,
      isActive: data['isActive'] == true,
    );
  }).toList();

  List<RatingRule> _parseRatingRules(List<dynamic> rows) => rows.map((row) {
    final data = Map<String, dynamic>.from(row as Map);
    return RatingRule(
      id: data['id']?.toString() ?? '',
      label: data['label']?.toString() ?? 'Rule',
      labelMl: data['labelMl']?.toString() ?? '',
      minScore: (data['minScore'] as num?)?.toInt() ?? 0,
      maxScore: (data['maxScore'] as num?)?.toInt() ?? 0,
      colorName: data['colorName']?.toString() ?? 'Green',
      isDefault: data['isPrimary'] == true || data['isDefault'] == true,
      activityId: data['activityId']?.toString() ?? '',
      activityName: data['activityName']?.toString() ?? '',
    );
  }).toList();

  List<ReportSnapshot> _parseReports(List<dynamic> rows) => rows.map((row) {
    final data = Map<String, dynamic>.from(row as Map);
    return ReportSnapshot(
      title: data['title']?.toString() ?? 'Report',
      value: data['value']?.toString() ?? '0',
      change: data['change']?.toString() ?? '',
      trendLabel: data['trendLabel']?.toString() ?? '',
    );
  }).toList();

  List<NotificationCampaign> _parseNotifications(List<dynamic> rows) =>
      rows.map((row) {
        final data = Map<String, dynamic>.from(row as Map);
        final status = data['status']?.toString() ?? 'draft';
        return NotificationCampaign(
          id: data['id']?.toString() ?? '',
          title: data['title']?.toString() ?? 'Notification',
          message: data['message']?.toString() ?? '',
          audience: data['audience']?.toString() ?? 'All users',
          scheduledFor: data['scheduledFor']?.toString() ?? '',
          status: status == 'sent'
              ? CampaignStatus.sent
              : status == 'scheduled'
              ? CampaignStatus.scheduled
              : CampaignStatus.draft,
        );
      }).toList();

  List<BadgeDefinition> _parseBadges(List<dynamic> rows) => rows.map((row) {
    final data = Map<String, dynamic>.from(row as Map);
    return BadgeDefinition(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? 'Badge',
      nameMl: data['nameMl']?.toString() ?? '',
      criteria: data['criteria']?.toString() ?? 'Criteria not configured',
      icon: data['icon']?.toString() ?? '🏅',
      bonusPoints: (data['bonusPoints'] as num?)?.toInt() ?? 0,
      recipientCount: (data['recipientCount'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] == true || data['isPublished'] == true,
    );
  }).toList();

  RecordStatus _parseRecordStatus(String? value) {
    switch (value) {
      case 'active':
        return RecordStatus.active;
      case 'archived':
        return RecordStatus.archived;
      default:
        return RecordStatus.review;
    }
  }
}
