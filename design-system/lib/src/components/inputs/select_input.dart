import 'package:flutter/material.dart';

/// Select/Dropdown input widget
class SelectInput extends StatefulWidget {
  final String? label;
  final List<String> options;
  final String? selectedValue;
  final Function(String)? onChanged;
  final bool multiple;
  final bool required;

  const SelectInput({
    this.label,
    required this.options,
    this.selectedValue,
    this.onChanged,
    this.multiple = false,
    this.required = false,
    Key? key,
  }) : super(key: key);

  @override
  State<SelectInput> createState() => _SelectInputState();
}

class _SelectInputState extends State<SelectInput> {
  @override
  Widget build(BuildContext context) {
    // TODO: Implement select dropdown
    return DropdownButtonFormField<String>(
      items: widget.options.map((value) {
        return DropdownMenuItem(value: value, child: Text(value));
      }).toList(),
      onChanged: widget.onChanged != null ? (v) => widget.onChanged!(v!) : null,
    );
  }
}
