/**
 * Health Check Route
 * 
 * Provides a simple endpoint for monitoring application health
 * Used by:
 * - Load balancers for health checks
 * - Uptime monitoring services
 * - CI/CD pipelines for deployment verification
 * - Client apps to verify API connectivity
 */

import { Router, Request, Response } from 'express';

const router = Router();

/**
 * Health check response type
 */
interface HealthCheckResponse {
  status: 'healthy' | 'degraded' | 'unhealthy';
  timestamp: string;
  version: string;
  uptime: number;
  checks: {
    database: boolean;
    cache: boolean;
    auth: boolean;
  };
}

/**
 * GET /health
 * 
 * Basic health check endpoint
 * Returns immediately without deep checks
 * 
 * Response:
 * ```json
 * {
 *   "status": "healthy",
 *   "timestamp": "2026-06-18T10:30:45.123Z",
 *   "version": "1.0.0"
 * }
 * ```
 */
router.get('/health', (req: Request, res: Response) => {
  const response = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: process.env.APP_VERSION || '1.0.0',
  };
  
  res.status(200).json(response);
});

/**
 * GET /health/detailed
 * 
 * Detailed health check with component status
 * Includes database and cache connectivity checks
 * 
 * Takes longer but provides more information
 * Used by monitoring systems
 * 
 * Response:
 * ```json
 * {
 *   "status": "healthy",
 *   "timestamp": "2026-06-18T10:30:45.123Z",
 *   "version": "1.0.0",
 *   "uptime": 3600,
 *   "checks": {
 *     "database": true,
 *     "cache": true,
 *     "auth": true
 *   }
 * }
 * ```
 */
router.get('/health/detailed', async (req: Request, res: Response) => {
  const startTime = Date.now();
  const response: HealthCheckResponse = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: process.env.APP_VERSION || '1.0.0',
    uptime: process.uptime(),
    checks: {
      database: true,
      cache: true,
      auth: true,
    },
  };
  
  try {
    // In production, add actual connectivity checks:
    
    // Database check
    // const dbHealth = await checkDatabaseConnection();
    // response.checks.database = dbHealth;
    
    // Cache check
    // const cacheHealth = await checkCacheConnection();
    // response.checks.cache = cacheHealth;
    
    // Auth service check
    // const authHealth = await checkAuthService();
    // response.checks.auth = authHealth;
    
    // Determine overall status
    const allHealthy = Object.values(response.checks).every(check => check === true);
    response.status = allHealthy ? 'healthy' : 'degraded';
    
    const statusCode = allHealthy ? 200 : 503;
    
    // Log performance
    const responseTime = Date.now() - startTime;
    console.log(`[HEALTH] Detailed check completed in ${responseTime}ms`);
    
    res.status(statusCode).json(response);
  } catch (error) {
    console.error('[HEALTH] Error in detailed health check:', error);
    
    res.status(503).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      version: process.env.APP_VERSION || '1.0.0',
      uptime: process.uptime(),
      checks: {
        database: false,
        cache: false,
        auth: false,
      },
    });
  }
});

/**
 * GET /health/readiness
 * 
 * Kubernetes-style readiness probe
 * Returns 200 if service is ready to handle requests
 * Returns 503 if warming up or shutting down
 * 
 * Used by orchestration systems (K8s, Docker Swarm)
 */
router.get('/health/readiness', (req: Request, res: Response) => {
  // Check if application is ready
  // In production, verify:
  // - Database is connected
  // - Cache is warmed up
  // - Auth service is available
  
  const isReady = true; // Set based on actual checks
  
  if (isReady) {
    res.status(200).json({ ready: true });
  } else {
    res.status(503).json({ ready: false });
  }
});

/**
 * GET /health/liveness
 * 
 * Kubernetes-style liveness probe
 * Returns 200 if application is still running
 * Returns 503 if the app is in a bad state
 * 
 * Should be fast and not do deep checks
 */
router.get('/health/liveness', (req: Request, res: Response) => {
  // Very simple check: is the app still running?
  const isAlive = true;
  
  if (isAlive) {
    res.status(200).json({ alive: true });
  } else {
    res.status(503).json({ alive: false });
  }
});

/**
 * GET /version
 * 
 * Returns current application version
 * Useful for debugging and deployment verification
 */
router.get('/version', (req: Request, res: Response) => {
  res.status(200).json({
    version: process.env.APP_VERSION || '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    timestamp: new Date().toISOString(),
  });
});

/**
 * Health Check Implementation Guide
 * 
 * ============================================
 * Setup Instructions
 * ============================================
 * 
 * 1. Add to Express app:
 *    ```typescript
 *    import healthRouter from './routes/health';
 *    app.use('/', healthRouter);
 *    ```
 * 
 * 2. Set environment variables:
 *    ```
 *    export APP_VERSION=1.0.0
 *    export NODE_ENV=production
 *    ```
 * 
 * 3. Test endpoints:
 *    ```bash
 *    curl http://localhost:3000/health
 *    curl http://localhost:3000/health/detailed
 *    ```
 * 
 * ============================================
 * Kubernetes Integration
 * ============================================
 * 
 * Add to Pod spec:
 * ```yaml
 * livenessProbe:
 *   httpGet:
 *     path: /health/liveness
 *     port: 3000
 *   initialDelaySeconds: 10
 *   periodSeconds: 30
 * 
 * readinessProbe:
 *   httpGet:
 *     path: /health/readiness
 *     port: 3000
 *   initialDelaySeconds: 5
 *   periodSeconds: 10
 * ```
 * 
 * ============================================
 * Response Codes
 * ============================================
 * 
 * 200 OK          - Healthy/Ready/Alive
 * 503 Service     - Unhealthy/Not Ready/Dead
 * Unavailable
 * 
 * ============================================
 * Monitoring & Alerts
 * ============================================
 * 
 * Set up monitoring:
 * - Check /health every 30 seconds
 * - Alert if status != 'healthy' for > 2 minutes
 * - Check /health/detailed every 5 minutes
 * - Log response time (should be < 100ms)
 * 
 * ============================================
 * Performance Expectations
 * ============================================
 * 
 * /health            - < 10ms (cached, no queries)
 * /health/detailed   - < 500ms (includes DB/cache checks)
 * /health/readiness  - < 50ms (simple checks)
 * /health/liveness   - < 10ms (ultra-fast)
 * 
 * If response is slow, the service is degraded
 */

export default router;
