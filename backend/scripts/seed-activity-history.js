/**
 * Seed realistic activity logs for the last 30 days.
 * Run: node scripts/seed-activity-history.js
 */

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

function mulberry32(seed) {
  return function () {
    let t = (seed += 0x6d2b79f5);
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function dateOnly(d) {
  return d.toISOString().slice(0, 10);
}

function pickWeighted(rnd, items) {
  const total = items.reduce((sum, item) => sum + item.weight, 0);
  let roll = rnd() * total;
  for (const item of items) {
    roll -= item.weight;
    if (roll <= 0) return item.value;
  }
  return items[items.length - 1].value;
}

function quantityForActivity(name, rnd) {
  const lower = name.toLowerCase();

  if (lower.includes('reading') || lower.includes('quran')) {
    return 1 + Math.floor(rnd() * 5); // pages
  }
  if (lower.includes('memorization')) {
    return 1 + Math.floor(rnd() * 4); // ayat/lines
  }
  if (lower.includes('dhikr')) {
    return 10 + Math.floor(rnd() * 91); // count 10..100
  }
  if (lower.includes('exercise')) {
    return 10 + Math.floor(rnd() * 31); // minutes 10..40
  }

  return null;
}

async function seedActivityHistory() {
  console.log('Starting activity history seed...\n');

  const { data: students, error: studentsErr } = await supabase
    .from('students')
    .select('id, profile_id')
    .order('created_at', { ascending: true });
  if (studentsErr) throw new Error(`Students fetch failed: ${studentsErr.message}`);
  if (!students || students.length === 0) throw new Error('No students found. Seed students first.');

  const { data: activities, error: activitiesErr } = await supabase
    .from('activities')
    .select('id, name, has_quantity, display_order')
    .eq('status', 'active')
    .order('display_order', { ascending: true })
    .limit(10);
  if (activitiesErr) throw new Error(`Activities fetch failed: ${activitiesErr.message}`);
  if (!activities || activities.length === 0) throw new Error('No activities found. Seed master data first.');

  const activityIds = activities.map((a) => a.id);
  const { data: ratings, error: ratingsErr } = await supabase
    .from('activity_ratings')
    .select('id, activity_id, marks, rating_name')
    .in('activity_id', activityIds)
    .order('marks', { ascending: false });
  if (ratingsErr) throw new Error(`Ratings fetch failed: ${ratingsErr.message}`);

  const ratingsByActivity = {};
  for (const r of ratings) {
    if (!ratingsByActivity[r.activity_id]) ratingsByActivity[r.activity_id] = [];
    ratingsByActivity[r.activity_id].push(r);
  }

  const today = new Date();
  const days = 30;

  const rows = [];

  for (let sIndex = 0; sIndex < students.length; sIndex += 1) {
    const student = students[sIndex];
    const rnd = mulberry32(1000 + sIndex * 1337);

    for (let d = 0; d < days; d += 1) {
      const dt = new Date(today);
      dt.setDate(today.getDate() - d);
      const logDate = dateOnly(dt);

      for (const activity of activities) {
        const completed = rnd() < 0.88;
        if (!completed) continue;

        const options = ratingsByActivity[activity.id] || [];
        if (options.length === 0) continue;

        const chosenMarks = pickWeighted(rnd, [
          { value: 10, weight: 45 },
          { value: 7, weight: 35 },
          { value: 4, weight: 15 },
          { value: 0, weight: 5 },
        ]);

        let selected = options.find((o) => o.marks === chosenMarks);
        if (!selected) {
          selected = options[0];
        }

        rows.push({
          student_id: student.id,
          activity_id: activity.id,
          rating_id: selected.id,
          log_date: logDate,
          quantity: activity.has_quantity ? quantityForActivity(activity.name, rnd) : null,
          marks_earned: selected.marks,
          parent_approved: rnd() < 0.75,
          notes: rnd() < 0.12 ? 'Auto-seeded progress entry' : null,
        });
      }
    }
  }

  const chunkSize = 500;
  let inserted = 0;
  for (let i = 0; i < rows.length; i += chunkSize) {
    const chunk = rows.slice(i, i + chunkSize);
    const { error } = await supabase
      .from('activity_logs')
      .upsert(chunk, { onConflict: 'student_id,activity_id,log_date' });
    if (error) throw new Error(`Upsert failed at chunk ${i / chunkSize + 1}: ${error.message}`);
    inserted += chunk.length;
  }

  const { count: totalLogs, error: countErr } = await supabase
    .from('activity_logs')
    .select('*', { count: 'exact', head: true });
  if (countErr) throw new Error(`Count failed: ${countErr.message}`);

  console.log('Seed complete.');
  console.log(`Students: ${students.length}`);
  console.log(`Activities used: ${activities.length}`);
  console.log(`Rows upserted: ${inserted}`);
  console.log(`Total activity_logs now: ${totalLogs}`);
}

seedActivityHistory().catch((err) => {
  console.error('Seed failed:', err.message);
  process.exit(1);
});
