/**
 * Main Application Entry Point
 * 
 * Initializes Express server with middleware, routes, and error handling
 */

import express, { Express, Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import morgan from 'morgan';
import config, { validateConfig } from './config/config';
import { initializeSupabaseSchema } from './config/supabase';
import { requestContextMiddleware } from './middleware/request-context';
import { isHttpError } from './errors/http-error';
import authRoutes from './routes/auth';
import adminRoutes from './routes/admin';
import studentRoutes from './routes/students';
import teacherRoutes from './routes/teachers';
import teacherPortalRoutes from './routes/teacher-portal';
import academicRoutes from './routes/academics';
import activityRoutes from './routes/activities';
import activityLogRoutes from './routes/activity-logs';
import achievementRoutes from './routes/achievements';
import reportRoutes from './routes/reports';
import notificationRoutes from './routes/notifications';
import parentRoutes from './routes/parents';

// Create Express app
const app: Express = express();

/**
 * Configure middleware
 */

// Security
app.use(helmet());

// CORS
app.use(
  cors({
    origin: (origin, callback) => {
      if (!origin) {
        callback(null, true);
        return;
      }

      const isConfiguredOrigin = config.cors.origins.includes(origin);
      const isDevLoopbackOrigin =
        config.app.env !== 'production' &&
        /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/i.test(origin);

      if (isConfiguredOrigin || isDevLoopbackOrigin) {
        callback(null, true);
        return;
      }

      callback(new Error(`CORS origin not allowed: ${origin}`));
    },
    credentials: config.cors.credentials,
  })
);

// Compression
app.use(compression());

// Request context
app.use(requestContextMiddleware);

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));

// Logging
if (config.app.env !== 'test') {
  app.use(morgan('combined'));
}

/**
 * Health check endpoint
 */
const healthHandler = (_req: Request, res: Response) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: config.app.version,
  });
};

app.get('/health', healthHandler);
app.get('/api/health', healthHandler);

/**
 * API Routes
 */
app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/students', studentRoutes);
app.use('/api/teachers', teacherRoutes);
app.use('/api/teacher', teacherPortalRoutes);
app.use('/api/academics', academicRoutes);
app.use('/api/activities', activityRoutes);
app.use('/api/activity-logs', activityLogRoutes);
app.use('/api/achievements', achievementRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/parents', parentRoutes);

/**
 * 404 Handler
 */
app.use((req: Request, res: Response) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Route ${req.path} not found`,
  });
});

/**
 * Global Error Handler
 */
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  void next;
  console.error('Error:', {
    requestId: req.requestId,
    path: req.path,
    error: err,
  });

  if (isHttpError(err)) {
    res.status(err.statusCode).json({
      success: false,
      error: err.message,
      details: err.details,
      requestId: req.requestId,
    });
    return;
  }

  res.status(500).json({
    success: false,
    error: 'Internal Server Error',
    message: config.app.env === 'development' ? err.message : 'An error occurred',
    requestId: req.requestId,
  });
});

/**
 * Initialize and start server
 */
export async function startServer(): Promise<void> {
  try {
    // Validate configuration
    validateConfig();

    // Initialize Supabase
    console.log('🔄 Connecting to Supabase...');
    await initializeSupabaseSchema();

    // Start listening
    app.listen(config.app.port, () => {
      console.log(`
╔════════════════════════════════════════════════════════════╗
║  🕌 Alif Online Moral School API                          ║
║  Version: ${config.app.version}                                    ║
║  Environment: ${config.app.env}                                ║
║  Server running on: http://localhost:${config.app.port}            ║
║  Health Check: http://localhost:${config.app.port}/health       ║
╚════════════════════════════════════════════════════════════╝
      `);
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
}

// Start server if this file is run directly
if (require.main === module) {
  startServer();
}

export default app;
