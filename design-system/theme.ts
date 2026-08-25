/**
 * Alif Online Moral School - Complete Design System Theme
 * 
 * Master theme file that combines colors, typography, spacing, and component styles
 * Provides a consistent design language across the entire application
 */

import { ColorSystem } from './colors';
import { Typography, TextStyles } from './typography';
import { Spacing, ComponentPadding, Gap } from './spacing';

export const AlifTheme = {
  // Core Design Tokens
  colors: ColorSystem,
  typography: Typography,
  spacing: Spacing,
  componentPadding: ComponentPadding,
  gap: Gap,

  // Shadow System
  shadows: {
    none: 'none',
    sm: '0 1px 2px 0 rgba(0, 0, 0, 0.05)',
    base: '0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06)',
    md: '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)',
    lg: '0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)',
    xl: '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)',
    elevation: {
      level1: '0 1px 3px rgba(0, 0, 0, 0.12), 0 1px 2px rgba(0, 0, 0, 0.24)',
      level2: '0 3px 6px rgba(0, 0, 0, 0.15), 0 2px 4px rgba(0, 0, 0, 0.12)',
      level3: '0 10px 20px rgba(0, 0, 0, 0.15), 0 3px 6px rgba(0, 0, 0, 0.10)',
      level4: '0 15px 25px rgba(0, 0, 0, 0.15), 0 5px 10px rgba(0, 0, 0, 0.05)',
    },
  },

  // Border Radius System
  borderRadius: {
    none: '0px',
    xs: '2px',
    sm: '4px',
    md: '8px',
    lg: '12px',
    xl: '16px',
    full: '9999px',
    
    component: {
      button: '8px',
      card: '12px',
      input: '8px',
      avatar: '50%',
      badge: '4px',
      modal: '12px',
    },
  },

  // Transitions & Animations
  transitions: {
    duration: {
      shortest: '150ms',
      shorter: '200ms',
      short: '250ms',
      standard: '300ms',
      complex: '375ms',
      enteringScreen: '225ms',
      leavingScreen: '195ms',
    },
    timing: {
      easeInOut: 'cubic-bezier(0.4, 0, 0.2, 1)',
      easeOut: 'cubic-bezier(0.0, 0, 0.2, 1)',
      easeIn: 'cubic-bezier(0.4, 0, 1, 1)',
      linear: 'linear',
      sharp: 'cubic-bezier(0.4, 0, 0.6, 1)',
    },
  },

  // Component Variants
  components: {
    button: {
      primary: {
        background: ColorSystem.primary[700],
        color: ColorSystem.text.light,
        hover: ColorSystem.primary[800],
        active: ColorSystem.primary[900],
        disabled: ColorSystem.neutral[400],
      },
      secondary: {
        background: ColorSystem.secondary[600],
        color: ColorSystem.text.light,
        hover: ColorSystem.secondary[700],
        active: ColorSystem.secondary[800],
        disabled: ColorSystem.neutral[400],
      },
      outline: {
        background: 'transparent',
        color: ColorSystem.primary[700],
        border: ColorSystem.primary[700],
        hover: ColorSystem.primary[50],
        disabled: ColorSystem.neutral[400],
      },
      text: {
        background: 'transparent',
        color: ColorSystem.primary[700],
        hover: ColorSystem.primary[50],
        disabled: ColorSystem.neutral[400],
      },
    },

    card: {
      background: ColorSystem.background.paper,
      border: ColorSystem.neutral[200],
      shadow: 'elevation.level1',
      hover: ColorSystem.neutral[100],
    },

    input: {
      background: ColorSystem.background.default,
      border: ColorSystem.neutral[300],
      text: ColorSystem.text.primary,
      placeholder: ColorSystem.text.tertiary,
      focus: {
        border: ColorSystem.primary[700],
        shadow: `0 0 0 3px ${ColorSystem.primary[100]}`,
      },
      disabled: {
        background: ColorSystem.neutral[100],
        border: ColorSystem.neutral[300],
        text: ColorSystem.text.disabled,
      },
      error: {
        border: ColorSystem.error,
        shadow: `0 0 0 3px ${ColorSystem.error}33`,
      },
      success: {
        border: ColorSystem.success,
        shadow: `0 0 0 3px ${ColorSystem.success}33`,
      },
    },

    badge: {
      success: {
        background: ColorSystem.rating.excellent,
        color: ColorSystem.text.light,
      },
      warning: {
        background: ColorSystem.rating.satisfactory,
        color: ColorSystem.text.primary,
      },
      error: {
        background: ColorSystem.rating.needsImprovement,
        color: ColorSystem.text.light,
      },
      info: {
        background: ColorSystem.info,
        color: ColorSystem.text.light,
      },
      default: {
        background: ColorSystem.neutral[200],
        color: ColorSystem.text.primary,
      },
    },

    alert: {
      success: {
        background: ColorSystem.success,
        border: ColorSystem.success,
        text: ColorSystem.text.light,
      },
      warning: {
        background: ColorSystem.warning,
        border: ColorSystem.warning,
        text: ColorSystem.text.primary,
      },
      error: {
        background: ColorSystem.error,
        border: ColorSystem.error,
        text: ColorSystem.text.light,
      },
      info: {
        background: ColorSystem.info,
        border: ColorSystem.info,
        text: ColorSystem.text.light,
      },
    },
  },

  // Responsive Breakpoints
  breakpoints: {
    xs: '0px',
    sm: '640px',
    md: '768px',
    lg: '1024px',
    xl: '1280px',
    '2xl': '1536px',
  },

  // Z-Index Scale
  zIndex: {
    hide: -1,
    auto: 'auto',
    base: 0,
    docked: 10,
    fixed: 100,
    modalBackdrop: 1300,
    modal: 1400,
    popover: 1500,
    tooltip: 1600,
    notification: 1700,
  },
} as const;

// Type exports for TypeScript
export type AlifThemeType = typeof AlifTheme;
export type ColorSystemType = typeof ColorSystem;
export type TypographyType = typeof Typography;
