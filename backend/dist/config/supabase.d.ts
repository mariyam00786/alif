/**
 * Supabase Client Configuration
 *
 * Single source for Supabase client initialization
 * Used for database operations, authentication, and file storage
 */
import type { SupabaseClient } from '@supabase/supabase-js';
/**
 * Get or create Supabase client
 */
export declare function getSupabaseClient(): SupabaseClient;
/**
 * Get Supabase client with anon key (for client-side operations)
 */
export declare function getSupabaseAnonClient(): SupabaseClient;
/**
 * Initialize database tables and schema
 * Run this once during setup
 */
export declare function initializeSupabaseSchema(): Promise<void>;
declare const _default: SupabaseClient<any, "public", "public", any, any>;
export default _default;
//# sourceMappingURL=supabase.d.ts.map