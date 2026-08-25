import 'package:flutter/material.dart';

import '../../components/portal_ui.dart';
import '../../services/parent_api_service.dart';
import 'parent_data.dart';

/// Daily-record approval screen for parents (`parent_approved`).
///
/// Lists records submitted by/for the parent's children that are awaiting
/// review, and lets the parent approve or send them back via the live API.
class ParentApprovalsScreen extends StatefulWidget {
  final bool isMalayalam;
  final Future<void> Function()? onChanged;

  const ParentApprovalsScreen({
    super.key,
    required this.isMalayalam,
    this.onChanged,
  });

  @override
  State<ParentApprovalsScreen> createState() => _ParentApprovalsScreenState();
}

class _ParentApprovalsScreenState extends State<ParentApprovalsScreen> {
  List<PendingApproval> _pending = const [];
  bool _loading = true;
  String? _error;
  final Set<String> _busy = {};
  final Set<String> _approved = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ParentApiService.fetchApprovals();
      if (!mounted) return;
      setState(() {
        _pending = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _resolve(
    PendingApproval rec,
    String outcome,
    bool isMalayalam,
  ) async {
    if (_busy.contains(rec.id) || _approved.contains(rec.id)) return;
    setState(() => _busy.add(rec.id));
    final name = isMalayalam
        ? (rec.childNameMl ?? rec.childName ?? '')
        : (rec.childName ?? '');
    final date = rec.rawDate ?? '';
    try {
      if (outcome == 'approved') {
        await ParentApiService.approve(rec.childId, date);
      } else {
        await ParentApiService.reject(rec.childId, date);
      }
      if (!mounted) return;
      setState(() {
        if (outcome == 'approved') {
          // Keep the card but lock it in an "approved" state so it can never
          // be approved a second time.
          _approved.add(rec.id);
        } else {
          _pending = _pending.where((r) => r.id != rec.id).toList();
        }
        _busy.remove(rec.id);
      });
      final msg = outcome == 'approved'
          ? (isMalayalam
                ? '$name ന്റെ റെക്കോർഡ് അംഗീകരിച്ചു'
                : 'Approved $name\'s record')
          : (isMalayalam
                ? '$name ന്റെ റെക്കോർഡ് തിരികെ അയച്ചു'
                : 'Sent back $name\'s record');
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: outcome == 'approved'
                ? const Color(0xFF10B981)
                : const Color(0xFFB7791F),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      await widget.onChanged?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy.remove(rec.id));
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              isMalayalam ? 'പ്രവർത്തനം പരാജയപ്പെട്ടു' : 'Action failed',
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMalayalam = widget.isMalayalam;
    final open = _pending;
    final pendingCount = open.where((r) => !_approved.contains(r.id)).length;

    return Scaffold(
      backgroundColor: kSurface,
      body: Column(
        children: [
          PortalHeader(
            title: isMalayalam ? 'അംഗീകാരം' : 'Approvals',
            subtitle: isMalayalam
                ? '$pendingCount എണ്ണം ബാക്കി'
                : '$pendingCount pending',
            icon: Icons.fact_check_rounded,
          ),
          Expanded(
            child: _loading
                ? EmptyState(
                    icon: Icons.fact_check_rounded,
                    title: isMalayalam ? 'ലോഡ് ചെയ്യുന്നു' : 'Loading',
                    message: isMalayalam
                        ? 'അംഗീകാരങ്ങൾ ലോഡ് ചെയ്യുന്നു...'
                        : 'Fetching pending approvals...',
                    loading: true,
                  )
                : _error != null
                ? EmptyState(
                    icon: Icons.wifi_off_rounded,
                    title: isMalayalam
                        ? 'ലോഡ് ചെയ്യാനായില്ല'
                        : 'Could not load',
                    message: isMalayalam
                        ? 'വീണ്ടും ശ്രമിക്കാൻ താഴേക്ക് വലിക്കുക'
                        : 'Pull down to retry.',
                  )
                : open.isEmpty
                ? EmptyState(
                    icon: Icons.verified_rounded,
                    title: isMalayalam ? 'എല്ലാം പൂർത്തിയായി' : 'All caught up',
                    message: isMalayalam
                        ? 'അംഗീകാരത്തിനായി ഒന്നും ബാക്കിയില്ല'
                        : 'No records waiting for your approval.',
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    color: kGreen,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                      children: [
                        for (final rec in open) ...[
                          _approvalCard(rec, isMalayalam),
                          const SizedBox(height: 14),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _approvalCard(PendingApproval rec, bool isMalayalam) {
    final highlights = isMalayalam ? rec.highlightsMl : rec.highlights;
    final childColor = rec.childColor ?? kGreen;
    final childAvatar = rec.childAvatar ?? '?';
    final childName = isMalayalam
        ? (rec.childNameMl ?? rec.childName ?? '')
        : (rec.childName ?? '');
    final busy = _busy.contains(rec.id);
    final approved = _approved.contains(rec.id);

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
                  color: childColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  childAvatar,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: childColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      childName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: kHeading,
                      ),
                    ),
                    Text(
                      isMalayalam ? rec.dateLabelMl : rec.dateLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: kMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: kGreenSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${rec.marks} ${isMalayalam ? 'മാർക്ക്' : 'marks'}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: kGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 17,
                color: Color(0xFF10B981),
              ),
              const SizedBox(width: 6),
              Text(
                '${rec.completed}/${rec.total} ${isMalayalam ? 'പ്രവർത്തനങ്ങൾ പൂർത്തിയായി' : 'activities completed'}',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: kBody,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final h in highlights)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    h,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: kBody,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (approved)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: kGreenSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    size: 18,
                    color: kGreen,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isMalayalam ? 'അംഗീകരിച്ചു' : 'Approved',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: kGreen,
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () => _resolve(rec, 'returned', isMalayalam),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB7791F),
                      side: const BorderSide(color: Color(0xFFE5C07B)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.undo_rounded, size: 18),
                    label: Text(
                      isMalayalam ? 'തിരികെ' : 'Send back',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: busy
                        ? null
                        : () => _resolve(rec, 'approved', isMalayalam),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      isMalayalam ? 'അംഗീകരിക്കുക' : 'Approve',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
