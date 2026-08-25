const fs = require('fs');
const path = require('path');
const puppeteer = require('puppeteer');

const ROOT = process.cwd();
const OUT_DIR = path.join(ROOT, 'qa-baseline', 'change-report-2026-06-25');

function ensureDir(dir) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function enableFlutterSemantics(page) {
  await page.waitForFunction(() => !!document.querySelector('flutter-view'), {
    timeout: 120000,
  });
  await page.evaluate(() => {
    const placeholder = document.querySelector(
      'flt-semantics-placeholder, [aria-label="Enable accessibility"]',
    );
    if (placeholder) placeholder.click();
  });
  await sleep(900);
}

async function clickByText(page, labels) {
  const labelList = Array.isArray(labels) ? labels : [labels];
  const clicked = await page.evaluate((candidates) => {
    const nodes = Array.from(
      document.querySelectorAll(
        'flt-semantics, [role="button"], button, div, span',
      ),
    );

    const norm = (v) =>
      (v || '')
        .toString()
        .replace(/\s+/g, ' ')
        .trim()
        .toLowerCase();

    const candidateNorm = candidates.map(norm);

    for (const wanted of candidateNorm) {
      const exact = nodes.filter((n) => norm(n.innerText || n.textContent) === wanted);
      const exactTarget = exact[exact.length - 1];
      if (exactTarget) {
        exactTarget.click();
        return true;
      }

      const partial = nodes.filter((n) => norm(n.innerText || n.textContent).includes(wanted));
      const partialTarget = partial[partial.length - 1];
      if (partialTarget) {
        partialTarget.click();
        return true;
      }
    }

    return false;
  }, labelList);

  await sleep(900);
  return clicked;
}

async function captureAdminSections(browser) {
  const page = await browser.newPage();
  await page.setViewport({ width: 1440, height: 900, deviceScaleFactor: 1.5 });

  await page.goto('http://localhost:5002', {
    waitUntil: 'domcontentloaded',
    timeout: 120000,
  });
  await enableFlutterSemantics(page);

  const sections = [
    {
      file: '01-admin-dashboard.png',
      labels: ['Dashboard'],
      title: 'Admin Dashboard (Updated)',
      sentence:
        'The dashboard now restores the old 2x2 KPI layout and each summary card opens its target section on tap.',
    },
    {
      file: '02-admin-students.png',
      labels: ['Students', 'Student Management'],
      title: 'Student Management Swipe Actions',
      sentence:
        'Student rows now support swipe gestures so edit and delete actions are cleaner and faster on the same list.',
    },
    {
      file: '03-admin-teachers.png',
      labels: ['Teachers', 'Teacher Management'],
      title: 'Teacher Management Swipe Actions',
      sentence:
        'Teacher rows now include swipe-to-edit and swipe-to-delete with clearer hints for action discoverability.',
    },
    {
      file: '04-admin-batches.png',
      labels: ['Batches & Classes', 'Batches'],
      title: 'Batch Management Swipe Actions',
      sentence:
        'Batch items now use swipe actions and remove inline icon clutter for a more focused management flow.',
    },
    {
      file: '05-admin-activities.png',
      labels: ['Activities', 'Activity Configuration'],
      title: 'Activity Configuration Swipe Guide',
      sentence:
        'Activity rows now support swipe edit and delete with an explicit guide card that explains the gesture directions.',
    },
    {
      file: '06-admin-ratings.png',
      labels: ['Rating', 'Rating Configuration'],
      title: 'Rating Configuration Swipe Actions',
      sentence:
        'Rating bands now support grouped swipe actions, replacing direct action icons with a consistent interaction model.',
    },
    {
      file: '07-admin-notifications.png',
      labels: ['Notifications', 'Notification Management'],
      title: 'Notification Management Swipe Actions',
      sentence:
        'Notification campaigns now use swipe edit and delete actions for consistency with the rest of the admin modules.',
    },
    {
      file: '08-admin-badges.png',
      labels: ['Badges', 'Badge Management'],
      title: 'Badge Management Swipe Actions',
      sentence:
        'Badge items now support swipe actions in both list and grid contexts while preserving the existing points label style.',
    },
  ];

  const captured = [];
  for (const section of sections) {
    await clickByText(page, section.labels);
    await page.screenshot({
      path: path.join(OUT_DIR, section.file),
      fullPage: true,
    });
    captured.push(section);
  }

  await page.close();
  return captured;
}

async function captureAdminLogin(browser) {
  const page = await browser.newPage();
  await page.setViewport({ width: 1440, height: 900, deviceScaleFactor: 1.5 });
  await page.goto('http://localhost:5004', {
    waitUntil: 'domcontentloaded',
    timeout: 120000,
  });
  await enableFlutterSemantics(page);
  const file = '09-admin-login-updated.png';
  await page.screenshot({ path: path.join(OUT_DIR, file), fullPage: true });
  await page.close();
  return {
    file,
    title: 'Admin Portal Login (Updated)',
    sentence:
      'The admin portal login is updated to the new OTP-focused entry screen with the refreshed visual style and messaging.',
  };
}

