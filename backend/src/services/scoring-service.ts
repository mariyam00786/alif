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
 * Default scoring rules for Phase 1
 * These are fallback values if custom rules are not in database
 */
const DEFAULT_RATING_MARKS: Record<string, number> = {
  excellent: 10,
  satisfactory: 5,
  needsImprovement: 2,
  notDone: 0,
};

/**
 * Rating name mappings (for flexible naming)
 * Maps both English and Malayalam variations
 */
const RATING_NAME_MAPPINGS: Record<string, string> = {
  // English variations
  excellent: 'excellent',
  'very good': 'excellent',
  'very well': 'excellent',
  
  satisfactory: 'satisfactory',
  good: 'satisfactory',
  'well done': 'satisfactory',
  
  'needs improvement': 'needsImprovement',
  'needs work': 'needsImprovement',
  'below target': 'needsImprovement',
  weak: 'needsImprovement',
  
  'not done': 'notDone',
  incomplete: 'notDone',
  'not completed': 'notDone',
  missed: 'notDone',
  
  // Malayalam variations (transliterated)
  uttamam: 'excellent',
  'utthama': 'excellent',
  
  sathanam: 'satisfactory',
  
  sudharithedumo: 'needsImprovement',
  
  cheyathiratheilla: 'notDone',
  'cheyathirathatilla': 'notDone',
};

/**
 * Normalizes rating name to standard form
 * @param ratingName - Raw rating name (any case)
 * @returns Standardized rating key (excellent, satisfactory, needsImprovement, notDone)
 */
function normalizeRatingName(ratingName: string): string {
  const normalized = ratingName.toLowerCase().trim();
  return RATING_NAME_MAPPINGS[normalized] || normalized;
}

/**
 * Validates a rating name against known types
 * @param ratingName - Rating to validate
 * @returns True if rating is valid
 */
export function isValidRating(ratingName: string): boolean {
  const normalized = normalizeRatingName(ratingName);
  return normalized in DEFAULT_RATING_MARKS;
}

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
export function getRatingMarks(
  ratingName: string,
  customRatingMarks?: Record<string, number>
): number {
  const normalized = normalizeRatingName(ratingName);
  
  // Check custom marks first (allows overrides)
  if (customRatingMarks && normalized in customRatingMarks) {
    return customRatingMarks[normalized];
  }
  
  // Fall back to default marks
  if (normalized in DEFAULT_RATING_MARKS) {
    return DEFAULT_RATING_MARKS[normalized as keyof typeof DEFAULT_RATING_MARKS];
  }
  
  // Unknown rating defaults to 0
  console.warn(`Unknown rating type: ${ratingName}. Defaulting to 0 marks.`);
  return 0;
}

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
export function calculateActivityMarks(
  ratingName: string,
  quantity?: number,
  quantityMultiplier?: number,
  maxQuantityBonus?: number,
  customRatingMarks?: Record<string, number>
): number {
  // Get base marks from rating
  const baseMarks = getRatingMarks(ratingName, customRatingMarks);
  
  // If no quantity tracking, return base marks
  if (quantity === undefined || quantity <= 0) {
    return baseMarks;
  }
  
  // Calculate quantity bonus
  const quantityBonus = quantityMultiplier
    ? Math.min(quantity * quantityMultiplier, maxQuantityBonus || quantity * quantityMultiplier)
    : 0;
  
  return baseMarks + quantityBonus;
}

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
export function calculateActivityScore(
  ratingName: string,
  quantity?: number,
  quantityMultiplier?: number,
  maxQuantityBonus?: number,
  customRatingMarks?: Record<string, number>
): ActivityScore {
  const baseMarks = getRatingMarks(ratingName, customRatingMarks);
  let totalMarks = baseMarks;
  let description = `${ratingName}: ${baseMarks} marks`;
  
  // Add quantity bonus if applicable
  if (quantity !== undefined && quantity > 0 && quantityMultiplier) {
    const quantityBonus = Math.min(
      quantity * quantityMultiplier,
      maxQuantityBonus || quantity * quantityMultiplier
    );
    totalMarks += quantityBonus;
    description += ` + ${quantityBonus} quantity bonus (${quantity} × ${quantityMultiplier})`;
  }
  
  description += ` = ${totalMarks} marks`;
  
  return {
    activity_id: '', // Set by caller
    rating_id: undefined, // Set by caller
    quantity,
    marks: totalMarks,
    description,
  };
}

/**
 * Validates scoring rules to ensure consistency
 * 
 * @param rules - Array of scoring rules
 * @returns Validation result with any issues
 */
export function validateScoringRules(rules: ScoringRule[]): {
  valid: boolean;
  errors: string[];
} {
  const errors: string[] = [];
  
  // Check for duplicate rating_ids
  const ratingIds = rules.map(r => r.rating_id);
  const duplicates = ratingIds.filter((id, index) => ratingIds.indexOf(id) !== index);
  if (duplicates.length > 0) {
    errors.push(`Duplicate rating IDs: ${[...new Set(duplicates)].join(', ')}`);
  }
  
  // Check that all rules have valid marks
  rules.forEach((rule, index) => {
    if (typeof rule.base_marks !== 'number' || rule.base_marks < 0) {
      errors.push(`Rule ${index}: Invalid marks value (must be >= 0)`);
    }
    
    if (rule.quantity_multiplier !== undefined && rule.quantity_multiplier < 0) {
      errors.push(`Rule ${index}: Invalid quantity_multiplier (must be >= 0)`);
    }
    
    if (rule.max_quantity !== undefined && rule.max_quantity <= 0) {
      errors.push(`Rule ${index}: Invalid max_quantity (must be > 0)`);
    }
  });
  
  return {
    valid: errors.length === 0,
    errors,
  };
}

/**
 * Calculates daily total marks from multiple activity scores
 * 
 * @param scores - Array of activity scores
 * @returns Sum of all marks
 */
export function calculateDailyTotal(scores: ActivityScore[]): number {
  return scores.reduce((total, score) => total + score.marks, 0);
}

/**
 * Gets scoring statistics for a rating distribution
 * 
 * Useful for understanding how marks are distributed across ratings
 * 
 * @param ratingDistribution - Count of each rating (e.g., { excellent: 5, satisfactory: 3 })
 * @param customRatingMarks - Custom marks (optional)
 * @returns Statistics including total, average, distribution
 */
export function getScoringStatistics(
  ratingDistribution: Record<string, number>,
  customRatingMarks?: Record<string, number>
): {
  totalActivities: number;
  totalPossibleMarks: number;
  totalEarnedMarks: number;
  averageMarks: number;
  distribution: Record<string, { count: number; marks: number }>;
} {
  let totalPossibleMarks = 0;
  let totalEarnedMarks = 0;
  let totalActivities = 0;
  
  const distribution: Record<string, { count: number; marks: number }> = {};
  
  // Calculate for each rating type
  for (const [ratingName, count] of Object.entries(ratingDistribution)) {
    const marks = getRatingMarks(ratingName, customRatingMarks);
    totalActivities += count;
    totalEarnedMarks += marks * count;
    totalPossibleMarks += 10 * count; // Assume max marks is 10
    
    distribution[ratingName] = {
      count,
      marks: marks * count,
    };
  }
  
  return {
    totalActivities,
    totalPossibleMarks,
    totalEarnedMarks,
    averageMarks: totalActivities > 0 ? totalEarnedMarks / totalActivities : 0,
    distribution,
  };
}

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
