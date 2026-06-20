import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../components/portal_ui.dart';

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

class _PrayerStatus {
  static const int none = -1;
  static const int jamaah = 0; // congregation — 10
  static const int ada = 1; // on time, alone — 6
  static const int missed = 2; // not prayed — 0
  static const marks = [10, 6, 0];
}

class _DailyMarkingScreenState extends State<DailyMarkingScreen> {
  bool _isLoading = false;
  bool _submitted = false;
  DateTime? _draftSavedAt;

  // 5 daily prayers with scheduled times.
  final List<Map<String, dynamic>> _prayers = [
    {
      'name': 'Fajr',
      'nameML': 'സുബ്ഹി',
      'time': '5:12 AM',
      'icon': Icons.wb_twilight_rounded,
      'status': _PrayerStatus.none,
    },
    {
      'name': 'Dhuhr',
      'nameML': 'ളുഹർ',
      'time': '12:30 PM',
      'icon': Icons.light_mode_rounded,
      'status': _PrayerStatus.none,
    },
    {
      'name': 'Asr',
      'nameML': 'അസർ',
      'time': '3:45 PM',
      'icon': Icons.wb_sunny_outlined,
      'status': _PrayerStatus.none,
    },
    {
      'name': 'Maghrib',
      'nameML': 'മഗ്‌രിബ്',
      'time': '6:48 PM',
      'icon': Icons.brightness_4_rounded,
      'status': _PrayerStatus.none,
    },
    {
      'name': 'Isha',
      'nameML': 'ഇശാ',
      'time': '8:15 PM',
      'icon': Icons.dark_mode_rounded,
      'status': _PrayerStatus.none,
    },
  ];

  // Other daily activities, rated 0-3.
  final List<Map<String, dynamic>> _activities = [
    {
      'category': 'Quran',
      'icon': Icons.menu_book_rounded,
      'name': 'Daily Recitation',
      'nameML': 'നിത്യ പാരായണം',
      'rating': -1,
    },
    {
      'category': 'Quran',
      'icon': Icons.menu_book_rounded,
      'name': 'Memorization (Hifz)',
      'nameML': 'ഹിഫ്സ്',
      'rating': -1,
    },
    {
      'category': 'Character',
      'icon': Icons.volunteer_activism_rounded,
      'name': 'Honesty',
      'nameML': 'സത്യസന്ധത',
      'rating': -1,
    },
    {
      'category': 'Character',
      'icon': Icons.volunteer_activism_rounded,
      'name': 'Helping Others',
      'nameML': 'മറ്റുള്ളവരെ സഹായിക്കൽ',
      'rating': -1,
    },
  ];

  static const _ratingMarks = [0, 4, 7, 10];

  int get _completedPrayers =>
      _prayers.where((p) => p['status'] != _PrayerStatus.none).length;

  int get _totalMarks {
    var total = 0;
    for (final p in _prayers) {
      final s = p['status'] as int;
      if (s != _PrayerStatus.none) total += _PrayerStatus.marks[s];
    }
    for (final a in _activities) {
      final r = a['rating'] as int;
      if (r >= 0) total += _ratingMarks[r];
    }
    return total;
  }

  int get _maxMarks => _prayers.length * 10 + _activities.length * 10;

  double get _progress {
    final marked =
        _completedPrayers +
        _activities.where((a) => (a['rating'] as int) >= 0).length;
    final total = _prayers.length + _activities.length;
    return total == 0 ? 0 : marked / total;
  }

