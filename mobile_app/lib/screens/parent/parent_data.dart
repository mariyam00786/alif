import 'package:flutter/material.dart';

/// A child linked to the signed-in parent.
class ParentChild {
  final String id;
  final String name;
  final String nameMl;
  final String batchId;
  final String batchName;
  final String batchNameMl;
  final String avatar; // initial letter
  final Color color;
  final int todayMarks;
  final int todayPct;
  final int weekPct;
  final int monthPct;
  final int rank;
  final int batchSize;
  final int pendingApprovals;
  final int badges;
  final bool active;
  final String lastUpdate;
  final String lastUpdateMl;

  const ParentChild({
    required this.id,
    required this.name,
    required this.nameMl,
    required this.batchId,
    required this.batchName,
    required this.batchNameMl,
    required this.avatar,
    required this.color,
    required this.todayMarks,
    required this.todayPct,
    required this.weekPct,
    required this.monthPct,
    required this.rank,
    required this.batchSize,
    required this.pendingApprovals,
    required this.badges,
    required this.active,
    required this.lastUpdate,
    required this.lastUpdateMl,
  });
}

/// An earned or in-progress achievement / badge for a child.
class ChildBadge {
  final String title;
  final String titleMl;
  final IconData icon;
  final Color color;
  final bool earned;
  final String detail;
  final String detailMl;

  const ChildBadge({
    required this.title,
    required this.titleMl,
    required this.icon,
    required this.color,
    required this.earned,
    required this.detail,
    required this.detailMl,
  });
}

/// A daily record awaiting parent approval.
class PendingApproval {
  final String id;
  final String childId;
  final String dateLabel;
  final String dateLabelMl;
  final int marks;
  final int completed;
  final int total;
  final List<String> highlights;
  final List<String> highlightsMl;

  // Live-data fields (populated from the API; null for static mock).
  final String? rawDate;
  final String? childName;
  final String? childNameMl;
  final String? childAvatar;
  final Color? childColor;

  const PendingApproval({
    required this.id,
    required this.childId,
    required this.dateLabel,
    required this.dateLabelMl,
    required this.marks,
    required this.completed,
    required this.total,
    required this.highlights,
    required this.highlightsMl,
    this.rawDate,
    this.childName,
    this.childNameMl,
    this.childAvatar,
    this.childColor,
  });
}
