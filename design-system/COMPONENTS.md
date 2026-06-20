# Design System - Component Library Documentation

## Overview

This design system provides a comprehensive, reusable component library for the Alif School application. All components are designed with mobile-first responsive layouts and support both English and Malayalam.

## Component Categories

### 1. **Basic UI Components**

#### Buttons
- **PrimaryButton**: Main action button with semantic green color
- **SecondaryButton**: Secondary action button with outlined style
- **DangerButton**: Destructive actions (delete, remove)
- **Variants**: Solid, Outlined, Text
- **Sizes**: Small (32px), Medium (40px), Large (48px)
- **States**: Default, Hover, Active, Disabled, Loading

Example usage:
```dart
PrimaryButton(
  label: 'Save Activity',
  onPressed: () {},
  size: ButtonSize.medium,
)
```

#### Inputs
- **TextInput**: Single-line text field
- **TextArea**: Multi-line text input
- **Select**: Dropdown selection with search support
- **DatePicker**: Calendar-based date selection
- **TimePicker**: Time selection component
- **Features**: Label, placeholder, helper text, error states, icons

Example usage:
```dart
TextInput(
  label: 'Student Name',
  placeholder: 'Enter full name',
  onChanged: (value) {},
  required: true,
)
```

#### Cards & Containers
- **Card**: Container with elevation and shadow
- **Modal**: Dialog for critical interactions
- **Sheet**: Drawer/Bottom sheet for navigation
- **Responsive**: Adapt padding and sizing based on device

### 2. **Data Display Components**

#### Tables
- **Features**: Sorting, filtering, pagination, row selection, export
- **Responsive**: Stack on mobile, full table on desktop
- **Accessibility**: Keyboard navigation, screen reader support

#### Badges & Chips
- **Badge**: Status indicator or label (success, warning, error, info)
- **Chip**: Removable filter or item
- **Progress**: Linear or circular progress indicator

#### Lists & Avatars
- **Avatar**: User profile image or initials
- **List**: Scrollable list with separators
- **Expandable**: Collapsible list items

### 3. **Data Visualization**

#### Charts
- **LineChart**: Activity trends over time
- **BarChart**: Comparative data (student performance)
- **AreaChart**: Cumulative progress
- **PieChart**: Category distribution

#### Specialized Visualizations
- **HeatmapCalendar**: Activity contribution calendar (GitHub-style)
- **ProgressChart**: Individual student progress visualization
- **LeaderboardCard**: Ranking and competition display

### 4. **Domain-Specific Components**

#### Activity & Performance
- **ActivityRatingControl**: 1-5 star rating for activity performance
  - Colors: Red (1) → Orange (2) → Yellow (3) → Lime (4) → Green (5)
  - Interactive and read-only modes

- **BehaviorRatingControl**: 1-5 scale for student behavior
  - Customizable labels and descriptions

- **DailyLogForm**: Complete form for logging student activities
  - Fields: Student, Activity type, Duration, Ratings, Notes
  - Image/file attachments support

#### Student Management
- **StudentSelector**: Single or multi-select student chooser
  - Searchable by name, ID, or class
  - Shows profile pictures and status

- **StudentCard**: Display student profile summary
  - Basic info, achievements, current status

- **StudentProgressView**: Detailed progress tracking
  - Charts, badges, milestone celebrations

### 5. **Navigation Components**

#### Main Navigation
- **AdminNavigation**: Sidebar navigation (desktop), collapsible
  - Menu items: Dashboard, Students, Teachers, Batches, Activities, Reports, Settings

- **AppNavigation**: Bottom tab navigation (mobile), top bar (desktop)
  - Context-aware menu based on user role

#### Language Switcher
- **LanguageSwitcher**: Toggle between English and Malayalam
- **Location**: Top-right corner or settings menu
- **Persistence**: Saves user language preference

### 6. **Layout System**

#### Responsive Breakpoints
- **Mobile (xs)**: 0 - 480px, 4-column grid
- **Tablet (sm)**: 480px - 768px, 8-column grid
- **Desktop (md)**: 768px - 1024px, 12-column grid
- **Large (lg)**: 1024px - 1440px, 12-column grid
- **Wide (xl)**: 1440px+, 12-column grid

#### Predefined Layouts
- **AdminLayout**: Sidebar + content + top bar
- **AppLayout**: Top/bottom navigation + content
- **FormLayout**: Responsive form grid (1/2/3 columns)
- **CardGrid**: Responsive card layouts (1/2/3/4 columns)

### 7. **Utility Components**

- **Alert**: Status messages (success, warning, error, info)
- **Toast**: Temporary notifications
- **SkeletonLoader**: Loading placeholders
- **EmptyState**: No content messaging
- **Divider**: Visual separator
- **Spacer**: Responsive spacing

## Using Components

### Basic Import Pattern

