/**
 * Supabase Client Configuration
 * 
 * Single source for Supabase client initialization
 * Used for database operations, authentication, and file storage
 */

import { createClient } from '@supabase/supabase-js';
import type { SupabaseClient } from '@supabase/supabase-js';
import config from './config';

// Initialize Supabase client with service role (for server-side operations)
let supabaseClient: SupabaseClient | null = null;

/**
 * Get or create Supabase client
 */
export function getSupabaseClient(): SupabaseClient {
  if (!supabaseClient) {
    if (!config.supabase.url || !config.supabase.serviceKey) {
      throw new Error('Supabase configuration is missing. Please check your .env file.');
    }

    supabaseClient = createClient(
      config.supabase.url,
      config.supabase.serviceKey,
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      }
    );
  }

  return supabaseClient;
}

/**
 * Get Supabase client with anon key (for client-side operations)
 */
export function getSupabaseAnonClient(): SupabaseClient {
  if (!config.supabase.url || !config.supabase.anonKey) {
    throw new Error('Supabase configuration is missing. Please check your .env file.');
  }

  return createClient(
    config.supabase.url,
    config.supabase.anonKey,
    {
      auth: {
        autoRefreshToken: true,
        persistSession: true,
      },
    }
  );
}

/**
 * Initialize database tables and schema
 * Run this once during setup
 */
export async function initializeSupabaseSchema(): Promise<void> {
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
    } else if (!error) {
      console.log('✅ Supabase schema is initialized');
    } else {
      throw error;
    }
  } catch (error) {
    console.error('❌ Error initializing Supabase schema:', error);
    throw error;
  }
}

export default getSupabaseClient();
