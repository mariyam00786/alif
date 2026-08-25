import 'package:flutter/material.dart';

/// Tabs widget for tabbed navigation
class Tabs extends StatefulWidget {
  final List<String> tabLabels;
  final List<Widget> tabContents;
  final Function(int)? onTabChanged;

  const Tabs({
    required this.tabLabels,
    required this.tabContents,
    this.onTabChanged,
    Key? key,
  }) : super(key: key);

  @override
  State<Tabs> createState() => _TabsState();
}

class _TabsState extends State<Tabs> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.tabLabels.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Implement tabs widget
    return const Text('Tabs');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
