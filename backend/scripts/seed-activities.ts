/**
 * Seed Data Script
 * 
 * Populates the Alif Online Moral School database with initial master data:
 * - Activity Categories (Prayer, Quran, Daily Routine, etc.)
 * - Activities (Subhi, Zuhr, Quran Reading, etc.)
 * - Activity Ratings (Excellent, Satisfactory, Needs Improvement, Not Done)
 * 
 * Run with: npx ts-node scripts/seed-activities.ts
 * 
 * This is a one-time setup script. For production, consider using Supabase migrations
 * or a proper database seeding tool.
 */

import { createClient } from '@supabase/supabase-js';
import * as dotenv from 'dotenv';
dotenv.config();

/**
 * Initialize Supabase client
 * Uses environment variables: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
 */
function initSupabaseClient() {
  const supabaseUrl = process.env.SUPABASE_URL;
  const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  
  if (!supabaseUrl || !supabaseKey) {
    throw new Error('Missing Supabase environment variables');
  }
  
  return createClient(supabaseUrl, supabaseKey);
}

/**
 * Activity Categories with English and Malayalam names
 * 
 * These are the main categories displayed on the daily marking screen
 */
const ACTIVITY_CATEGORIES = [
  {
    id: 'cat-salah',
    name: 'Salah (Prayer)',
    name_ml: 'നമസ്സ്',
    icon: '🙏',
    display_order: 1,
    status: 'active',
  },
  {
    id: 'cat-quran',
    name: 'Quran',
    name_ml: 'ഖുറാൻ',
    icon: '📖',
    display_order: 2,
    status: 'active',
  },
  {
    id: 'cat-dua',
    name: 'Dua & Dhikr',
    name_ml: 'ദുഅാ & തിക്കിർ',
    icon: '✨',
    display_order: 3,
    status: 'active',
  },
  {
    id: 'cat-sunnah',
    name: 'Sunnah Practices',
    name_ml: 'സുന്നത്',
    icon: '🌟',
    display_order: 4,
    status: 'active',
  },
  {
    id: 'cat-akhlaq',
    name: 'Good Character (Akhlaq)',
    name_ml: 'നല്ല സ്വഭാവം',
    icon: '💎',
    display_order: 5,
    status: 'active',
  },
  {
    id: 'cat-lifestyle',
    name: 'Healthy Lifestyle',
    name_ml: 'ആരോഗ്യകരമായ ജീവിതശൈലി',
    icon: '🏃',
    display_order: 6,
    status: 'active',
  },
];

/**
 * Activities for each category
 * Each activity can have optional quantity tracking (pages, minutes, etc.)
 */
