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

export default router;