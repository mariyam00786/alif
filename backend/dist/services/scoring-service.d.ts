/**
 * Scoring Service
 *
 * Calculates marks earned for activities based on:
 * 1. Rating selected (excellent, satisfactory, needs improvement, not done)
 * 2. Quantity completed (for activities with quantity tracking)
 * 3. Custom scoring rules from database
 *
 * Phase 1 Rules:
 * - Excellent (Excellent): 10 marks
 * - Satisfactory (Good): 5 marks
 * - Needs Improvement: 2 marks
 * - Not Done: 0 marks
 */
import { ActivityScore, ScoringRule } from '../types/database';
/**
 * Validates a rating name against known types
 * @param ratingName - Rating to validate
 * @returns True if rating is valid
 */
export declare function isValidRating(ratingName: string): boolean;
/**
 * Gets base marks for a rating (before quantity bonuses)
 *
 * @param ratingName - Name of the rating (e.g., 'excellent', 'satisfactory')
 * @param customRatingMarks - Optional custom marks mapping from database
 * @returns Base marks for the rating
 *
 * @example
 * getRatingMarks('excellent') // returns 10
 * getRatingMarks('satisfactory') // returns 5
 * getRatingMarks('excellent', { excellent: 15 }) // returns 15 (overridden)
 */
export declare function getRatingMarks(ratingName: string, customRatingMarks?: Record<string, number>): number;
/**
 * Calculates total marks for an activity
 *
 * Marks = base marks from rating + quantity bonus (if applicable)
 *
 * @param ratingName - Rating selected (e.g., 'excellent', 'satisfactory')
 * @param quantity - Optional quantity completed (e.g., pages read, minutes spent)
 * @param quantityMultiplier - Marks per unit of quantity (optional)
 * @param maxQuantityBonus - Maximum bonus marks from quantity (optional)
 * @param customRatingMarks - Custom marks for each rating (from database)
 * @returns Total marks earned
 *
 * @example
 * // Simple rating
 * calculateActivityMarks('excellent') // returns 10
 *
 * // With quantity bonus
 * calculateActivityMarks('satisfactory', 10, 1, 5)
 * // returns 5 (base) + min(10 * 1, 5) = 10 marks
 *
 * // With custom marks
 * calculateActivityMarks('excellent', undefined, undefined, undefined, { excellent: 15 })
 * // returns 15
 */
export declare function calculateActivityMarks(ratingName: string, quantity?: number, quantityMultiplier?: number, maxQuantityBonus?: number, customRatingMarks?: Record<string, number>): number;
/**
 * Calculates marks with full scoring details
 *
 * Returns both the marks and a human-readable description
 *
 * @param ratingName - Rating selected
 * @param quantity - Optional quantity (pages, minutes, etc.)
 * @param quantityMultiplier - Marks per unit
 * @param maxQuantityBonus - Maximum bonus
 * @param customRatingMarks - Custom marks override
 * @returns ActivityScore with marks and description
 *
 * @example
 * const score = calculateActivityScore('excellent', 10, 1, 5);
 * console.log(score.marks); // 15
 * console.log(score.description); // "Excellent (10) + 5 quantity bonus = 15 marks"
 */
export declare function calculateActivityScore(ratingName: string, quantity?: number, quantityMultiplier?: number, maxQuantityBonus?: number, customRatingMarks?: Record<string, number>): ActivityScore;
/**
 * Validates scoring rules to ensure consistency
 *
 * @param rules - Array of scoring rules
 * @returns Validation result with any issues
 */
export declare function validateScoringRules(rules: ScoringRule[]): {
    valid: boolean;
    errors: string[];
};
/**
 * Calculates daily total marks from multiple activity scores
 *
 * @param scores - Array of activity scores
 * @returns Sum of all marks
 */
export declare function calculateDailyTotal(scores: ActivityScore[]): number;
/**
 * Gets scoring statistics for a rating distribution
 *
 * Useful for understanding how marks are distributed across ratings
 *
 * @param ratingDistribution - Count of each rating (e.g., { excellent: 5, satisfactory: 3 })
 * @param customRatingMarks - Custom marks (optional)
 * @returns Statistics including total, average, distribution
 */
export declare function getScoringStatistics(ratingDistribution: Record<string, number>, customRatingMarks?: Record<string, number>): {
    totalActivities: number;
    totalPossibleMarks: number;
    totalEarnedMarks: number;
    averageMarks: number;
    distribution: Record<string, {
        count: number;
        marks: number;
    }>;
};
/**
 * Phase 1 Scoring Summary
 *
 * ============================================
 * Default Marks System
 * ============================================
 * Excellent (✓✓)        = 10 marks
 * Satisfactory (✓)      = 5 marks
 * Needs Improvement (△) = 2 marks
 * Not Done (✗)          = 0 marks
 *
 * ============================================
 * Quantity Bonus (Optional)
 * ============================================
 * For activities with quantity tracking:
 * - Multiplier: X marks per unit (e.g., 0.5 marks per page)
 * - Max Bonus: Cap total bonus (e.g., max 5 bonus marks)
 *
 * Example: Reading 10 pages with 0.5 multiplier and 5 max bonus
 * Excellent rating: 10 + min(10 × 0.5, 5) = 15 marks
 *
 * ============================================
 * Customization
 * ============================================
 * Admin can override marks in database
 * Custom rules are loaded and applied per activity
 * Falls back to defaults if custom rules not found
 */
//# sourceMappingURL=scoring-service.d.ts.map