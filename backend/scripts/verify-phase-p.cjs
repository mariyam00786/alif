// Throwaway: verify Phase P parent endpoints end-to-end against the live
// backend (port 3000). Mints an app JWT for a real parent profile, then
// exercises the new approval / notification / profile / preferences routes.
//
//   $env:JWT_SECRET="your-jwt-secret-change-in-production"
//   node scripts/verify-phase-p.cjs
//
// Deleted after the run.

const jwt = require('jsonwebtoken');
const http = require('http');

const JWT_SECRET = process.env.JWT_SECRET || 'your-jwt-secret-change-in-production';
const BASE = 'http://localhost:3000/api';

function req(method, path, body, token) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const headers = { 'Content-Type': 'application/json', Accept: 'application/json' };
    if (token) headers.Authorization = `Bearer ${token}`;
    if (data) headers['Content-Length'] = Buffer.byteLength(data);
    const r = http.request(
      { host: '127.0.0.1', port: 3000, path: `${BASE.replace('http://localhost:3000', '')}${path}`, method, headers },
      (res) => {
        let buf = '';
        res.on('data', (c) => (buf += c));
        res.on('end', () => {
          let json;
          try { json = JSON.parse(buf); } catch { json = buf; }
          resolve({ status: res.statusCode, json });
        });
      }
    );
    r.on('error', reject);
    if (data) r.write(data);
    r.end();
  });
}

(async () => {
  // Resolve the first parent profile.
  const { Client } = require('pg');
  const client = new Client({
    host: 'db.ikgszadoqfttxugaewtk.supabase.co',
    port: 5432,
    user: 'postgres',
    password: process.env.SUPABASE_DB_PASSWORD,
    database: 'postgres',
    ssl: { rejectUnauthorized: false },
  });
  await client.connect();
  const { rows } = await client.query(
    `SELECT p.id AS profile_id, p.phone, p.full_name, u.id AS auth_user_id
       FROM profiles p
       JOIN auth.users u ON u.id = p.id
      WHERE p.role = 'parent'
      LIMIT 1;`
  );
  await client.end();
  if (!rows.length) throw new Error('No parent profile found in DB.');
  const parent = rows[0];
  console.log('Parent:', parent.full_name, parent.phone);

  const token = jwt.sign(
    { role: 'parent', phone: parent.phone, name: parent.full_name, profile_id: parent.profile_id },
    JWT_SECRET,
    { subject: parent.profile_id, expiresIn: '1h' }
  );

  console.log('\n--- GET /me/notifications ---');
  console.log((await req('GET', '/parents/me/notifications', null, token)).json);

  console.log('\n--- GET /me/approvals (open) ---');
  let apps = (await req('GET', '/parents/me/approvals', null, token)).json;
  console.log(JSON.stringify({ count: apps?.data?.length, sample: apps?.data?.[0] }));

  console.log('\n--- GET /me/profile ---');
  console.log((await req('GET', '/parents/me/profile', null, token)).json);

  console.log('\n--- PUT /me/profile (rename) ---');
  console.log((await req('PUT', '/parents/me/profile', { full_name: parent.full_name + ' (QA)' }, token)).json);

  console.log('\n--- GET /me/preferences ---');
  console.log((await req('GET', '/parents/me/preferences', null, token)).json);

  console.log('\n--- PUT /me/preferences ---');
  console.log((await req('PUT', '/parents/me/preferences', {
    notify_daily: false,
    hide_child_name_on_leaderboard: true,
  }, token)).json);

  // If we have an approval, exercise reject -> send-back round-trip.
  if (apps?.data?.length) {
    const a = apps.data[0];
    console.log(`\n--- POST reject ${(a).child_id} ${(a).date} ---`);
    console.log((await req('POST', `/parents/me/approvals/${a.child_id}/${a.date}/reject`, {}, token)).json);

    console.log('\n--- GET /me/approvals (should show rejected with can_undo=true) ---');
    apps = (await req('GET', '/parents/me/approvals', null, token)).json;
    console.log(JSON.stringify({ count: apps?.data?.length, sample: apps?.data?.[0] }));

    console.log(`\n--- POST send-back (undo) ${a.child_id} ${a.date} ---`);
    console.log((await req('POST', `/parents/me/approvals/${a.child_id}/${a.date}/send-back`, {}, token)).json);
  }

  // Mark first notification as read.
  const notifs = (await req('GET', '/parents/me/notifications', null, token)).json;
  if (notifs?.data?.length) {
    const n = notifs.data[0];
    console.log(`\n--- POST /me/notifications/${n.id}/read ---`);
    console.log((await req('POST', `/parents/me/notifications/${n.id}/read`, {}, token)).json);
    console.log('--- GET /me/notifications (read_at now set) ---');
    console.log(JSON.stringify({ unread: notifs.unread_count, first: ((await req('GET', '/parents/me/notifications', null, token)).json)?.data?.[0] }));
  }

  // Restore the original name.
  console.log('\n--- restore name ---');
  console.log((await req('PUT', '/parents/me/profile', { full_name: parent.full_name }, token)).json?.success);
})().catch((e) => { console.error('FAIL:', e.message); process.exit(1); });
