/**
 * Activity Endpoints
 * 
 * API routes for retrieving activity master data
 * (Categories, Activities, Ratings)
 * 
 * Endpoints:
 * - GET /api/activities/categories - Get all categories
 * - GET /api/activities/categories/:id - Get specific category
 * - GET /api/activities/categories/:id/activities - Get activities in category
 * - GET /api/activities - Get all activities
 * - GET /api/activities/:id - Get specific activity
 * - GET /api/activities/:id/ratings - Get rating options for activity
 * - GET /api/activities/structure/daily - Complete structure for daily marking
 */

import { Router, Request, Response } from 'express';
import { asyncHandler } from '../middleware/error-handler';
import { requireAuth } from '../middleware/auth';
import { requireRoles } from '../middleware/authorization';
import { ensureObject, getRequiredString, getOptionalString } from '../utils/validation';
import { getSupabaseClient } from '../config/supabase';
import { HttpError } from '../errors/http-error';
import {
  getCategories,
  getActivitiesByCategory,
  getAllActivities,
  getCategoryById,
  getActivityById,
  getRatings,
  getRatingById,
  buildDailyActivityStructure,
} from '../services/activity-service';

const router = Router();

/**
 * GET /api/activities/categories
 * 
 * Get all activity categories
 * 
 * Response: 200 OK
 * ```json
 * {
 *   "success": true,
 *   "data": [
 *     {
 *       "id": "cat-salah",
 *       "name": "Salah (Prayer)",
 *       "name_ml": "നമസ്സ്",
 *       "icon": "🙏",
 *       "display_order": 1,
 *       "status": "active"
 *     },
 *     ...
 *   ]
 * }
 * ```
 */
router.get(
  '/categories',
  asyncHandler(async (req: Request, res: Response) => {
    const categories = await getCategories();
    
    res.status(200).json({
      success: true,
      data: categories,
    });
  })
);

/**
 * GET /api/activities/categories/:categoryId
 * 
 * Get a specific category by ID
 * 
 * Response: 200 OK
 * Error: 404 Not Found
 */
router.get(
  '/categories/:categoryId',
  asyncHandler(async (req: Request, res: Response) => {
    const { categoryId } = req.params;
    const category = await getCategoryById(categoryId);
    
    if (!category) {
      return res.status(404).json({
        success: false,
        error: 'NOT_FOUND',
        message: `Category ${categoryId} not found`,
      });
    }
    
    res.status(200).json({
      success: true,
      data: category,
    });
  })
);

/**
 * GET /api/activities/categories/:categoryId/activities
 * 
 * Get all activities in a specific category
 * 
 * Response: 200 OK
 * ```json
 * {
 *   "success": true,
 *   "data": [
 *     {
 *       "id": "act-subhi",
 *       "category_id": "cat-salah",
 *       "name": "Subhi Prayer",
 *       "name_ml": "സുബ്ഹ് നമസ്സ്",
 *       "display_order": 1,
 *       "has_quantity": false,
 *       "status": "active"
 *     },
 *     ...
 *   ]
 * }
 * ```
 */
router.get(
  '/categories/:categoryId/activities',
  asyncHandler(async (req: Request, res: Response) => {
    const { categoryId } = req.params;
    const activities = await getActivitiesByCategory(categoryId);
    
    res.status(200).json({
      success: true,
      data: activities,
    });
  })
);

/**
 * GET /api/activities
 * 
 * Get all activities (flattened, no category grouping)
 * 
 * Optional query params:
 * - categoryId: Filter by category
 * - hasQuantity: Filter by quantity tracking (true/false)
 * 
 * Response: 200 OK
 */
router.get(
  '/',
  asyncHandler(async (req: Request, res: Response) => {
    const { categoryId, hasQuantity } = req.query;
    let activities = await getAllActivities();
    
    // Optional filtering
    if (categoryId) {
      activities = activities.filter(a => a.category_id === categoryId);
    }
    
    if (hasQuantity !== undefined) {
      const filterByQuantity = hasQuantity === 'true';
      activities = activities.filter(a => a.has_quantity === filterByQuantity);
    }
    
    res.status(200).json({
      success: true,
      data: activities,
    });
  })
);

