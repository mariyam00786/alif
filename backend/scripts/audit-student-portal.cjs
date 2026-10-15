const http = require('http');

function request(options, data) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => (body += chunk));
      res.on('end', () => {
        let parsed = null;
        try {
          parsed = JSON.parse(body);
        } catch (_) {
          parsed = body;
        }
        resolve({ status: res.statusCode, headers: res.headers, body: parsed });
      });
    });
    req.on('error', reject);
    if (data) {
      req.write(typeof data === 'string' ? data : JSON.stringify(data));
    }
    req.end();
  });
}

async function runAudit() {
  console.log('=== STARTING COMPLETE STUDENT PORTAL AUDIT ===\n');
  const results = [];

  function record(testName, passed, details) {
    results.push({ testName, passed, details });
    const mark = passed ? '✅ PASS' : '❌ FAIL';
    console.log(`${mark}: ${testName}`);
    if (details) console.log(`   -> ${details}`);
  }

  try {
    // 1. Health check
    const health = await request({
      hostname: 'localhost',
      port: 3000,
      path: '/api/health',
      method: 'GET',
    });
    record('API Health Check', health.status === 200, `Status: ${health.status}, Version: ${health.body?.version}`);

    // 2. Request OTP for Student Ameen Junior (9900000031)
    const otpReq = await request(
      {
        hostname: 'localhost',
        port: 3000,
        path: '/api/auth/request-otp',
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      },
      { phone: '+919900000031' }
    );
    record(
      'Auth: Request OTP (+919900000031)',
      otpReq.status === 200 && otpReq.body?.success,
      `Status: ${otpReq.status}, Message: ${otpReq.body?.message}`
    );

    // 3. Verify OTP
    const otpVerify = await request(
      {
        hostname: 'localhost',
        port: 3000,
        path: '/api/auth/verify-otp',
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      },
      { phone: '+919900000031', otp: '1234' }
    );
    const token = otpVerify.body?.data?.token || otpVerify.body?.data?.session?.access_token || otpVerify.body?.data?.accessToken;
    const userRole = otpVerify.body?.data?.user?.role;
    record(
      'Auth: Verify OTP & Issue Token',
      otpVerify.status === 200 && !!token,
      `Status: ${otpVerify.status}, Role: ${userRole}, HasToken: ${!!token}`
    );

    if (!token) {
      console.error('Cannot proceed with authenticated tests without token.');
      return;
    }

    const authHeaders = {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    };

    // 4. Home Summary
    const homeSummary = await request({
      hostname: 'localhost',
      port: 3000,
      path: '/api/students/me/home-summary',
      method: 'GET',
      headers: authHeaders,
    });
    const hsData = homeSummary.body?.data;
    record(
      'Student Portal: GET /api/students/me/home-summary',
      homeSummary.status === 200 && homeSummary.body?.success && typeof hsData?.today_done === 'number',
      `Streak: ${hsData?.streak_days}, Done: ${hsData?.today_done}/${hsData?.today_total}, Rank: #${hsData?.batch_rank} in ${hsData?.batch_name}`
    );

    // 5. Daily Structure (Categories + Activities + Ratings)
    const dailyStructure = await request({
      hostname: 'localhost',
      port: 3000,
      path: '/api/activities/structure/daily',
      method: 'GET',
      headers: authHeaders,
    });
    const cats = dailyStructure.body?.data?.categories;
    const catCount = Array.isArray(cats) ? cats.length : 0;
    record(
      'Activity: GET /api/activities/structure/daily',
      dailyStructure.status === 200 && catCount > 0,
      `Loaded ${catCount} categories (e.g. ${cats?.[0]?.name})`
    );

    // 6. Leaderboard
    const leaderboard = await request({
      hostname: 'localhost',
      port: 3000,
      path: '/api/students/me/leaderboard',
      method: 'GET',
      headers: authHeaders,
    });
    const lbData = leaderboard.body?.data;
    record(
      'Student Portal: GET /api/students/me/leaderboard',
      leaderboard.status === 200 && Array.isArray(lbData?.daily) && Array.isArray(lbData?.weekly),
      `Daily entries: ${lbData?.daily?.length}, Weekly entries: ${lbData?.weekly?.length}`
    );

    // 7. Badges
    const badges = await request({
      hostname: 'localhost',
      port: 3000,
      path: '/api/students/me/badges',
      method: 'GET',
      headers: authHeaders,
    });
    const badgeList = badges.body?.data?.badges;
    record(
      'Student Portal: GET /api/students/me/badges',
      badges.status === 200 && Array.isArray(badgeList) && badgeList.length > 0,
      `Badges returned: ${badgeList?.length}, First: ${badgeList?.[0]?.name} (Earned: ${badgeList?.[0]?.earned})`
    );

    // 8. Notifications
    const notifs = await request({
      hostname: 'localhost',
      port: 3000,
      path: '/api/students/me/notifications',
      method: 'GET',
      headers: authHeaders,
    });
    const notifList = notifs.body?.data;
    record(
      'Student Portal: GET /api/students/me/notifications',
      notifs.status === 200 && Array.isArray(notifList) && notifList.length > 0,
      `Notifications count: ${notifList?.length}, Title: "${notifList?.[0]?.title}"`
    );

    // 9. Progress
    const progress = await request({
      hostname: 'localhost',
      port: 3000,
      path: '/api/students/me/progress',
      method: 'GET',
      headers: authHeaders,
    });
    const progData = progress.body?.data;
    record(
      'Student Portal: GET /api/students/me/progress',
      progress.status === 200 && Array.isArray(progData?.daily) && progData?.weekly && progData?.monthly,
      `Daily days: ${progData?.daily?.length}, Week total: ${progData?.weekly?.totalMarks}, Month avg: ${progData?.monthly?.avg}`
    );

    // 10. Activity Logs list
    const today = new Date().toISOString().slice(0, 10);
    const logsList = await request({
      hostname: 'localhost',
      port: 3000,
      path: `/api/activity-logs?date=${today}`,
      method: 'GET',
      headers: authHeaders,
    });
    record(
      `Activity Logs: GET /api/activity-logs?date=${today}`,
      logsList.status === 200 && logsList.body?.success,
      `Logs returned: ${logsList.body?.data?.length ?? 0}`
    );

    const upsertLog = await request(
      {
        hostname: 'localhost',
        port: 3000,
        path: '/api/activity-logs',
        method: 'POST',
        headers: authHeaders,
      },
      {
        activityId: 'act-fajr',
        ratingId: 'rating-fajr-jamaah',
        marks_earned: 5,
        logDate: today,
        notes: 'Audited log save',
      }
    );
    record(
      'Activity Logs: POST /api/activity-logs (Marking)',
      upsertLog.status === 200 || upsertLog.status === 201,
      `Status: ${upsertLog.status}, Success: ${upsertLog.body?.success}`
    );

    console.log('\n=== AUDIT SUMMARY ===');
    const passedCount = results.filter((r) => r.passed).length;
    console.log(`Passed: ${passedCount} / ${results.length}`);
    if (passedCount === results.length) {
      console.log('🎉 ALL BACKEND STUDENT PORTAL ENDPOINTS PASSING CLEANLY!\n');
    } else {
      console.log('⚠️ Some checks failed. See details above.\n');
    }
  } catch (err) {
    console.error('Audit encountered unexpected failure:', err);
  }
}

runAudit();
