import { ScoringService, ScoringValidationError } from './scoring-service';

describe('ScoringService', () => {
  const service = new ScoringService();

  it('returns marks from a rating-based activity', () => {
    expect(service.calculateScore({
      activity: {
        id: 'activity-prayer',
        name: 'Subhi',
        has_quantity: false,
      },
      rating: {
        id: 'rating-satisfactory',
        activity_id: 'activity-prayer',
        marks: 5,
        rating_name: 'Satisfactory',
      },
    })).toEqual({
      marks: 5,
      ratingId: 'rating-satisfactory',
      quantity: null,
      source: 'rating',
    });
  });

  it('maps quantity-based activities to the matching quantity rule', () => {
    expect(service.calculateScore({
      activity: {
        id: 'activity-quran',
        name: 'Quran Recitation',
        has_quantity: true,
      },
      quantity: 5,
      scoringRules: [
        {
          id: 'rule-a',
          activity_id: 'activity-quran',
          rule_type: 'quantity',
          min_quantity: 0,
          max_quantity: 1,
          marks: 0,
          display_order: 1,
        },
        {
          id: 'rule-b',
          activity_id: 'activity-quran',
          rule_type: 'quantity',
          min_quantity: 2,
          max_quantity: 4,
          marks: 5,
          display_order: 2,
        },
        {
          id: 'rule-c',
          activity_id: 'activity-quran',
          rule_type: 'quantity',
          min_quantity: 5,
          max_quantity: 10,
          marks: 10,
          display_order: 3,
        },
      ],
    })).toEqual({
      marks: 10,
      ratingId: null,
      quantity: 5,
      source: 'quantity',
    });
  });

  it('rejects a rating that belongs to a different activity', () => {
    expect(() => service.calculateScore({
      activity: {
        id: 'activity-prayer',
        name: 'Subhi',
        has_quantity: false,
      },
      rating: {
        id: 'rating-excellent',
        activity_id: 'other-activity',
        marks: 10,
        rating_name: 'Excellent',
      },
    })).toThrow(ScoringValidationError);
  });
});