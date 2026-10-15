/**
 * Supabase Client Configuration
 * 
 * Single source for Supabase client initialization
 * Used for database operations, authentication, and file storage
 */

import { createClient } from '@supabase/supabase-js';
import type { SupabaseClient } from '@supabase/supabase-js';
import config from './config';

// Circuit breaker state for offline resilience
let lastFailedAt = 0;
const OFFLINE_COOLDOWN_MS = 30000;

export function isSupabaseOffline(): boolean {
  return Date.now() - lastFailedAt < OFFLINE_COOLDOWN_MS;
}

export function markSupabaseOffline(): void {
  lastFailedAt = Date.now();
}

const safeFetch: typeof fetch = async (input, init) => {
  if (isSupabaseOffline()) {
    throw new Error('Supabase is currently unreachable (circuit breaker active)');
  }

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 1500);

  try {
    const res = await fetch(input as any, {
      ...init,
      signal: controller.signal,
    });
    clearTimeout(timer);
    return res;
  } catch (err: any) {
    clearTimeout(timer);
    markSupabaseOffline();
    throw err;
  }
};

// Initialize Supabase client with service role (for server-side operations)
let supabaseClient: SupabaseClient | null = null;

/**
 * Get or create Supabase client
 */
export function getSupabaseClient(): SupabaseClient {
  if (!supabaseClient) {
    const hasConfig = Boolean(config.supabase.url && config.supabase.serviceKey);
    if (!hasConfig) {
      console.warn('⚠️ Supabase configuration missing. Falling back to offline mock mode.');
      markSupabaseOffline();
    }

    const url = config.supabase.url || 'https://placeholder-offline.supabase.co';
    const key = config.supabase.serviceKey || 'placeholder-service-key';

    supabaseClient = createClient(
      url,
      key,
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
        global: {
          fetch: safeFetch,
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
  const url = config.supabase.url || 'https://placeholder-offline.supabase.co';
  const key = config.supabase.anonKey || 'placeholder-anon-key';

  return createClient(
    url,
    key,
    {
      auth: {
        autoRefreshToken: true,
        persistSession: true,
      },
      global: {
        fetch: safeFetch,
      },
    }
  );
}

/**
 * Initialize database tables and schema
 * Run this once during setup
 */
export async function initializeSupabaseSchema(): Promise<void> {
  if (!config.supabase.url || !config.supabase.serviceKey) {
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
    } else if (!error) {
      console.log('✅ Supabase schema is initialized');
    } else {
      throw error;
    }
  } catch (error) {
    console.error('❌ Error initializing Supabase schema:', error);
  }
}

export default getSupabaseClient();
