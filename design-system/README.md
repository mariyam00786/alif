# Alif Online Moral School - Design System

## Overview

This design system provides a comprehensive, themeable set of design tokens for the Alif Online Moral School application. All colors, typography, spacing, and component styles are centrally managed here.

## File Structure

- **colors.ts** - Color palette with semantic colors and utility functions
- **typography.ts** - Font families, text styles, and typographic scales
- **spacing.ts** - Spacing scale and component padding presets
- **theme.ts** - Master theme combining all design tokens
- **index.ts** - Unified exports

## Core Design Tokens

### Colors

The color system is based on Islamic green (#2E7D32) as primary and gold (#FFA000) as secondary.

```typescript
import { ColorSystem } from '@alif-school/design-system';

// Access primary colors
const primaryColor = ColorSystem.primary[700];    // #2E7D32
const secondaryColor = ColorSystem.secondary[800]; // #FFA000

// Access rating colors
const excellent = ColorSystem.rating.excellent;      // #4CAF50 (Green)
const satisfactory = ColorSystem.rating.satisfactory; // #FFC107 (Yellow)
const needsImprovement = ColorSystem.rating.needsImprovement; // #FF9800 (Orange)
const notDone = ColorSystem.rating.notDone;          // #9E9E9E (Gray)
```

### Typography

Supports both English and Malayalam with Material Design 3 scales.

```typescript
import { Typography, TextStyles } from '@alif-school/design-system';

// Use preset styles
const heading = TextStyles.pageTitle;
const malayalamHeading = TextStyles.malayalamTitle;

// Or access raw typography values
const fontSize = Typography.headline.large.fontSize;
```

### Spacing

4px-based spacing scale for consistency.

```typescript
import { Spacing, ComponentPadding } from '@alif-school/design-system';

// Use tokens
const padding = Spacing.lg;        // 16px
const buttonPadding = ComponentPadding.button.medium;

// Includes utility presets
const cardPadding = ComponentPadding.card.medium;
const inputPadding = ComponentPadding.input;
```

### Complete Theme

```typescript
import { AlifTheme } from '@alif-school/design-system';

// Access all design tokens
const primaryColor = AlifTheme.colors.primary[700];
const buttonStyle = AlifTheme.components.button.primary;
const shadow = AlifTheme.shadows.elevation.level2;
const radius = AlifTheme.borderRadius.component.button;
```

## Component Styles

Pre-configured component variants:

- **Button**: primary, secondary, outline, text
- **Card**: with background, border, shadow, hover states
- **Input**: with focus, disabled, error, success states
- **Badge**: success, warning, error, info, default
- **Alert**: success, warning, error, info

## Usage Guidelines

### In React/Web

```typescript
import { AlifTheme } from '@alif-school/design-system';

const Button = styled.button`
  background-color: ${AlifTheme.colors.primary[700]};
  color: ${AlifTheme.colors.text.light};
  padding: ${AlifTheme.componentPadding.button.medium.x} 
           ${AlifTheme.componentPadding.button.medium.y};
  border-radius: ${AlifTheme.borderRadius.component.button};
  transition: background-color ${AlifTheme.transitions.duration.short}
              ${AlifTheme.transitions.timing.easeInOut};
  
  &:hover {
    background-color: ${AlifTheme.colors.primary[800]};
  }
`;
```

### In Flutter

Map TypeScript design tokens to Flutter equivalents:

```dart
final AlifColors = {
  'primary': Color(0xFF2E7D32),
  'secondary': Color(0xFFFFA000),
  'excellent': Color(0xFF4CAF50),
  'satisfactory': Color(0xFFFFC107),
  'needsImprovement': Color(0xFFFF9800),
  'notDone': Color(0xFF9E9E9E),
};
```

## Extending the Design System

To add new colors, typography styles, or components:

1. Add to appropriate file (colors.ts, typography.ts, etc.)
2. Export from theme.ts
3. Update index.ts
4. Document in this README

## Accessibility

- All color combinations meet WCAG AA contrast requirements
- Typography scales are readable at specified sizes
- Interactive elements have minimum 44x44px touch targets (via spacing system)

## Localization Support

The system supports:
- **English**: Poppins, Roboto
- **Malayalam**: Noto Sans Malayalam, Manjari
- **Mono/Code**: Courier New

## Related Documentation

- 📄 **[Component Tokens](./COMPONENT_TOKENS.md)** - Detailed specifications for all reusable components ⭐
- 🎨 [Phase 1 Foundation](../docs/PHASE_1_FOUNDATION.md) - Design system branding rules
- 🚀 [Phase 1 Checklist](../docs/PHASE_1_IMPLEMENTATION_CHECKLIST.md) - Implementation tasks

## Complete Component Reference

All component specifications (Button, Input, Card, Badge, Table, Modal, Date Picker, Rating Selector, Quantity Input, Progress Summary) are documented in [COMPONENT_TOKENS.md](./COMPONENT_TOKENS.md) with:
- ✅ Visual specs (colors, sizes, spacing)
- ✅ Typography requirements
- ✅ State behaviors (hover, focus, disabled, error)
- ✅ Responsive adjustments (mobile/tablet/desktop)
- ✅ Accessibility notes
- ✅ Color combinations
- ✅ Implementation examples

## Validation Checklist

- ✅ All colors use `ColorPalette` or `ColorSystem`
- ✅ All typography uses `TextStyles` or `Typography`
- ✅ All spacing uses `Spacing` values
- ✅ All shadows use `AlifTheme.shadows`
- ✅ All border radius uses `AlifTheme.borderRadius`
- ✅ All transitions use `AlifTheme.transitions`
- ✅ All components have hover, focus, active, disabled states
- ✅ Responsive design tested (320px, 768px, 1024px)
- ✅ Bilingual support verified (English/Malayalam)
- ✅ WCAG AA accessibility verified
- ✅ No hardcoded color, size, or spacing values
- ✅ Components documented and reviewed

## References

- Material Design 3: https://m3.material.io/
- Islamic Green: #2E7D32
- Gold Accent: #FFA000
- WCAG Accessibility: https://www.w3.org/WAI/WCAG21/quickref/

---

**Last Updated**: June 18, 2026  
**Version**: 1.0.0 (Phase 1 - Locked)  
**Status**: ✅ Complete and ready for implementation
