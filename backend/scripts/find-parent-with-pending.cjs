const { Client } = require('pg');
const c = new Client({
  host: 'db.ikgszadoqfttxugaewtk.supabase.co',
  port: 5432,
  user: 'postgres',
  password: '90QtjJGBXQQJtXZc',
  database: 'postgres',
  ssl: { rejectUnauthorized: false },
});
(async () => {
  await c.connect();
  const r = await c.query(`
    SELECT p.id AS parent_id, p.phone, p.full_name,
           s.id AS student_id,
           COUNT(al.*) FILTER (WHERE al.parent_decision='pending') AS pending,
           COUNT(al.*) FILTER (WHERE al.parent_decision='approved') AS approved,
           COUNT(al.*) AS total
      FROM profiles p
      JOIN parent_students ps ON ps.parent_profile_id = p.id
      JOIN students s ON s.id = ps.student_id
      JOIN activity_logs al ON al.student_id = s.id
     WHERE p.role = 'parent'
     GROUP BY p.id, s.id
     ORDER BY pending DESC
     LIMIT 5;
  `);
  console.log(r.rows);
  await c.end();
})().catch((e) => { console.error(e.message); process.exit(1); });
