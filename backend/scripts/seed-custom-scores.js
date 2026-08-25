/**
 * Seed custom activity logs to achieve exact scores for students:
 * - Afrin: 97
 * - Ameen Junior: 94
 * - Safa Mariyam: 89
 * - Huda Fathima: 73
 * 
 * Run: node scripts/seed-custom-scores.js
 */

require('dotenv').config({ path: 'c:/Users/My PC/alif/backend/.env' });
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function seedCustomScores() {
  console.log('Starting custom scores seeding...');

  // 1. Fetch students and profiles
  const { data: students, error: studentsErr } = await supabase
    .from('students')
    .select('id, profile_id, profiles(full_name)');
  if (studentsErr) throw studentsErr;

  console.log('Found students:', students.map(s => ({ id: s.id, name: s.profiles?.full_name })));

  // Find the specific students
  const afrin = students.find(s => s.profiles?.full_name === 'Afrin');
  const ameen = students.find(s => s.profiles?.full_name === 'Ameen Junior');
  const safa = students.find(s => s.profiles?.full_name === 'Safa Mariyam');
  const huda = students.find(s => s.profiles?.full_name === 'Huda Fathima');

  if (!afrin || !ameen || !safa || !huda) {
    console.error('Could not find all required students in the database!');
    console.log('Afrin:', !!afrin, 'Ameen:', !!ameen, 'Safa:', !!safa, 'Huda:', !!huda);
    return;
  }

  // 2. Fetch activities and ratings
  const { data: activities, error: activitiesErr } = await supabase
    .from('activities')
    .select('id, name, has_quantity')
    .eq('status', 'active');
  if (activitiesErr) throw activitiesErr;

  const { data: ratings, error: ratingsErr } = await supabase
    .from('activity_ratings')
    .select('id, activity_id, marks, rating_name');
  if (ratingsErr) throw ratingsErr;

  const ratingsByActivity = {};
  for (const r of ratings) {
    if (!ratingsByActivity[r.activity_id]) ratingsByActivity[r.activity_id] = [];
    ratingsByActivity[r.activity_id].push(r);
  }

  // 3. Clear existing logs
  console.log('Clearing existing activity logs...');
  const { error: deleteErr } = await supabase
    .from('activity_logs')
    .delete()
    .neq('id', '00000000-0000-0000-0000-000000000000');
  if (deleteErr) throw deleteErr;

  // 4. Generate logs to hit exact scores
  // The score is calculated as the sum of marks earned.
  // We want:
  // - Afrin: 97
  // - Ameen Junior: 94
  // - Safa Mariyam: 89
  // - Huda Fathima: 73
  // Let's distribute these scores across some activities.
  // For example, to get 97: 9 * 10 + 1 * 7 = 97.
  // To get 94: 9 * 10 + 1 * 4 = 94.
  // To get 89: 8 * 10 + 1 * 7 + 1 * 2 (wait, we only have 10, 7, 4, 0).
  // Let's see: 8 * 10 + 1 * 7 + 1 * 4 = 91.
  // Wait, how can we get 89?
  // 8 * 10 + 1 * 9? No, ratings only have 10, 7, 4, 0.
  // Wait, can we get 89 with 10, 7, 4?
  // Let's check:
  // 8 * 10 + 1 * 7 + 1 * 4 = 91.
  // 7 * 10 + 2 * 7 + 1 * 4 = 88.
  // 6 * 10 + 4 * 7 + 0 * 4 = 88.
  // 5 * 10 + 5 * 7 + 1 * 4 = 89! Yes! 5 * 10 + 5 * 7 + 1 * 4 = 50 + 35 + 4 = 89.
  // To get 73:
  // 5 * 10 + 3 * 7 + 1 * 4 = 50 + 21 + 4 = 75.
  // 4 * 10 + 4 * 7 + 1 * 4 = 40 + 28 + 4 = 72.
  // 5 * 10 + 2 * 7 + 2 * 4 = 50 + 14 + 8 = 72.
  // 6 * 10 + 1 * 7 + 1 * 4 + 1 * 0 = 60 + 7 + 4 = 71.
  // 3 * 10 + 6 * 7 + 0 * 4 = 30 + 42 = 72.
  // 2 * 10 + 7 * 7 + 1 * 4 = 20 + 49 + 4 = 73! Yes! 2 * 10 + 7 * 7 + 1 * 4 = 20 + 49 + 4 = 73.
  // Let's write a helper to find a combination of marks that sums to the target score.
  function findCombination(target) {
    for (let n10 = 0; n10 <= 20; n10++) {
      for (let n7 = 0; n7 <= 20; n7++) {
        for (let n4 = 0; n4 <= 20; n4++) {
          if (n10 * 10 + n7 * 7 + n4 * 4 === target) {
            return { 10: n10, 7: n7, 4: n4 };
          }
        }
      }
    }
    return null;
  }

  const targets = [
    { student: afrin, score: 97 },
    { student: ameen, score: 94 },
    { student: safa, score: 89 },
    { student: huda, score: 73 }
  ];

  const logsToInsert = [];
  const today = new Date();

  for (const t of targets) {
    const combo = findCombination(t.score);
    if (!combo) {
      console.error(`Could not find combination for score ${t.score}`);
      continue;
    }
    console.log(`Student ${t.student.profiles.full_name} target ${t.score} combo:`, combo);

    // We need to generate logs. Let's distribute them over different activities and dates.
    let dateOffset = 0;
    let activityIndex = 0;

    const addLogsForMark = (mark, count) => {
      for (let i = 0; i < count; i++) {
        const activity = activities[activityIndex % activities.length];
        const options = ratingsByActivity[activity.id] || [];
        const rating = options.find(o => o.marks === mark) || options[0];

        const dt = new Date(today);
        dt.setDate(today.getDate() - dateOffset);
        const logDate = dt.toISOString().slice(0, 10);

        logsToInsert.push({
          student_id: t.student.id,
          activity_id: activity.id,
          rating_id: rating.id,
          log_date: logDate,
          quantity: activity.has_quantity ? 1 : null,
          marks_earned: mark,
          parent_approved: true,
          notes: 'Demo score entry'
        });

        dateOffset++;
        activityIndex++;
      }
    };

    addLogsForMark(10, combo[10]);
    addLogsForMark(7, combo[7]);
    addLogsForMark(4, combo[4]);
  }

  console.log(`Inserting ${logsToInsert.length} logs...`);
  const { error: insertErr } = await supabase
    .from('activity_logs')
    .insert(logsToInsert);

  if (insertErr) throw insertErr;

  console.log('Successfully seeded custom scores!');
}

seedCustomScores().catch(console.error);