/**
 * GET /api/activities/:activityId
 * 
 * Get a specific activity by ID
 * 
 * Response: 200 OK
 * Error: 404 Not Found
 */
router.get(
  '/:activityId',
  asyncHandler(async (req: Request, res: Response) => {
    const { activityId } = req.params;
    const activity = await getActivityById(activityId);
    
    if (!activity) {
      return res.status(404).json({
        success: false,
        error: 'NOT_FOUND',
        message: `Activity ${activityId} not found`,
      });
    }
    
    res.status(200).json({
      success: true,
      data: activity,
    });
  })
);

/**
 * GET /api/activities/:activityId/ratings
 * 
 * Get all rating options for an activity
 * 
 * Response: 200 OK
 * ```json
 * {
 *   "success": true,
 *   "data": [
 *     {
 *       "id": "rating-excellent",
 *       "activity_id": "act-subhi",
 *       "rating_name": "Excellent",
 *       "rating_name_ml": "ഉത്തമം",
 *       "marks": 10,
 *       "color": "#4CAF50",
 *       "display_order": 1
 *     },
 *     ...
 *   ]
 * }
 * ```
 */
router.get(
  '/:activityId/ratings',
  asyncHandler(async (req: Request, res: Response) => {
    const { activityId } = req.params;
    const ratings = await getRatings(activityId);
    
    res.status(200).json({
      success: true,
      data: ratings,
    });
  })
);

/**
 * GET /api/activities/ratings/:ratingId
 * 
 * Get a specific rating by ID
 * 
 * Response: 200 OK
 * Error: 404 Not Found
 */
router.get(
  '/ratings/:ratingId',
  asyncHandler(async (req: Request, res: Response) => {
    const { ratingId } = req.params;
    const rating = await getRatingById(ratingId);
    
    if (!rating) {
      return res.status(404).json({
        success: false,
        error: 'NOT_FOUND',
        message: `Rating ${ratingId} not found`,
      });
    }
    
    res.status(200).json({
      success: true,
      data: rating,
    });
  })
);

/**
 * GET /api/activities/structure/daily
 * 
 * Get complete activity structure for daily marking screen
 * 
 * Returns categories with nested activities and ratings
 * This is the main endpoint used by frontend for rendering the daily marking screen
 * 
 * Response: 200 OK
 * ```json
 * {
 *   "success": true,
 *   "data": {
 *     "categories": [
 *       {
 *         "id": "cat-salah",
 *         "name": "Salah (Prayer)",
 *         "name_ml": "നമസ്സ്",
 *         "icon": "🙏",
 *         "activities": [
 *           {
 *             "id": "act-subhi",
 *             "name": "Subhi Prayer",
 *             "name_ml": "സുബ്ഹ് നമസ്സ്",
 *             "has_quantity": false,
 *             "ratings": [
 *               {
 *                 "id": "rating-excellent",
 *                 "rating_name": "Excellent",
 *                 "marks": 10,
 *                 "color": "#4CAF50"
 *               },
 *               ...
 *             ]
 *           },
 *           ...
 *         ]
 *       },
 *       ...
 *     ]
 *   }
 * }
 * ```
 * 
 * Cache: Results are cached for 5 minutes
 */
router.get(
  '/structure/daily',
  asyncHandler(async (req: Request, res: Response) => {
    const structure = await buildDailyActivityStructure();
    
    res.status(200).json({
      success: true,
      data: structure,
    });
  })
);

// ===== Shared CRUD helpers (admin) =====

function toPoints(value: unknown): number {
  const n = typeof value === 'number' ? value : Number(value);
  return Number.isFinite(n) ? Math.trunc(n) : 0;
}

/** Maps a status string to the DB CHECK-enum-safe value. */
function toStatus(value: unknown): 'active' | 'inactive' {
  return value === 'inactive' ? 'inactive' : 'active';
}

/** Normalizes a color string for storage; returns null for empty input. */
function toColor(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  return trimmed || null;
}