```dart
import 'package:alif_design_system/components/buttons.dart';
import 'package:alif_design_system/components/inputs.dart';
import 'package:alif_design_system/layout/responsive.dart';
```

### Applying Spacing

```dart
// Use the spacing system
padding: EdgeInsets.all(spacing.base * 4), // 16px
margin: EdgeInsets.symmetric(vertical: spacing.base * 3),
```

### Responsive Design

```dart
// Use ResponsiveBuilder for responsive layouts
ResponsiveBuilder(
  mobile: (context) => MobileLayout(),
  tablet: (context) => TabletLayout(),
  desktop: (context) => DesktopLayout(),
)
```

### Theme Integration

All components automatically use the design system theme:
- Colors (primary, secondary, semantic colors)
- Typography (fonts, sizes, weights)
- Spacing (base unit system)
- Shadows & Elevations
- Border radius (rounded corners)

## Design Tokens

### Colors

**Primary**: Green (#2E7D32)
- Used for primary actions, success states, main navigation

**Secondary**: Gold (#FFA000)
- Used for highlights, secondary actions, achievements

**Semantic Colors**:
- Success: Green (#2E7D32)
- Warning: Orange (#F57C00)
- Error: Red (#D32F2F)
- Info: Blue (#1976D2)

**Neutrals**: Gray scale from #000 to #FFF

### Typography

**Fonts**:
- English: Inter, Roboto (sans-serif)
- Malayalam: Manjari, Poppins (supporting Malayalam)

**Scales**:
- Display: 40px (desktop), 28px (mobile)
- Heading1: 32px (desktop), 24px (mobile)
- Heading2: 28px (desktop), 20px (mobile)
- Body: 16px (desktop), 14px (mobile)
- Caption: 12px

### Spacing

**Base Unit**: 4px

- `spacing.base * 1` = 4px
- `spacing.base * 2` = 8px
- `spacing.base * 3` = 12px
- `spacing.base * 4` = 16px
- `spacing.base * 6` = 24px
- `spacing.base * 8` = 32px

## Responsive Best Practices

1. **Mobile-First Approach**: Design for mobile first, then enhance for larger screens
2. **Touch Targets**: Minimum 48px × 48px touch target sizes
3. **Safe Area**: Respect device safe areas (notches, home indicators)
4. **Readable Text**: Minimum 14px font size on mobile
5. **Adequate Spacing**: Use spacing system consistently
6. **Flexible Layouts**: Use responsive grid and flex layouts

## Component States

All interactive components support:
- **Default**: Normal, interactive state
- **Hover**: Mouse hover (desktop only)
- **Active**: Currently selected or active
- **Disabled**: Non-interactive state
- **Loading**: Async operation in progress
- **Error**: Error state with messaging
- **Success**: Confirmation/success state

## Accessibility

- **Semantic HTML/Flutter**: Proper widget hierarchy
- **Color Contrast**: WCAG AA compliant
- **Keyboard Navigation**: Full keyboard support
- **Screen Readers**: Proper labels and descriptions
- **Focus Indicators**: Clear focus states
- **Alt Text**: For images and icons

## Performance

- **Lazy Loading**: Components load on demand
- **Optimized Rendering**: Minimal rebuilds in Flutter
- **Efficient Animations**: Smooth 60fps transitions
- **Small Bundle**: Tree-shaking unused components

## Customization

Components accept parameters for customization:

```dart
// Example: Customize button colors
PrimaryButton(
  label: 'Custom Button',
  backgroundColor: Colors.purple,
  onPressed: () {},
)
```

## Integration Examples

### Activity Rating Form

```dart
Widget buildActivityLog() {
  return Column(
    children: [
      StudentSelector(
        onSelected: (student) => setStudent(student),
      ),
      TextInput(
        label: 'Activity',
        placeholder: 'What activity?',
      ),
      ActivityRatingControl(
        label: 'Performance',
        onChanged: (rating) => setRating(rating),
      ),
      DailyLogForm(
        onSubmit: submitLog,
      ),
    ],
  );
}
```

### Admin Dashboard

```dart
Widget buildAdminDashboard() {
  return AdminLayout(
    navigationItems: navigationItems,
    content: Column(
      children: [
        heading('Dashboard'),
        CardGrid(
          columns: responsiveColumns,
          children: [
            StatCard(),
            StudentStatsCard(),
            ActivityTrendCard(),
          ],
        ),
      ],
    ),
  );
}
```

## Contributing

When adding new components:
1. Follow the component specification in `components.ts`
2. Implement in appropriate file (buttons.dart, inputs.dart, etc.)
3. Support all specified sizes and variants
4. Include accessibility features
5. Test on mobile, tablet, and desktop
6. Add documentation and examples
7. Update this README

## Version

**Design System Version**: 1.0.0
**Last Updated**: June 18, 2026

---

For more information, see the [project README](../README.md) and [design system overview](./README.md).
