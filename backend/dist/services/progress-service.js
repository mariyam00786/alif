"use strict";
/**
 * Progress Service
 *
 * Retrieves and calculates student progress metrics
 *
 * Metrics:
 * - Daily marks earned
 * - Weekly totals and trends
 * - Monthly summaries
 * - Batch rankings
 * - Performance statistics
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.getDailyMarks = getDailyMarks;
exports.getWeeklyTotal = getWeeklyTotal;
exports.getMonthlyTotal = getMonthlyTotal;
exports.getRank = getRank;
exports.getTopStudents = getTopStudents;
exports.calculateTrend = calculateTrend;
/**
 * Gets daily marks for a specific date
 *
 * @param dailyRecords - Array of daily records or logs
 * @param date - Date in YYYY-MM-DD format
 * @returns Daily progress metrics
 */
function getDailyMarks(records, date) {
    const record = records.find(r => r.log_date === date);
    if (!record) {
        return null;
    }
    return {
        date,
        marks_earned: record.total_marks,
        completion_percentage: record.completion_percentage,
        activities_completed: record.activities_completed,
        total_activities: record.total_activities,
    };
}
/**
 * Parses date string to Date object
 */
function parseDate(dateStr) {
    const [year, month, day] = dateStr.split('-').map(Number);
    return new Date(year, month - 1, day);
}
/**
 * Gets week start date (Monday) for a given date
 */
function getWeekStart(date) {
    const d = new Date(date);
    const day = d.getDay();
    const diff = d.getDate() - day + (day === 0 ? -6 : 1);
    return new Date(d.setDate(diff));
}
/**
 * Gets week end date (Sunday) for a given date
 */
function getWeekEnd(date) {
    const d = new Date(date);
    const day = d.getDay();
    const diff = d.getDate() - day + (day === 0 ? 0 : 7);
    return new Date(d.setDate(diff));
}
/**
 * Formats date as YYYY-MM-DD
 */
function formatDate(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
}
/**
 * Gets week number for a date (ISO week)
 */
function getWeekNumber(date) {
    const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
    const dayNum = d.getUTCDay() || 7;
    d.setUTCDate(d.getUTCDate() + 4 - dayNum);
    const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
    return Math.ceil((((d.getTime() - yearStart.getTime()) / 86400000) + 1) / 7);
}
/**
 * Gets weekly total marks for a student
 *
 * Returns total marks for the week containing the given start date
 *
 * @param records - Daily records for the student
 * @param startDate - Any date within the week (YYYY-MM-DD)
 * @returns Weekly progress metrics
 *
 * @example
 * const weekly = getWeeklyTotal(records, '2026-06-18');
 * // Returns { total_marks: 75, daily_average: 10.7, ... }
 */
function getWeeklyTotal(records, startDate) {
    const date = parseDate(startDate);
    const weekStart = getWeekStart(date);
    const weekEnd = getWeekEnd(date);
    let total_marks = 0;
    let days_logged = 0;
    const days = [];
    // Iterate through each day of the week
    const current = new Date(weekStart);
    while (current <= weekEnd) {
        const dateStr = formatDate(current);
        const dayProgress = getDailyMarks(records, dateStr);
        if (dayProgress) {
            total_marks += dayProgress.marks_earned;
            days_logged += 1;
            days.push(dayProgress);
        }
        else {
            // Add zero day
            days.push({
                date: dateStr,
                marks_earned: 0,
                completion_percentage: 0,
                activities_completed: 0,
                total_activities: 0,
            });
        }
        current.setDate(current.getDate() + 1);
    }
    const daily_average = days_logged > 0 ? total_marks / days_logged : 0;
    const completion_percentage = days.length > 0
        ? (days.reduce((sum, d) => sum + d.completion_percentage, 0) / days.length)
        : 0;
    return {
        week_start_date: formatDate(weekStart),
        week_end_date: formatDate(weekEnd),
        total_marks,
        daily_average: Math.round(daily_average * 10) / 10,
        days_logged,
        completion_percentage: Math.round(completion_percentage * 10) / 10,
        days,
    };
}
/**
 * Gets monthly total marks for a student
 *
 * @param records - Daily records for the student
 * @param month - Month in YYYY-MM format
 * @returns Monthly progress metrics
 *
 * @example
 * const monthly = getMonthlyTotal(records, '2026-06');
 * // Returns { total_marks: 300, daily_average: 9.7, ... }
 */
