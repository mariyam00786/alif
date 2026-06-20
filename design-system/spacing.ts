/**
 * Alif Online Moral School - Spacing System
 * 
 * Consistent spacing scale based on 4px base unit
 * Ensures alignment and visual harmony across the application
 * 
 * SCALE (all values in pixels):
 * xs (4px): Icon padding, tight spacing
 * sm (8px): Small gaps, compact spacing
 * md (12px): Standard padding, normal gaps
 * lg (16px): Default spacing, button padding
 * xl (20px): Comfortable spacing, section padding
 * xxl (24px): Generous spacing, large sections
 * xxxl (32px): Extra spacing, major sections
 * 
 * USAGE GUIDELINES:
 * - Padding: Use for internal spacing within components
 * - Margin/Gap: Use for spacing between elements
 * - Outer spacing: Use lg (16px) as default
 * - Inner padding: Use md (12px) as default
 * 
 * BREAKPOINTS:
 * - Mobile: 320px - 599px
 * - Tablet: 600px - 899px
 * - Desktop: 900px+
 */

export const Spacing = {
  // Base unit: 4px
  xs: '4px',    // 4px
  sm: '8px',    // 8px
  md: '12px',   // 12px
  lg: '16px',   // 16px
  xl: '20px',   // 20px
  xxl: '24px',  // 24px
  xxxl: '32px', // 32px
  
  // Extended scale
  0: '0px',
  1: '4px',
  2: '8px',
  3: '12px',
  4: '16px',
  5: '20px',
  6: '24px',
  8: '32px',
  10: '40px',
  12: '48px',
  16: '64px',
  20: '80px',
  24: '96px',
  32: '128px',
} as const;

/**
 * Component-level padding presets
 */
export const ComponentPadding = {
  // Button padding
  button: {
    small: { x: Spacing.md, y: Spacing.sm },     // 12px, 8px
    medium: { x: Spacing.lg, y: Spacing.md },    // 16px, 12px
    large: { x: Spacing.xl, y: Spacing.lg },     // 20px, 16px
  },

  // Card padding
  card: {
    small: Spacing.md,  // 12px
    medium: Spacing.lg, // 16px
    large: Spacing.xl,  // 20px
  },

  // Section padding
  section: {
    mobile: Spacing.lg,  // 16px
    tablet: Spacing.xxl, // 24px
    desktop: Spacing.xxxl, // 32px
  },

  // Input field padding
  input: {
    x: Spacing.lg,  // 16px
    y: Spacing.md,  // 12px
  },

  // Modal padding
  modal: Spacing.xl, // 20px
} as const;

/**
 * Gap/margin presets for layouts
 */
export const Gap = {
  // List/Grid gaps
  list: {
    compact: Spacing.sm,   // 8px
    normal: Spacing.md,    // 12px
    comfortable: Spacing.lg, // 16px
  },

  // Row gaps
  row: {
    tight: Spacing.sm,     // 8px
    normal: Spacing.md,    // 12px
    relaxed: Spacing.lg,   // 16px
  },

  // Column gaps
  column: {
    tight: Spacing.md,     // 12px
    normal: Spacing.lg,    // 16px
    relaxed: Spacing.xxl,  // 24px
  },
} as const;

/**
 * Common Spacing Patterns
 * =======================
 * 
 * BUTTONS & CONTROLS:
 * - Small button: padding 8px 12px (sm vertical, md horizontal)
 * - Medium button: padding 12px 16px (md vertical, lg horizontal)
 * - Large button: padding 16px 20px (lg vertical, xl horizontal)
 * 
 * CARDS & CONTAINERS:
 * - Small card: 12px padding (md)
 * - Medium card: 16px padding (lg)
 * - Large card: 20px padding (xl)
 * - Card gaps: 12px between items (md)
 * 
 * FORMS & INPUTS:
 * - Input padding: 12px vertical, 16px horizontal (md/lg)
 * - Form gaps: 16px between inputs (lg)
 * - Label margin: 8px bottom (sm)
 * - Help text margin: 4px top (xs)
 * 
 * LAYOUT & SECTIONS:
 * - Mobile section: 16px padding (lg)
 * - Tablet section: 24px padding (xxl)
 * - Desktop section: 32px padding (xxxl)
 * - Section gaps: 24px (xxl)
 * 
 * LISTS & GRIDS:
 * - List item gap: 8px (compact), 12px (normal), 16px (comfortable)
 * - Grid gap: 16px (desktop), 12px (mobile)
 * - Item spacing: 4px-8px tight, 12px normal, 16px-20px relaxed
 * 
 * MODALS & DIALOGS:
 * - Modal padding: 20px (xl)
 * - Modal gap between elements: 16px (lg)
 * - Close button positioning: 16px from edge (lg)
 */