/** Ensures a category exists; throws 404 when missing. */
async function requireCategory(categoryId: string): Promise<void> {
  const supabase = getSupabaseClient();
  const { data } = await supabase
    .from('activity_categories')
    .select('id')
    .eq('id', categoryId)
    .maybeSingle();
  if (!data) throw new HttpError(404, `Category ${categoryId} not found.`);
}

/** Finds a category by name, creating it when it does not yet exist. */
async function resolveCategoryId(name: string): Promise<string> {
  const supabase = getSupabaseClient();
  const trimmed = name.trim();
  const { data: existing } = await supabase
    .from('activity_categories')
    .select('id')
    .eq('name', trimmed)
    .maybeSingle();
  if (existing) return (existing as { id: string }).id;

  const { data, error } = await supabase
    .from('activity_categories')
    .insert({ name: trimmed, status: 'active' })
    .select('id')
    .single();
  if (error) throw new HttpError(500, `Unable to create category: ${error.message}`);
  return (data as { id: string }).id;
}

/**
 * Persists the activity's point value as an `activity_ratings` band, since the
 * `activities` table has no points column. Updates the top band when one exists,
 * else inserts one.
 */
async function syncActivityPoints(activityId: string, points: number): Promise<void> {
  const supabase = getSupabaseClient();
  const { data: ratings } = await supabase
    .from('activity_ratings')
    .select('id, marks')
    .eq('activity_id', activityId)
    .order('marks', { ascending: false });

  if (ratings && ratings.length > 0) {
    await supabase.from('activity_ratings').update({ marks: points }).eq('id', (ratings[0] as { id: string }).id);
    return;
  }
  await supabase.from('activity_ratings').insert({
    activity_id: activityId,
    rating_name: 'Completed',
    marks: points,
    display_order: 1,
  });
}

// ===== Category CRUD (FRD §4.1.5) =====
// POST/PUT/DELETE on activity_categories. The admin panel uses these to manage
// parent categories (Prayer, Sunnah, Daily Routine, etc.) with bilingual names,
// icon, display order and status — the FRD §4.1.5 category fields.

router.post(
  '/categories',
  requireAuth,
  requireRoles('admin'),
  asyncHandler(async (req: Request, res: Response) => {
    const body = ensureObject(req.body);
    const supabase = getSupabaseClient();
    const { data, error } = await supabase
      .from('activity_categories')
      .insert({
        name: getRequiredString(body.name, 'name'),
        name_en: getOptionalString(body.name_en, 'name_en') ?? null,
        name_ml: getOptionalString(body.name_ml, 'name_ml') ?? null,
        icon: getOptionalString(body.icon, 'icon') ?? null,
        display_order: toPoints(body.display_order),
        status: toStatus(body.status),
      })
      .select('*')
      .single();
    if (error) throw new HttpError(500, `Unable to create category: ${error.message}`);
    res.status(201).json({ success: true, data });
  })
);

router.put(
  '/categories/:id',
  requireAuth,
  requireRoles('admin'),
  asyncHandler(async (req: Request, res: Response) => {
    const body = ensureObject(req.body);
    const supabase = getSupabaseClient();
    const { data, error } = await supabase
      .from('activity_categories')
      .update({
        name: getRequiredString(body.name, 'name'),
        name_en: getOptionalString(body.name_en, 'name_en') ?? null,
        name_ml: getOptionalString(body.name_ml, 'name_ml') ?? null,
        icon: getOptionalString(body.icon, 'icon') ?? null,
        display_order: toPoints(body.display_order),
        status: toStatus(body.status),
      })
      .eq('id', req.params.id)
      .select('*')
      .maybeSingle();
    if (error) throw new HttpError(500, `Unable to update category: ${error.message}`);
    if (!data) throw new HttpError(404, 'Category not found.');
    res.json({ success: true, data });
  })
);