async function captureStudentLoginAndSwitch(browser) {
  const page = await browser.newPage();
  await page.setViewport({ width: 430, height: 932, deviceScaleFactor: 2 });
  await page.goto('http://localhost:5001', {
    waitUntil: 'domcontentloaded',
    timeout: 120000,
  });
  await enableFlutterSemantics(page);

  const loginFile = '10-student-login-updated.png';
  await page.screenshot({ path: path.join(OUT_DIR, loginFile), fullPage: true });

  const switchRect = await page.evaluate(() => {
    const all = Array.from(document.querySelectorAll('flt-semantics, div, span, p, h1, h2, h3'));
    const target = all.find((node) => {
      const text = (node.textContent || '').replace(/\s+/g, ' ').trim().toLowerCase();
      return (
        text.includes('student / parent portal') ||
        text.includes('teacher portal') ||
        text.includes('portal')
      );
    });
    if (!target) return null;
    const rect = target.getBoundingClientRect();
    return {
      x: Math.max(0, rect.x - 20),
      y: Math.max(0, rect.y - 35),
      width: Math.min(window.innerWidth - Math.max(0, rect.x - 20), rect.width + 40),
      height: Math.min(window.innerHeight - Math.max(0, rect.y - 35), Math.max(rect.height + 90, 180)),
    };
  });

  const switchFile = '11-student-switch-option.png';
  if (switchRect && switchRect.width > 20 && switchRect.height > 20) {
    await page.screenshot({
      path: path.join(OUT_DIR, switchFile),
      clip: switchRect,
    });
  } else {
    await page.screenshot({
      path: path.join(OUT_DIR, switchFile),
      clip: { x: 0, y: 0, width: 430, height: 280 },
    });
  }

  await page.close();

  return [
    {
      file: loginFile,
      title: 'Student Portal Login (Updated)',
      sentence:
        'The student portal login is updated with the redesigned mobile-first authentication screen and clearer entry flow.',
    },
    {
      file: switchFile,
      title: 'Student Portal Switch Option',
      sentence:
        'A dedicated portal switch area is now shown so users can clearly choose the student/parent side with an in-app switching path.',
    },
  ];
}

function buildHtml(entries) {
  const sections = entries
    .map(
      (item) => `
      <section class="card">
        <h2>${item.title}</h2>
        <img src="${item.file}" alt="${item.title}" />
        <p>${item.sentence}</p>
      </section>`,
    )
    .join('\n');

  return `<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <title>Alif Change Report - 2026-06-25</title>
  <style>
    @page { size: A4; margin: 16mm 12mm; }
    body {
      margin: 0;
      font-family: "Segoe UI", Arial, sans-serif;
      color: #0f172a;
      background: #f8fafc;
    }
    .wrap {
      max-width: 980px;
      margin: 0 auto;
      padding: 20px;
    }
    h1 {
      margin: 0 0 8px;
      font-size: 28px;
    }
    .sub {
      margin: 0 0 18px;
      color: #475569;
      font-size: 14px;
    }
    .card {
      background: #ffffff;
      border: 1px solid #e2e8f0;
      border-radius: 14px;
      padding: 14px;
      margin: 0 0 16px;
      page-break-inside: avoid;
      break-inside: avoid;
      box-shadow: 0 2px 8px rgba(15, 23, 42, 0.05);
    }
    .card h2 {
      margin: 0 0 10px;
      font-size: 18px;
      color: #0b3a75;
    }
    .card img {
      width: 100%;
      border-radius: 10px;
      border: 1px solid #e5e7eb;
      display: block;
      margin-bottom: 10px;
    }
    .card p {
      margin: 0;
      font-size: 14px;
      line-height: 1.5;
      color: #1e293b;
    }
  </style>
</head>
<body>
  <div class="wrap">
    <h1>Alif Admin and Student Portal Change Report</h1>
    <p class="sub">Date: 2026-06-25 | Screenshots with one-sentence English summaries</p>
    ${sections}
  </div>
</body>
</html>`;
}

async function createPdf(htmlPath, pdfPath, browser) {
  const page = await browser.newPage();
  await page.goto(`file:///${htmlPath.replace(/\\/g, '/')}`, {
    waitUntil: 'networkidle0',
    timeout: 120000,
  });
  await page.pdf({
    path: pdfPath,
    format: 'A4',
    printBackground: true,
    margin: {
      top: '12mm',
      right: '10mm',
      bottom: '12mm',
      left: '10mm',
    },
  });
  await page.close();
}

(async () => {
  ensureDir(OUT_DIR);

  const browser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox'],
  });

  try {
    const entries = [];
    const adminSections = await captureAdminSections(browser);
    entries.push(...adminSections);

    const adminLogin = await captureAdminLogin(browser);
    entries.push(adminLogin);

    const studentEntries = await captureStudentLoginAndSwitch(browser);
    entries.push(...studentEntries);

    const html = buildHtml(entries);
    const htmlPath = path.join(OUT_DIR, 'change-report.html');
    const pdfPath = path.join(OUT_DIR, 'alif-change-report-2026-06-25.pdf');

    fs.writeFileSync(htmlPath, html, 'utf8');
    await createPdf(htmlPath, pdfPath, browser);

    console.log('REPORT_DIR=' + OUT_DIR);
    console.log('PDF=' + pdfPath);
  } finally {
    await browser.close();
  }
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
