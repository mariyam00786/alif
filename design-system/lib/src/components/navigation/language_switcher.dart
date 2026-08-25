import 'package:flutter/material.dart';

/// Language switcher widget for English/Malayalam
class LanguageSwitcher extends StatefulWidget {
  final Function(String)? onLanguageChanged;
  final String currentLanguage;

  const LanguageSwitcher({
    this.onLanguageChanged,
    this.currentLanguage = 'en',
    Key? key,
  }) : super(key: key);

  @override
  State<LanguageSwitcher> createState() => _LanguageSwitcherState();
}

class _LanguageSwitcherState extends State<LanguageSwitcher> {
  @override
  Widget build(BuildContext context) {
    // TODO: Implement language switcher
    return const Text('Language Switcher');
  }
}
