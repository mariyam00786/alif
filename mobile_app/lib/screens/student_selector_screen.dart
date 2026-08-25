import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../constants/colors.dart';
import '../constants/dimensions.dart';

/// Student selector screen for parent login
///
/// Features:
/// - Display all linked students
/// - Easy selection with visual feedback
/// - Student avatar and info
/// - Navigation to student dashboard
/// - Bilingual support
class StudentSelectorScreen extends StatefulWidget {
  final ValueChanged<String> onStudentSelected;

  const StudentSelectorScreen({super.key, required this.onStudentSelected});

  @override
  State<StudentSelectorScreen> createState() => _StudentSelectorScreenState();
}

class _StudentSelectorScreenState extends State<StudentSelectorScreen> {
  // Mock data: parent's linked students
  final List<Map<String, dynamic>> _students = [
    {
      'id': 'student-001',
      'name': 'Ahmed Ali',
      'batch': 'Class A',
      'avatar': 'A',
      'avatarColor': ColorPalette.primaryDark,
      'status': 'Active',
      'lastUpdate': '2 hours ago',
    },
    {
      'id': 'student-002',
      'name': 'Fatima Khan',
      'batch': 'Class B',
      'avatar': 'F',
      'avatarColor': ColorPalette.secondary,
      'status': 'Active',
      'lastUpdate': '1 hour ago',
    },
    {
      'id': 'student-003',
      'name': 'Mohammed Hassan',
      'batch': 'Class A',
      'avatar': 'M',
      'avatarColor': ColorPalette.ratingExcellent,
      'status': 'Inactive',
      'lastUpdate': '3 days ago',
    },
  ];

  String? _selectedStudentId;

  @override
  Widget build(BuildContext context) {
    final isMalayalam = context.isMalayalam;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isMalayalam ? 'വിദ്യാർഥി തിരഞ്ഞെടുക്കുക' : 'Select Student',
        ),
        backgroundColor: ColorPalette.primaryDark,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(SpacingScale.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message
              Text(
                isMalayalam
                    ? 'നിങ്ങളുടെ കുട്ടികളിൽ ഒരാൾ തിരഞ്ഞെടുക്കുക'
                    : 'Select one of your children to view their progress',
                style: TextStyle(fontSize: 14, color: ColorPalette.neutral600),
                textDirection: isMalayalam
                    ? TextDirection.rtl
                    : TextDirection.ltr,
              ),
              SizedBox(height: SpacingScale.lg),

              // Student list
              _buildStudentList(isMalayalam),

              SizedBox(height: SpacingScale.xxl),

              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.primaryDark,
                    padding: EdgeInsets.all(SpacingScale.md),
                  ),
                  onPressed: _selectedStudentId != null
                      ? () => _handleContinue(isMalayalam)
                      : null,
                  child: Text(
                    isMalayalam ? 'തുടരുക' : 'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentList(bool isMalayalam) {
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _students.length,
      separatorBuilder: (_, _) => SizedBox(height: SpacingScale.md),
      itemBuilder: (context, index) {
        final student = _students[index];
        final isSelected = _selectedStudentId == student['id'];

        return GestureDetector(
          onTap: () => setState(() => _selectedStudentId = student['id']),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? ColorPalette.primaryDark
                    : ColorPalette.neutral300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? ColorPalette.primaryDark.withValues(alpha: 0.05)
                  : Colors.transparent,
            ),
            padding: EdgeInsets.all(SpacingScale.md),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: student['avatarColor'],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      student['avatar'],
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: SpacingScale.lg),

                // Student info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['name'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ColorPalette.textPrimary,
                        ),
                        textDirection: isMalayalam
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                      ),
                      SizedBox(height: SpacingScale.xs),
                      Text(
                        student['batch'],
                        style: TextStyle(
                          fontSize: 12,
                          color: ColorPalette.neutral600,
                        ),
                        textDirection: isMalayalam
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                      ),
                      SizedBox(height: SpacingScale.sm),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: student['status'] == 'Active'
                                  ? ColorPalette.ratingExcellent
                                  : ColorPalette.neutral500,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: SpacingScale.sm),
                          Text(
                            student['lastUpdate'],
                            style: TextStyle(
                              fontSize: 10,
                              color: ColorPalette.neutral500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Selection indicator
                if (isSelected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: ColorPalette.primaryDark,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check, color: Colors.white, size: 16),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleContinue(bool isMalayalam) {
    if (_selectedStudentId == null) {
      return;
    }
    widget.onStudentSelected(_selectedStudentId!);
  }
}
