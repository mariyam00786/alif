/**
 * Activity Master Service
 *
 * Manages the master data for activities:
 * - Activity categories (Prayer, Quran, Sunnah, etc.)
 * - Activities within categories (Subhi, Zuhr, Quran Reading, etc.)
 * - Rating options for each activity (Excellent, Satisfactory, etc.)
 *
 * Includes caching with TTL (Time To Live) for performance
 */
import { ActivityCategory, Activity, ActivityRating } from '../types/database';
/**
 * Clears all cache
 */
export declare function clearAllCache(): void;
/**
 * Gets cache statistics (for monitoring)
 */
export declare function getCacheStats(): {
    size: number;
    entries: string[];
};
/**
 * Gets all active categories
 *
 * Results are cached for 5 minutes
 *
 * @returns Array of activity categories sorted by display order
 *
 * @example
 * const categories = await getCategories();
 * // [
 * //   { id: 'cat-prayer', name: 'Salah', ... },
 * //   { id: 'cat-quran', name: 'Quran', ... }
 * // ]
 */
export declare function getCategories(): Promise<ActivityCategory[]>;
/**
 * Gets all activities in a category
 *
 * Results are cached per category for 5 minutes
 *
 * @param categoryId - Category ID to fetch activities for
 * @returns Array of activities sorted by display order
 *
 * @example
 * const activities = await getActivitiesByCategory('cat-prayer');
 * // [{ id: 'act-subhi', name: 'Subhi Prayer', ... }, ...]
 */
export declare function getActivitiesByCategory(categoryId: string): Promise<Activity[]>;
/**
 * Gets all activities across all categories (flattened)
 *
 * @returns Array of all activities sorted by category then display order
 */
export declare function getAllActivities(): Promise<Activity[]>;
/**
 * Gets rating options for an activity
 *
 * Results are cached per activity for 5 minutes
 *
 * @param activityId - Activity ID
 * @returns Array of rating options sorted by display order
 *
 * @example
 * const ratings = await getRatings('act-subhi');
 * // [
 * //   { id: 'rating-excellent', rating_name: 'Excellent', marks: 10 },
 * //   { id: 'rating-satisfactory', rating_name: 'Satisfactory', marks: 5 },
 * //   ...
 * // ]
 */
export declare function getRatings(activityId: string): Promise<ActivityRating[]>;
/**
 * Gets all ratings across all activities
 *
 * @returns Array of all ratings (may have duplicates if ratings are shared)
 */
export declare function getAllRatings(): Promise<ActivityRating[]>;
/**
 * Gets a specific category by ID
 *
 * @param categoryId - Category ID
 * @returns Category object or null if not found
 */
export declare function getCategoryById(categoryId: string): Promise<ActivityCategory | null>;
/**
 * Gets a specific activity by ID
 *
 * @param activityId - Activity ID
 * @returns Activity object or null if not found
 */
export declare function getActivityById(activityId: string): Promise<Activity | null>;
/**
 * Gets a specific rating by ID
 *
 * @param ratingId - Rating ID
 * @returns Rating object or null if not found
 */
export declare function getRatingById(ratingId: string): Promise<ActivityRating | null>;
/**
 * Builds the complete activity structure for a day
 *
 * Returns categories with nested activities and ratings
 * Used for daily marking screens
 *
 * @returns Complete structure ready for UI rendering
 *
 * @example
 * const structure = await getBuildDailyActivityStructure();
 * // {
 * //   categories: [
 * //     {
 * //       id: 'cat-prayer',
 * //       name: 'Salah',
 * //       activities: [
 * //         {
 * //           id: 'act-subhi',
 * //           name: 'Subhi Prayer',
 * //           ratings: [
 * //             { id: 'rating-excellent', name: 'Excellent', marks: 10 },
 * //             ...
 * //           ]
 * //         },
 * //         ...
 * //       ]
 * //     },
 * //     ...
 * //   ]
 * // }
 */
export declare function buildDailyActivityStructure(): Promise<{
    categories: Array<{
        id: string;
        name: string;
        name_ml?: string;
        icon?: string;
        activities: Array<{
            id: string;
            name: string;
            name_ml?: string;
            has_quantity: boolean;
            ratings: ActivityRating[];
        }>;
    }>;
}>;
/**
 * Invalidates cache for a specific category
 * Use after updating categories
 */
export declare function invalidateCategoryCache(categoryId?: string): void;
/**
 * Invalidates cache for a specific activity
 * Use after updating activities
 */
export declare function invalidateActivityCache(activityId: string): void;
/**
 * Activity Master Service Summary
 *
 * ============================================
 * Responsibilities
 * ============================================
 * - Provide master data (categories, activities, ratings)
 * - Cache with 5-minute TTL
 * - Support queries at different levels (all, by category, by ID)
 * - Build complete structure for daily marking
 *
 * ============================================
 * Caching Strategy
 * ============================================
 * - All categories: 1 entry, 5min TTL
 * - Activities per category: separate entry, 5min TTL
 * - Ratings per activity: separate entry, 5min TTL
 * - On update: invalidate relevant cache
 *
 * ============================================
 * Data Flow
 * ============================================
 * 1. Admin creates/updates categories in admin panel
 * 2. Admin creates/updates activities within categories
 * 3. Admin sets default ratings (often shared)
 * 4. Service caches the structure
 * 5. Daily marking uses cached structure
 * 6. Cache auto-refreshes after 5 minutes
 */
//# sourceMappingURL=activity-service.d.ts.map