  @override
  Widget build(BuildContext context) {
    final isMalayalam = context.isMalayalam;
    final pct = (_progress * 100).round();

    return Scaffold(
      backgroundColor: kSurface,
      floatingActionButton: _submitFab(isMalayalam),
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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
              children: [
                const SectionLabel(
                  'Prayers · നമസ്കാരം',
                  icon: Icons.mosque_rounded,
                ),
                const SizedBox(height: 12),
                ..._prayers.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _prayerCard(p, isMalayalam),
                  ),
                ),
                const SizedBox(height: 12),
                const SectionLabel(
                  'Quran · ഖുർആൻ',
                  icon: Icons.menu_book_rounded,
                ),
                const SizedBox(height: 12),
                ..._activities
                    .where((a) => a['category'] == 'Quran')
                    .map(
                      (a) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _activityCard(a, isMalayalam),
                      ),
                    ),
                const SizedBox(height: 12),
                const SectionLabel(
                  'Character · സ്വഭാവം',
                  icon: Icons.volunteer_activism_rounded,
                ),
                const SizedBox(height: 12),
                ..._activities
                    .where((a) => a['category'] == 'Character')
                    .map(
                      (a) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _activityCard(a, isMalayalam),
                      ),
                    ),
                const SizedBox(height: 8),
                _totalCard(isMalayalam),
                const SizedBox(height: 16),
                _autoSaveBar(isMalayalam),
              ],
            ),
          ),
        ],
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

  Widget _prayerCard(Map<String, dynamic> p, bool isMalayalam) {
    final status = p['status'] as int;
    final marked = status != _PrayerStatus.none;
    final accent = marked ? _statusColor(status) : kMuted;

    return SoftCard(
      borderColor: marked ? accent.withValues(alpha: 0.35) : kBorder,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(p['icon'] as IconData, color: accent, size: 27),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMalayalam ? p['nameML'] : p['name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: kHeading,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 15,
                          color: kMuted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          p['time'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: kMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (marked)
                Icon(Icons.check_circle_rounded, color: accent, size: 26),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _statusChip(
                p,
                _PrayerStatus.jamaah,
                isMalayalam ? 'ജമാഅത്ത്' : "Jama'ah",
              ),
              const SizedBox(width: 8),
              _statusChip(
                p,
                _PrayerStatus.ada,
                isMalayalam ? 'അദാഅ്' : 'On time',
              ),
              const SizedBox(width: 8),
              _statusChip(
                p,
                _PrayerStatus.missed,
                isMalayalam ? 'വിട്ടു' : 'Missed',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(Map<String, dynamic> p, int value, String label) {
    final selected = p['status'] == value;
    final color = _statusColor(value);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => p['status'] = value);
          _autoSaveDraft();
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 15),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? color : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(int status) {
    switch (status) {
      case _PrayerStatus.jamaah:
        return const Color(0xFF10B981);
      case _PrayerStatus.ada:
        return const Color(0xFFF59E0B);
      case _PrayerStatus.missed:
        return const Color(0xFFEF4444);
      default:
        return kMuted;
    }
  }

  Widget _activityCard(Map<String, dynamic> a, bool isMalayalam) {
    final rating = a['rating'] as int;
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: kGreenSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(a['icon'] as IconData, color: kGreen, size: 23),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  isMalayalam ? a['nameML'] : a['name'],
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: kHeading,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(4, (i) {
              final labels = isMalayalam
                  ? ['ഇല്ല', 'കുറവ്', 'നല്ലത്', 'ഉത്തമം']
                  : ['None', 'Fair', 'Good', 'Best'];
              final colors = [
                const Color(0xFFEF4444),
                const Color(0xFFF59E0B),
                const Color(0xFF3B82F6),
                const Color(0xFF10B981),
              ];
              final selected = rating == i;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 3 ? 8 : 0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => a['rating'] = i);
                      _autoSaveDraft();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? colors[i]
                            : colors[i].withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: selected
                              ? colors[i]
                              : colors[i].withValues(alpha: 0.22),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          labels[i],
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : colors[i],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _totalCard(bool isMalayalam) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D5A34), Color(0xFF3C7A47)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332D5A34),
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

  // Floating side action — single tap to submit. Drafts save automatically,
  // so students no longer need a separate "Save Draft" button.
  Widget _submitFab(bool isMalayalam) {
    return FloatingActionButton.extended(
      onPressed: _isLoading ? null : () => _submit(isMalayalam),
      backgroundColor: kGreen,
      foregroundColor: Colors.white,
      elevation: 3,
      icon: _isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : Icon(
              _submitted ? Icons.check_circle_rounded : Icons.send_rounded,
              size: 20,
            ),
      label: Text(
        _isLoading
            ? (isMalayalam ? 'സമർപ്പിക്കുന്നു…' : 'Submitting…')
            : _submitted
            ? (isMalayalam ? 'വീണ്ടും സമർപ്പിക്കുക' : 'Submit again')
            : (isMalayalam ? 'സമർപ്പിക്കുക' : 'Submit'),
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
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
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _submitted = true;
    });
    _showSnack(
      isMalayalam ? 'വിജയകരമായി സമർപ്പിച്ചു' : 'Submitted successfully',
      icon: Icons.check_circle_rounded,
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
