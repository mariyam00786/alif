"use strict";
/**
 * Supabase Client Configuration
 *
 * Single source for Supabase client initialization
 * Used for database operations, authentication, and file storage
 */
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.isSupabaseOffline = isSupabaseOffline;
exports.markSupabaseOffline = markSupabaseOffline;
exports.getSupabaseClient = getSupabaseClient;
exports.getSupabaseAnonClient = getSupabaseAnonClient;
exports.initializeSupabaseSchema = initializeSupabaseSchema;
const supabase_js_1 = require("@supabase/supabase-js");
const config_1 = __importDefault(require("./config"));
// Circuit breaker state for offline resilience
let lastFailedAt = 0;
const OFFLINE_COOLDOWN_MS = 30000;
function isSupabaseOffline() {
    return Date.now() - lastFailedAt < OFFLINE_COOLDOWN_MS;
}
function markSupabaseOffline() {
    lastFailedAt = Date.now();
}
const safeFetch = async (input, init) => {
    if (isSupabaseOffline()) {
        throw new Error('Supabase is currently unreachable (circuit breaker active)');
    }
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 1500);
    try {
        const res = await fetch(input, {
            ...init,
            signal: controller.signal,
        });
        clearTimeout(timer);
        return res;
    }
    catch (err) {
        clearTimeout(timer);
        markSupabaseOffline();
        throw err;
    }
};
// Initialize Supabase client with service role (for server-side operations)
let supabaseClient = null;
/**
 * Get or create Supabase client
 */
function getSupabaseClient() {
    if (!supabaseClient) {
        const hasConfig = Boolean(config_1.default.supabase.url && config_1.default.supabase.serviceKey);
        if (!hasConfig) {
            console.warn('⚠️ Supabase configuration missing. Falling back to offline mock mode.');
            markSupabaseOffline();
        }
        const url = config_1.default.supabase.url || 'https://placeholder-offline.supabase.co';
        const key = config_1.default.supabase.serviceKey || 'placeholder-service-key';
        supabaseClient = (0, supabase_js_1.createClient)(url, key, {
            auth: {
                autoRefreshToken: false,
                persistSession: false,
            },
            global: {
                fetch: safeFetch,
            },
        });
    }
    return supabaseClient;
}
/**
 * Get Supabase client with anon key (for client-side operations)
 */
function getSupabaseAnonClient() {
    const url = config_1.default.supabase.url || 'https://placeholder-offline.supabase.co';
    const key = config_1.default.supabase.anonKey || 'placeholder-anon-key';
    return (0, supabase_js_1.createClient)(url, key, {
        auth: {
            autoRefreshToken: true,
            persistSession: true,
        },
        global: {
            fetch: safeFetch,
        },
    });
}
/**
 * Initialize database tables and schema
 * Run this once during setup
 */
async function initializeSupabaseSchema() {
    if (!config_1.default.supabase.url || !config_1.default.supabase.serviceKey) {
        console.warn('⚠️ Skipping schema initialization: Supabase credentials not set.');
        return;
    }
    const client = getSupabaseClient();
    try {
        console.log('🔄 Initializing Supabase schema...');
        const { error } = await client
            .from('profiles')
            .select('id', { count: 'exact', head: true });
        if (error && error.code === 'PGRST116') {
            console.log('⚠️  Some tables do not exist. Please run migrations using Supabase CLI:');
            console.log('   npx supabase migration up');
        }
        else if (!error) {
            console.log('✅ Supabase schema is initialized');
        }
        else {
            throw error;
        }
    }
    catch (error) {
        console.error('❌ Error initializing Supabase schema:', error);
    }
}
exports.default = getSupabaseClient();
//# sourceMappingURL=supabase.js.map