"use strict";
/**
 * Main Application Entry Point
 *
 * Initializes Express server with middleware, routes, and error handling
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.startServer = startServer;
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const helmet_1 = __importDefault(require("helmet"));
const compression_1 = __importDefault(require("compression"));
const morgan_1 = __importDefault(require("morgan"));
const config_1 = __importStar(require("./config/config"));
const supabase_1 = require("./config/supabase");
const request_context_1 = require("./middleware/request-context");
const http_error_1 = require("./errors/http-error");
const auth_1 = __importDefault(require("./routes/auth"));
const admin_1 = __importDefault(require("./routes/admin"));
const students_1 = __importDefault(require("./routes/students"));
const teachers_1 = __importDefault(require("./routes/teachers"));
const academics_1 = __importDefault(require("./routes/academics"));
const activities_1 = __importDefault(require("./routes/activities"));
const activity_logs_1 = __importDefault(require("./routes/activity-logs"));
const achievements_1 = __importDefault(require("./routes/achievements"));
const reports_1 = __importDefault(require("./routes/reports"));
const notifications_1 = __importDefault(require("./routes/notifications"));
// Create Express app
const app = (0, express_1.default)();
/**
 * Configure middleware
 */
// Security
app.use((0, helmet_1.default)());
// CORS
app.use((0, cors_1.default)({
    origin: (origin, callback) => {
        if (!origin) {
            callback(null, true);
            return;
        }
        const isConfiguredOrigin = config_1.default.cors.origins.includes(origin);
        const isDevLoopbackOrigin = config_1.default.app.env !== 'production' &&
            /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/i.test(origin);
        if (isConfiguredOrigin || isDevLoopbackOrigin) {
            callback(null, true);
            return;
        }
        callback(new Error(`CORS origin not allowed: ${origin}`));
    },
    credentials: config_1.default.cors.credentials,
}));
// Compression
app.use((0, compression_1.default)());
// Request context
app.use(request_context_1.requestContextMiddleware);
// Body parsing
app.use(express_1.default.json({ limit: '10mb' }));
app.use(express_1.default.urlencoded({ limit: '10mb', extended: true }));
// Logging
if (config_1.default.app.env !== 'test') {
    app.use((0, morgan_1.default)('combined'));
}
/**
 * Health check endpoint
 */
app.get('/health', (_req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        version: config_1.default.app.version,
    });
});
/**
 * API Routes
 */
app.use('/api/auth', auth_1.default);
app.use('/api/admin', admin_1.default);
app.use('/api/students', students_1.default);
app.use('/api/teachers', teachers_1.default);
app.use('/api/academics', academics_1.default);
app.use('/api/activities', activities_1.default);
app.use('/api/activity-logs', activity_logs_1.default);
app.use('/api/achievements', achievements_1.default);
app.use('/api/reports', reports_1.default);
app.use('/api/notifications', notifications_1.default);
/**
 * 404 Handler
 */
app.use((req, res) => {
    res.status(404).json({
        error: 'Not Found',
        message: `Route ${req.path} not found`,
    });
});
/**
 * Global Error Handler
 */
app.use((err, req, res, next) => {
    void next;
    console.error('Error:', {
        requestId: req.requestId,
        path: req.path,
        error: err,
    });
    if ((0, http_error_1.isHttpError)(err)) {
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
        message: config_1.default.app.env === 'development' ? err.message : 'An error occurred',
        requestId: req.requestId,
    });
});
/**
 * Initialize and start server
 */
async function startServer() {
    try {
        // Validate configuration
        (0, config_1.validateConfig)();
        // Initialize Supabase
        console.log('🔄 Connecting to Supabase...');
        await (0, supabase_1.initializeSupabaseSchema)();
        // Start listening
        app.listen(config_1.default.app.port, () => {
            console.log(`
╔════════════════════════════════════════════════════════════╗
║  🕌 Alif Online Moral School API                          ║
║  Version: ${config_1.default.app.version}                                    ║
║  Environment: ${config_1.default.app.env}                                ║
║  Server running on: http://localhost:${config_1.default.app.port}            ║
║  Health Check: http://localhost:${config_1.default.app.port}/health       ║
╚════════════════════════════════════════════════════════════╝
      `);
        });
    }
    catch (error) {
        console.error('❌ Failed to start server:', error);
        process.exit(1);
    }
}
// Start server if this file is run directly
if (require.main === module) {
    startServer();
}
exports.default = app;
//# sourceMappingURL=app.js.map