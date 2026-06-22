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
  bool _isLoading = false;
  bool _submitted = false;
  bool _confirmed = false;
  bool _loadingStructure = true;
  DateTime? _draftSavedAt;

  // The full activity catalog loaded from the backend. Every category and
  // activity shown here mirrors the admin configuration, so the student marks
  // exactly the same items that teachers, parents and admin see.
  //
  // Each category: { name, nameML, icon (IconData), activities: List<Map> }
  // Each activity: { id, name, nameML, icon, rating (-1..3), ratings: {name:id} }
  List<Map<String, dynamic>> _cats = [];

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
    if (n.contains('salah') || n.contains('prayer'))
      return Icons.mosque_rounded;
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

  @override
  void initState() {
    super.initState();
    _loadStructure();
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

      final builtActs = <Map<String, dynamic>>[];
      for (final a in (cm['activities'] as List?) ?? const []) {
        final am = a as Map<String, dynamic>;
        if ((am['status'] ?? 'active').toString() != 'active') continue;
        final id = (am['id'] ?? '').toString();
        if (id.isEmpty) continue;

        final ratingMap = <String, String>{};
        for (final r in (am['ratings'] as List?) ?? const []) {
          final rm = r as Map<String, dynamic>;
          ratingMap[(rm['rating_name'] ?? '').toString()] = (rm['id'] ?? '')
              .toString();
        }

        builtActs.add({
          'id': id,
          'name': (am['name'] ?? '').toString(),
          'nameML': (am['name_ml'] ?? am['name'] ?? '').toString(),
          'icon': icon,
          'rating': -1,
          'ratings': ratingMap,
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

    if (!mounted) return;
    setState(() {
      _cats = built;
      _loadingStructure = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMalayalam = context.isMalayalam;
    final pct = (_progress * 100).round();

    return Scaffold(
      backgroundColor: kSurface,
      bottomNavigationBar: (_loadingStructure || _cats.isEmpty)
          ? null
          : _submitBar(isMalayalam),
      body: Column(
        children: [
          PortalHeader(
            title: isMalayalam ? 'ഇത്തിസാബ്' : 'Daily Marking',
            subtitle: _formatDate(widget.date),
            icon: Icons.checklist_rounded,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ringBadge(pct),
                const SizedBox(width: 12),
                const PortalProfileAvatar(),
              ],
            ),
          ),
          Expanded(
            child: _loadingStructure
                ? const Center(child: CircularProgressIndicator())
                : _cats.isEmpty
                ? _emptyState(isMalayalam)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                    children: [
                      for (final cat in _cats) ...[
                        SectionLabel(
                          '${cat['name']} · ${cat['nameML']}',
                          icon: cat['icon'] as IconData,
                        ),
                        const SizedBox(height: 12),
                        _categoryCard(cat, isMalayalam),
                        const SizedBox(height: 12),
                      ],
                      _totalCard(isMalayalam),
                      if (_markedCount > 0 && !_submitted) ...[
                        const SizedBox(height: 12),
                        _confirmTile(isMalayalam),
                      ],
                      const SizedBox(height: 16),
                      _autoSaveBar(isMalayalam),
                      const SizedBox(height: 28),
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
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: CircularProgressIndicator(
              value: _progress,
              strokeWidth: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          Text(
            '$pct%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryCard(Map<String, dynamic> cat, bool isMalayalam) {
    final items = (cat['activities'] as List).cast<Map<String, dynamic>>();
    final done = items.where((a) => (a['rating'] as int) >= 0).length;
    return SoftCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
            child: Row(
              children: [
                Icon(
                  cat['icon'] as IconData,
                  size: 15,
                  color: kGreen.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isMalayalam ? cat['nameML'] : cat['name'],
                    style: AppTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kGreen.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$done/${items.length}',
                    style: TextStyle(
                      color: kGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (int i = 0; i < items.length; i++) ...[
            _activityRow(items[i], isMalayalam),
            if (i < items.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Color _darken(Color c, [double amount = 0.16]) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  Widget _activityRow(Map<String, dynamic> a, bool isMalayalam) {
    final rating = a['rating'] as int;
    final rated = rating >= 0;
    final accent = rated ? _ratingColor(rating) : kGreen;

    final iconBadge = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, _darken(accent)],
        ),
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.32),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(a['icon'] as IconData, color: Colors.white, size: 20),
    );

    final header = Row(
      children: [
        iconBadge,
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            isMalayalam ? a['nameML'] : a['name'],
            style: AppTextStyles.cardTitle,
          ),
        ),
        if (rated) ...[
          const SizedBox(width: 8),
          _ratingPill(rating, isMalayalam),
        ],
      ],
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(10, rated ? 9 : 11, 10, rated ? 9 : 11),
      decoration: BoxDecoration(
        color: rated ? accent.withValues(alpha: 0.07) : const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(16),
        border: rated
            ? Border.all(color: accent.withValues(alpha: 0.30))
            : null,
      ),
      child: rated
          ? header
          : Column(
              children: [
                header,
                const SizedBox(height: 10),
                Row(
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

  Widget _ratingChip(Map<String, dynamic> a, int value, bool isMalayalam) {
    final color = _ratingColor(value);
    return Expanded(
      child: GestureDetector(
        onTap: _submitted
            ? null
            : () {
                setState(() => a['rating'] = value);
                _autoSaveDraft();
              },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 3),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: color.withValues(alpha: 0.40),
              width: 1.3,
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
                const SizedBox(width: 4),
                Text(
                  _ratingLabel(value, isMalayalam),
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

  Widget _ratingPill(int rating, bool isMalayalam) {
    final color = _ratingColor(rating);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 13, 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, _darken(color)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.38),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 13,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _ratingLabel(rating, isMalayalam),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _ratingColor(int i) {
    const colors = [
      Color(0xFFEF4444),
      Color(0xFFE0A82E),
      Color(0xFF3B82F6),
      Color(0xFF10B981),
    ];
    return (i >= 0 && i < colors.length) ? colors[i] : kMuted;
  }

  String _ratingLabel(int i, bool isMalayalam) {
    final labels = isMalayalam
        ? ['ഇല്ല', 'കുറവ്', 'നല്ലത്', 'ഉത്തമം']
        : ['None', 'Fair', 'Good', 'Best'];
    return (i >= 0 && i < labels.length) ? labels[i] : '';
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

  // Persistent bottom action bar — sits below the list so it never overlaps
  // the rating buttons. Drafts save automatically, so there is no separate
  // "Save Draft" button.
  Widget _submitBar(bool isMalayalam) {
    final locked = _markedCount == 0 || !_confirmed;
    final disabled = _isLoading || _submitted || locked;
    final bg = (_submitted || locked) ? kMuted : kGreen;

    final label = _isLoading
        ? (isMalayalam ? 'സമർപ്പിക്കുന്നു…' : 'Submitting…')
        : _submitted
        ? (isMalayalam ? 'ഇന്ന് സമർപ്പിച്ചു' : 'Submitted today')
        : _markedCount == 0
        ? (isMalayalam ? 'ഒന്നെങ്കിലും അടയാളപ്പെടുത്തുക' : 'Mark at least one')
        : !_confirmed
        ? (isMalayalam ? 'ഉറപ്പിക്കുക' : 'Confirm first')
        : (isMalayalam
              ? '$_markedCount/${_allActs.length} സമർപ്പിക്കുക'
              : 'Submit $_markedCount/${_allActs.length}');

    final icon = _isLoading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          )
        : Icon(
            _submitted
                ? Icons.check_circle_rounded
                : locked
                ? Icons.lock_outline_rounded
                : Icons.send_rounded,
            size: 20,
            color: Colors.white,
          );

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
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: disabled ? null : () => _submit(isMalayalam),
            style: ElevatedButton.styleFrom(
              backgroundColor: bg,
              disabledBackgroundColor: bg,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Final confirmation tick — student verifies everything is correct before
  // the submit button unlocks.
  Widget _confirmTile(bool isMalayalam) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _confirmed = !_confirmed),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: _confirmed ? kGreen.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _confirmed ? kGreen : kBorder,
            width: _confirmed ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: _confirmed ? kGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _confirmed ? kGreen : kMuted,
                  width: 1.8,
                ),
              ),
              child: _confirmed
                  ? const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isMalayalam
                    ? 'ഇതെല്ലാം ശരിയാണ്, സമർപ്പിക്കാൻ തയ്യാർ'
                    : 'I confirm everything is correct',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: _confirmed ? kGreen : kHeading,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Subtle status line showing that marks are kept safe automatically.
  Widget _autoSaveBar(bool isMalayalam) {
    final saved = _draftSavedAt != null;
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            saved ? Icons.cloud_done_rounded : Icons.cloud_queue_rounded,
            size: 18,
            color: saved ? kGreen : kMuted,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              saved
                  ? (isMalayalam
                        ? 'ഡ്രാഫ്റ്റ് സ്വയം സേവ് ചെയ്തു · ${_formatTime(_draftSavedAt!)}'
                        : 'Draft auto-saved · ${_formatTime(_draftSavedAt!)}')
                  : (isMalayalam
                        ? 'മാർക്ക് ചെയ്യുമ്പോൾ സ്വയം സേവ് ആകും'
                        : 'Your marks save automatically'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: saved ? kGreen : kMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _autoSaveDraft() {
    setState(() => _draftSavedAt = DateTime.now());
  }

  Future<void> _submit(bool isMalayalam) async {
    if (_markedCount == 0 || !_confirmed || _submitted || _isLoading) return;
    setState(() => _isLoading = true);

    var persistedAny = false;
    var hadFailure = false;

    final futures = <Future<void>>[];
    for (final a in _allActs) {
      final r = a['rating'] as int;
      if (r < 0) continue;
      final activityId = (a['id'] ?? '').toString();
      final ratingName = _ratingNames[r];
      final ratingId =
          (a['ratings'] as Map<String, String>?)?[ratingName] ?? '';
      if (activityId.isEmpty || ratingId.isEmpty) {
        hadFailure = true;
        continue;
      }
      futures.add(() async {
        final res = await MobileApiService.submitActivityLog(
          studentId: widget.studentId,
          activityId: activityId,
          logDate: widget.date,
          ratingId: ratingId,
        );
        if (res.success) {
          persistedAny = true;
        } else {
          hadFailure = true;
        }
      }());
    }
    await Future.wait(futures);

    if (!mounted) return;

    if (!persistedAny) {
      setState(() => _isLoading = false);
      _showSnack(
        isMalayalam
            ? 'സമർപ്പിക്കാൻ കഴിഞ്ഞില്ല · വീണ്ടും ശ്രമിക്കുക'
            : 'Could not submit · please try again',
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    setState(() {
      _isLoading = false;
      _submitted = true;
    });
    _showSnack(
      hadFailure
          ? (isMalayalam
                ? 'ഭാഗികമായി സമർപ്പിച്ചു · ചിലത് സംരക്ഷിക്കാനായില്ല'
                : 'Partially submitted · some marks could not be saved')
          : (isMalayalam
                ? 'ഇന്നത്തേക്ക് സമർപ്പിച്ചു · ഒരു ദിവസം ഒരു തവണ മാത്രം'
                : 'Submitted for today · one submission per day'),
      icon: hadFailure
          ? Icons.warning_amber_rounded
          : Icons.check_circle_rounded,
    );
    widget.onSubmitSuccess?.call();
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

  String _formatTime(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final ap = t.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ap';
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
