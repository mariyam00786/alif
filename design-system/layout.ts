/**
 * Layout System
 * Defines responsive layouts, grid systems, and spacing patterns
 */

import { spacing } from './spacing';

// Responsive grid system
export const gridSystem = {
  // Mobile-first approach
  mobile: {
    columns: 4,
    gutter: spacing.base * 4, // 16px
    margin: spacing.base * 3, // 12px
    maxWidth: 480,
  },
  tablet: {
    columns: 8,
    gutter: spacing.base * 4, // 16px
    margin: spacing.base * 6, // 24px
    maxWidth: 768,
  },
  desktop: {
    columns: 12,
    gutter: spacing.base * 6, // 24px
    margin: spacing.base * 8, // 32px
    maxWidth: 1440,
  },
  wide: {
    columns: 12,
    gutter: spacing.base * 8, // 32px
    margin: spacing.base * 10, // 40px
    maxWidth: 1920,
  },
};

// Layout patterns for different user roles
export const layoutPatterns = {
  // Admin panel - two-column layout with sidebar
  adminLayout: {
    type: 'sidebar',
    sidebar: {
      width: { mobile: 280, tablet: 280, desktop: 300 },
      collapsible: true,
      sticky: true,
    },
    topBar: {
      height: 64,
      sticky: true,
      components: ['logo', 'search', 'notifications', 'profile'],
    },
    content: {
      padding: { mobile: spacing.base * 3, tablet: spacing.base * 4, desktop: spacing.base * 6 },
      maxWidth: 1200,
    },
    footer: {
      height: 'auto',
      padding: spacing.base * 4,
      background: 'subtle',
    },
  },

  // App layouts - bottom navigation (mobile), top navigation (desktop)
  appLayout: {
    type: 'hybrid',
    mobile: {
      navigation: 'bottom',
      height: 56,
      items: 4,
    },
    tablet: {
      navigation: 'top',
      height: 64,
      layout: 'horizontal',
    },
    desktop: {
      navigation: 'top',
      height: 64,
      layout: 'horizontal',
    },
    content: {
      padding: { mobile: spacing.base * 3, tablet: spacing.base * 4, desktop: spacing.base * 6 },
    },
  },

  // Form layouts - responsive form fields
  formLayout: {
    mobile: {
      columns: 1,
      gutter: spacing.base * 4,
    },
    tablet: {
      columns: 2,
      gutter: spacing.base * 4,
    },
    desktop: {
      columns: 3,
      gutter: spacing.base * 6,
    },
  },

  // Card grid - responsive card layouts
  cardGrid: {
    mobile: {
      columns: 1,
      gutter: spacing.base * 3,
    },
    tablet: {
      columns: 2,
      gutter: spacing.base * 4,
    },
    desktop: {
      columns: 3,
      gutter: spacing.base * 6,
    },
    wide: {
      columns: 4,
      gutter: spacing.base * 6,
    },
  },

  // Leaderboard layout
  leaderboardLayout: {
    mobile: {
      columns: 1,
      cardWidth: '100%',
      avatarSize: 48,
    },
    tablet: {
      columns: 2,
      cardWidth: 'calc(50% - 8px)',
      avatarSize: 56,
    },
    desktop: {
      columns: 3,
      cardWidth: 'calc(33.333% - 10px)',
      avatarSize: 64,
    },
  },

  // Table layout - responsive data tables
  tableLayout: {
    mobile: {
      display: 'stack', // Show as stacked cards
      columns: 3, // Show priority columns
    },
    tablet: {
      display: 'table',
      columns: 6,
      scrollable: true,
    },
    desktop: {
      display: 'table',
      columns: 'all',
      scrollable: false,
    },
  },

  // Modal/Dialog layout
  modalLayout: {
    mobile: {
      width: '90%',
      maxWidth: 400,
      maxHeight: '90%',
    },
    tablet: {
      width: '70%',
      maxWidth: 600,
      maxHeight: '80%',
    },
    desktop: {
      width: '50%',
      maxWidth: 800,
      maxHeight: '80%',
    },
  },
};

// Spacing patterns for common layouts
export const spacingPatterns = {
  // Page/Section spacing
  section: {
    margin: spacing.base * 8, // 32px
    padding: spacing.base * 6, // 24px
  },
  subsection: {
    margin: spacing.base * 6, // 24px
    padding: spacing.base * 4, // 16px
  },
  card: {
    padding: spacing.base * 4, // 16px
  },
  compact: {
    padding: spacing.base * 2, // 8px
  },

  // Content spacing
  paragraph: {
    marginBottom: spacing.base * 3, // 12px
  },
  heading: {
    marginBottom: spacing.base * 2, // 8px
  },
  list: {
    itemSpacing: spacing.base * 2, // 8px
  },

  // Form spacing
  formField: {
    marginBottom: spacing.base * 4, // 16px
  },
  formGroup: {
    marginBottom: spacing.base * 6, // 24px
  },
  formAction: {
    marginTop: spacing.base * 6, // 24px
    buttonSpacing: spacing.base * 2, // 8px
  },
};

// Responsive typography
export const responsiveTypography = {
  // Display sizes adjust per device
  display: {
    mobile: { fontSize: 28, lineHeight: 36 },
    tablet: { fontSize: 32, lineHeight: 40 },
    desktop: { fontSize: 40, lineHeight: 48 },
  },
  heading1: {
    mobile: { fontSize: 24, lineHeight: 32 },
    tablet: { fontSize: 28, lineHeight: 36 },
    desktop: { fontSize: 32, lineHeight: 40 },
  },
  heading2: {
    mobile: { fontSize: 20, lineHeight: 28 },
    tablet: { fontSize: 24, lineHeight: 32 },
    desktop: { fontSize: 28, lineHeight: 36 },
  },
  heading3: {
    mobile: { fontSize: 18, lineHeight: 26 },
    tablet: { fontSize: 20, lineHeight: 28 },
    desktop: { fontSize: 24, lineHeight: 32 },
  },
  body: {
    mobile: { fontSize: 14, lineHeight: 22 },
    tablet: { fontSize: 15, lineHeight: 24 },
    desktop: { fontSize: 16, lineHeight: 24 },
  },
  bodySmall: {
    mobile: { fontSize: 12, lineHeight: 18 },
    tablet: { fontSize: 13, lineHeight: 20 },
    desktop: { fontSize: 14, lineHeight: 22 },
  },
  caption: {
    mobile: { fontSize: 11, lineHeight: 16 },
    tablet: { fontSize: 12, lineHeight: 18 },
    desktop: { fontSize: 12, lineHeight: 18 },
  },
};

// Safe area considerations for mobile
export const safeArea = {
  mobile: {
    paddingTop: 12,
    paddingBottom: 12,
    paddingLeft: 16,
    paddingRight: 16,
  },
  iosNotch: {
    paddingTop: 44,
  },
  androidNotch: {
    paddingTop: 24,
  },
};

export default layoutPatterns;