router.delete(
  '/categories/:id',
  requireAuth,
  requireRoles('admin'),
  asyncHandler(async (req: Request, res: Response) => {
    const supabase = getSupabaseClient();
    const { error } = await supabase
      .from('activity_categories')
      .delete()
      .eq('id', req.params.id);
    if (error) throw new HttpError(500, `Unable to delete category: ${error.message}`);
    res.json({ success: true });
  })
);

// ===== Activity CRUD (FRD §4.1.5 / §4.1.7 sub-activity fields) =====

router.post(
  '/items',
  requireAuth,
  requireRoles('admin'),
  asyncHandler(async (req: Request, res: Response) => {
    const body = ensureObject(req.body);
    const supabase = getSupabaseClient();
    const categoryId = await resolveCategoryId(getRequiredString(body.category, 'category'));

    const { data, error } = await supabase
      .from('activities')
      .insert({
        category_id: categoryId,
        name: getRequiredString(body.name, 'name'),
        name_en: getOptionalString(body.name_en, 'name_en') ?? null,
        name_ml: getOptionalString(body.name_ml, 'name_ml') ?? null,
        has_quantity: Boolean(body.has_quantity),
        unit_label: getOptionalString(body.unit_label, 'unit_label') ?? null,
        max_quantity: toPoints(body.max_quantity) || null,
        display_order: toPoints(body.display_order),
        status: toStatus(body.status),
      })
      .select('*')
      .single();
    if (error) throw new HttpError(500, `Unable to create activity: ${error.message}`);

    await syncActivityPoints((data as { id: string }).id, toPoints(body.points));
    res.status(201).json({ success: true, data });
  })
);

router.put(
  '/items/:id',
  requireAuth,
  requireRoles('admin'),
  asyncHandler(async (req: Request, res: Response) => {
    const body = ensureObject(req.body);
    const supabase = getSupabaseClient();
    const categoryId = await resolveCategoryId(getRequiredString(body.category, 'category'));

    const { data, error } = await supabase
      .from('activities')
      .update({
        category_id: categoryId,
        name: getRequiredString(body.name, 'name'),
        name_en: getOptionalString(body.name_en, 'name_en') ?? null,
        name_ml: getOptionalString(body.name_ml, 'name_ml') ?? null,
        has_quantity: Boolean(body.has_quantity),
        unit_label: getOptionalString(body.unit_label, 'unit_label') ?? null,
        max_quantity: toPoints(body.max_quantity) || null,
        display_order: toPoints(body.display_order),
        status: toStatus(body.status),
      })
      .eq('id', req.params.id)
      .select('*')
      .maybeSingle();
    if (error) throw new HttpError(500, `Unable to update activity: ${error.message}`);
    if (!data) throw new HttpError(404, 'Activity not found.');

    await syncActivityPoints(req.params.id, toPoints(body.points));
    res.json({ success: true, data });
  })
);

router.delete(
  '/items/:id',
  requireAuth,
  requireRoles('admin'),
  asyncHandler(async (req: Request, res: Response) => {
    const supabase = getSupabaseClient();
    const { error } = await supabase.from('activities').delete().eq('id', req.params.id);
    if (error) throw new HttpError(500, `Unable to delete activity: ${error.message}`);
    res.json({ success: true });
  })
);

// ===== Per-activity rating-band CRUD (FRD §4.1.6) =====
// Admin creates the FRD 4-band scale (Excellent/Satisfactory/Needs Improvement/
// Not Done with marks + Malayalam + color + is_not_done flag) per activity.
// Routes are scoped by activity id; the existing generic PUT/DELETE
// /admin/rating-rules/:id remain for editing/deleting a band directly.

