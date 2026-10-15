"use strict";
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
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const error_handler_1 = require("../middleware/error-handler");
const auth_1 = require("../middleware/auth");
const authorization_1 = require("../middleware/authorization");
const validation_1 = require("../utils/validation");
const supabase_1 = require("../config/supabase");
const http_error_1 = require("../errors/http-error");
const activity_service_1 = require("../services/activity-service");
const router = (0, express_1.Router)();
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
router.get('/categories', (0, error_handler_1.asyncHandler)(async (req, res) => {
    const categories = await (0, activity_service_1.getCategories)();
    res.status(200).json({
        success: true,
        data: categories,
    });
}));
/**
 * GET /api/activities/categories/:categoryId
 *
 * Get a specific category by ID
 *
 * Response: 200 OK
 * Error: 404 Not Found
 */
router.get('/categories/:categoryId', (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { categoryId } = req.params;
    const category = await (0, activity_service_1.getCategoryById)(categoryId);
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
}));
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
router.get('/categories/:categoryId/activities', (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { categoryId } = req.params;
    const activities = await (0, activity_service_1.getActivitiesByCategory)(categoryId);
    res.status(200).json({
        success: true,
        data: activities,
    });
}));
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
router.get('/', (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { categoryId, hasQuantity } = req.query;
    let activities = await (0, activity_service_1.getAllActivities)();
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
}));
/**
 * GET /api/activities/:activityId
 *
 * Get a specific activity by ID
 *
 * Response: 200 OK
 * Error: 404 Not Found
 */
router.get('/:activityId', (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { activityId } = req.params;
    const activity = await (0, activity_service_1.getActivityById)(activityId);
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
}));
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
router.get('/:activityId/ratings', (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { activityId } = req.params;
    const ratings = await (0, activity_service_1.getRatings)(activityId);
    res.status(200).json({
        success: true,
        data: ratings,
    });
}));
/**
 * GET /api/activities/ratings/:ratingId
 *
 * Get a specific rating by ID
 *
 * Response: 200 OK
 * Error: 404 Not Found
 */
router.get('/ratings/:ratingId', (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { ratingId } = req.params;
    const rating = await (0, activity_service_1.getRatingById)(ratingId);
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
}));
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
router.get('/structure/daily', (0, error_handler_1.asyncHandler)(async (req, res) => {
    const structure = await (0, activity_service_1.buildDailyActivityStructure)();
    res.status(200).json({
        success: true,
        data: structure,
    });
}));
// ===== Shared CRUD helpers (admin) =====
function toPoints(value) {
    const n = typeof value === 'number' ? value : Number(value);
    return Number.isFinite(n) ? Math.trunc(n) : 0;
}
/** Maps a status string to the DB CHECK-enum-safe value. */
function toStatus(value) {
    return value === 'inactive' ? 'inactive' : 'active';
}
/** Normalizes a color string for storage; returns null for empty input. */
function toColor(value) {
    if (typeof value !== 'string')
        return null;
    const trimmed = value.trim();
    return trimmed || null;
}
/** Ensures a category exists; throws 404 when missing. */
async function requireCategory(categoryId) {
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { data } = await supabase
        .from('activity_categories')
        .select('id')
        .eq('id', categoryId)
        .maybeSingle();
    if (!data)
        throw new http_error_1.HttpError(404, `Category ${categoryId} not found.`);
}
/** Finds a category by name, creating it when it does not yet exist. */
async function resolveCategoryId(name) {
    const supabase = (0, supabase_1.getSupabaseClient)();
    const trimmed = name.trim();
    const { data: existing } = await supabase
        .from('activity_categories')
        .select('id')
        .eq('name', trimmed)
        .maybeSingle();
    if (existing)
        return existing.id;
    const { data, error } = await supabase
        .from('activity_categories')
        .insert({ name: trimmed, status: 'active' })
        .select('id')
        .single();
    if (error)
        throw new http_error_1.HttpError(500, `Unable to create category: ${error.message}`);
    return data.id;
}
/**
 * Persists the activity's point value as an `activity_ratings` band, since the
 * `activities` table has no points column. Updates the top band when one exists,
 * else inserts one.
 */
