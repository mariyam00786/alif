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
exports.getSupabaseClient = getSupabaseClient;
exports.getSupabaseAnonClient = getSupabaseAnonClient;
exports.initializeSupabaseSchema = initializeSupabaseSchema;
const supabase_js_1 = require("@supabase/supabase-js");
const config_1 = __importDefault(require("./config"));
// Initialize Supabase client with service role (for server-side operations)
let supabaseClient = null;
/**
 * Get or create Supabase client
 */
function getSupabaseClient() {
    if (!supabaseClient) {
        if (!config_1.default.supabase.url || !config_1.default.supabase.serviceKey) {
            throw new Error('Supabase configuration is missing. Please check your .env file.');
        }
        supabaseClient = (0, supabase_js_1.createClient)(config_1.default.supabase.url, config_1.default.supabase.serviceKey, {
            auth: {
                autoRefreshToken: false,
                persistSession: false,
            },
        });
    }
    return supabaseClient;
}
/**
 * Get Supabase client with anon key (for client-side operations)
 */
function getSupabaseAnonClient() {
    if (!config_1.default.supabase.url || !config_1.default.supabase.anonKey) {
        throw new Error('Supabase configuration is missing. Please check your .env file.');
    }
    return (0, supabase_js_1.createClient)(config_1.default.supabase.url, config_1.default.supabase.anonKey, {
        auth: {
            autoRefreshToken: true,
            persistSession: true,
        },
    });
}
/**
 * Initialize database tables and schema
 * Run this once during setup
 */
async function initializeSupabaseSchema() {
    const client = getSupabaseClient();
    try {
        console.log('🔄 Initializing Supabase schema...');
        // Schema will be created via migration files
        // This is just a verification check
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
        throw error;
    }
}
exports.default = getSupabaseClient();
//# sourceMappingURL=supabase.js.map