const ACTIVITIES = [
  // Salah (Prayer)
  {
    id: 'act-subhi',
    category_id: 'cat-salah',
    name: 'Subhi Prayer',
    name_ml: 'സുബ്ഹ് നമസ്സ്',
    display_order: 1,
    has_quantity: false,
    status: 'active',
  },
  {
    id: 'act-zuhr',
    category_id: 'cat-salah',
    name: 'Zuhr Prayer',
    name_ml: 'സോമ നമസ്സ്',
    display_order: 2,
    has_quantity: false,
    status: 'active',
  },
  {
    id: 'act-asr',
    category_id: 'cat-salah',
    name: 'Asr Prayer',
    name_ml: 'അസർ നമസ്സ്',
    display_order: 3,
    has_quantity: false,
    status: 'active',
  },
  {
    id: 'act-maghrib',
    category_id: 'cat-salah',
    name: 'Maghrib Prayer',
    name_ml: 'മഗ്രിബ് നമസ്സ്',
    display_order: 4,
    has_quantity: false,
    status: 'active',
  },
  {
    id: 'act-isha',
    category_id: 'cat-salah',
    name: 'Isha Prayer',
    name_ml: 'ഇശാ നമസ്സ്',
    display_order: 5,
    has_quantity: false,
    status: 'active',
  },

  // Quran
  {
    id: 'act-quran-reading',
    category_id: 'cat-quran',
    name: 'Quran Reading',
    name_ml: 'ഖുറാൻ വായന',
    display_order: 1,
    has_quantity: true,
    status: 'active',
  },
  {
    id: 'act-quran-memorization',
    category_id: 'cat-quran',
    name: 'Quran Memorization',
    name_ml: 'ഖുറാൻ മുഖാണ്ഠനം',
    display_order: 2,
    has_quantity: true,
    status: 'active',
  },
  {
    id: 'act-tafsir',
    category_id: 'cat-quran',
    name: 'Quran Study (Tafsir)',
    name_ml: 'ഖുറാൻ പഠനം',
    display_order: 3,
    has_quantity: false,
    status: 'active',
  },

  // Dua & Dhikr
  {
    id: 'act-morning-dua',
    category_id: 'cat-dua',
    name: 'Morning Dua',
    name_ml: 'ഉത്തരപ്രഭാത ദുഅാ',
    display_order: 1,
    has_quantity: false,
    status: 'active',
  },
  {
    id: 'act-evening-dua',
    category_id: 'cat-dua',
    name: 'Evening Dua',
    name_ml: 'സന്ധ്യാ ദുഅാ',
    display_order: 2,
    has_quantity: false,
    status: 'active',
  },
  {
    id: 'act-dhikr',
    category_id: 'cat-dua',
    name: 'Dhikr (Remembrance)',
    name_ml: 'തിക്കിർ',
    display_order: 3,
    has_quantity: true,
    status: 'active',
  },

  // Sunnah Practices
  {
    id: 'act-sunnah-prayer',
    category_id: 'cat-sunnah',
    name: 'Sunnah Prayers (Rawatib)',
    name_ml: 'സുന്നത് നമസ്സ്',
    display_order: 1,
    has_quantity: false,
    status: 'active',
  },
  {
    id: 'act-tahajjud',
    category_id: 'cat-sunnah',
    name: 'Tahajjud (Night Prayer)',
    name_ml: 'തഹജ്ജുദ്',
    display_order: 2,
    has_quantity: false,
    status: 'active',
  },
  {
    id: 'act-fasting',
    category_id: 'cat-sunnah',
    name: 'Voluntary Fasting',
    name_ml: 'സ്വേച്ഛാ നാളിന ഉപവാസം',
    display_order: 3,
    has_quantity: false,
    status: 'active',
  },

  // Good Character
  {
    id: 'act-kindness',
    category_id: 'cat-akhlaq',
    name: 'Kindness & Compassion',
    name_ml: 'കരുണ ഭരണ',
    display_order: 1,
    has_quantity: false,
    status: 'active',
  },
  {
    id: 'act-honesty',
    category_id: 'cat-akhlaq',
    name: 'Honesty & Integrity',
    name_ml: 'സത്യനിഷ്ഠ',
    display_order: 2,
    has_quantity: false,
    status: 'active',
  },
  {
    id: 'act-respect',
    category_id: 'cat-akhlaq',
    name: 'Respect to Elders',
    name_ml: 'മുതിർജനങ്ങളോട് സമ്മാനം',
    display_order: 3,
    has_quantity: false,
    status: 'active',
  },
  {
    id: 'act-helping',
    category_id: 'cat-akhlaq',
    name: 'Helping Family',
    name_ml: 'കുടുംബത്തെ സഹായിക്കൽ',
    display_order: 4,
    has_quantity: false,
    status: 'active',
  },

  // Healthy Lifestyle
  {
    id: 'act-exercise',
    category_id: 'cat-lifestyle',
    name: 'Physical Exercise',
    name_ml: 'വ്യായാമം',
    display_order: 1,
    has_quantity: true,
    status: 'active',
  },
  {
    id: 'act-healthy-food',
    category_id: 'cat-lifestyle',
    name: 'Healthy Eating',
    name_ml: 'ആരോഗ്യകരമായ ഭക്ഷണം',
    display_order: 2,
    has_quantity: false,
    status: 'active',
  },
  {
    id: 'act-sleep',
    category_id: 'cat-lifestyle',
    name: 'Good Sleep Habits',
    name_ml: 'നല്ല ഉറക്കം',
    display_order: 3,
    has_quantity: false,
    status: 'active',
  },
];

/**
 * Rating options (shared across all activities)
 * These are the standard ratings in Phase 1
 */
