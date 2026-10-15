import 'package:flutter/material.dart';

import '../../components/portal_ui.dart';
import '../../services/parent_api_service.dart';

/// Live progress view for a single child (parent view).
///
/// Shows a daily / weekly / monthly summary with a per-day completion bar
/// chart and a category-wise marks breakdown, fed by the backend
/// `/me/children/:id/progress` endpoint.
class ChildProgressView extends StatefulWidget {
  final String childId;
  final bool isMalayalam;

  const ChildProgressView({
    super.key,
    required this.childId,
    required this.isMalayalam,
  });

  @override
  State<ChildProgressView> createState() => _ChildProgressViewState();
}

class _ChildProgressViewState extends State<ChildProgressView> {
  static const _periods = ['daily', 'weekly', 'monthly'];
  int _periodIndex = 1; // default: weekly
  late Future<ChildProgress> _future;
  late Future<ChildHomeSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _future = ParentApiService.fetchProgress(
      widget.childId,
      _periods[_periodIndex],
    );
    _summaryFuture = ParentApiService.fetchHomeSummary(widget.childId);
  }

  void _selectPeriod(int i) {
    if (i == _periodIndex) return;
    setState(() {
      _periodIndex = i;
      _future = ParentApiService.fetchProgress(widget.childId, _periods[i]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMalayalam = widget.isMalayalam;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: PortalSegmented(
            index: _periodIndex,
            items: isMalayalam
                ? const ['ദിവസം', 'ആഴ്ച', 'മാസം']
                : const ['Daily', 'Weekly', 'Monthly'],
            onChanged: _selectPeriod,
          ),
        ),
        Expanded(
          child: FutureBuilder<ChildProgress>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return EmptyState(
                  icon: Icons.insights_rounded,
                  title: isMalayalam ? 'ലോഡ് ചെയ്യുന്നു' : 'Loading',
                  message: isMalayalam
                      ? 'പുരോഗതി ലോഡ് ചെയ്യുന്നു...'
                      : 'Fetching progress...',
                  loading: true,
                );
              }
              if (snap.hasError || !snap.hasData) {
                return EmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: isMalayalam ? 'ലോഡ് ചെയ്യാനായില്ല' : 'Could not load',
                  message: isMalayalam
                      ? 'വീണ്ടും ശ്രമിക്കുക'
                      : 'Please try again later.',
                );
              }
              return _content(snap.data!, isMalayalam);
            },
          ),
        ),
      ],
    );
  }

  Widget _content(ChildProgress data, bool isMalayalam) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        // Live "today snapshot" — streak, week points, today's marks (live).
        _todaySnapshot(isMalayalam),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: StatTile(
                icon: Icons.star_rounded,
                value: '${data.totalMarks}',
                label: isMalayalam ? 'ആകെ മാർക്ക്' : 'Total marks',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                icon: Icons.percent_rounded,
                value: '${data.completionPct}%',
                label: isMalayalam ? 'പൂർത്തീകരണം' : 'Completion',
                tint: const Color(0xFF3B82F6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SectionLabel(
          isMalayalam ? 'ദിനംപ്രതി പുരോഗതി' : 'Day-by-day',
          icon: Icons.bar_chart_rounded,
        ),
        const SizedBox(height: 12),
        if (data.series.isEmpty)
          EmptyState(
            icon: Icons.bar_chart_rounded,
            title: isMalayalam ? 'വിവരം ഇല്ല' : 'No data',
            message: isMalayalam
                ? 'ഈ കാലയളവിൽ പ്രവർത്തനങ്ങൾ ഇല്ല'
                : 'No activity in this period.',
          )
        else
          SoftCard(child: _barChart(data.series, isMalayalam)),
        const SizedBox(height: 18),
        SectionLabel(
          isMalayalam ? 'വിഭാഗം തിരിച്ച്' : 'By category',
          icon: Icons.category_rounded,
        ),
        const SizedBox(height: 12),
        if (data.breakdown.isEmpty)
          EmptyState(
            icon: Icons.category_rounded,
            title: isMalayalam ? 'വിവരം ഇല്ല' : 'No data',
            message: isMalayalam
                ? 'ഈ കാലയളവിൽ മാർക്കുകൾ ഇല്ല'
                : 'No marks in this period.',
          )
        else
          SoftCard(
            child: Column(
              children: [
                for (final cat in data.breakdown)
                  _categoryRow(cat, _maxMarks(data.breakdown), isMalayalam),
              ],
            ),
          ),
      ],
    );
  }

  Widget _todaySnapshot(bool isMalayalam) {
    return FutureBuilder<ChildHomeSummary>(
      future: _summaryFuture,
      builder: (context, snap) {
        // Graceful: if the snapshot fails, just hide the card (the rest of
        // the progress view still renders from its own FutureBuilder).
        if (snap.connectionState != ConnectionState.done || !snap.hasData) {
          return const SizedBox.shrink();
        }
        final s = snap.data!;
        return SoftCard(
          color: kGreenSoft,
          borderColor: kGreen.withValues(alpha: 0.22),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: Color(0xFFEF4444),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isMalayalam
                        ? '${s.streakDays} ദിവസം സ്ട്രീക്ക്'
                        : '${s.streakDays} day streak',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: kHeading,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: kGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isMalayalam
                          ? '${s.todayDone}/${s.todayTotal} ഇന്ന്'
                          : '${s.todayDone}/${s.todayTotal} today',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _snapStat(
                      Icons.star_rounded,
                      '${s.todayMarks}',
                      isMalayalam ? 'ഇന്നത്തെ മാർക്ക്' : "Today's marks",
                    ),
                  ),
                  _vDivider(),
                  Expanded(
                    child: _snapStat(
                      Icons.calendar_view_week_rounded,
                      '${s.weekPoints}',
                      isMalayalam ? 'ആഴ്ച പോയിന്റ്' : 'Week points',
                    ),
                  ),
                  _vDivider(),
                  Expanded(
                    child: _snapStat(
                      Icons.emoji_events_rounded,
                      s.batchRank > 0 ? '#${s.batchRank}' : '—',
                      isMalayalam ? 'ബാച്ച് റാങ്ക്' : 'Batch rank',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _snapStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: kGreen, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: kHeading,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: kMuted,
          ),
        ),
      ],
    );
  }

  Widget _vDivider() {
    return Container(
      width: 1,
      height: 38,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: kBorder,
    );
  }

  int _maxMarks(List<ProgressCategory> cats) {
    var m = 1;
    for (final c in cats) {
      if (c.marks > m) m = c.marks;
    }
    return m;
  }

  Widget _barChart(List<ProgressDay> series, bool isMalayalam) {
    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final d in series)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${d.pct}%',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: kMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 10 + (d.pct / 100) * 96,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [kGreen, Color(0xFF14B8A6)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _dayLabel(d.date),
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: kMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Renders an ISO date (`yyyy-MM-dd`) as a short `dd/MM` label.
  String _dayLabel(String iso) {
    final parts = iso.split('-');
    if (parts.length == 3) return '${parts[2]}/${parts[1]}';
    return iso;
  }

  Widget _categoryRow(ProgressCategory cat, int maxMarks, bool isMalayalam) {
    final pct = maxMarks > 0 ? (cat.marks / maxMarks).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              isMalayalam ? cat.categoryMl : cat.category,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: kHeading,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 8,
                  backgroundColor: kBorder,
                  valueColor: const AlwaysStoppedAnimation(kGreen),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '${cat.marks}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: kGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
