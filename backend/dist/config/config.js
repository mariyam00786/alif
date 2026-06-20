"use strict";
/**
 * Environment Configuration
 *
 * All configuration is read from environment variables
 * Never commit sensitive information to version control
 */
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.config = void 0;
exports.validateConfig = validateConfig;
const dotenv_1 = __importDefault(require("dotenv"));
// Load environment variables from .env file
dotenv_1.default.config();
exports.config = {
    // Application
    app: {
        name: 'Alif Online Moral School API',
        version: '1.0.0',
        port: parseInt(process.env.PORT || '3000', 10),
        env: process.env.NODE_ENV || 'development',
    },
    // Supabase Configuration
    supabase: {
        url: process.env.SUPABASE_URL || '',
        anonKey: process.env.SUPABASE_ANON_KEY || '',
        serviceKey: process.env.SUPABASE_SERVICE_ROLE_KEY || '',
    },
    // JWT Configuration
    jwt: {
        secret: process.env.JWT_SECRET || 'your-secret-key-change-in-production',
        expiresIn: process.env.JWT_EXPIRES_IN || '7d',
    },
    // OTP Configuration (handled by Supabase Auth)
    otp: {
        provider: 'supabase',
        expirationTime: parseInt(process.env.OTP_EXPIRATION_TIME || '600', 10), // 10 minutes
    },
    // Email Configuration (handled by Supabase Auth)
    email: {
        fromEmail: process.env.EMAIL_FROM || 'noreply@alifschool.com',
        fromName: process.env.EMAIL_FROM_NAME || 'Alif School',
    },
    // File Storage (Supabase Storage)
    storage: {
        provider: 'supabase',
        bucket: process.env.STORAGE_BUCKET || 'alif-school',
    },
    // Logging
    logging: {
        level: process.env.LOG_LEVEL || 'info',
        format: process.env.LOG_FORMAT || 'json',
    },
    // CORS Configuration
    cors: {
        origins: (process.env.CORS_ORIGINS || 'http://localhost:3000,http://localhost:3001').split(','),
        credentials: process.env.CORS_CREDENTIALS !== 'false',
    },
    // API Rate Limiting
    rateLimit: {
        windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '900000', 10), // 15 minutes
        maxRequests: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100', 10),
    },
    // Database
    database: {
        pool: {
            min: parseInt(process.env.DB_POOL_MIN || '2', 10),
            max: parseInt(process.env.DB_POOL_MAX || '10', 10),
        },
    },
};
/**
 * Validate that all required environment variables are set
 */
function validateConfig() {
    const requiredVars = [
        'SUPABASE_URL',
        'SUPABASE_ANON_KEY',
        'SUPABASE_SERVICE_ROLE_KEY',
    ];
    const missing = requiredVars.filter((varName) => !process.env[varName]);
    if (missing.length > 0) {
        console.warn(`⚠️  Warning: Missing environment variables: ${missing.join(', ')}. 
       Please set them in your .env file before deploying to production.`);
    }
    if (exports.config.app.env === 'production' && missing.length > 0) {
        throw new Error(`❌ Required environment variables missing in production: ${missing.join(', ')}`);
    }
}
exports.default = exports.config;
//# sourceMappingURL=config.js.map