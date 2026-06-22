/**
 * Seed users and relational data for demo/testing.
 * Run: node scripts/seed-users-and-relations.js
 */

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

const DEFAULT_PASSWORD = 'Demo@12345';

const DEMO_USERS = [
  { email: 'admin@alifschool.com', phone: '+919900000001', full_name: 'System Admin', full_name_ml: 'സിസ്റ്റം അഡ്മിൻ', role: 'admin' },
  { email: 'teacher1@alifschool.com', phone: '+919900000011', full_name: 'Usthad Rahman', full_name_ml: 'ഉസ്താദ് റഹ്മാൻ', role: 'teacher' },
  { email: 'teacher2@alifschool.com', phone: '+919900000012', full_name: 'Usthad Faizal', full_name_ml: 'ഉസ്താദ് ഫൈസൽ', role: 'teacher' },
  { email: 'parent1@alifschool.com', phone: '+919900000021', full_name: 'Parent Ameen', full_name_ml: 'രക്ഷിതാവ് അമീൻ', role: 'parent' },
  { email: 'parent2@alifschool.com', phone: '+919900000022', full_name: 'Parent Safa', full_name_ml: 'രക്ഷിതാവ് സഫ', role: 'parent' },
  { email: 'student1@alifschool.com', phone: '+919900000031', full_name: 'Ameen Junior', full_name_ml: 'അമീൻ ജൂനിയർ', role: 'student' },
  { email: 'student2@alifschool.com', phone: '+919900000032', full_name: 'Safa Mariyam', full_name_ml: 'സഫ മറിയം', role: 'student' },
  { email: 'student3@alifschool.com', phone: '+919900000033', full_name: 'Huda Fathima', full_name_ml: 'ഹുദ ഫാത്തിമ', role: 'student' },
];

async function getAllAuthUsers() {
  const users = [];
  let page = 1;
  const perPage = 200;

  while (true) {
    const { data, error } = await supabase.auth.admin.listUsers({ page, perPage });
    if (error) throw new Error(error.message);
    users.push(...data.users);
    if (data.users.length < perPage) break;
    page += 1;
  }

  return users;
}

async function ensureAuthUser(user) {
  const allUsers = await getAllAuthUsers();
  const existing = allUsers.find((u) => u.email === user.email);
  if (existing) return existing;

  const { data, error } = await supabase.auth.admin.createUser({
    email: user.email,
    password: DEFAULT_PASSWORD,
    phone: user.phone,
    email_confirm: true,
    user_metadata: {
      full_name: user.full_name,
      role: user.role,
    },
  });

  if (error) throw new Error(`Auth create failed for ${user.email}: ${error.message}`);
  return data.user;
}