router.post(
  '/items/:activityId/ratings',
  requireAuth,
  requireRoles('admin'),
  asyncHandler(async (req: Request, res: Response) => {
    const body = ensureObject(req.body);
    const activityId = req.params.activityId;
    const supabase = getSupabaseClient();
    // Validate the activity exists.
    const { data: act } = await supabase
      .from('activities')
      .select('id')
      .eq('id', activityId)
      .maybeSingle();
    if (!act) throw new HttpError(404, 'Activity not found.');

    const { data, error } = await supabase
      .from('activity_ratings')
      .insert({
        activity_id: activityId,
        rating_name: getRequiredString(body.rating_name, 'rating_name'),
        rating_name_ml: getOptionalString(body.rating_name_ml, 'rating_name_ml') ?? null,
        marks: toPoints(body.marks),
        color: toColor(body.color),
        display_order: toPoints(body.display_order),
        is_not_done: Boolean(body.is_not_done),
        is_default: Boolean(body.is_default),
      })
      .select('*')
      .single();
    if (error) throw new HttpError(500, `Unable to create rating band: ${error.message}`);
    res.status(201).json({ success: true, data });
  })
);

router.put(
  '/ratings/:ratingId',
  requireAuth,
  requireRoles('admin'),
  asyncHandler(async (req: Request, res: Response) => {
    const body = ensureObject(req.body);
    const supabase = getSupabaseClient();
    const { data, error } = await supabase
      .from('activity_ratings')
      .update({
        rating_name: getRequiredString(body.rating_name, 'rating_name'),
        rating_name_ml: getOptionalString(body.rating_name_ml, 'rating_name_ml') ?? null,
        marks: toPoints(body.marks),
        color: toColor(body.color),
        display_order: toPoints(body.display_order),
        is_not_done: Boolean(body.is_not_done),
        is_default: Boolean(body.is_default),
      })
      .eq('id', req.params.ratingId)
      .select('*')
      .maybeSingle();
    if (error) throw new HttpError(500, `Unable to update rating band: ${error.message}`);
    if (!data) throw new HttpError(404, 'Rating band not found.');
    res.json({ success: true, data });
  })
);

router.delete(
  '/ratings/:ratingId',
  requireAuth,
  requireRoles('admin'),
  asyncHandler(async (req: Request, res: Response) => {
    const supabase = getSupabaseClient();
    const { error } = await supabase
      .from('activity_ratings')
      .delete()
      .eq('id', req.params.ratingId);
    if (error) throw new HttpError(500, `Unable to delete rating band: ${error.message}`);
    res.json({ success: true });
  })
);

// ===== Special scoring rules CRUD (FRD §4.1.6 special rules) =====
// Per-activity tiered scoring (Jama'ah=10 / On-time=5 / Late=2; Quran pages
// 10/5/2 = 10/5/2 marks). Stored in activity_scoring_rules with rule_type='tier'.

router.post(
  '/items/:activityId/scoring-rules',
  requireAuth,
  requireRoles('admin'),
  asyncHandler(async (req: Request, res: Response) => {
    const body = ensureObject(req.body);
    const activityId = req.params.activityId;
    const supabase = getSupabaseClient();
    const { data: act } = await supabase
      .from('activities')
      .select('id')
      .eq('id', activityId)
      .maybeSingle();
    if (!act) throw new HttpError(404, 'Activity not found.');

    const { data, error } = await supabase
      .from('activity_scoring_rules')
      .insert({
        activity_id: activityId,
        rule_type: getOptionalString(body.rule_type, 'rule_type') ?? 'tier',
        label: getOptionalString(body.label, 'label') ?? null,
        label_ml: getOptionalString(body.label_ml, 'label_ml') ?? null,
        min_quantity: toPoints(body.min_quantity) || null,
        max_quantity: toPoints(body.max_quantity) || null,
        marks: toPoints(body.marks),
        color: toColor(body.color),
        display_order: toPoints(body.display_order),
      })
      .select('*')
      .single();
    if (error) throw new HttpError(500, `Unable to create scoring rule: ${error.message}`);
    res.status(201).json({ success: true, data });
  })
);

router.delete(
  '/scoring-rules/:ruleId',
  requireAuth,
  requireRoles('admin'),
  asyncHandler(async (req: Request, res: Response) => {
    const supabase = getSupabaseClient();
    const { error } = await supabase
      .from('activity_scoring_rules')
      .delete()
      .eq('id', req.params.ruleId);
    if (error) throw new HttpError(500, `Unable to delete scoring rule: ${error.message}`);
    res.json({ success: true });
  })
);

export default router;