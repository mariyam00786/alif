/**
 * Full Database Seed Script
 * Run: node scripts/seed-all.js
 */

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function clearExisting() {
  console.log('🧹 Clearing existing master data...');
  await supabase.from('activity_ratings').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('activities').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('activity_categories').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('student_badges').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('badges').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('teacher_batches').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('classes').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('batches').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  console.log('✅ Cleared\n');
}

async function seed() {
  console.log('🌱 Starting full database seed...\n');

  const { count: existingCats } = await supabase
    .from('activity_categories').select('*', { count: 'exact', head: true });
  if (existingCats > 0) await clearExisting();

  // 1. ACTIVITY CATEGORIES
  console.log('📚 Seeding activity categories...');
  const { data: cats, error: catErr } = await supabase
    .from('activity_categories')
    .insert([
      { name: 'Salah (Prayer)',           name_ml: 'നമസ്കാരം',                   icon: '🙏', display_order: 1 },
      { name: 'Quran',                    name_ml: 'ഖുർആൻ',                      icon: '📖', display_order: 2 },
      { name: 'Dua & Dhikr',             name_ml: 'ദുആ & ദിക്ർ',               icon: '✨', display_order: 3 },
      { name: 'Sunnah Practices',        name_ml: 'സുന്നത്ത്',                  icon: '🌟', display_order: 4 },
      { name: 'Good Character (Akhlaq)', name_ml: 'സ്വഭാവഗുണം',               icon: '💎', display_order: 5 },
      { name: 'Healthy Lifestyle',       name_ml: 'ആരോഗ്യകരമായ ജീവിതശൈലി',   icon: '🏃', display_order: 6 },
    ])
    .select();

  if (catErr) { console.error('❌ Categories failed:', catErr.message); process.exit(1); }
  console.log(`✅ ${cats.length} categories seeded\n`);

  const catMap = Object.fromEntries(cats.map(c => [c.name, c.id]));

  // 2. ACTIVITIES
  console.log('📝 Seeding activities...');
  const activities = [
    { category_id: catMap['Salah (Prayer)'],           name: 'Subhi Prayer',         name_ml: 'സുബ്ഹ് നമസ്കാരം',        display_order: 1, has_quantity: false },
    { category_id: catMap['Salah (Prayer)'],           name: 'Zuhr Prayer',          name_ml: 'ളുഹ്ർ നമസ്കാരം',        display_order: 2, has_quantity: false },
    { category_id: catMap['Salah (Prayer)'],           name: 'Asr Prayer',           name_ml: 'അസർ നമസ്കാരം',          display_order: 3, has_quantity: false },
    { category_id: catMap['Salah (Prayer)'],           name: 'Maghrib Prayer',       name_ml: 'മഗ്രിബ് നമസ്കാരം',      display_order: 4, has_quantity: false },
    { category_id: catMap['Salah (Prayer)'],           name: 'Isha Prayer',          name_ml: 'ഇശാ നമസ്കാരം',          display_order: 5, has_quantity: false },
    { category_id: catMap['Quran'],                    name: 'Quran Reading',        name_ml: 'ഖുർആൻ പാരായണം',         display_order: 1, has_quantity: true  },
    { category_id: catMap['Quran'],                    name: 'Quran Memorization',   name_ml: 'ഖുർആൻ ഹിഫ്ദ്',          display_order: 2, has_quantity: true  },
    { category_id: catMap['Quran'],                    name: 'Quran Study (Tafsir)', name_ml: 'ഖുർആൻ പഠനം',            display_order: 3, has_quantity: false },
    { category_id: catMap['Dua & Dhikr'],              name: 'Morning Dua',          name_ml: 'പ്രഭാത ദുആ',             display_order: 1, has_quantity: false },
    { category_id: catMap['Dua & Dhikr'],              name: 'Evening Dua',          name_ml: 'സന്ധ്യ ദുആ',             display_order: 2, has_quantity: false },
    { category_id: catMap['Dua & Dhikr'],              name: 'Dhikr',                name_ml: 'ദിക്ർ',                  display_order: 3, has_quantity: true  },
    { category_id: catMap['Sunnah Practices'],         name: 'Sunnah Prayer',        name_ml: 'സുന്നത്ത് നമസ്കാരം',     display_order: 1, has_quantity: false },
    { category_id: catMap['Sunnah Practices'],         name: 'Fasting (Siyam)',      name_ml: 'നോമ്പ്',                 display_order: 2, has_quantity: false },
    { category_id: catMap['Sunnah Practices'],         name: 'Sadaqah',              name_ml: 'സദഖ',                    display_order: 3, has_quantity: false },
    { category_id: catMap['Good Character (Akhlaq)'], name: 'Helping Others',       name_ml: 'മറ്റുള്ളവരെ സഹായിക്കൽ', display_order: 1, has_quantity: false },
    { category_id: catMap['Good Character (Akhlaq)'], name: 'Respecting Elders',    name_ml: 'മൂത്തവരെ ബഹുമാനിക്കൽ',  display_order: 2, has_quantity: false },
    { category_id: catMap['Healthy Lifestyle'],        name: 'Exercise',             name_ml: 'വ്യായാമം',               display_order: 1, has_quantity: true  },
    { category_id: catMap['Healthy Lifestyle'],        name: 'Early Sleep',          name_ml: 'നേരത്തേ ഉറക്കം',        display_order: 2, has_quantity: false },
  ];

  const { data: acts, error: actErr } = await supabase
    .from('activities').insert(activities).select();

  if (actErr) { console.error('❌ Activities failed:', actErr.message); process.exit(1); }
  console.log(`✅ ${acts.length} activities seeded\n`);

  // 3. RATINGS (4 ratings per activity)
  console.log('⭐ Seeding activity ratings...');
  const ratings = [
    { rating_name: 'Excellent',         rating_name_ml: 'മികച്ചത്',      marks: 10, color: '#4CAF50', display_order: 1 },
    { rating_name: 'Good',              rating_name_ml: 'നല്ലത്',         marks: 7,  color: '#2196F3', display_order: 2 },
    { rating_name: 'Needs Improvement', rating_name_ml: 'മെച്ചപ്പെടണം', marks: 4,  color: '#FF9800', display_order: 3 },
    { rating_name: 'Not Done',          rating_name_ml: 'ചെയ്തില്ല',     marks: 0,  color: '#9E9E9E', display_order: 4 },
  ];
  const allRatings = acts.flatMap(act => ratings.map(r => ({ ...r, activity_id: act.id })));

  const { data: ratingData, error: ratingErr } = await supabase
    .from('activity_ratings').insert(allRatings).select();

  if (ratingErr) { console.error('❌ Ratings failed:', ratingErr.message); process.exit(1); }
  console.log(`✅ ${ratingData.length} ratings seeded\n`);

  // 4. BATCHES
  console.log('🏫 Seeding batches...');
  const { data: batches, error: batchErr } = await supabase
    .from('batches')
    .insert([
      { name: 'Morning Batch',  name_ml: 'പ്രഭാത ബാച്ച്',    capacity: 30, timing: '6:00 AM - 8:00 AM', status: 'active' },
      { name: 'Evening Batch',  name_ml: 'സന്ധ്യ ബാച്ച്',     capacity: 30, timing: '5:00 PM - 7:00 PM', status: 'active' },
      { name: 'Weekend Batch',  name_ml: 'വീക്കെൻഡ് ബാച്ച്', capacity: 40, timing: 'Sat & Sun 9:00 AM', status: 'active' },
    ])
    .select();

  if (batchErr) { console.error('❌ Batches failed:', batchErr.message); process.exit(1); }
  console.log(`✅ ${batches.length} batches seeded\n`);

  // 5. CLASSES
  console.log('📋 Seeding classes...');
  const { data: classes, error: classErr } = await supabase
    .from('classes')
    .insert([
      { name: 'Beginners',    name_ml: 'തുടക്കക്കാർ', level: 'beginner',     batch_id: batches[0].id, status: 'active' },
      { name: 'Intermediate', name_ml: 'ഇടക്കാർ',      level: 'intermediate', batch_id: batches[0].id, status: 'active' },
      { name: 'Advanced',     name_ml: 'മുൻനിര',       level: 'advanced',     batch_id: batches[1].id, status: 'active' },
      { name: 'Junior',       name_ml: 'ജൂനിയർ',       level: 'beginner',     batch_id: batches[1].id, status: 'active' },
      { name: 'Senior',       name_ml: 'സീനിയർ',       level: 'advanced',     batch_id: batches[2].id, status: 'active' },
    ])
    .select();

  if (classErr) { console.error('❌ Classes failed:', classErr.message); process.exit(1); }
  console.log(`✅ ${classes.length} classes seeded\n`);

  // 6. BADGES
  console.log('🏅 Seeding badges...');
  const { data: badgesData, error: badgeErr } = await supabase
    .from('badges')
    .insert([
      { name: 'Prayer Warrior', name_ml: 'നമസ്കാര വീരൻ',     description: 'All 5 prayers for 7 days',   icon: '🏆', bonus_points: 50,  criteria: { type: 'prayer_streak', days: 7  } },
      { name: 'Quran Reader',   name_ml: 'ഖുർആൻ വായനക്കാരൻ', description: 'Read Quran for 30 days',      icon: '📖', bonus_points: 100, criteria: { type: 'quran_streak',  days: 30 } },
      { name: 'Perfect Week',   name_ml: 'മികച്ച ആഴ്ച',       description: 'All activities for a week',  icon: '⭐', bonus_points: 75,  criteria: { type: 'perfect_week',  count: 1 } },
      { name: 'Early Bird',     name_ml: 'അതിരാവിലെ',         description: 'Subhi on time for 10 days',  icon: '🌅', bonus_points: 40,  criteria: { type: 'subhi_streak',  days: 10 } },
      { name: 'Dhikr Champion', name_ml: 'ദിക്ർ ചാമ്പ്യൻ',    description: 'Daily dhikr for 15 days',    icon: '✨', bonus_points: 60,  criteria: { type: 'dhikr_streak',  days: 15 } },
      { name: 'Good Character', name_ml: 'നല്ല സ്വഭാവം',      description: 'Akhlaq activities 21 days',  icon: '💎', bonus_points: 80,  criteria: { type: 'akhlaq_streak', days: 21 } },
    ])
    .select();

  if (badgeErr) { console.error('❌ Badges failed:', badgeErr.message); process.exit(1); }
  console.log(`✅ ${badgesData.length} badges seeded\n`);

  // SUMMARY
  console.log('╔══════════════════════════════════════════╗');
  console.log('║         ✅ Seed Complete!                ║');
  console.log('╠══════════════════════════════════════════╣');
  console.log(`║  Activity Categories : ${String(cats.length).padEnd(17)}║`);
  console.log(`║  Activities          : ${String(acts.length).padEnd(17)}║`);
  console.log(`║  Activity Ratings    : ${String(ratingData.length).padEnd(17)}║`);
  console.log(`║  Batches             : ${String(batches.length).padEnd(17)}║`);
  console.log(`║  Classes             : ${String(classes.length).padEnd(17)}║`);
  console.log(`║  Badges              : ${String(badgesData.length).padEnd(17)}║`);
  console.log('╚══════════════════════════════════════════╝');
}

seed().catch(err => {
  console.error('❌ Seed failed:', err.message);
  process.exit(1);
});
