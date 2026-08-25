import { ActivityLoggingService } from './activity-logging-service';
import { ScoringService, ScoringValidationError } from '../scoring/scoring-service';

describe('ActivityLoggingService', () => {
  const service = new ActivityLoggingService(new ScoringService());

  it('builds a rating-based log entry with the selected rating marks', () => {
    const entry = service.buildLogEntry({
      draft: {
        studentId: 'student-1',
        activityId: 'activity-prayer',
        logDate: '2026-06-18',
        ratingId: 'rating-excellent',
        notes: 'Completed on time',
      },
      activity: {
        id: 'activity-prayer',
        name: 'Subhi',
        has_quantity: false,
      },
      rating: {
        id: 'rating-excellent',
        activity_id: 'activity-prayer',
        marks: 10,
        rating_name: 'Excellent',
      },
    });

    expect(entry).toEqual({
      student_id: 'student-1',
      activity_id: 'activity-prayer',
      rating_id: 'rating-excellent',
      log_date: '2026-06-18',
      quantity: null,
      marks_earned: 10,
      parent_approved: false,
      notes: 'Completed on time',
    });
  });

  it('builds a quantity-based log entry from quantity bands without a rating id', () => {
    const entry = service.buildLogEntry({
      draft: {
        studentId: 'student-2',
        activityId: 'activity-quran',
        logDate: '2026-06-18',
        quantity: 6,
      },
      activity: {
        id: 'activity-quran',
        name: 'Quran Recitation',
        has_quantity: true,
      },
      scoringRules: [
        {
          id: 'rule-1',
          activity_id: 'activity-quran',
          rule_type: 'quantity',
          min_quantity: 0,
          max_quantity: 1,
          marks: 0,
          display_order: 1,
        },
        {
          id: 'rule-2',
          activity_id: 'activity-quran',
          rule_type: 'quantity',
          min_quantity: 2,
          max_quantity: 4,
          marks: 5,
          display_order: 2,
        },
        {
          id: 'rule-3',
          activity_id: 'activity-quran',
          rule_type: 'quantity',
          min_quantity: 5,
          max_quantity: 9,
          marks: 10,
          display_order: 3,
        },
      ],
    });

    expect(entry).toEqual({
      student_id: 'student-2',
      activity_id: 'activity-quran',
      rating_id: null,
      log_date: '2026-06-18',
      quantity: 6,
      marks_earned: 10,
      parent_approved: false,
      notes: null,
    });
  });

  it('rejects a quantity-based activity when no quantity rule matches', () => {
    expect(() => service.buildLogEntry({
      draft: {
        studentId: 'student-2',
        activityId: 'activity-quran',
        logDate: '2026-06-18',
        quantity: 12,
      },
      activity: {
        id: 'activity-quran',
        name: 'Quran Recitation',
        has_quantity: true,
      },
      scoringRules: [
        {
          id: 'rule-2',
          activity_id: 'activity-quran',
          rule_type: 'quantity',
          min_quantity: 2,
          max_quantity: 4,
          marks: 5,
          display_order: 2,
        },
      ],
    })).toThrow(ScoringValidationError);
  });
});