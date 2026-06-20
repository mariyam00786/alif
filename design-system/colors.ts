/**
 * Alif Online Moral School - Color System
 * 
 * This is the single source of truth for all application colors.
 * Theme colors are derived from the Alif school branding (Green & Gold)
 */

export const ColorSystem = {
  // Primary Colors
  primary: {
    50: '#E8F5E9',   // Lightest
    100: '#C8E6C9',
    200: '#A5D6A7',
    300: '#81C784',
    400: '#66BB6A',
    500: '#4CAF50',  // Main Green
    600: '#43A047',
    700: '#388E3C',
    800: '#2E7D32',  // Dark Green (Primary Dark)
    900: '#1B5E20',  // Darkest
  },

  // Secondary Colors (Gold/Orange)
  secondary: {
    50: '#FFF3E0',
    100: '#FFE0B2',
    200: '#FFCC80',
    300: '#FFB74D',
    400: '#FFA726',
    500: '#FFA000',  // Gold (Main Secondary)
    600: '#F57C00',
    700: '#E65100',
    800: '#F57F17',  // Dark Gold
    900: '#BF360C',
  },

  // Semantic Colors
  success: '#2E7D32',
  warning: '#FFC107',      // Satisfactory
  error: '#FF9800',        // Needs Improvement / Orange
  info: '#2196F3',
  
  // Activity Rating Colors
  rating: {
    excellent: '#2E7D32',     // Green - Excellent
    satisfactory: '#FFC107',  // Yellow - Satisfactory
    needsImprovement: '#FF9800', // Orange - Needs Improvement
    notDone: '#9E9E9E',       // Gray - Not Done
  },

  // Neutral Colors
  neutral: {
    50: '#FAFAFA',
    100: '#F5F5F5',
    200: '#EEEEEE',
    300: '#E0E0E0',
    400: '#BDBDBD',
    500: '#9E9E9E',
    600: '#757575',
    700: '#616161',
    800: '#424242',
    900: '#212121',
  },

  // Background
  background: {
    light: '#FAFAFA',
    default: '#FFFFFF',
    paper: '#F5F5F5',
    overlay: 'rgba(0, 0, 0, 0.5)',
  },

  // Text Colors
  text: {
    primary: '#212121',      // Dark text on light
    secondary: '#757575',    // Secondary text
    tertiary: '#9E9E9E',     // Tertiary text
    light: '#FFFFFF',        // Light text on dark
    lightSecondary: 'rgba(255, 255, 255, 0.87)',
    disabled: '#BDBDBD',
  },

  // Brand Colors (Islamic Green Theme)
  brand: {
    primary: '#2E7D32',      // Deep green
    accent: '#FFA000',       // Gold
    light: '#E8F5E9',        // Light green background
    dark: '#1B5E20',         // Very dark green
  },
} as const;

/**
 * Utility function to get rating color based on rating type
 */
export const getRatingColor = (rating: 'excellent' | 'satisfactory' | 'needsImprovement' | 'notDone'): string => {
  return ColorSystem.rating[rating];
};

/**
 * Utility function to get contrasting text color for a background
 */
export const getContrastTextColor = (backgroundColor: string): string => {
  // This would ideally calculate luminance, but for simplicity:
  const darkBgs = ['#2E7D32', '#1B5E20', '#212121', '#424242'];
  return darkBgs.includes(backgroundColor) ? ColorSystem.text.light : ColorSystem.text.primary;
};

/**
 * Locked Color Palette - Master reference for all colors
 * This palette is frozen for Phase 1 and should not change without design review
 * 
 * Primary Brand Color: Deep Islamic Green (#2E7D32)
 * Secondary Accent: Gold (#FFA000)
 * Rating System: Green (Excellent), Yellow (Satisfactory), Orange (Needs Improvement), Gray (Not Done)
 */
export const ColorPalette = {
  // Primary Brand Colors
  primaryDark: '#2E7D32',      // Primary dark - headings, buttons, main UI
  primaryLight: '#4CAF50',     // Primary light - status, accents
  primaryLightest: '#E8F5E9',  // Primary lightest - backgrounds, states

  // Secondary Accent Colors
  secondaryDark: '#FFA000',    // Secondary dark - important accents
  secondaryLight: '#FFB74D',   // Secondary light - hover states
  secondaryLightest: '#FFF3E0', // Secondary lightest - backgrounds

  // Rating System Colors
  ratingExcellent: '#4CAF50',           // Green - Excellent/Best performance
  ratingSatisfactory: '#FFC107',        // Yellow - Satisfactory/Good performance
  ratingNeedsImprovement: '#FF9800',    // Orange - Needs Improvement/Below expectations
  ratingNotDone: '#9E9E9E',             // Gray - Not Done/Incomplete

  // Neutral Colors
  neutralDarkest: '#212121',   // Text on light backgrounds
  neutralDark: '#616161',      // Secondary text
  neutralMedium: '#9E9E9E',    // Tertiary text, disabled
  neutralLight: '#BDBDBD',     // Subtle borders
  neutralLighter: '#EEEEEE',   // Light borders
  neutralLightest: '#FAFAFA',  // Light backgrounds

  // Semantic Colors
  success: '#4CAF50',          // Success states (same as excellent)
  warning: '#FFC107',          // Warning states (same as satisfactory)
  error: '#FF9800',            // Error states (same as needs improvement)
  info: '#2196F3',             // Information/informational states

  // Backgrounds
  backgroundLight: '#FAFAFA',  // Light mode background
  backgroundDefault: '#FFFFFF', // Default/card background
  backgroundPaper: '#F5F5F5',  // Paper/surface background

  // Text Colors
  textOnLight: '#212121',      // Primary text on light backgrounds
  textSecondaryOnLight: '#616161', // Secondary text on light
  textOnDark: '#FFFFFF',       // Primary text on dark backgrounds
  textSecondaryOnDark: 'rgba(255, 255, 255, 0.87)', // Secondary text on dark
  textDisabled: '#BDBDBD',     // Disabled text
} as const;

/**
 * Color Usage Documentation
 * ===========================
 * 
 * PRIMARY DARK (#2E7D32) - Use for:
 * - Page headers and section titles
 * - Primary action buttons
 * - Active navigation items
 * - Primary form controls
 * - Important UI elements
 * 
 * SECONDARY DARK (#FFA000) - Use for:
 * - Secondary action buttons
 * - Badge highlights
 * - Achievement/reward indicators
 * - Call-to-action accents
 * - Important statistics
 * 
 * RATING COLORS - Use for:
 * - Excellent (#4CAF50): Top performance, badges, success states
 * - Satisfactory (#FFC107): Good/moderate performance, warnings
 * - Needs Improvement (#FF9800): Below target, error/warning states
 * - Not Done (#9E9E9E): Incomplete, disabled states
 * 
 * NEUTRAL COLORS - Use for:
 * - Text: Use neutralDarkest for body text on light, textOnDark for dark
 * - Borders: Use neutralLight or neutralLighter for subtle divisions
 * - Backgrounds: Use neutralLightest or neutralLight for sections
 * - Disabled: Use neutralMedium for disabled form elements
 * 
 * BACKGROUNDS - Use for:
 * - Page: backgroundLight
 * - Cards/Containers: backgroundDefault or backgroundPaper
 * - Overlays: Use with appropriate opacity (0.5-0.7)
 */
