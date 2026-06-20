"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ActivityScoringRuleService = exports.ActivityRatingService = exports.ActivityService = exports.ActivityCategoryService = void 0;
const base_resource_service_1 = require("../shared/base-resource-service");
class ActivityCategoryService extends base_resource_service_1.BaseResourceService {
    constructor() {
        super('activity_categories', 'activity category');
    }
}
exports.ActivityCategoryService = ActivityCategoryService;
class ActivityService extends base_resource_service_1.BaseResourceService {
    constructor() {
        super('activities', 'activity');
    }
}
exports.ActivityService = ActivityService;
class ActivityRatingService extends base_resource_service_1.BaseResourceService {
    constructor() {
        super('activity_ratings', 'activity rating');
    }
}
exports.ActivityRatingService = ActivityRatingService;
class ActivityScoringRuleService extends base_resource_service_1.BaseResourceService {
    constructor() {
        super('activity_scoring_rules', 'activity scoring rule');
    }
}
exports.ActivityScoringRuleService = ActivityScoringRuleService;
//# sourceMappingURL=activity-catalog-service.js.map