async function seedUsersAndRelations() {
  console.log('👥 Seeding auth users and relational data...\n');

  const userMap = {};
  for (const user of DEMO_USERS) {
    const authUser = await ensureAuthUser(user);
    userMap[user.email] = authUser;
  }
  console.log(`✅ Auth users ready: ${Object.keys(userMap).length}`);

  const profiles = DEMO_USERS.map((u) => ({
    id: userMap[u.email].id,
    phone: u.phone,
    full_name: u.full_name,
    full_name_ml: u.full_name_ml,
    role: u.role,
    updated_at: new Date().toISOString(),
  }));

  const { error: profileErr } = await supabase.from('profiles').upsert(profiles, { onConflict: 'id' });
  if (profileErr) throw new Error(`Profiles upsert failed: ${profileErr.message}`);
  console.log(`✅ Profiles upserted: ${profiles.length}`);

  const { data: batches, error: batchErr } = await supabase.from('batches').select('id,name').order('created_at', { ascending: true });
  if (batchErr) throw new Error(`Batches fetch failed: ${batchErr.message}`);
  if (!batches || batches.length === 0) throw new Error('No batches found. Run scripts/seed-all.js first.');

  const { data: classes, error: classErr } = await supabase.from('classes').select('id,name').order('created_at', { ascending: true });
  if (classErr) throw new Error(`Classes fetch failed: ${classErr.message}`);
  if (!classes || classes.length === 0) throw new Error('No classes found. Run scripts/seed-all.js first.');

  const teacherProfiles = profiles.filter((p) => p.role === 'teacher');
  const parentProfiles = profiles.filter((p) => p.role === 'parent');
  const studentProfiles = profiles.filter((p) => p.role === 'student');

  const { data: existingTeachers, error: existingTeachersErr } = await supabase
    .from('teachers')
    .select('id,profile_id');
  if (existingTeachersErr) throw new Error(`Teachers fetch failed: ${existingTeachersErr.message}`);

  const existingTeacherProfileIds = new Set((existingTeachers || []).map((t) => t.profile_id));
  const TEACHER_SUBJECTS = [
    ['Quran', 'Tajweed', 'Islamic Studies'],
    ['Hadith', 'Fiqh', 'Arabic'],
  ];
  const teachersToInsert = teacherProfiles
    .filter((p) => !existingTeacherProfileIds.has(p.id))
    .map((p, idx) => ({
      profile_id: p.id,
      email: DEMO_USERS.find((u) => u.phone === p.phone).email,
      qualification: 'Islamic Studies',
      subjects: TEACHER_SUBJECTS[idx % TEACHER_SUBJECTS.length],
      status: 'active',
    }));

  if (teachersToInsert.length > 0) {
    const { error: teacherInsertErr } = await supabase.from('teachers').insert(teachersToInsert);
    if (teacherInsertErr) throw new Error(`Teacher insert failed: ${teacherInsertErr.message}`);
  }

  const { data: teachers, error: teachersErr } = await supabase
    .from('teachers')
    .select('id,profile_id')
    .in('profile_id', teacherProfiles.map((p) => p.id));
  if (teachersErr) throw new Error(`Teachers load failed: ${teachersErr.message}`);
  console.log(`✅ Teachers ready: ${teachers.length}`);

  const { data: existingStudents, error: existingStudentsErr } = await supabase
    .from('students')
    .select('id,profile_id');
  if (existingStudentsErr) throw new Error(`Students fetch failed: ${existingStudentsErr.message}`);

  const existingStudentProfileIds = new Set((existingStudents || []).map((s) => s.profile_id));
  const studentsToInsert = [
    {
      profile_id: studentProfiles[0].id,
      parent_phone: parentProfiles[0].phone,
      father_name: 'Ameen Father',
      mother_name: 'Ameen Mother',
      date_of_birth: '2014-06-10',
      gender: 'male',
      batch_id: batches[0].id,
      class_id: classes[0].id,
      address: 'Kozhikode',
      status: 'active',
    },
    {
      profile_id: studentProfiles[1].id,
      parent_phone: parentProfiles[1].phone,
      father_name: 'Safa Father',
      mother_name: 'Safa Mother',
      date_of_birth: '2013-09-22',
      gender: 'female',
      batch_id: batches[1].id,
      class_id: classes[1].id,
      address: 'Malappuram',
      status: 'active',
    },
    {
      profile_id: studentProfiles[2].id,
      parent_phone: '+919900000023',
      father_name: 'Huda Father',
      mother_name: 'Huda Mother',
      date_of_birth: '2012-12-03',
      gender: 'female',
      batch_id: batches[2].id,
      class_id: classes[2].id,
      address: 'Kasaragod',
      status: 'active',
    },
  ].filter((s) => !existingStudentProfileIds.has(s.profile_id));

  if (studentsToInsert.length > 0) {
    const { error: studentInsertErr } = await supabase.from('students').insert(studentsToInsert);
    if (studentInsertErr) throw new Error(`Student insert failed: ${studentInsertErr.message}`);
  }

  const { data: students, error: studentsErr } = await supabase
    .from('students')
    .select('id,profile_id,parent_phone,batch_id,class_id')
    .in('profile_id', studentProfiles.map((p) => p.id));
  if (studentsErr) throw new Error(`Students load failed: ${studentsErr.message}`);
  console.log(`✅ Students ready: ${students.length}`);

  const { error: parentLinkErr } = await supabase.from('parent_students').upsert([
    { parent_profile_id: parentProfiles[0].id, student_id: students[0].id, relationship: 'parent' },
    { parent_profile_id: parentProfiles[1].id, student_id: students[1].id, relationship: 'parent' },
    { parent_profile_id: parentProfiles[1].id, student_id: students[2].id, relationship: 'parent' },
  ], { onConflict: 'parent_profile_id,student_id' });
  if (parentLinkErr) throw new Error(`Parent-student linking failed: ${parentLinkErr.message}`);
  console.log('✅ Parent-student relations ready');

  const { error: teacherBatchErr } = await supabase.from('teacher_batches').upsert([
    { teacher_id: teachers[0].id, batch_id: batches[0].id },
    { teacher_id: teachers[0].id, batch_id: batches[1].id },
    { teacher_id: teachers[1].id, batch_id: batches[2].id },
  ], { onConflict: 'teacher_id,batch_id' });
  if (teacherBatchErr) throw new Error(`Teacher-batch linking failed: ${teacherBatchErr.message}`);
  console.log('✅ Teacher-batch assignments ready');

  const { data: activities, error: actErr } = await supabase
    .from('activities')
    .select('id,name')
    .order('display_order', { ascending: true })
    .limit(2);
  if (actErr) throw new Error(`Activity fetch failed: ${actErr.message}`);

  const { data: ratings, error: ratingErr } = await supabase
    .from('activity_ratings')
    .select('id,activity_id,rating_name,marks')
    .in('activity_id', activities.map((a) => a.id));
  if (ratingErr) throw new Error(`Rating fetch failed: ${ratingErr.message}`);

  const bestRatingByActivity = {};
  for (const rating of ratings) {
    if (!bestRatingByActivity[rating.activity_id] || rating.marks > bestRatingByActivity[rating.activity_id].marks) {
      bestRatingByActivity[rating.activity_id] = rating;
    }
  }

  const today = new Date().toISOString().slice(0, 10);
  const activityLogs = [];
  for (const student of students) {
    for (const activity of activities) {
      const rating = bestRatingByActivity[activity.id];
      if (!rating) continue;
      activityLogs.push({
        student_id: student.id,
        activity_id: activity.id,
        rating_id: rating.id,
        log_date: today,
        quantity: 1,
        marks_earned: rating.marks,
        parent_approved: true,
        notes: 'Demo seeded entry',
      });
    }
  }

  const { error: logsErr } = await supabase
    .from('activity_logs')
    .upsert(activityLogs, { onConflict: 'student_id,activity_id,log_date' });
  if (logsErr) throw new Error(`Activity logs upsert failed: ${logsErr.message}`);
  console.log(`✅ Activity logs upserted: ${activityLogs.length}`);

  const { data: badges, error: badgesErr } = await supabase.from('badges').select('id').limit(1);
  if (badgesErr) throw new Error(`Badge fetch failed: ${badgesErr.message}`);
  if (badges && badges.length > 0) {
    const { error: studentBadgeErr } = await supabase
      .from('student_badges')
      .upsert([
        { student_id: students[0].id, badge_id: badges[0].id },
      ], { onConflict: 'student_id,badge_id' });
    if (studentBadgeErr) throw new Error(`Student badge upsert failed: ${studentBadgeErr.message}`);
  }
  console.log('✅ Student badge assignment ready');

  const adminProfile = profiles.find((p) => p.role === 'admin');
  const { count: notificationsCount } = await supabase
    .from('notifications')
    .select('*', { count: 'exact', head: true });

  if (!notificationsCount || notificationsCount === 0) {
    const { error: notifyErr } = await supabase.from('notifications').insert([
      {
        title: 'Welcome to Alif School Admin',
        body: 'Demo data seeded successfully. You can now test dashboards and reports.',
        target_type: 'all',
        created_by: adminProfile.id,
      },
      {
        title: 'Class Schedule Update',
        body: 'Weekend batch starts at 9:00 AM.',
        target_type: 'batch',
        target_id: batches[2].id,
        created_by: adminProfile.id,
      },
    ]);
    if (notifyErr) throw new Error(`Notification seed failed: ${notifyErr.message}`);
  }
  console.log('✅ Notifications ready');

  const summaryQueries = await Promise.all([
    supabase.from('profiles').select('*', { count: 'exact', head: true }),
    supabase.from('teachers').select('*', { count: 'exact', head: true }),
    supabase.from('students').select('*', { count: 'exact', head: true }),
    supabase.from('parent_students').select('*', { count: 'exact', head: true }),
    supabase.from('teacher_batches').select('*', { count: 'exact', head: true }),
    supabase.from('activity_logs').select('*', { count: 'exact', head: true }),
    supabase.from('student_badges').select('*', { count: 'exact', head: true }),
    supabase.from('notifications').select('*', { count: 'exact', head: true }),
  ]);

  console.log('\n╔══════════════════════════════════════════╗');
  console.log('║    ✅ Users & Relations Seed Complete     ║');
  console.log('╠══════════════════════════════════════════╣');
  console.log(`║ Profiles         : ${String(summaryQueries[0].count || 0).padEnd(22)}║`);
  console.log(`║ Teachers         : ${String(summaryQueries[1].count || 0).padEnd(22)}║`);
  console.log(`║ Students         : ${String(summaryQueries[2].count || 0).padEnd(22)}║`);
  console.log(`║ Parent links     : ${String(summaryQueries[3].count || 0).padEnd(22)}║`);
  console.log(`║ Teacher batches  : ${String(summaryQueries[4].count || 0).padEnd(22)}║`);
  console.log(`║ Activity logs    : ${String(summaryQueries[5].count || 0).padEnd(22)}║`);
  console.log(`║ Student badges   : ${String(summaryQueries[6].count || 0).padEnd(22)}║`);
  console.log(`║ Notifications    : ${String(summaryQueries[7].count || 0).padEnd(22)}║`);
  console.log('╚══════════════════════════════════════════╝\n');

  console.log(`Demo login password for all seeded users: ${DEFAULT_PASSWORD}`);
}

seedUsersAndRelations().catch((err) => {
  console.error('❌ Seed failed:', err.message);
  process.exit(1);
});
