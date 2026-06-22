/**
 * Environment Configuration
 * 
 * All configuration is read from environment variables
 * Never commit sensitive information to version control
 */

import dotenv from 'dotenv';

// Load environment variables from .env file
dotenv.config();

export const config = {
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

  // MsgHex WhatsApp OTP provider
  msghex: {
    apiUrl: process.env.MSGHEX_API_URL || 'https://api.msghex.com',
    secret: process.env.MSGHEX_API_SECRET || '',
    account: process.env.MSGHEX_SESSION_ID || '',
    messageTemplate:
      process.env.MSGHEX_OTP_TEMPLATE ||
      'Your Alif School verification code is {{otp}}. Valid for 5 minutes.',
    otpTtlSeconds: parseInt(process.env.MSGHEX_OTP_TTL || '300', 10), // 5 minutes
    maxVerifyAttempts: parseInt(process.env.OTP_MAX_ATTEMPTS || '5', 10),
    otpLength: parseInt(process.env.OTP_LENGTH || '4', 10),
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
} as const;

/**
 * Validate that all required environment variables are set
 */
export function validateConfig(): void {
  const requiredVars = [
    'SUPABASE_URL',
    'SUPABASE_ANON_KEY',
    'SUPABASE_SERVICE_ROLE_KEY',
  ];

  const missing = requiredVars.filter((varName) => !process.env[varName]);

  if (missing.length > 0) {
    console.warn(
      `⚠️  Warning: Missing environment variables: ${missing.join(', ')}. 
       Please set them in your .env file before deploying to production.`
    );
  }

  if (config.app.env === 'production' && missing.length > 0) {
    throw new Error(
      `❌ Required environment variables missing in production: ${missing.join(', ')}`
    );
  }
}

export default config;
