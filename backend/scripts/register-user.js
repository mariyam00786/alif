/**
 * Register (or update) a user for phone + OTP login.
 *
 * Creates a Supabase auth user (so profiles.id has a valid FK) and upserts the
 * matching profiles row used by the phone/OTP login flow.
 *
 * Usage:
 *   node scripts/register-user.js <phone> <full_name> <role> [full_name_ml]
 *
 * Examples:
 *   node scripts/register-user.js +918078926771 "Adhila" student
 *   node scripts/register-user.js +919900000001 "System Admin" admin "സിസ്റ്റം അഡ്മിൻ"
 *
 * Roles: student | parent | teacher | admin
 */

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const VALID_ROLES = ['student', 'parent', 'teacher', 'admin'];

function normalizePhone(input) {
  const trimmed = String(input || '').trim();
  if (!trimmed) return null;
  const withPlus = trimmed.startsWith('+') ? trimmed : `+${trimmed}`;
  return /^\+\d{6,15}$/.test(withPlus) ? withPlus : null;
}

function emailForPhone(phone) {
  // Deterministic placeholder email; OTP login never uses it.
  return `otp_${phone.replace(/\D/g, '')}@phone.alifschool.local`;
}

async function getAllAuthUsers(supabase) {
  const users = [];
  let page = 1;
  const perPage = 200;
  // eslint-disable-next-line no-constant-condition
  while (true) {
    const { data, error } = await supabase.auth.admin.listUsers({ page, perPage });
    if (error) throw new Error(error.message);
    users.push(...data.users);
    if (data.users.length < perPage) break;
    page += 1;
  }
  return users;
}

async function main() {
  const [, , rawPhone, rawName, rawRole, rawNameMl] = process.argv;

  const phone = normalizePhone(rawPhone);
  const fullName = (rawName || '').trim();
  const role = (rawRole || '').trim().toLowerCase();
  const fullNameMl = (rawNameMl || '').trim() || null;

  if (!phone) {
    console.error('❌ Invalid or missing phone. Use international format, e.g. +918078926771');
    process.exit(1);
  }
  if (!fullName) {
    console.error('❌ Missing full name. Pass it as the second argument.');
    process.exit(1);
  }
  if (!VALID_ROLES.includes(role)) {
    console.error(`❌ Invalid role "${role}". Use one of: ${VALID_ROLES.join(', ')}`);
    process.exit(1);
  }

  const supabaseUrl = process.env.SUPABASE_URL;
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!supabaseUrl || !serviceKey) {
    console.error('❌ SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set in backend/.env');
    process.exit(1);
  }

  const supabase = createClient(supabaseUrl, serviceKey);
  const email = emailForPhone(phone);

  console.log(`👤 Registering ${fullName} (${role}) with phone ${phone}...`);

  // 1) Ensure an auth user exists (match by email or phone).
  const allUsers = await getAllAuthUsers(supabase);
  let authUser = allUsers.find(
    (u) => u.email === email || (u.phone && `+${u.phone.replace(/\D/g, '')}` === phone)
  );

  if (!authUser) {
    const { data, error } = await supabase.auth.admin.createUser({
      email,
      phone,
      email_confirm: true,
      phone_confirm: true,
      user_metadata: { full_name: fullName, role },
    });
    if (error) throw new Error(`Auth user create failed: ${error.message}`);
    authUser = data.user;
    console.log(`✅ Auth user created: ${authUser.id}`);
  } else {
    console.log(`ℹ️  Auth user already exists: ${authUser.id}`);
  }

  // 2) Upsert the profile used by the OTP login flow.
  const profile = {
    id: authUser.id,
    phone,
    full_name: fullName,
    full_name_ml: fullNameMl,
    role,
    updated_at: new Date().toISOString(),
  };

  const { error: profileErr } = await supabase
    .from('profiles')
    .upsert(profile, { onConflict: 'id' });
  if (profileErr) throw new Error(`Profile upsert failed: ${profileErr.message}`);

  console.log(`✅ Profile ready for ${phone} (${role}).`);
  console.log('🎉 Done. This user can now log in via phone + OTP.');
}

main().catch((err) => {
  console.error('❌ Registration failed:', err.message);
  process.exit(1);
});
