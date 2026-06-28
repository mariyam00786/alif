import 'dart:async';

import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../components/portal_ui.dart';
import '../services/api_service.dart';
import '../shared/theme/theme.dart';

/// Daily marking screen (Ihthisab — accountability sheet).
///
/// Centerpiece is the 5 daily prayers, each marked as
/// Jama'ah (congregation) / Adâ (on time) / Missed, plus
/// Quran and Character activities.
class DailyMarkingScreen extends StatefulWidget {
  final String studentId;
  final String date;
  final VoidCallback? onSubmitSuccess;

  const DailyMarkingScreen({
    super.key,
    required this.studentId,
    required this.date,
    this.onSubmitSuccess,
  });

  @override
  State<DailyMarkingScreen> createState() => _DailyMarkingScreenState();
}

class _DailyMarkingScreenState extends State<DailyMarkingScreen> {
  bool _loadingStructure = true;

  // Refreshes the sheet every minute so a prayer unlocks the moment its
  // configured time arrives without the student having to reopen the screen.
  Timer? _ticker;

  // The full activity catalog loaded from the backend. Every category and
  // activity shown here mirrors the admin configuration, so the student marks
  // exactly the same items that teachers, parents and admin see.
  //
  // Each category: { name, nameML, icon (IconData), activities: List<Map> }
  // Each activity: { id, name, nameML, icon, rating (-1..3), ratings: {name:id} }
  List<Map<String, dynamic>> _cats = [];

  // Yesterday's prayer review. Lets the student notice prayers they forgot to
  // mark the previous day. Each entry: { name, nameML, marked (bool), band }.
  List<Map<String, dynamic>> _yesterdayPrayers = [];

  // Unified 4-band rating scale shared by every activity (matches backend).
  static const _ratingMarks = [0, 4, 7, 10];
  static const _ratingNames = [
    'Not Done',
    'Needs Improvement',
    'Good',
    'Excellent',
  ];

  /// Flattened list of every activity across all categories.
  List<Map<String, dynamic>> get _allActs => _cats
      .expand((c) => (c['activities'] as List).cast<Map<String, dynamic>>())
      .toList();

  int get _totalMarks {
    var total = 0;
    for (final a in _allActs) {
      final r = a['rating'] as int;
      if (r >= 0) total += _ratingMarks[r];
    }
    return total;
  }

  int get _maxMarks => _allActs.length * 10;

  /// How many activities have been marked so far.
  int get _markedCount =>
      _allActs.where((a) => (a['rating'] as int) >= 0).length;

  double get _progress {
    final total = _allActs.length;
    if (total == 0) return 0;
    final marked = _allActs.where((a) => (a['rating'] as int) >= 0).length;
    return marked / total;
  }

  IconData _iconForCategory(String name) {
    final n = name.toLowerCase();
    if (n.contains('salah') || n.contains('prayer')) {
      return Icons.mosque_rounded;
    }
    if (n.contains('quran')) return Icons.menu_book_rounded;
    if (n.contains('dua') || n.contains('dhikr')) {
      return Icons.auto_awesome_rounded;
    }
    if (n.contains('sunnah')) return Icons.star_rounded;
    if (n.contains('character') || n.contains('akhlaq')) {
      return Icons.volunteer_activism_rounded;
    }
    if (n.contains('health')) return Icons.fitness_center_rounded;
    return Icons.check_circle_outline_rounded;
  }

  /// The five daily prayers use a dedicated 3-way scale
  /// (Jama'ah / On time / Missed) instead of the shared 4-band scale.
  bool _isPrayerCategory(String name) {
    final n = name.toLowerCase();
    return n.contains('salah') ||
        n.contains('prayer') ||
        n.contains('namaz') ||
        n.contains('niskar');
  }

  /// Maps a prayer choice to the shared backend rating band index:
  /// Jama'ah → Excellent (3), On time → Good (2), Missed → Not Done (0).
  static const _prayerBands = [3, 2, 0];

  // Local start time (minutes since midnight) for each daily prayer. A prayer
  // can only be marked once its time has arrived; before that it stays locked.
  // Adjust these to the local timetable as needed.
  static const Map<String, int> _prayerUnlockMinutes = {
    'subhi': 4 * 60 + 47, // Fajr 04:47
    'fajr': 4 * 60 + 47,
    'zuhr': 12 * 60 + 29, // Dhuhr 12:29
    'dhuhr': 12 * 60 + 29,
    'luhr': 12 * 60 + 29,
    'asr': 15 * 60 + 56, // Asr 15:56
    'maghrib': 18 * 60 + 53, // Maghrib 18:53
    'isha': 20 * 60 + 11, // Isha 20:11
  };

