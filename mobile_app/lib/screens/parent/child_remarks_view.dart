import 'package:flutter/material.dart';

import '../../components/portal_ui.dart';

/// Teacher remarks for a child (FRD 4.2.7 — parent view).
/// Shows feedback notes left by teachers, with category, date and tone.
/// Sample data with graceful fallback; embeddable in the child detail shell.
class ChildRemarksView extends StatelessWidget {
  final String childId;
  final bool isMalayalam;

  const ChildRemarksView({
    super.key,
    required this.childId,
    required this.isMalayalam,
  });

  static const List<Map<String, dynamic>> _remarks = [
    {
      'teacher': 'Ustad Rahman',
      'teacherMl': 'ഉസ്താദ് റഹ്മാൻ',
      'subject': 'Quran',
      'subjectMl': 'ഖുർആൻ',
      'text': 'Mashallah, excellent Tajweed this week. Keep up the recitation.',
      'textMl':
          'മാഷാ അല്ലാഹ്, ഈ ആഴ്ച തജ്‌വീദ് മികച്ചതായിരുന്നു. പാരായണം തുടരുക.',
      'date': '18 Jun',
      'tone': 'praise',
    },
    {
      'teacher': 'Ustada Fatima',
      'teacherMl': 'ഉസ്താദ ഫാത്തിമ',
      'subject': 'Character',
      'subjectMl': 'സ്വഭാവം',
      'text':
          'Very helpful towards classmates. A kind and responsible student.',
      'textMl':
          'സഹപാഠികളെ ഏറെ സഹായിക്കുന്നു. ദയയും ഉത്തരവാദിത്തവുമുള്ള വിദ്യാർത്ഥി.',
      'date': '15 Jun',
      'tone': 'praise',
    },
    {
      'teacher': 'Ustad Rahman',
      'teacherMl': 'ഉസ്താദ് റഹ്മാൻ',
      'subject': 'Attendance',
      'subjectMl': 'ഹാജർ',
      'text':
          'Missed Fajr marking twice this week. Please encourage consistency.',
      'textMl':
          'ഈ ആഴ്ച രണ്ടുതവണ സുബ്ഹി മാർക്കിംഗ് വിട്ടു. സ്ഥിരത പ്രോത്സാഹിപ്പിക്കുക.',
      'date': '12 Jun',
      'tone': 'note',
    },
  ];

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

  @override
  Widget build(BuildContext context) {
    if (_remarks.isEmpty) {
      return EmptyState(
        icon: Icons.rate_review_rounded,
        title: isMalayalam ? 'കുറിപ്പുകൾ ഇല്ല' : 'No remarks yet',
        message: isMalayalam
            ? 'അധ്യാപകർ കുറിപ്പ് ചേർത്താൽ ഇവിടെ കാണാം'
            : 'Teacher remarks will appear here.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      children: [
        SectionLabel(
          isMalayalam ? 'അധ്യാപകരുടെ കുറിപ്പുകൾ' : 'Teacher Remarks',
          icon: Icons.rate_review_rounded,
        ),
        const SizedBox(height: 12),
        ..._remarks.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _remarkCard(r),
          ),
        ),
      ],
    );
  }

  Widget _remarkCard(Map<String, dynamic> r) {
    final tone = r['tone'] as String;
    final color = _toneColor(tone);
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
                child: Icon(_toneIcon(tone), color: color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMalayalam
                          ? r['teacherMl'] as String
                          : r['teacher'] as String,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: kHeading,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isMalayalam
                            ? r['subjectMl'] as String
                            : r['subject'] as String,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                r['date'] as String,
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
            isMalayalam ? r['textMl'] as String : r['text'] as String,
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
}
