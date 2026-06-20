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
 * Cache entry with TTL
 */
interface CacheEntry<T> {
  data: T;
  timestamp: number;
  ttlMs: number;
}

/**
 * In-memory cache for master data
 * In production, consider using Redis or similar
 */
const cache = new Map<string, CacheEntry<any>>();

/**
 * Default cache TTL: 5 minutes
 */
const DEFAULT_TTL_MS = 5 * 60 * 1000;

/**
 * Checks if a cache entry is still valid
 */
function isCacheValid<T>(entry: CacheEntry<T>): boolean {
  const now = Date.now();
  return now - entry.timestamp < entry.ttlMs;
}

/**
 * Gets value from cache if valid
 */
function getFromCache<T>(key: string): T | null {
  const entry = cache.get(key) as CacheEntry<T> | undefined;
  
  if (!entry) {
    return null;
  }
  
  if (isCacheValid(entry)) {
    return entry.data;
  }
  
  // Cache expired, remove it
  cache.delete(key);
  return null;
}

/**
 * Stores value in cache with TTL
 */
function setCache<T>(key: string, data: T, ttlMs: number = DEFAULT_TTL_MS): void {
  cache.set(key, {
    data,
    timestamp: Date.now(),
    ttlMs,
  });
}

/**
 * Clears specific cache entry
 */
function clearCache(key: string): void {
  cache.delete(key);
}

/**
 * Clears all cache
 */
export function clearAllCache(): void {
  cache.clear();
}

/**
 * Gets cache statistics (for monitoring)
 */
export function getCacheStats(): {
  size: number;
  entries: string[];
} {
  return {
    size: cache.size,
    entries: Array.from(cache.keys()),
  };
}

/**
 * Mock database query functions (replace with Supabase in production)
 * 
 * In real implementation, these would query the database
 */

/**
 * Fetches all activity categories from database
 * 
 * In production, replace with: 
 * ```
 * const { data } = await supabase
 *   .from('activity_categories')
 *   .select('*')
 *   .eq('status', 'active')
 *   .order('display_order', { ascending: true });
 * ```
 */
async function fetchCategoriesFromDB(): Promise<ActivityCategory[]> {
  // Mock implementation - replace with real DB call
  return [
    {
      id: 'cat-prayer',
      name: 'Salah (Prayer)',
      name_ml: 'നമസ്സ്',
      icon: '🙏',
      display_order: 1,
      status: 'active',
      created_at: new Date().toISOString(),
    },
    {
      id: 'cat-quran',
      name: 'Quran',
      name_ml: 'ഖുറാൻ',
      icon: '📖',
      display_order: 2,
      status: 'active',
      created_at: new Date().toISOString(),
    },
  ];
}

/**
 * Fetches activities for a category
 */
async function fetchActivitiesByCategoryFromDB(categoryId: string): Promise<Activity[]> {
  // Mock implementation
  if (categoryId === 'cat-prayer') {
    return [
      {
        id: 'act-subhi',
        category_id: categoryId,
        name: 'Subhi Prayer',
        name_ml: 'സുബ്ഹ് നമസ്സ്',
        display_order: 1,
        has_quantity: false,
        status: 'active',
        created_at: new Date().toISOString(),
      },
      {
        id: 'act-zuhr',
        category_id: categoryId,
        name: 'Zuhr Prayer',
        name_ml: 'സോമ നമസ്സ്',
        display_order: 2,
        has_quantity: false,
        status: 'active',
        created_at: new Date().toISOString(),
      },
    ];
  }
  return [];
}

/**
 * Fetches rating options for an activity
 */