  /// Returns the unlock time (minutes since midnight) for a prayer activity,
  /// or null if it is not a recognised daily prayer.
  int? _prayerUnlockFor(Map<String, dynamic> a) {
    if (a['isPrayer'] != true) return null;
    final n = (a['name'] ?? '').toString().toLowerCase();
    for (final entry in _prayerUnlockMinutes.entries) {
      if (n.contains(entry.key)) return entry.value;
    }
    return null;
  }

  /// True only when the marking sheet is for the real current date.
  bool get _isToday {
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    return widget.date == today;
  }

  /// True when this activity is a prayer whose time has not arrived yet today,
  /// so it must not be markable until then.
  bool _isTimeLocked(Map<String, dynamic> a) {
    if (!_isToday) return false;
    final unlock = _prayerUnlockFor(a);
    if (unlock == null) return false;
    final now = DateTime.now();
    return now.hour * 60 + now.minute < unlock;
  }

  /// Formats minutes-since-midnight as a friendly 12-hour clock (e.g. 12:29 PM).
  String _formatClock(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final ampm = h < 12 ? 'AM' : 'PM';
    var hour = h % 12;
    if (hour == 0) hour = 12;
    return '$hour:${m.toString().padLeft(2, '0')} $ampm';
  }

  @override
  void initState() {
    super.initState();
    _loadStructure();
    // Re-evaluate time locks once a minute so prayers unlock on schedule.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DailyMarkingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When the day rolls over (the parent passes a new `date`), the reused
    // State still holds the previous day's locked marks. Reload the sheet for
    // the new date so the student sees a fresh day and any marks already saved
    // for it, instead of yesterday's submitted state.
    if (oldWidget.date != widget.date) {
      setState(() {
        _loadingStructure = true;
        _cats = [];
      });
      _loadStructure();
    }
  }

  /// Loads the full activity catalog from the backend and builds the marking
  /// sheet dynamically so it always matches the admin configuration.
  Future<void> _loadStructure() async {
    final res = await MobileApiService.getDailyStructure();
    if (!mounted) return;
    if (!res.success || res.data == null) {
      setState(() => _loadingStructure = false);
      return;
    }

    final cats = (res.data!['categories'] as List?) ?? const [];
    final built = <Map<String, dynamic>>[];

    for (final c in cats) {
      final cm = c as Map<String, dynamic>;
      if ((cm['status'] ?? 'active').toString() != 'active') continue;
      final catName = (cm['name'] ?? '').toString();
      final icon = _iconForCategory(catName);
      final isPrayer = _isPrayerCategory(catName);

      final builtActs = <Map<String, dynamic>>[];
      for (final a in (cm['activities'] as List?) ?? const []) {
        final am = a as Map<String, dynamic>;
        if ((am['status'] ?? 'active').toString() != 'active') continue;
        final id = (am['id'] ?? '').toString();
        if (id.isEmpty) continue;

        final ratingMap = <String, String>{};
        final ratingById = <String, String>{};
        for (final r in (am['ratings'] as List?) ?? const []) {
          final rm = r as Map<String, dynamic>;
          final rName = (rm['rating_name'] ?? '').toString();
          final rId = (rm['id'] ?? '').toString();
          ratingMap[rName] = rId;
          ratingById[rId] = rName;
        }

        builtActs.add({
          'id': id,
          'name': (am['name'] ?? '').toString(),
          'nameML': (am['name_ml'] ?? am['name'] ?? '').toString(),
          'icon': icon,
          'rating': -1,
          'ratings': ratingMap,
          'ratingsById': ratingById,
          'isPrayer': isPrayer,
          'locked': false,
          'saving': false,
        });
      }

      if (builtActs.isEmpty) continue;
      built.add({
        'name': catName,
        'nameML': (cm['name_ml'] ?? catName).toString(),
        'icon': icon,
        'activities': builtActs,
      });
    }

    // Restore any marks already saved for this day so they appear locked.
    await _restoreSavedLogs(built);

    if (!mounted) return;
    setState(() {
      _cats = built;
      _loadingStructure = false;
    });

    // After the sheet is ready, quietly check whether any of yesterday's
    // prayers were left unmarked so the student can be reminded.
    _loadYesterday();
  }

