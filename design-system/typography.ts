/**
 * Alif Online Moral School - Typography System
 * 
 * Bilingual support for Malayalam and English
 * Follows Material Design 3 guidelines
 * 
 * FONT FAMILIES:
 * - English: Poppins (primary), Roboto (fallback)
 * - Malayalam: Noto Sans Malayalam (primary), Manjari (fallback)
 * 
 * FONT WEIGHTS:
 * - 400 (Regular): Body text, descriptions
 * - 500 (Medium): Labels, secondary headings
 * - 600 (Semibold): Card titles, emphasis
 * - 700 (Bold): Headlines, page titles
 * 
 * SCALE:
 * - xs: 11px (smallest labels)
 * - sm: 12px (small text, captions)
 * - base: 14px (labels, button text)
 * - lg: 16px (body text)
 * - xl: 18px (section titles)
 * - 2xl: 22px (card/modal titles)
 * - 3xl: 28px (headline medium)
 * - 4xl: 32px (headline large)
 * - 5xl+: 36px+ (display/hero text)
 */

export const Typography = {
  // Font Families
  fonts: {
    // English Font Stack
    english: 'Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
    
    // Malayalam Font Stack
    malayalam: '"Noto Sans Malayalam", "Manjari", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
    
    // Mono Font (for code/inputs)
    mono: '"Courier New", monospace',
  },

  // Display Styles (Hero/Headings)
  display: {
    large: {
      fontSize: '57px',
      lineHeight: '64px',
      fontWeight: 700,
      letterSpacing: '0px',
    },
    medium: {
      fontSize: '45px',
      lineHeight: '52px',
      fontWeight: 700,
      letterSpacing: '0px',
    },
    small: {
      fontSize: '36px',
      lineHeight: '44px',
      fontWeight: 700,
      letterSpacing: '0px',
    },
  },

  // Headline Styles
  headline: {
    large: {
      fontSize: '32px',
      lineHeight: '40px',
      fontWeight: 700,
      letterSpacing: '0px',
    },
    medium: {
      fontSize: '28px',
      lineHeight: '36px',
      fontWeight: 700,
      letterSpacing: '0px',
    },
    small: {
      fontSize: '24px',
      lineHeight: '32px',
      fontWeight: 700,
      letterSpacing: '0px',
    },
  },

  // Title Styles
  title: {
    large: {
      fontSize: '22px',
      lineHeight: '28px',
      fontWeight: 600,
      letterSpacing: '0px',
    },
    medium: {
      fontSize: '18px',
      lineHeight: '24px',
      fontWeight: 600,
      letterSpacing: '0.1px',
    },
    small: {
      fontSize: '16px',
      lineHeight: '24px',
      fontWeight: 600,
      letterSpacing: '0.1px',
    },
  },

  // Body Styles
  body: {
    large: {
      fontSize: '16px',
      lineHeight: '24px',
      fontWeight: 400,
      letterSpacing: '0.5px',
    },
    medium: {
      fontSize: '14px',
      lineHeight: '20px',
      fontWeight: 400,
      letterSpacing: '0.25px',
    },
    small: {
      fontSize: '12px',
      lineHeight: '16px',
      fontWeight: 400,
      letterSpacing: '0.4px',
    },
  },

  // Label Styles
  label: {
    large: {
      fontSize: '14px',
      lineHeight: '20px',
      fontWeight: 500,
      letterSpacing: '0.1px',
    },
    medium: {
      fontSize: '12px',
      lineHeight: '16px',
      fontWeight: 500,
      letterSpacing: '0.5px',
    },
    small: {
      fontSize: '11px',
      lineHeight: '16px',
      fontWeight: 500,
      letterSpacing: '0.5px',
    },
  },

  // Button Styles
  button: {
    fontSize: '14px',
    lineHeight: '20px',
    fontWeight: 600,
    letterSpacing: '0.1px',
    textTransform: 'capitalize' as const,
  },
} as const;

/**
 * Preset text styles for common use cases
 */
export const TextStyles = {
  // Page Title
  pageTitle: {
    ...Typography.headline.large,
    fontFamily: Typography.fonts.english,
  },

  // Section Title
  sectionTitle: {
    ...Typography.headline.medium,
    fontFamily: Typography.fonts.english,
  },

  // Card Title
  cardTitle: {
    ...Typography.title.medium,
    fontFamily: Typography.fonts.english,
  },

  // Body Text
  bodyText: {
    ...Typography.body.medium,
    fontFamily: Typography.fonts.english,
  },

  // Small Label
  label: {
    ...Typography.label.medium,
    fontFamily: Typography.fonts.english,
  },

  // Button Text
  buttonText: {
    ...Typography.button,
    fontFamily: Typography.fonts.english,
  },

  // Malayalam Text
  malayalamText: {
    ...Typography.body.medium,
    fontFamily: Typography.fonts.malayalam,
  },

  // Malayalam Title
  malayalamTitle: {
    ...Typography.title.medium,
    fontFamily: Typography.fonts.malayalam,
  },
} as const;

/**
 * Typography System Summary
 * ==========================
 * 
 * Font Weights Available:
 * - 400: Regular (body, descriptions)
 * - 500: Medium (labels, secondaries)
 * - 600: Semibold (titles, emphasis)
 * - 700: Bold (headers, important)
 * 
 * Size Scale (from smallest to largest):
 * - Display: 36px, 45px, 57px (hero/page headers)
 * - Headline: 24px, 28px, 32px (section headers)
 * - Title: 16px, 18px, 22px (card/modal headers)
 * - Body: 12px, 14px, 16px (main content)
 * - Label: 11px, 12px, 14px (small text, captions)
 * - Button: 14px @ 600 weight
 * 
 * Usage Recommendations:
 * - Page titles: display.large or headline.large
 * - Section titles: headline.medium or headline.small
 * - Card headers: title.medium or title.large
 * - Body text: body.large or body.medium
 * - Labels/captions: label.medium or label.small
 * - Button text: button (always 14px @ 600)
 * 
 * Bilingual Usage:
 * - English text: Use TextStyles with .english font stack
 * - Malayalam text: Use TextStyles with .malayalam font stack
 * - Mixed content: Ensure proper font switching per language
 */
