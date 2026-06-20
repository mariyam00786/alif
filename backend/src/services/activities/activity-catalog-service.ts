import { BaseResourceService } from '../shared/base-resource-service';

export class ActivityCategoryService extends BaseResourceService {
  constructor() {
    super('activity_categories', 'activity category');
  }
}

export class ActivityService extends BaseResourceService {
  constructor() {
    super('activities', 'activity');
  }
}

export class ActivityRatingService extends BaseResourceService {
  constructor() {
    super('activity_ratings', 'activity rating');
  }
}

export class ActivityScoringRuleService extends BaseResourceService {
  constructor() {
    super('activity_scoring_rules', 'activity scoring rule');
  }
}