const RATING_OPTIONS = [
  {
    id: 'rating-excellent',
    rating_name: 'Excellent',
    rating_name_ml: 'ഉത്തമം',
    marks: 10,
    color: '#4CAF50',
    display_order: 1,
  },
  {
    id: 'rating-satisfactory',
    rating_name: 'Satisfactory',
    rating_name_ml: 'സാധാരണം',
    marks: 5,
    color: '#FFC107',
    display_order: 2,
  },
  {
    id: 'rating-needs-improvement',
    rating_name: 'Needs Improvement',
    rating_name_ml: 'സുധരിതേയും',
    marks: 2,
    color: '#FF9800',
    display_order: 3,
  },
  {
    id: 'rating-not-done',
    rating_name: 'Not Done',
    rating_name_ml: 'ചെയ്യാതിരുന്നത്',
    marks: 0,
    color: '#9E9E9E',
    display_order: 4,
  },
];

/**
 * Main seed function
 */
async function seedDatabase() {
  const supabase = initSupabaseClient();
  
  console.log('🌱 Starting database seed...\n');
  
  try {
    // Seed Categories
    console.log('📚 Seeding activity categories...');
    const { error: catError } = await supabase
      .from('activity_categories')
      .insert(ACTIVITY_CATEGORIES);
    
    if (catError) throw new Error(`Category seed failed: ${catError.message}`);
    console.log(`✅ Seeded ${ACTIVITY_CATEGORIES.length} categories\n`);
    
    // Seed Activities
    console.log('📝 Seeding activities...');
    const { error: actError } = await supabase
      .from('activities')
      .insert(ACTIVITIES);
    
    if (actError) throw new Error(`Activity seed failed: ${actError.message}`);
    console.log(`✅ Seeded ${ACTIVITIES.length} activities\n`);
    
    // Seed Ratings (for each activity)
    console.log('⭐ Seeding activity ratings...');
    const ratingsToInsert = ACTIVITIES.flatMap(activity =>
      RATING_OPTIONS.map(rating => ({
        ...rating,
        activity_id: activity.id,
      }))
    );
    
    const { error: ratingError } = await supabase
      .from('activity_ratings')
      .insert(ratingsToInsert);
    
    if (ratingError) throw new Error(`Rating seed failed: ${ratingError.message}`);
    console.log(`✅ Seeded ${ratingsToInsert.length} ratings\n`);
    
    // Verify counts
    const { data: catCount } = await supabase
      .from('activity_categories')
      .select('id', { count: 'exact' });
    
    const { data: actCount } = await supabase
      .from('activities')
      .select('id', { count: 'exact' });
    
    const { data: ratingCount } = await supabase
      .from('activity_ratings')
      .select('id', { count: 'exact' });
    
    console.log('📊 Database verification:');
    console.log(`   Categories: ${catCount?.length ?? 0}`);
    console.log(`   Activities: ${actCount?.length ?? 0}`);
    console.log(`   Ratings: ${ratingCount?.length ?? 0}`);
    console.log('\n✨ Database seed completed successfully!');
    
  } catch (error) {
    console.error('\n❌ Seed failed:', (error as Error).message);
    process.exit(1);
  }
}

/**
 * Clear all seeded data (for testing/reset)
 * Use with caution!
 */
export async function clearSeedData() {
  const supabase = initSupabaseClient();
  
  console.log('🗑️  Clearing seeded data...');
  
  try {
    // Delete in reverse order to respect foreign keys
    await supabase.from('activity_ratings').delete().gte('id', '');
    console.log('   ✅ Ratings cleared');
    
    await supabase.from('activities').delete().gte('id', '');
    console.log('   ✅ Activities cleared');
    
    await supabase.from('activity_categories').delete().gte('id', '');
    console.log('   ✅ Categories cleared');
    
    console.log('\n✨ All seed data cleared!');
  } catch (error) {
    console.error('❌ Clear failed:', (error as Error).message);
    process.exit(1);
  }
}

/**
 * Run script
 * 
 * Set environment variables first:
 * export SUPABASE_URL=your_url
 * export SUPABASE_SERVICE_ROLE_KEY=your_key
 * 
 * Then run:
 * npx ts-node scripts/seed-activities.ts
 */
if (require.main === module) {
  seedDatabase();
}

export { seedDatabase, ACTIVITY_CATEGORIES, ACTIVITIES, RATING_OPTIONS };
