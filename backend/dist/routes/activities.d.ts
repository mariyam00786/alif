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
declare const router: import("express-serve-static-core").Router;
export default router;
//# sourceMappingURL=activities.d.ts.map