function getMonthlyTotal(records, month) {
    const [year, monthNum] = month.split('-').map(Number);
    let total_marks = 0;
    let days_logged = 0;
    const weeks = new Map();
    // Get last day of month
    const lastDay = new Date(year, monthNum, 0).getDate();
    // Iterate through each day of the month
    for (let day = 1; day <= lastDay; day++) {
        const dateStr = `${String(year).padStart(4, '0')}-${String(monthNum).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
        const dayProgress = getDailyMarks(records, dateStr);
        if (dayProgress) {
            total_marks += dayProgress.marks_earned;
            days_logged += 1;
            // Track by week
            const date = parseDate(dateStr);
            const weekNum = getWeekNumber(date);
            const week = weeks.get(weekNum) || { marks: 0, count: 0 };
            week.marks += dayProgress.marks_earned;
            week.count += 1;
            weeks.set(weekNum, week);
        }
    }
    const daily_average = days_logged > 0 ? total_marks / days_logged : 0;
    const weekly_breakdown = Array.from(weeks.entries())
        .map(([weekNum, data]) => ({
        week_number: weekNum,
        marks: data.marks,
        average: Math.round((data.marks / data.count) * 10) / 10,
    }))
        .sort((a, b) => a.week_number - b.week_number);
    return {
        month,
        total_marks,
        daily_average: Math.round(daily_average * 10) / 10,
        days_logged,
        completion_percentage: days_logged > 0 ? (days_logged / lastDay) * 100 : 0,
        weekly_breakdown,
    };
}
/**
 * Calculates student rank in batch for a specific date
 *
 * Ranks students by total marks for the day
 *
 * @param studentId - Student to rank
 * @param allStudentRecords - Map of student_id to their records
 * @param batchStudentIds - IDs of students in the batch
 * @param date - Date to calculate ranking for (YYYY-MM-DD)
 * @returns Rank (1 = top) or null if no data
 *
 * @example
 * const rank = getRank('student-123', allRecords, batchIds, '2026-06-18');
 * // Returns 3 (3rd place in batch)
 */
function getRank(studentId, allStudentRecords, batchStudentIds, date) {
    // Get marks for this student
    const studentRecords = allStudentRecords[studentId];
    const studentDaily = getDailyMarks(studentRecords || [], date);
    if (!studentDaily) {
        return null;
    }
    // Count how many students scored more
    let betterScores = 0;
    batchStudentIds.forEach(otherId => {
        if (otherId === studentId)
            return;
        const otherRecords = allStudentRecords[otherId];
        const otherDaily = getDailyMarks(otherRecords || [], date);
        if (otherDaily && otherDaily.marks_earned > studentDaily.marks_earned) {
            betterScores += 1;
        }
    });
    return betterScores + 1;
}
/**
 * Gets top N students in batch for a specific date
 *
 * @param allStudentRecords - Map of student_id to records and names
 * @param batchStudentIds - IDs of students in batch
 * @param date - Date to rank for
 * @param limit - Number of top students to return (default 10)
 * @returns Array of ranking entries sorted by marks descending
 */
function getTopStudents(allStudentRecords, batchStudentIds, date, limit = 10) {
    const rankings = [];
    batchStudentIds.forEach(studentId => {
        const data = allStudentRecords[studentId];
        if (!data)
            return;
        const daily = getDailyMarks(data.records, date);
        if (!daily)
            return;
        rankings.push({
            rank: 0, // Will be set after sorting
            student_id: studentId,
            student_name: data.name,
            total_marks: daily.marks_earned,
            completion_percentage: daily.completion_percentage,
            days_logged: 1,
        });
    });
    // Sort by marks descending
    rankings.sort((a, b) => b.total_marks - a.total_marks);
    // Set ranks
    rankings.forEach((entry, index) => {
        entry.rank = index + 1;
    });
    return rankings.slice(0, limit);
}
/**
 * Calculates performance trend (is student improving?)
 *
 * Compares recent week to previous week
 *
 * @param records - Daily records
 * @param referenceDate - Date to measure from
 * @returns Trend: positive (improving), negative (declining), neutral (same)
 */
function calculateTrend(records, referenceDate = new Date().toISOString().split('T')[0]) {
    const refDate = parseDate(referenceDate);
    // Get current week
    const currentWeek = getWeeklyTotal(records, referenceDate);
    // Get previous week (7 days earlier)
    const prevDate = new Date(refDate);
    prevDate.setDate(prevDate.getDate() - 7);
    const previousWeek = getWeeklyTotal(records, formatDate(prevDate));
    const current = currentWeek.daily_average;
    const previous = previousWeek.daily_average;
    let trend = 'neutral';
    if (current > previous * 1.05) {
        trend = 'improving';
    }
    else if (current < previous * 0.95) {
        trend = 'declining';
    }
    const percentage = previous > 0 ? Math.round(((current - previous) / previous) * 100) : 0;
    return {
        trend,
        percentage,
        currentWeekAverage: current,
        previousWeekAverage: previous,
    };
}
/**
 * Progress Service Summary
 *
 * ============================================
 * Metrics Available
 * ============================================
 * - Daily: marks, completion %
 * - Weekly: total, average, trend
 * - Monthly: total, average, weekly breakdown
 * - Ranking: position in batch, leaderboard
 * - Trend: improving/declining
 *
 * ============================================
 * Use Cases
 * ============================================
 * - Student dashboard: show daily/weekly/monthly
 * - Parent app: track child's progress
 * - Leaderboard: compare within batch
 * - Notifications: send when trend changes
 * - Reports: weekly/monthly summaries
 *
 * ============================================
 * Performance Considerations
 * ============================================
 * - Cache monthly summaries (rarely change)
 * - Calculate weekly on demand
 * - Calculate daily on write (from logs)
 * - Index by date for fast lookups
 */
//# sourceMappingURL=progress-service.js.map