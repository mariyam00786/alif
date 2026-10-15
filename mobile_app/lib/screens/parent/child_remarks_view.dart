import 'package:flutter/material.dart';

import '../../components/portal_ui.dart';
import '../../services/parent_api_service.dart';

/// Teacher remarks for a child (FRD 4.2.7 — parent view).
///
/// Shows feedback notes left by teachers, fed LIVE by the backend
/// `GET /me/children/:childId/remarks` endpoint (real `student_remarks`
/// rows joined with the teacher's name + a tone tag). Falls back to an
/// empty state when a child has no remarks yet.
class ChildRemarksView extends StatefulWidget {
  final String childId;
  final bool isMalayalam;

  const ChildRemarksView({
    super.key,
    required this.childId,
    required this.isMalayalam,
  });

  @override
  State<ChildRemarksView> createState() => _ChildRemarksViewState();
}

class _ChildRemarksViewState extends State<ChildRemarksView> {
  late Future<List<ChildRemark>> _future;

  @override
  void initState() {
    super.initState();
    _future = ParentApiService.fetchRemarks(widget.childId);
  }

  Future<void> _reload() {
    setState(() {
      _future = ParentApiService.fetchRemarks(widget.childId);
    });
    return _future;
  }

  Color _toneColor(String tone) {
    switch (tone) {
      case 'praise':
        return const Color(0xFF10B981);
      case 'note':
        return const Color(0xFFF59E0B);
      default:
        return kGreen;
    }
  }

  IconData _toneIcon(String tone) {
    switch (tone) {
      case 'praise':
        return Icons.favorite_rounded;
      case 'note':
        return Icons.info_outline_rounded;
      default:
        return Icons.chat_bubble_outline_rounded;
    }
  }

  String _toneLabel(String tone, bool isMalayalam) {
    switch (tone) {
      case 'praise':
        return isMalayalam ? 'പ്രശംസ' : 'Praise';
      case 'note':
        return isMalayalam ? 'ശ്രദ്ധിക്കുക' : 'Note';
      default:
        return isMalayalam ? 'അറിയിപ്പ്' : 'Info';
    }
  }

  String _formatDate(DateTime dt, bool isMalayalam) {
    final now = DateTime.now();
    final diff = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(dt.year, dt.month, dt.day));
    if (diff.inDays == 0) return isMalayalam ? 'ഇന്ന്' : 'Today';
    if (diff.inDays == 1) return isMalayalam ? 'ഇന്നലെ' : 'Yesterday';
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
    return '${dt.day} ${months[dt.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final isMalayalam = widget.isMalayalam;

    return FutureBuilder<List<ChildRemark>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return EmptyState(
            icon: Icons.rate_review_rounded,
            title: isMalayalam ? 'ലോഡ് ചെയ്യുന്നു' : 'Loading',
            message: isMalayalam
                ? 'അധ്യാപക കുറിപ്പുകൾ ലോഡ് ചെയ്യുന്നു...'
                : 'Fetching teacher remarks...',
            loading: true,
          );
        }
        if (snap.hasError || !snap.hasData) {
          return EmptyState(
            icon: Icons.wifi_off_rounded,
            title: isMalayalam ? 'ലോഡ് ചെയ്യാനായില്ല' : 'Could not load',
            message: isMalayalam
                ? 'വീണ്ടും ശ്രമിക്കാൻ താഴേക്ക് വലിക്കുക'
                : 'Pull down to retry.',
          );
        }

        final remarks = snap.data!;
        if (remarks.isEmpty) {
          return EmptyState(
            icon: Icons.rate_review_rounded,
            title: isMalayalam ? 'കുറിപ്പുകൾ ഇല്ല' : 'No remarks yet',
            message: isMalayalam
                ? 'അധ്യാപകർ കുറിപ്പ് ചേർത്താൽ ഇവിടെ കാണാം'
                : 'Teacher remarks will appear here.',
          );
        }

        return RefreshIndicator(
          onRefresh: _reload,
          color: kGreen,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            children: [
              SectionLabel(
                isMalayalam ? 'അധ്യാപകരുടെ കുറിപ്പുകൾ' : 'Teacher Remarks',
                icon: Icons.rate_review_rounded,
              ),
              const SizedBox(height: 12),
              for (final r in remarks) ...[
                _remarkCard(r, isMalayalam),
                const SizedBox(height: 12),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _remarkCard(ChildRemark r, bool isMalayalam) {
    final color = _toneColor(r.tone);
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_toneIcon(r.tone), color: color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.teacher,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: kHeading,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        if (r.subject != null && r.subject!.isNotEmpty)
                          _chip(r.subject!, color),
                        _chip(_toneLabel(r.tone, isMalayalam), color),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(r.createdAt, isMalayalam),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: kMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            r.message,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: kBody,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