  /// Loads the student's already-saved marks for this date and applies them to
  /// the freshly built sheet, locking each item that was previously committed.
  Future<void> _restoreSavedLogs(List<Map<String, dynamic>> built) async {
    final logsRes = await MobileApiService.getMyActivityLogs(
      from: widget.date,
      to: widget.date,
    );
    if (!logsRes.success || logsRes.data == null) return;

    final ratingByActivity = <String, String>{};
    for (final log in logsRes.data!) {
      final aid = (log['activity_id'] ?? '').toString();
      final rid = (log['rating_id'] ?? '').toString();
      if (aid.isNotEmpty && rid.isNotEmpty) ratingByActivity[aid] = rid;
    }
    if (ratingByActivity.isEmpty) return;

    for (final cat in built) {
      for (final a
          in (cat['activities'] as List).cast<Map<String, dynamic>>()) {
        final rid = ratingByActivity[a['id']];
        if (rid == null) continue;
        final name = (a['ratingsById'] as Map<String, String>)[rid];
        final band = name != null ? _ratingNames.indexOf(name) : -1;
        if (band >= 0) {
          a['rating'] = band;
          a['locked'] = true;
        }
      }
    }
  }

  /// The ISO date (yyyy-MM-dd) for the day before the sheet's date.
  String _yesterdayDate() {
    DateTime base;
    try {
      base = DateTime.parse(widget.date);
    } catch (_) {
      base = DateTime.now();
    }
    final y = base.subtract(const Duration(days: 1));
    return '${y.year.toString().padLeft(4, '0')}-'
        '${y.month.toString().padLeft(2, '0')}-'
        '${y.day.toString().padLeft(2, '0')}';
  }

  /// Loads yesterday's prayer marks so the student can spot any they forgot to
  /// mark. Builds a small list of every prayer with its status for that day.
  Future<void> _loadYesterday() async {
    // Collect the prayer activities from the loaded structure.
    final prayerActs = _allActs.where((a) => a['isPrayer'] == true).toList();
    if (prayerActs.isEmpty) return;

    final yDate = _yesterdayDate();
    final logsRes = await MobileApiService.getMyActivityLogs(
      from: yDate,
      to: yDate,
    );
    if (!mounted) return;

    final ratingByActivity = <String, String>{};
    if (logsRes.success && logsRes.data != null) {
      for (final log in logsRes.data!) {
        final aid = (log['activity_id'] ?? '').toString();
        final rid = (log['rating_id'] ?? '').toString();
        if (aid.isNotEmpty && rid.isNotEmpty) ratingByActivity[aid] = rid;
      }
    }

    final review = <Map<String, dynamic>>[];
    for (final a in prayerActs) {
      final rid = ratingByActivity[a['id']];
      var band = -1;
      if (rid != null) {
        final name = (a['ratingsById'] as Map<String, String>)[rid];
        band = name != null ? _ratingNames.indexOf(name) : -1;
      }
      review.add({
        // Keep a reference to the real activity so a forgotten prayer can be
        // marked now against yesterday's date.
        'activity': a,
        'name': a['name'],
        'nameML': a['nameML'],
        'marked': band >= 0,
        'band': band,
        'saving': false,
      });
    }

    setState(() => _yesterdayPrayers = review);
  }

  /// Number of yesterday's prayers the student forgot to mark.
  int get _yesterdayUnmarked =>
      _yesterdayPrayers.where((p) => p['marked'] != true).length;

