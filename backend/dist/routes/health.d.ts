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
declare const router: import("express-serve-static-core").Router;
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
//# sourceMappingURL=health.d.ts.map