async function syncActivityPoints(activityId, points) {
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { data: ratings } = await supabase
        .from('activity_ratings')
        .select('id, marks')
        .eq('activity_id', activityId)
        .order('marks', { ascending: false });
    if (ratings && ratings.length > 0) {
        await supabase.from('activity_ratings').update({ marks: points }).eq('id', ratings[0].id);
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
router.post('/categories', auth_1.requireAuth, (0, authorization_1.requireRoles)('admin'), (0, error_handler_1.asyncHandler)(async (req, res) => {
    const body = (0, validation_1.ensureObject)(req.body);
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { data, error } = await supabase
        .from('activity_categories')
        .insert({
        name: (0, validation_1.getRequiredString)(body.name, 'name'),
        name_en: (0, validation_1.getOptionalString)(body.name_en, 'name_en') ?? null,
        name_ml: (0, validation_1.getOptionalString)(body.name_ml, 'name_ml') ?? null,
        icon: (0, validation_1.getOptionalString)(body.icon, 'icon') ?? null,
        display_order: toPoints(body.display_order),
        status: toStatus(body.status),
    })
        .select('*')
        .single();
    if (error)
        throw new http_error_1.HttpError(500, `Unable to create category: ${error.message}`);
    res.status(201).json({ success: true, data });
}));
router.put('/categories/:id', auth_1.requireAuth, (0, authorization_1.requireRoles)('admin'), (0, error_handler_1.asyncHandler)(async (req, res) => {
    const body = (0, validation_1.ensureObject)(req.body);
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { data, error } = await supabase
        .from('activity_categories')
        .update({
        name: (0, validation_1.getRequiredString)(body.name, 'name'),
        name_en: (0, validation_1.getOptionalString)(body.name_en, 'name_en') ?? null,
        name_ml: (0, validation_1.getOptionalString)(body.name_ml, 'name_ml') ?? null,
        icon: (0, validation_1.getOptionalString)(body.icon, 'icon') ?? null,
        display_order: toPoints(body.display_order),
        status: toStatus(body.status),
    })
        .eq('id', req.params.id)
        .select('*')
        .maybeSingle();
    if (error)
        throw new http_error_1.HttpError(500, `Unable to update category: ${error.message}`);
    if (!data)
        throw new http_error_1.HttpError(404, 'Category not found.');
    res.json({ success: true, data });
}));
router.delete('/categories/:id', auth_1.requireAuth, (0, authorization_1.requireRoles)('admin'), (0, error_handler_1.asyncHandler)(async (req, res) => {
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { error } = await supabase
        .from('activity_categories')
        .delete()
        .eq('id', req.params.id);
    if (error)
        throw new http_error_1.HttpError(500, `Unable to delete category: ${error.message}`);
    res.json({ success: true });
}));
// ===== Activity CRUD (FRD §4.1.5 / §4.1.7 sub-activity fields) =====
router.post('/items', auth_1.requireAuth, (0, authorization_1.requireRoles)('admin'), (0, error_handler_1.asyncHandler)(async (req, res) => {
    const body = (0, validation_1.ensureObject)(req.body);
    const supabase = (0, supabase_1.getSupabaseClient)();
    const categoryId = await resolveCategoryId((0, validation_1.getRequiredString)(body.category, 'category'));
    const { data, error } = await supabase
        .from('activities')
        .insert({
        category_id: categoryId,
        name: (0, validation_1.getRequiredString)(body.name, 'name'),
        name_en: (0, validation_1.getOptionalString)(body.name_en, 'name_en') ?? null,
        name_ml: (0, validation_1.getOptionalString)(body.name_ml, 'name_ml') ?? null,
        has_quantity: Boolean(body.has_quantity),
        unit_label: (0, validation_1.getOptionalString)(body.unit_label, 'unit_label') ?? null,
        max_quantity: toPoints(body.max_quantity) || null,
        display_order: toPoints(body.display_order),
        status: toStatus(body.status),
    })
        .select('*')
        .single();
    if (error)
        throw new http_error_1.HttpError(500, `Unable to create activity: ${error.message}`);
    await syncActivityPoints(data.id, toPoints(body.points));
    res.status(201).json({ success: true, data });
}));
router.put('/items/:id', auth_1.requireAuth, (0, authorization_1.requireRoles)('admin'), (0, error_handler_1.asyncHandler)(async (req, res) => {
    const body = (0, validation_1.ensureObject)(req.body);
    const supabase = (0, supabase_1.getSupabaseClient)();
    const categoryId = await resolveCategoryId((0, validation_1.getRequiredString)(body.category, 'category'));
    const { data, error } = await supabase
        .from('activities')
        .update({
        category_id: categoryId,
        name: (0, validation_1.getRequiredString)(body.name, 'name'),
        name_en: (0, validation_1.getOptionalString)(body.name_en, 'name_en') ?? null,
        name_ml: (0, validation_1.getOptionalString)(body.name_ml, 'name_ml') ?? null,
        has_quantity: Boolean(body.has_quantity),
        unit_label: (0, validation_1.getOptionalString)(body.unit_label, 'unit_label') ?? null,
        max_quantity: toPoints(body.max_quantity) || null,
        display_order: toPoints(body.display_order),
        status: toStatus(body.status),
    })
        .eq('id', req.params.id)
        .select('*')
        .maybeSingle();
    if (error)
        throw new http_error_1.HttpError(500, `Unable to update activity: ${error.message}`);
    if (!data)
        throw new http_error_1.HttpError(404, 'Activity not found.');
    await syncActivityPoints(req.params.id, toPoints(body.points));
    res.json({ success: true, data });
}));
router.delete('/items/:id', auth_1.requireAuth, (0, authorization_1.requireRoles)('admin'), (0, error_handler_1.asyncHandler)(async (req, res) => {
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { error } = await supabase.from('activities').delete().eq('id', req.params.id);
    if (error)
        throw new http_error_1.HttpError(500, `Unable to delete activity: ${error.message}`);
    res.json({ success: true });
}));
// ===== Per-activity rating-band CRUD (FRD §4.1.6) =====
// Admin creates the FRD 4-band scale (Excellent/Satisfactory/Needs Improvement/
// Not Done with marks + Malayalam + color + is_not_done flag) per activity.
// Routes are scoped by activity id; the existing generic PUT/DELETE
// /admin/rating-rules/:id remain for editing/deleting a band directly.
router.post('/items/:activityId/ratings', auth_1.requireAuth, (0, authorization_1.requireRoles)('admin'), (0, error_handler_1.asyncHandler)(async (req, res) => {
    const body = (0, validation_1.ensureObject)(req.body);
    const activityId = req.params.activityId;
    const supabase = (0, supabase_1.getSupabaseClient)();
    // Validate the activity exists.
    const { data: act } = await supabase
        .from('activities')
        .select('id')
        .eq('id', activityId)
        .maybeSingle();
    if (!act)
        throw new http_error_1.HttpError(404, 'Activity not found.');
    const { data, error } = await supabase
        .from('activity_ratings')
        .insert({
        activity_id: activityId,
        rating_name: (0, validation_1.getRequiredString)(body.rating_name, 'rating_name'),
        rating_name_ml: (0, validation_1.getOptionalString)(body.rating_name_ml, 'rating_name_ml') ?? null,
        marks: toPoints(body.marks),
        color: toColor(body.color),
        display_order: toPoints(body.display_order),
        is_not_done: Boolean(body.is_not_done),
        is_default: Boolean(body.is_default),
    })
        .select('*')
        .single();
    if (error)
        throw new http_error_1.HttpError(500, `Unable to create rating band: ${error.message}`);
    res.status(201).json({ success: true, data });
}));
router.put('/ratings/:ratingId', auth_1.requireAuth, (0, authorization_1.requireRoles)('admin'), (0, error_handler_1.asyncHandler)(async (req, res) => {
    const body = (0, validation_1.ensureObject)(req.body);
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { data, error } = await supabase
        .from('activity_ratings')
        .update({
        rating_name: (0, validation_1.getRequiredString)(body.rating_name, 'rating_name'),
        rating_name_ml: (0, validation_1.getOptionalString)(body.rating_name_ml, 'rating_name_ml') ?? null,
        marks: toPoints(body.marks),
        color: toColor(body.color),
        display_order: toPoints(body.display_order),
        is_not_done: Boolean(body.is_not_done),
        is_default: Boolean(body.is_default),
    })
        .eq('id', req.params.ratingId)
        .select('*')
        .maybeSingle();
    if (error)
        throw new http_error_1.HttpError(500, `Unable to update rating band: ${error.message}`);
    if (!data)
        throw new http_error_1.HttpError(404, 'Rating band not found.');
    res.json({ success: true, data });
}));
router.delete('/ratings/:ratingId', auth_1.requireAuth, (0, authorization_1.requireRoles)('admin'), (0, error_handler_1.asyncHandler)(async (req, res) => {
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { error } = await supabase
        .from('activity_ratings')
        .delete()
        .eq('id', req.params.ratingId);
    if (error)
        throw new http_error_1.HttpError(500, `Unable to delete rating band: ${error.message}`);
    res.json({ success: true });
}));
// ===== Special scoring rules CRUD (FRD §4.1.6 special rules) =====
// Per-activity tiered scoring (Jama'ah=10 / On-time=5 / Late=2; Quran pages
// 10/5/2 = 10/5/2 marks). Stored in activity_scoring_rules with rule_type='tier'.
router.post('/items/:activityId/scoring-rules', auth_1.requireAuth, (0, authorization_1.requireRoles)('admin'), (0, error_handler_1.asyncHandler)(async (req, res) => {
    const body = (0, validation_1.ensureObject)(req.body);
    const activityId = req.params.activityId;
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { data: act } = await supabase
        .from('activities')
        .select('id')
        .eq('id', activityId)
        .maybeSingle();
    if (!act)
        throw new http_error_1.HttpError(404, 'Activity not found.');
    const { data, error } = await supabase
        .from('activity_scoring_rules')
        .insert({
        activity_id: activityId,
        rule_type: (0, validation_1.getOptionalString)(body.rule_type, 'rule_type') ?? 'tier',
        label: (0, validation_1.getOptionalString)(body.label, 'label') ?? null,
        label_ml: (0, validation_1.getOptionalString)(body.label_ml, 'label_ml') ?? null,
        min_quantity: toPoints(body.min_quantity) || null,
        max_quantity: toPoints(body.max_quantity) || null,
        marks: toPoints(body.marks),
        color: toColor(body.color),
        display_order: toPoints(body.display_order),
    })
        .select('*')
        .single();
    if (error)
        throw new http_error_1.HttpError(500, `Unable to create scoring rule: ${error.message}`);
    res.status(201).json({ success: true, data });
}));
router.delete('/scoring-rules/:ruleId', auth_1.requireAuth, (0, authorization_1.requireRoles)('admin'), (0, error_handler_1.asyncHandler)(async (req, res) => {
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { error } = await supabase
        .from('activity_scoring_rules')
        .delete()
        .eq('id', req.params.ruleId);
    if (error)
        throw new http_error_1.HttpError(500, `Unable to delete scoring rule: ${error.message}`);
    res.json({ success: true });
}));
exports.default = router;
//# sourceMappingURL=activities.js.map