import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../components/portal_ui.dart';
import '../services/api_service.dart';
import '../shared/theme/theme.dart';

/// Student progress view with daily, weekly and monthly summaries.
class ProgressViewScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  /// When true, the screen renders without its own Scaffold / green header so
  /// it can be embedded inside another shell (e.g. the parent child detail).
  final bool embedded;

  const ProgressViewScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    this.embedded = false,
  });

  @override
  State<ProgressViewScreen> createState() => _ProgressViewScreenState();
}

class _ProgressViewScreenState extends State<ProgressViewScreen> {
  int _tab = 0; // 0=Daily, 1=Weekly, 2=Monthly

  bool _loading = true;
  List<Map<String, dynamic>> _daily = [];
  Map<String, dynamic>? _weekly;
  Map<String, dynamic>? _monthly;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final res = await MobileApiService.getProgress();
    if (!mounted) return;
    if (res.success && res.data != null) {
      final data = res.data!;
      setState(() {
        _daily = ((data['daily'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
        _weekly = (data['weekly'] as Map?)?.cast<String, dynamic>();
        _monthly = (data['monthly'] as Map?)?.cast<String, dynamic>();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  /// Human label for a `YYYY-MM-DD` date string relative to today.
  String _dayLabel(String? isoDate, bool isMalayalam) {
    if (isoDate == null) return '';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return isoDate;
    final today = DateTime.now();
    final d0 = DateTime(today.year, today.month, today.day);
    final d1 = DateTime(date.year, date.month, date.day);
    final diff = d0.difference(d1).inDays;
    if (diff == 0) return isMalayalam ? 'ഇന്ന്' : 'Today';
    if (diff == 1) return isMalayalam ? 'ഇന്നലെ' : 'Yesterday';
    const en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const ml = ['തിങ്കൾ', 'ചൊവ്വ', 'ബുധൻ', 'വ്യാഴം', 'വെള്ളി', 'ശനി', 'ഞായർ'];
    final idx = d1.weekday - 1;
    return isMalayalam ? ml[idx] : en[idx];
  }

  @override
  Widget build(BuildContext context) {
    final isMalayalam = context.isMalayalam;

    final segItems = isMalayalam
        ? const ['ദിനം', 'ആഴ്ച', 'മാസം']
        : const ['Daily', 'Weekly', 'Monthly'];

    final body = Column(
      children: [
        if (widget.embedded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
            child: PortalSegmented(
              index: _tab,
              items: segItems,
              onChanged: (i) => setState(() => _tab = i),
            ),
          )
        else
          MinimalHeader(
            title: isMalayalam ? 'പുരോഗതി' : 'Progress',
            subtitle: widget.studentName,
            isMalayalam: isMalayalam,
            notifications: const [],
            notificationSource: PortalNotificationSource.student,
            avatarName: widget.studentName,
            bottom: PortalSegmented(
              index: _tab,
              items: segItems,
              onChanged: (i) => setState(() => _tab = i),
            ),
          ),
        Expanded(
          child: IndexedStack(
            index: _tab,
            children: [
              _dailyView(isMalayalam),
              _weeklyView(isMalayalam),
              _monthlyView(isMalayalam),
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) return body;
    return Scaffold(backgroundColor: kSurface, body: body);
  }

  // ---- Daily ----
  Widget _dailyView(bool isMalayalam) {
    if (_loading) return _loadingView();
    if (_daily.isEmpty) {
      return _emptyView(isMalayalam);
    }
    final today = _daily.first;
    final recent = _daily.length > 1 ? _daily.sublist(1) : const [];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        _heroCard(
          isMalayalam ? 'ഇന്നത്തെ മാർക്ക്' : "Today's Marks",
          '${_asInt(today['marks'])}',
          '${_asInt(today['done'])}/${_asInt(today['total'])} ${isMalayalam ? 'പൂർത്തിയായി' : 'activities'}',
          _asInt(today['pct']) / 100.0,
        ),
        const SizedBox(height: 12),
        SectionLabel(
          isMalayalam ? 'കഴിഞ്ഞ ദിവസങ്ങൾ' : 'Recent Days',
          icon: Icons.history_rounded,
        ),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          EmptyState(
            icon: Icons.history_rounded,
            title: isMalayalam ? 'ഇതുവരെ റെക്കോർഡ് ഇല്ല' : 'No history yet',
            message: isMalayalam
                ? 'ദിനംപ്രതി മാർക്ക് ചെയ്താൽ ഇവിടെ കാണാം'
                : 'Mark your day to see progress here.',
          )
        else
          SoftCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (int i = 0; i < recent.length; i++) ...[
                  _dayRow(recent[i] as Map<String, dynamic>, isMalayalam),
                  if (i != recent.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.borderSoft,
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _dayRow(Map<String, dynamic> d, bool isMalayalam) {
    final pct = _asInt(d['pct']);
    final color = _pctColor(pct);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _trendDot(d['trend'] as String? ?? 'flat'),
                    const SizedBox(width: 9),
                    Text(
                      _dayLabel(d['date'] as String?, isMalayalam),
                      style: AppTextStyles.cardTitle,
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: pct / 100.0,
                    minHeight: 7,
                    backgroundColor: AppColors.surfaceMuted,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_asInt(d['marks'])}',
                style: AppTextStyles.statNumber.copyWith(color: kHeading),
              ),
              const SizedBox(height: 2),
              Text(
                '$pct%',
                style: AppTextStyles.labelSmall.copyWith(color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- Weekly ----
  Widget _weeklyView(bool isMalayalam) {
    if (_loading) return _loadingView();
    final w = _weekly;
    if (w == null) return _emptyView(isMalayalam);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        _heroCard(
          isMalayalam ? 'ഈ ആഴ്ച' : 'This Week',
          '${_asInt(w['totalMarks'])}',
          '${_asInt(w['done'])}/${_asInt(w['total'])} ${isMalayalam ? 'പ്രവർത്തനങ്ങൾ' : 'activities'}',
          _asInt(w['pct']) / 100.0,
          period: _weekRangeLabel(isMalayalam),
        ),
        const SizedBox(height: 12),
        _metricCard([
          _MetricItem(
            Icons.trending_up_rounded,
            '${_asInt(w['avg'])}',
            isMalayalam ? 'ശരാശരി' : 'Avg / day',
            kGreen,
          ),
          _MetricItem(
            Icons.emoji_events_rounded,
            '${_asInt(w['best'])}',
            isMalayalam ? 'മികച്ച ദിനം' : 'Best day',
            const Color(0xFFF59E0B),
          ),
          _MetricItem(
            Icons.check_circle_rounded,
            '${_asInt(w['done'])}/${_asInt(w['total'])}',
            isMalayalam ? 'പൂർത്തിയായവ' : 'Completed',
            const Color(0xFF10B981),
          ),
        ]),
      ],
    );
  }

  // ---- Monthly ----
  Widget _monthlyView(bool isMalayalam) {
    if (_loading) return _loadingView();
    final m = _monthly;
    if (m == null) return _emptyView(isMalayalam);
    final improve = _asInt(m['improve']);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        _heroCard(
          isMalayalam ? 'ഈ മാസം' : 'This Month',
          '${_asInt(m['totalMarks'])}',
          '${_asInt(m['days'])} ${isMalayalam ? 'സജീവ ദിനങ്ങൾ' : 'active days'}',
          _asInt(m['pct']) / 100.0,
          period: _monthLabel(isMalayalam),
        ),
        const SizedBox(height: 12),
        if (improve != 0)
          SoftCard(
            color: kGreenSoft,
            borderColor: kGreen.withValues(alpha: 0.25),
            child: Row(
              children: [
                Icon(
                  improve > 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: kGreen,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    improve > 0
                        ? (isMalayalam
                              ? 'കഴിഞ്ഞ മാസത്തേക്കാൾ $improve% മെച്ചപ്പെട്ടു'
                              : '$improve% better than last month')
                        : (isMalayalam
                              ? 'കഴിഞ്ഞ മാസത്തേക്കാൾ ${improve.abs()}% കുറവ്'
                              : '${improve.abs()}% lower than last month'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: kGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (improve != 0) const SizedBox(height: 12),
        _metricCard([
          _MetricItem(
            Icons.trending_up_rounded,
            '${_asInt(m['avg'])}',
            isMalayalam ? 'ശരാശരി' : 'Avg / day',
            kGreen,
          ),
          _MetricItem(
            Icons.emoji_events_rounded,
            '${_asInt(m['best'])}',
            isMalayalam ? 'മികച്ച ദിനം' : 'Best day',
            const Color(0xFFF59E0B),
          ),
          _MetricItem(
            Icons.calendar_month_rounded,
            '${_asInt(m['days'])}',
            isMalayalam ? 'സജീവ ദിനങ്ങൾ' : 'Active days',
            const Color(0xFF10B981),
          ),
        ]),
      ],
    );
  }

  // ---- Shared ----
  Widget _heroCard(
    String label,
    String value,
    String sub,
    double progress, {
    String? period,
  }) {
    final p = progress.clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDeep,
            AppColors.primary,
            AppColors.primaryLight,
          ],
          stops: [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.24),
            blurRadius: 28,
            spreadRadius: -10,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Soft decorative orb for a touch of delight.
          Positioned(
            right: -34,
            top: -46,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                        if (period != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              period,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      sub,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 64,
                height: 64,
                child: CustomPaint(
                  painter: _RingPainter(p),
                  child: Center(
                    child: Text(
                      '${(p * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trendDot(String trend) {
    late IconData icon;
    late Color color;
    switch (trend) {
      case 'up':
        icon = Icons.arrow_upward_rounded;
        color = AppColors.success;
        break;
      case 'down':
        icon = Icons.arrow_downward_rounded;
        color = AppColors.error;
        break;
      default:
        icon = Icons.remove_rounded;
        color = AppColors.warning;
    }
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 13),
    );
  }

  Color _pctColor(int pct) {
    if (pct >= 80) return const Color(0xFF10B981); // strong — green
    if (pct >= 50) return const Color(0xFFE0A82E); // fair — amber
    return const Color(0xFFEF4444); // low — red
  }

  int _asInt(dynamic v) => (v is num) ? v.toInt() : 0;

  /// Label for the current Mon–Sun week, e.g. "Jun 18 – 24".
  String _weekRangeLabel(bool isMalayalam) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 6));
    const mEn = [
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
    const mMl = [
      'ജനു',
      'ഫെബ്',
      'മാർ',
      'ഏപ്രി',
      'മേയ്',
      'ജൂൺ',
      'ജൂലൈ',
      'ഓഗ',
      'സെപ്',
      'ഒക്ടോ',
      'നവം',
      'ഡിസം',
    ];
    final months = isMalayalam ? mMl : mEn;
    final startLabel = '${months[start.month - 1]} ${start.day}';
    final endLabel = start.month == end.month
        ? '${end.day}'
        : '${months[end.month - 1]} ${end.day}';
    return '$startLabel – $endLabel';
  }

  /// Label for the current month, e.g. "June 2026".
  String _monthLabel(bool isMalayalam) {
    final now = DateTime.now();
    const mEn = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const mMl = [
      'ജനുവരി',
      'ഫെബ്രുവരി',
      'മാർച്ച്',
      'ഏപ്രിൽ',
      'മേയ്',
      'ജൂൺ',
      'ജൂലൈ',
      'ഓഗസ്റ്റ്',
      'സെപ്റ്റംബർ',
      'ഒക്ടോബർ',
      'നവംബർ',
      'ഡിസംബർ',
    ];
    final months = isMalayalam ? mMl : mEn;
    return '${months[now.month - 1]} ${now.year}';
  }

  /// A single compact card holding several inline metrics (replaces the old
  /// grid of separate stat tiles).
  Widget _metricCard(List<_MetricItem> items) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Expanded(child: _metricCol(items[i])),
            if (i != items.length - 1)
              Container(width: 1, height: 40, color: kBorder),
          ],
        ],
      ),
    );
  }

  Widget _metricCol(_MetricItem m) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(m.icon, color: m.color, size: 20),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            m.value,
            style: AppTextStyles.statNumber.copyWith(
              color: kHeading,
              fontSize: 19,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          m.label,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelSmall,
        ),
      ],
    );
  }

  Widget _loadingView() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 80),
        child: CircularProgressIndicator(color: kGreen),
      ),
    );
  }

  Widget _emptyView(bool isMalayalam) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 28),
      children: [
        EmptyState(
          icon: Icons.insights_rounded,
          title: isMalayalam ? 'ഡാറ്റ ലഭ്യമല്ല' : 'No data yet',
          message: isMalayalam
              ? 'ദിനംപ്രതി മാർക്ക് ചെയ്താൽ പുരോഗതി ഇവിടെ കാണാം.'
              : 'Mark your activities to see your progress here.',
        ),
      ],
    );
  }
}

/// A compact inline metric (icon + value + label) used in [_metricCard].
class _MetricItem {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MetricItem(this.icon, this.value, this.label, this.color);
}

/// Minimal circular progress ring with a soft track and rounded cap, drawn in
/// white for use on the teal hero card.
class _RingPainter extends CustomPainter {
  final double progress;

  const _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 7.0;
    final rect =
        Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = Colors.white.withValues(alpha: 0.22);
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, track);
    if (progress > 0) {
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, fg);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}