  @override
  Widget build(BuildContext context) {
    final isMalayalam = context.isMalayalam;
    final pct = (_progress * 100).round();

    return Scaffold(
      backgroundColor: kSurface,
      bottomNavigationBar: (_loadingStructure || _cats.isEmpty)
          ? null
          : _statusBar(isMalayalam),
      body: Column(
        children: [
          MinimalHeader(
            title: isMalayalam ? 'ഇത്തിസാബ്' : 'Daily Marking',
            subtitle: _formatDate(widget.date),
            isMalayalam: isMalayalam,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ringBadge(pct),
                const SizedBox(width: 12),
                const PortalProfileAvatar(onDark: false, size: 44),
              ],
            ),
          ),
          Expanded(
            child: _loadingStructure
                ? const Center(child: CircularProgressIndicator())
                : _cats.isEmpty
                ? _emptyState(isMalayalam)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    children: [
                      for (final cat in _cats) ...[
                        if (_isPrayerCategory((cat['name'] ?? '').toString()) &&
                            _isToday &&
                            _yesterdayUnmarked > 0) ...[
                          _yesterdayBanner(isMalayalam),
                          const SizedBox(height: 10),
                        ],
                        _sectionHeader(cat, isMalayalam),
                        const SizedBox(height: 8),
                        _categoryCard(cat, isMalayalam),
                        const SizedBox(height: 12),
                      ],
                      _totalCard(isMalayalam),
                      const SizedBox(height: 12),
                      _autoSaveNote(isMalayalam),
                      const SizedBox(height: 16),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(bool isMalayalam) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 44, color: kMuted),
            const SizedBox(height: 12),
            Text(
              isMalayalam
                  ? 'പ്രവർത്തനങ്ങൾ ലോഡ് ചെയ്യാനായില്ല'
                  : 'Could not load activities',
              textAlign: TextAlign.center,
              style: AppTextStyles.cardTitle,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                setState(() => _loadingStructure = true);
                _loadStructure();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(isMalayalam ? 'വീണ്ടും ശ്രമിക്കുക' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ringBadge(int pct) {
    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: CircularProgressIndicator(
              value: _progress,
              strokeWidth: 4,
              strokeCap: StrokeCap.round,
              backgroundColor: kGreen.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation(kGreen),
            ),
          ),
          Text(
            '$pct%',
            style: const TextStyle(
              color: AppColors.primaryDeep,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// A gentle amber reminder shown above today's prayers when one or more of
  /// yesterday's prayers were never marked. Tapping it opens the full review.
  Widget _yesterdayBanner(bool isMalayalam) {
    final n = _yesterdayUnmarked;
    const amber = Color(0xFFE0A82E);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showYesterdaySheet(isMalayalam),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: amber.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: amber.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.history_rounded,
                size: 20,
                color: Color(0xFFB8860B),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMalayalam
                          ? 'ഇന്നലത്തെ $n നമസ്കാരം മാർക്ക് ചെയ്തിട്ടില്ല'
                          : '$n prayer${n == 1 ? '' : 's'} unmarked yesterday',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF8A6D0B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isMalayalam
                          ? 'ഇപ്പോൾ മാർക്ക് ചെയ്യാൻ ടാപ്പ് ചെയ്യുക'
                          : 'Tap to mark them now',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8A6D0B).withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: Color(0xFFB8860B),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom sheet listing every one of yesterday's prayers with its status, so
  /// the student can clearly see which ones they forgot to mark — and mark any
  /// they missed, saved against yesterday's date.
  void _showYesterdaySheet(bool isMalayalam) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.neutral300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.history_rounded,
                            size: 20,
                            color: kGreen,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isMalayalam
                                  ? 'ഇന്നലത്തെ നമസ്കാരം'
                                  : "Yesterday's prayers",
                              style: AppTextStyles.cardTitle,
                            ),
                          ),
                          Text(
                            _formatDate(_yesterdayDate()),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isMalayalam
                            ? 'നിസ്കരിച്ചിട്ടും മാർക്ക് ചെയ്യാൻ മറന്നുപോയ നമസ്കാരം ഇപ്പോൾ മാർക്ക് ചെയ്യാം.'
                            : 'Mark any prayer you offered yesterday but forgot to record.',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: kMuted,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),
                      for (final p in _yesterdayPrayers)
                        _yesterdayRow(p, isMalayalam, setSheetState),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// A single prayer line inside the yesterday sheet. Marked prayers show their
  /// status; unmarked ones show the Jama'ah / On time / Missed chips so the
  /// student can record a prayer they forgot, saved against yesterday's date.
  Widget _yesterdayRow(
    Map<String, dynamic> p,
    bool isMalayalam,
    void Function(void Function()) setSheetState,
  ) {
    final marked = p['marked'] == true;
    final saving = p['saving'] == true;
    final band = p['band'] as int;
    final name = isMalayalam ? (p['nameML'] ?? p['name']) : p['name'];

    if (marked) {
      final color = _ratingColor(band);
      final status = _prayerLabel(band, isMalayalam);
      final icon = band <= 0 ? Icons.close_rounded : Icons.check_rounded;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.heading,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 13, color: color),
                  const SizedBox(width: 5),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Unmarked → let the student record it now.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.heading,
                  ),
                ),
              ),
              if (saving)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0A82E).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.report_gmailerrorred_rounded,
                        size: 13,
                        color: Color(0xFFE0A82E),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isMalayalam ? 'മാർക്ക് ചെയ്തില്ല' : 'Not marked',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB8860B),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (int i = 0; i < _prayerBands.length; i++) ...[
                _yesterdayChip(
                  p,
                  _prayerBands[i],
                  isMalayalam,
                  setSheetState,
                  disabled: saving,
                ),
                if (i < _prayerBands.length - 1) const SizedBox(width: 7),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// A tappable prayer choice inside the yesterday sheet.
  Widget _yesterdayChip(
    Map<String, dynamic> p,
    int value,
    bool isMalayalam,
    void Function(void Function()) setSheetState, {
    bool disabled = false,
  }) {
    final color = _ratingColor(value);
    final label = _prayerLabel(value, isMalayalam);
    return Expanded(
      child: GestureDetector(
        onTap: disabled
            ? null
            : () => _saveYesterday(p, value, isMalayalam, setSheetState),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 3),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: disabled ? 0.05 : 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: disabled ? 0.22 : 0.28),
              width: 1.2,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Saves a forgotten prayer for yesterday's date and locks it on success.
  Future<void> _saveYesterday(
    Map<String, dynamic> p,
    int band,
    bool isMalayalam,
    void Function(void Function()) setSheetState,
  ) async {
    if (p['marked'] == true || p['saving'] == true) return;

    final a = p['activity'] as Map<String, dynamic>?;
    final activityId = (a?['id'] ?? '').toString();
    final ratingName = (band >= 0 && band < _ratingNames.length)
        ? _ratingNames[band]
        : '';
    final ratingId = (a?['ratings'] as Map<String, String>?)?[ratingName] ?? '';

    if (activityId.isEmpty || ratingId.isEmpty) {
      _showSnack(
        isMalayalam
            ? 'സേവ് ചെയ്യാനായില്ല · വീണ്ടും ശ്രമിക്കുക'
            : 'Could not save · please try again',
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    setSheetState(() => p['saving'] = true);

    final res = await MobileApiService.submitActivityLog(
      studentId: widget.studentId,
      activityId: activityId,
      logDate: _yesterdayDate(),
      ratingId: ratingId,
    );

    if (!mounted) return;

    if (res.success) {
      setSheetState(() {
        p['saving'] = false;
        p['marked'] = true;
        p['band'] = band;
      });
      // Refresh the banner count on the main sheet.
      setState(() {});
      widget.onSubmitSuccess?.call();
    } else {
      setSheetState(() => p['saving'] = false);
      _showSnack(
        isMalayalam
            ? 'സേവ് ചെയ്യാനായില്ല · വീണ്ടും ശ്രമിക്കുക'
            : 'Could not save · please try again',
        icon: Icons.error_outline_rounded,
      );
    }
  }

  /// Minimal section header: a small green icon, the category name in both
  /// languages and the marked count on the right (e.g. "5/5").
  Widget _sectionHeader(Map<String, dynamic> cat, bool isMalayalam) {
    final items = (cat['activities'] as List).cast<Map<String, dynamic>>();
    final done = items.where((a) => (a['rating'] as int) >= 0).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
      child: Row(
        children: [
          Icon(cat['icon'] as IconData, size: 18, color: kGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${cat['name']} · ${cat['nameML']}',
              style: AppTextStyles.sectionTitle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$done/${items.length}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: kMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryCard(Map<String, dynamic> cat, bool isMalayalam) {
    final items = (cat['activities'] as List).cast<Map<String, dynamic>>();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppDecorations.soft,
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _activityRow(items[i], isMalayalam),
            if (i < items.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
                color: AppColors.borderSoft,
              ),
          ],
        ],
      ),
    );
  }

  Widget _activityRow(Map<String, dynamic> a, bool isMalayalam) {
    final rating = a['rating'] as int;
    final rated = rating >= 0;
    final isPrayer = a['isPrayer'] == true;
    final saving = a['saving'] == true;

    final iconBadge = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: kGreenSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(a['icon'] as IconData, color: kGreen, size: 19),
    );

    final header = Row(
      children: [
        iconBadge,
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            isMalayalam ? a['nameML'] : a['name'],
            style: AppTextStyles.cardTitle,
          ),
        ),
        if (saving) ...[
          const SizedBox(width: 8),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ] else if (rated) ...[
          const SizedBox(width: 8),
          _ratingPill(rating, isMalayalam, isPrayer),
          const SizedBox(width: 8),
          Icon(
            Icons.lock_outline_rounded,
            size: 16,
            color: AppColors.neutral400,
          ),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(11),
      child: rated
          ? header
          : _isTimeLocked(a)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const SizedBox(height: 10),
                // Show the choices so the student knows what is coming, but
                // greyed out and not tappable until the prayer time arrives.
                Row(
                  children: [
                    for (int i = 0; i < _prayerBands.length; i++) ...[
                      _ratingChip(
                        a,
                        _prayerBands[i],
                        isMalayalam,
                        isPrayer: true,
                        disabled: true,
                      ),
                      if (i < _prayerBands.length - 1) const SizedBox(width: 7),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                _timeLockedNote(a, isMalayalam),
              ],
            )
          : Column(
              children: [
                header,
                const SizedBox(height: 10),
                isPrayer
                    ? Row(
                        children: [
                          for (int i = 0; i < _prayerBands.length; i++) ...[
                            _ratingChip(
                              a,
                              _prayerBands[i],
                              isMalayalam,
                              isPrayer: true,
                            ),
                            if (i < _prayerBands.length - 1)
                              const SizedBox(width: 7),
                          ],
                        ],
                      )
                    : Row(
                        children: [
                          for (int i = 0; i < 4; i++) ...[
                            _ratingChip(a, i, isMalayalam),
                            if (i < 3) const SizedBox(width: 7),
                          ],
                        ],
                      ),
              ],
            ),
    );
  }

  /// A small, unobtrusive pill shown in place of the rating chips for a prayer
  /// whose time has not arrived yet, telling the student when they can mark it.
  Widget _timeLockedNote(Map<String, dynamic> a, bool isMalayalam) {
    final unlock = _prayerUnlockFor(a);
    final clock = unlock != null ? _formatClock(unlock) : '';
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 9),
        decoration: BoxDecoration(
          color: AppColors.neutral100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_rounded, size: 13, color: kMuted),
            const SizedBox(width: 5),
            Text(
              isMalayalam ? '$clock-ന് ശേഷം' : 'After $clock',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: kMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ratingChip(
    Map<String, dynamic> a,
    int value,
    bool isMalayalam, {
    bool isPrayer = false,
    bool disabled = false,
  }) {
    // When disabled (prayer time not arrived) the chip is greyed and inert so
    // the student can see the option but cannot pick it yet.
    final color = disabled ? AppColors.neutral400 : _ratingColor(value);
    final label = isPrayer
        ? _prayerLabel(value, isMalayalam)
        : _ratingLabel(value, isMalayalam);
    return Expanded(
      child: GestureDetector(
        onTap: disabled ? null : () => _saveActivity(a, value, isMalayalam),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 3),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: disabled ? 0.05 : 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: disabled ? 0.22 : 0.28),
              width: 1.2,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ratingPill(int rating, bool isMalayalam, bool isPrayer) {
    final color = _ratingColor(rating);
    final isBest = rating >= 3;
    final isMiss = rating <= 0;
    final label = isPrayer
        ? _prayerLabel(rating, isMalayalam)
        : _ratingLabel(rating, isMalayalam);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: isBest ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMiss ? Icons.close_rounded : Icons.check_rounded,
            color: isBest ? Colors.white : color,
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: isBest ? Colors.white : color,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _ratingColor(int i) {
    const colors = [
      Color(0xFFDC2626), // Not Done / Missed — red
      Color(0xFFE53935), // Needs Improvement — red
      Color(0xFFFB8C00), // Good / On time — orange
      Color(0xFF2E7D32), // Excellent / Jama'ah — green
    ];
    return (i >= 0 && i < colors.length) ? colors[i] : kMuted;
  }

  String _ratingLabel(int i, bool isMalayalam) {
    final labels = isMalayalam
        ? ['ഇല്ല', 'കുറവ്', 'നല്ലത്', 'ഉത്തമം']
        : ['None', 'Fair', 'Good', 'Best'];
    return (i >= 0 && i < labels.length) ? labels[i] : '';
  }

  /// Prayer-specific label for a backend rating band.
  /// Jama'ah (band 3) / On time (bands 1-2) / Missed (band 0).
  String _prayerLabel(int band, bool isMalayalam) {
    if (band >= 3) return isMalayalam ? 'ജമാഅത്ത്' : "Jama'ah";
    if (band <= 0) return isMalayalam ? 'വിട്ടു' : 'Missed';
    return isMalayalam ? 'ഓൺ ടൈം' : 'On time';
  }

  Widget _totalCard(bool isMalayalam) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF115E59), Color(0xFF0F766E)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330F766E),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMalayalam ? 'ആകെ മാർക്ക്' : 'Total Marks',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$_totalMarks',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      TextSpan(
                        text: ' / $_maxMarks',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  // Persistent bottom status bar. Each mark is saved to the backend and locked
  // the moment it is tapped, so there is no separate submit step.
  Widget _statusBar(bool isMalayalam) {
    final total = _allActs.length;
    final done = _markedCount;
    final allDone = total > 0 && done >= total;
    final bg = allDone ? kGreen : const Color(0xFF0F766E);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Container(
          height: 52,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                allDone ? Icons.check_circle_rounded : Icons.cloud_done_rounded,
                size: 20,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Text(
                allDone
                    ? (isMalayalam
                          ? 'എല്ലാം സേവ് ചെയ്തു · $done/$total'
                          : 'All saved · $done/$total')
                    : (isMalayalam
                          ? 'സേവ് ചെയ്തു $done/$total · ടാപ്പ് ചെയ്താൽ ലോക്ക് ആകും'
                          : 'Saved $done/$total · tap locks the mark'),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Subtle status line reminding that marks save automatically and lock.
  Widget _autoSaveNote(bool isMalayalam) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_clock_rounded, size: 18, color: kMuted),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              isMalayalam
                  ? 'ഓരോ മാർക്കും ഉടനെ സേവ് ആകും · പിന്നെ മാറ്റാനാകില്ല'
                  : 'Each mark saves instantly and cannot be changed',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Saves a single activity mark to the backend and locks it on success.
  /// On failure the optimistic selection is rolled back.
  Future<void> _saveActivity(
    Map<String, dynamic> a,
    int band,
    bool isMalayalam,
  ) async {
    if (a['locked'] == true || a['saving'] == true) return;

    // A prayer cannot be marked before its time has arrived.
    if (_isTimeLocked(a)) {
      final unlock = _prayerUnlockFor(a);
      final clock = unlock != null ? _formatClock(unlock) : '';
      _showSnack(
        isMalayalam
            ? 'സമയം ആയിട്ടില്ല · $clock-ന് ശേഷം മാർക്ക് ചെയ്യാം'
            : 'Not time yet · markable after $clock',
        icon: Icons.schedule_rounded,
      );
      return;
    }

    final activityId = (a['id'] ?? '').toString();
    final ratingName = (band >= 0 && band < _ratingNames.length)
        ? _ratingNames[band]
        : '';
    final ratingId = (a['ratings'] as Map<String, String>?)?[ratingName] ?? '';

    if (activityId.isEmpty || ratingId.isEmpty) {
      _showSnack(
        isMalayalam
            ? 'സേവ് ചെയ്യാനായില്ല · വീണ്ടും ശ്രമിക്കുക'
            : 'Could not save · please try again',
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    setState(() {
      a['rating'] = band;
      a['saving'] = true;
    });

    final res = await MobileApiService.submitActivityLog(
      studentId: widget.studentId,
      activityId: activityId,
      logDate: widget.date,
      ratingId: ratingId,
    );

    if (!mounted) return;

    if (res.success) {
      setState(() {
        a['saving'] = false;
        a['locked'] = true;
      });
      widget.onSubmitSuccess?.call();
    } else {
      setState(() {
        a['saving'] = false;
        a['rating'] = -1;
      });
      _showSnack(
        isMalayalam
            ? 'സേവ് ചെയ്യാനായില്ല · വീണ്ടും ശ്രമിക്കുക'
            : 'Could not save · please try again',
        icon: Icons.error_outline_rounded,
      );
    }
  }

  void _showSnack(String msg, {required IconData icon}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: kGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return iso;
    }
  }
}
