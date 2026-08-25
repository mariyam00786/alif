"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ScoringService = exports.ScoringValidationError = void 0;
class ScoringValidationError extends Error {
    constructor(message) {
        super(message);
        this.name = 'ScoringValidationError';
    }
}
exports.ScoringValidationError = ScoringValidationError;
class ScoringService {
    calculateScore(context) {
        if (context.activity.has_quantity) {
            return this.calculateQuantityScore(context);
        }
        return this.calculateRatingScore(context);
    }
    calculateRatingScore(context) {
        if (typeof context.quantity !== 'undefined') {
            throw new ScoringValidationError('Rating-based activities do not accept quantity input.');
        }
        if (!context.rating) {
            throw new ScoringValidationError('Rating-based activities require a rating.');
        }
        if (context.rating.activity_id !== context.activity.id) {
            throw new ScoringValidationError('Selected rating does not belong to the requested activity.');
        }
        return {
            marks: context.rating.marks,
            ratingId: context.rating.id,
            quantity: null,
            source: 'rating',
        };
    }
    calculateQuantityScore(context) {
        if (!Number.isInteger(context.quantity) || (context.quantity ?? 0) < 0) {
            throw new ScoringValidationError('Quantity-based activities require a non-negative integer quantity.');
        }
        if (context.rating) {
            throw new ScoringValidationError('Quantity-based activities cannot store a rating selection.');
        }
        const rules = (context.scoringRules ?? [])
            .filter((rule) => rule.rule_type === 'quantity' && rule.activity_id === context.activity.id)
            .sort((left, right) => left.display_order - right.display_order);
        if (rules.length === 0) {
            throw new ScoringValidationError('Quantity-based activities require quantity scoring rules.');
        }
        const matchingRule = rules.find((rule) => {
            const meetsMinimum = (context.quantity ?? 0) >= (rule.min_quantity ?? 0);
            const meetsMaximum = typeof rule.max_quantity === 'number'
                ? (context.quantity ?? 0) <= rule.max_quantity
                : true;
            return meetsMinimum && meetsMaximum;
        });
        if (!matchingRule) {
            throw new ScoringValidationError('No quantity scoring rule matches the provided quantity.');
        }
        return {
            marks: matchingRule.marks,
            ratingId: null,
            quantity: context.quantity ?? null,
            source: 'quantity',
        };
    }
}
exports.ScoringService = ScoringService;
//# sourceMappingURL=scoring-service.js.map