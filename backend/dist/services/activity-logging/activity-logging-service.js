"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ActivityLoggingService = void 0;
const scoring_service_1 = require("../scoring/scoring-service");
class ActivityLoggingService {
    constructor(scoringService = new scoring_service_1.ScoringService()) {
        this.scoringService = scoringService;
    }
    buildLogEntry(input) {
        if (input.draft.activityId !== input.activity.id) {
            throw new Error('Draft activity and loaded activity do not match.');
        }
        const calculatedScore = this.scoringService.calculateScore({
            activity: input.activity,
            rating: input.rating,
            scoringRules: input.scoringRules,
            quantity: input.draft.quantity,
        });
        return {
            student_id: input.draft.studentId,
            activity_id: input.draft.activityId,
            rating_id: calculatedScore.ratingId,
            log_date: input.draft.logDate,
            quantity: calculatedScore.quantity,
            marks_earned: calculatedScore.marks,
            parent_approved: input.draft.parentApproved ?? false,
            notes: input.draft.notes ?? null,
        };
    }
}
exports.ActivityLoggingService = ActivityLoggingService;
//# sourceMappingURL=activity-logging-service.js.map