async function fetchRatingsFromDB(activityId: string): Promise<ActivityRating[]> {
  // Mock implementation - all activities have same rating options
  return [
    {
      id: 'rating-excellent',
      activity_id: activityId,
      rating_name: 'Excellent',
      rating_name_ml: 'ഉത്തമം',
      marks: 10,
      color: '#4CAF50',
      display_order: 1,
      created_at: new Date().toISOString(),
    },
    {
      id: 'rating-satisfactory',
      activity_id: activityId,
      rating_name: 'Satisfactory',
      rating_name_ml: 'സാധാരണം',
      marks: 5,
      color: '#FFC107',
      display_order: 2,
      created_at: new Date().toISOString(),
    },
    {
      id: 'rating-needs-improvement',
      activity_id: activityId,
      rating_name: 'Needs Improvement',
      rating_name_ml: 'സുധരിതേയും',
      marks: 2,
      color: '#FF9800',
      display_order: 3,
      created_at: new Date().toISOString(),
    },
    {
      id: 'rating-not-done',
      activity_id: activityId,
      rating_name: 'Not Done',
      rating_name_ml: 'ചെയ്യാതിരുന്നത്',
      marks: 0,
      color: '#9E9E9E',
      display_order: 4,
      created_at: new Date().toISOString(),
    },
  ];
}

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
export async function getCategories(): Promise<ActivityCategory[]> {
  const cacheKey = 'categories:all';
  
  // Check cache first
  const cached = getFromCache<ActivityCategory[]>(cacheKey);
  if (cached) {
    return cached;
  }
  
  // Fetch from DB
  const categories = await fetchCategoriesFromDB();
  
  // Store in cache
  setCache(cacheKey, categories);
  
  return categories;
}

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
export async function getActivitiesByCategory(categoryId: string): Promise<Activity[]> {
  const cacheKey = `activities:category:${categoryId}`;
  
  // Check cache
  const cached = getFromCache<Activity[]>(cacheKey);
  if (cached) {
    return cached;
  }
  
  // Fetch from DB
  const activities = await fetchActivitiesByCategoryFromDB(categoryId);
  
  // Store in cache
  setCache(cacheKey, activities);
  
  return activities;
}

/**
 * Gets all activities across all categories (flattened)
 * 
 * @returns Array of all activities sorted by category then display order
 */
export async function getAllActivities(): Promise<Activity[]> {
  const categories = await getCategories();
  const allActivities: Activity[] = [];
  
  for (const category of categories) {
    const activities = await getActivitiesByCategory(category.id);
    allActivities.push(...activities);
  }
  
  return allActivities;
}

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
export async function getRatings(activityId: string): Promise<ActivityRating[]> {
  const cacheKey = `ratings:activity:${activityId}`;
  
  // Check cache
  const cached = getFromCache<ActivityRating[]>(cacheKey);
  if (cached) {
    return cached;
  }
  
  // Fetch from DB
  const ratings = await fetchRatingsFromDB(activityId);
  
  // Store in cache
  setCache(cacheKey, ratings);
  
  return ratings;
}

/**
 * Gets all ratings across all activities
 * 
 * @returns Array of all ratings (may have duplicates if ratings are shared)
 */
export async function getAllRatings(): Promise<ActivityRating[]> {
  const activities = await getAllActivities();
  const allRatings: ActivityRating[] = [];
  
  for (const activity of activities) {
    const ratings = await getRatings(activity.id);
    allRatings.push(...ratings);
  }
  
  return allRatings;
}

/**
 * Gets a specific category by ID
 * 
 * @param categoryId - Category ID
 * @returns Category object or null if not found
 */
export async function getCategoryById(categoryId: string): Promise<ActivityCategory | null> {
  const categories = await getCategories();
  return categories.find(c => c.id === categoryId) || null;
}

/**
 * Gets a specific activity by ID
 * 
 * @param activityId - Activity ID
 * @returns Activity object or null if not found
 */
export async function getActivityById(activityId: string): Promise<Activity | null> {
  const activities = await getAllActivities();
  return activities.find(a => a.id === activityId) || null;
}

/**
 * Gets a specific rating by ID
 * 
 * @param ratingId - Rating ID
 * @returns Rating object or null if not found
 */
export async function getRatingById(ratingId: string): Promise<ActivityRating | null> {
  const ratings = await getAllRatings();
  return ratings.find(r => r.id === ratingId) || null;
}

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
export async function buildDailyActivityStructure(): Promise<{
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
}> {
  const categories = await getCategories();
  
  const result = await Promise.all(
    categories.map(async (category) => ({
      id: category.id,
      name: category.name,
      name_ml: category.name_ml,
      icon: category.icon,
      activities: await Promise.all(
        (await getActivitiesByCategory(category.id)).map(async (activity) => ({
          id: activity.id,
          name: activity.name,
          name_ml: activity.name_ml,
          has_quantity: activity.has_quantity,
          ratings: await getRatings(activity.id),
        }))
      ),
    }))
  );
  
  return { categories: result };
}

/**
 * Invalidates cache for a specific category
 * Use after updating categories
 */
export function invalidateCategoryCache(categoryId?: string): void {
  if (categoryId) {
    clearCache(`activities:category:${categoryId}`);
  } else {
    clearCache('categories:all');
  }
}

/**
 * Invalidates cache for a specific activity
 * Use after updating activities
 */
export function invalidateActivityCache(activityId: string): void {
  clearCache(`ratings:activity:${activityId}`);
}

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
