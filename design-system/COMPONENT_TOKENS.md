# Component Token Documentation

This document defines all reusable component tokens and their styles for the Alif Online Moral School application.

## Overview

All components follow these principles:
- **Color**: Use tokens from `ColorSystem` and `ColorPalette`
- **Typography**: Use preset styles from `TextStyles`
- **Spacing**: Use values from `Spacing` and `ComponentPadding`
- **Shadows**: Use tokens from `AlifTheme.shadows`
- **Border Radius**: Use tokens from `AlifTheme.borderRadius`
- **Transitions**: Use tokens from `AlifTheme.transitions`

---

## Button Component

### Variants

#### Primary Button
- **Use case**: Main actions, form submissions, primary CTAs
- **Background**: `ColorPalette.primaryDark` (#2E7D32)
- **Text**: `ColorPalette.textOnDark` (white)
- **Padding**: `ComponentPadding.button.medium` (16px horizontal, 12px vertical)
- **Border Radius**: `AlifTheme.borderRadius.component.button` (8px)
- **Shadow**: `AlifTheme.shadows.md` (hover state)
- **Font**: `TextStyles.buttonText`

**States:**
- Default: Primary color
- Hover: Darker shade (#1B5E20)
- Active: Darkest shade (#0D3E1F)
- Disabled: Gray with reduced opacity

#### Secondary Button
- **Use case**: Secondary actions, alternative paths
- **Background**: `ColorPalette.secondaryDark` (#FFA000)
- **Text**: `ColorPalette.textOnLight` (dark gray)
- **Padding**: Same as primary
- **Border Radius**: Same as primary
- **Shadow**: Same as primary

**States:**
- Default: Secondary color
- Hover: Darker shade (#E68900)
- Active: Even darker
- Disabled: Gray with reduced opacity

#### Outline Button
- **Use case**: Tertiary actions, cancellations
- **Background**: Transparent
- **Border**: 2px solid `ColorPalette.primaryDark`
- **Text**: `ColorPalette.primaryDark`
- **Padding**: Slightly increased for visual balance
- **Border Radius**: Same as primary

**States:**
- Default: Transparent with border
- Hover: Light background tint (#E8F5E9)
- Active: Darker background
- Disabled: Gray border

#### Text Button
- **Use case**: Minimal actions, inline actions
- **Background**: Transparent
- **Text**: `ColorPalette.primaryDark`
- **Padding**: No padding (text only)
- **Hover**: Underline or background tint

---

## Input Component

### Field Types

#### Text Input
- **Background**: `ColorPalette.backgroundDefault` (white)
- **Border**: 1px solid `ColorPalette.neutralLight`
- **Border Radius**: `AlifTheme.borderRadius.component.input` (8px)
- **Padding**: `ComponentPadding.input` (12px vertical, 16px horizontal)
- **Font**: `TextStyles.bodyText`

**States:**
- Default: Light gray border
- Focus: Green border (#2E7D32), subtle shadow
- Error: Red/orange border (#FF9800)
- Disabled: Gray background, disabled text

#### Phone Input
- **Same as text input**
- **Placeholder**: "+1 (555) 000-0000"
- **Validation**: Format checking for phone numbers

#### Password Input
- **Same as text input**
- **Icon**: Eye icon for show/hide password
- **Masked**: Dots instead of characters

#### Email Input
- **Same as text input**
- **Validation**: Email format validation
- **Placeholder**: "user@example.com"

### Decorations

**Label (above input)**
- **Font**: `TextStyles.label` (12px, 500 weight)
- **Color**: `ColorPalette.textOnLight`
- **Margin**: 8px below label (sm)
- **Mandatory indicator**: Red asterisk if required

**Helper Text (below input)**
- **Font**: `Typography.label.small` (11px)
- **Color**: `ColorPalette.neutralMedium`
- **Margin**: 4px above text (xs)

**Error Message**
- **Font**: Same as helper text
- **Color**: `ColorPalette.ratingNeedsImprovement` (#FF9800)
- **Icon**: Error icon (optional)

---

## Card Component

### Base Card
- **Background**: `ColorPalette.backgroundDefault` (white)
- **Border**: 1px solid `ColorPalette.neutralLighter` (optional)
- **Border Radius**: `AlifTheme.borderRadius.component.card` (12px)
- **Padding**: `ComponentPadding.card.medium` (16px)
- **Shadow**: `AlifTheme.shadows.base` or `AlifTheme.shadows.elevation.level1`
- **Transition**: Smooth transition on hover

**Variants:**

#### Elevated Card
- **Shadow**: `AlifTheme.shadows.md`
- **Hover**: `AlifTheme.shadows.lg`
- **Use case**: Important content, clickable cards

#### Outlined Card
- **Border**: 2px solid `ColorPalette.neutralLighter`
- **Shadow**: None
- **Hover**: Background tint
- **Use case**: Grouped items, lists

#### Filled Card
- **Background**: `ColorPalette.neutralLightest` (#FAFAFA)
- **Border**: None
- **Shadow**: None
- **Use case**: Subtle sections, secondary content

### Card Sections

**Header**
- **Padding**: `ComponentPadding.card.medium`
- **Font**: `TextStyles.cardTitle`
- **Icon**: Optional action button (top-right)

**Content**
- **Padding**: `ComponentPadding.card.medium`
- **Font**: `TextStyles.bodyText`
- **Gap between items**: `Gap.list.normal` (12px)

**Footer**
- **Padding**: `ComponentPadding.card.medium`
- **Border top**: 1px solid `ColorPalette.neutralLighter`
- **Action buttons**: Right-aligned

---

## Badge Component

### Variants

#### Success Badge
- **Background**: `ColorPalette.ratingExcellent` (#4CAF50)
- **Text**: White
- **Border Radius**: `AlifTheme.borderRadius.component.badge` (4px)
- **Padding**: 4px 8px
- **Font**: `Typography.label.small`

#### Warning Badge
- **Background**: `ColorPalette.ratingSatisfactory` (#FFC107)
- **Text**: Dark text
- **Same styling as success**

#### Error Badge
- **Background**: `ColorPalette.ratingNeedsImprovement` (#FF9800)
- **Text**: White
- **Same styling as success**

#### Info Badge
- **Background**: `ColorPalette.info` (#2196F3)
- **Text**: White
- **Same styling as success**

#### Neutral Badge
- **Background**: `ColorPalette.neutralLight` (#BDBDBD)
- **Text**: `ColorPalette.textOnLight`
- **Same styling as success**

---

## Table Component

### Row Styling
- **Height**: 48px default
- **Padding**: 12px per cell
- **Border bottom**: 1px solid `ColorPalette.neutralLighter`
- **Hover**: Background `ColorPalette.primaryLightest`

### Header Styling
- **Background**: `ColorPalette.neutralLightest`
- **Font**: `TextStyles.label` (bold)
- **Color**: `ColorPalette.textOnLight`
- **Padding**: 12px (more generous)
- **Border bottom**: 2px solid `ColorPalette.neutralLight`

### Cell Styling
- **Font**: `TextStyles.bodyText`
- **Color**: `ColorPalette.textOnLight`
- **Alignment**: Left by default, right for numbers
- **Overflow**: Truncate with ellipsis

### Alternating Rows (Optional)
- **Even rows**: Default background
- **Odd rows**: `ColorPalette.backgroundPaper` (#F5F5F5)

---

## Modal/Dialog Component

### Container
- **Background**: White
- **Border Radius**: `AlifTheme.borderRadius.component.modal` (12px)
- **Shadow**: `AlifTheme.shadows.elevation.level4`
- **Width**: 90vw (mobile), 600px (desktop)
- **Max Height**: 90vh

### Header
- **Padding**: `ComponentPadding.modal` (20px)
- **Font**: `TextStyles.sectionTitle`
- **Close Button**: Top-right corner
- **Border bottom**: 1px solid `ColorPalette.neutralLighter`

### Body
- **Padding**: `ComponentPadding.modal` (20px)
- **Gap between items**: `Gap.column.normal` (16px)
- **Max height**: Scrollable if content exceeds space
- **Font**: `TextStyles.bodyText`

### Footer
- **Padding**: `ComponentPadding.modal` (20px)
- **Border top**: 1px solid `ColorPalette.neutralLighter`
- **Button alignment**: Right-aligned
- **Gap between buttons**: 12px

### Overlay
- **Background**: `ColorPalette.background.overlay` (rgba 0,0,0,0.5)
- **Transition**: Fade in/out 300ms

---

## Date Picker Component

### Calendar Grid
- **Cell size**: 40px x 40px
- **Gap**: 4px
- **Background**: White
- **Border**: 1px solid `ColorPalette.neutralLight`
- **Border Radius**: 8px

### Day Cells
- **Default**: White text on transparent
- **Selected**: White text on `ColorPalette.primaryDark`
- **Today**: Border around date
- **Outside month**: Gray text
- **Hover**: Light background tint
- **Disabled**: Gray text, no hover

### Header Controls
- **Font**: `TextStyles.label`
- **Prev/Next buttons**: Icon buttons
- **Month/Year display**: Centered, semibold

---

## Rating Selector Component

### Rating Options
- **Display**: Horizontal row or vertical stack
- **Options**: 4 choices (Excellent, Satisfactory, Needs Improvement, Not Done)
- **Gap**: 12px between options

### Each Rating Option
- **Type**: Radio button with label
- **Default**: Unselected gray circle
- **Selected**: Filled circle with rating color
- **Hover**: Light background
- **Label**: Right of circle, `TextStyles.bodyText`

### Color Mapping
- **Excellent**: `ColorPalette.ratingExcellent` (#4CAF50)
- **Satisfactory**: `ColorPalette.ratingSatisfactory` (#FFC107)
- **Needs Improvement**: `ColorPalette.ratingNeedsImprovement` (#FF9800)
- **Not Done**: `ColorPalette.ratingNotDone` (#9E9E9E)

---

## Quantity Input Component

### Layout
- **Default**: Number input with +/- buttons
- **Alternative**: Stepper (minus button, number, plus button)

### Controls
- **Button size**: 32px x 32px
- **Button icons**: +/- symbols or chevrons
- **Button color**: `ColorPalette.primaryDark`
- **Button disabled**: Gray when at min/max

### Input Field
- **Width**: 60px (sufficient for typical quantities)
- **Text alignment**: Center
- **Font**: `TextStyles.label` (mono-spaced for numbers)
- **Validation**: Only numeric input

### Unit Label
- **Font**: `TextStyles.label`
- **Color**: `ColorPalette.textSecondaryOnLight`
- **Position**: Right of input (e.g., "pages", "minutes")
- **Margin**: 8px left

### Min/Max Constraints
- **Min**: Typically 0
- **Max**: Activity-specific (e.g., max pages to read)
- **Validation message**: Show if out of range

---

## Progress Summary Card

### Layout
- Vertical card with:
  - Date display (top)
  - Total marks (large, centered)
  - Completion percentage (visual bar)
  - Rank display (optional)

### Components

**Date**
- **Font**: `TextStyles.label`
- **Color**: `ColorPalette.textSecondaryOnLight`
- **Format**: "June 18, 2026"

**Total Marks**
- **Font**: `Typography.display.small` (36px, bold)
- **Color**: `ColorPalette.primaryDark`
- **Format**: "85/100"

**Completion Bar**
- **Background**: `ColorPalette.neutralLighter`
- **Fill**: `ColorPalette.ratingExcellent` or gradient
- **Height**: 8px
- **Border Radius**: 4px
- **Percentage text**: Right of bar (e.g., "85%")

**Rank Display** (Optional)
- **Font**: `TextStyles.label`
- **Text**: "Rank: 3rd of 42"
- **Color**: `ColorPalette.primaryDark`

---

## Responsive Behavior

### Mobile (< 600px)
- Button padding: Larger for touch targets (48px minimum height)
- Input padding: Increased for easier typing
- Modal width: 100% with margins
- Card margin: Reduced to fit screen
- Spacing: Use `lg` as default instead of `xl`

### Tablet (600px - 900px)
- Card width: 90% of screen
- Modal width: 600px
- Spacing: Use `xxl` for sections
- Padding: Standard `lg`

### Desktop (> 900px)
- Card width: Fixed or maxed
- Modal width: Fixed 600px
- Spacing: Use `xxxl` for major sections
- Padding: Standard `lg` to `xl`

---

## Color Combinations

### Recommended Color Pairs

**Primary on Light Background**
- Text: `ColorPalette.textOnLight`
- Background: `ColorPalette.backgroundDefault`
- Accent: `ColorPalette.primaryDark`

**Primary on Primary Background**
- Text: `ColorPalette.textOnDark`
- Background: `ColorPalette.primaryDark`
- Accent: `ColorPalette.secondaryDark`

**Success Indicator**
- Background: `ColorPalette.ratingExcellent` (#4CAF50)
- Text: White
- Border: None or darker shade

**Warning Indicator**
- Background: `ColorPalette.ratingSatisfactory` (#FFC107)
- Text: `ColorPalette.textOnLight`
- Border: None

**Error Indicator**
- Background: `ColorPalette.ratingNeedsImprovement` (#FF9800)
- Text: White
- Border: None

---

## Accessibility Notes

1. **Color Contrast**: Ensure 4.5:1 ratio for text
2. **Button Size**: Minimum 44x44px touch targets (mobile)
3. **Focus States**: Visible focus ring on all interactive elements
4. **Icons**: Always pair with text labels
5. **Form Labels**: Always visible and associated with inputs
6. **Error Messages**: Always announce clearly
7. **Bilingual**: Support both English and Malayalam fonts

---

## Implementation Checklist

- [ ] Colors: All use `ColorPalette` constants
- [ ] Typography: All use `TextStyles` presets
- [ ] Spacing: All use `Spacing` values
- [ ] Shadows: All use `AlifTheme.shadows`
- [ ] Border Radius: All use `AlifTheme.borderRadius`
- [ ] Transitions: All use `AlifTheme.transitions`
- [ ] States: Hover, focus, active, disabled defined
- [ ] Responsive: Mobile, tablet, desktop rules set
- [ ] Accessibility: WCAG 2.1 AA compliant
- [ ] Documentation: Each component documented

---

**Last Updated**: June 18, 2026  
**Phase**: 1 - Foundation  
**Status**: Complete
