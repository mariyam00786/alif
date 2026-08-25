/**
 * Component System Specifications
 * Defines all reusable UI components and their specifications
 */

// Component sizes and states
export const componentSizes = {
  // Button sizes
  button: {
    sm: { height: 32, padding: '8px 12px', fontSize: 12 },
    md: { height: 40, padding: '10px 16px', fontSize: 14 },
    lg: { height: 48, padding: '12px 20px', fontSize: 16 },
  },
  // Input sizes
  input: {
    sm: { height: 32, padding: '8px 12px', fontSize: 12 },
    md: { height: 40, padding: '10px 16px', fontSize: 14 },
    lg: { height: 48, padding: '12px 20px', fontSize: 16 },
  },
  // Card sizes
  card: {
    compact: { padding: 12, borderRadius: 8 },
    default: { padding: 16, borderRadius: 12 },
    spacious: { padding: 20, borderRadius: 16 },
  },
};

// Component states
export const componentStates = {
  button: ['default', 'hover', 'active', 'disabled', 'loading'],
  input: ['default', 'focused', 'filled', 'error', 'disabled'],
  card: ['default', 'hover', 'selected', 'disabled'],
  badge: ['default', 'success', 'warning', 'error', 'info'],
  table: ['idle', 'hover', 'selected', 'sorting'],
};

// Rating control specifications
export const ratingControlSpecs = {
  activityRating: {
    scale: 1, // 1-5
    labels: {
      1: 'Poor',
      2: 'Fair',
      3: 'Good',
      4: 'Very Good',
      5: 'Excellent',
    },
    colors: {
      1: '#D32F2F', // Red
      2: '#F57C00', // Orange
      3: '#FDD835', // Yellow
      4: '#AFB42B', // Lime
      5: '#2E7D32', // Green
    },
  },
  behaviorRating: {
    scale: 1, // 1-5
    labels: {
      1: 'Needs Work',
      2: 'Improving',
      3: 'Satisfactory',
      4: 'Good',
      5: 'Excellent',
    },
  },
};

// Navigation pattern specifications
export const navigationPatterns = {
  admin: {
    layout: 'sidebar',
    menus: ['Dashboard', 'Students', 'Teachers', 'Batches', 'Activities', 'Reports', 'Settings'],
    adminOnly: ['Settings', 'Reports'],
  },
  teacher: {
    layout: 'bottom-nav',
    menus: ['Dashboard', 'Students', 'Batches', 'Notifications'],
  },
  parent: {
    layout: 'bottom-nav',
    menus: ['Dashboard', 'Children', 'Progress', 'Notifications'],
  },
  student: {
    layout: 'bottom-nav',
    menus: ['Dashboard', 'Log Activity', 'Progress', 'Leaderboard'],
  },
};

// Responsive breakpoints
export const breakpoints = {
  xs: 0,
  sm: 480,
  md: 768,
  lg: 1024,
  xl: 1440,
  xxl: 1920,
};

// Component specifications for all UI elements
export const componentSpecs = {
  // Buttons
  PrimaryButton: {
    variants: ['solid', 'outlined', 'text'],
    sizes: ['sm', 'md', 'lg'],
    states: componentStates.button,
    description: 'Main action button with semantic meaning',
  },
  SecondaryButton: {
    variants: ['solid', 'outlined', 'text'],
    sizes: ['sm', 'md', 'lg'],
    states: componentStates.button,
    description: 'Secondary action button',
  },
  DangerButton: {
    variants: ['solid', 'outlined', 'text'],
    sizes: ['sm', 'md', 'lg'],
    states: componentStates.button,
    description: 'Destructive action button',
  },

  // Inputs
  TextInput: {
    variants: ['outlined', 'filled', 'underline'],
    sizes: ['sm', 'md', 'lg'],
    states: componentStates.input,
    description: 'Single-line text input field',
    properties: ['label', 'placeholder', 'helperText', 'errorText', 'icon', 'disabled'],
  },
  TextArea: {
    variants: ['outlined', 'filled', 'underline'],
    sizes: ['sm', 'md', 'lg'],
    states: componentStates.input,
    description: 'Multi-line text input field',
    properties: ['label', 'placeholder', 'maxLength', 'rows', 'disabled'],
  },
  Select: {
    variants: ['outlined', 'filled', 'underline'],
    sizes: ['sm', 'md', 'lg'],
    states: componentStates.input,
    description: 'Dropdown selection component',
    properties: ['label', 'options', 'multiple', 'searchable', 'disabled'],
  },
  DatePicker: {
    variants: ['input', 'inline'],
    sizes: ['sm', 'md', 'lg'],
    description: 'Date selection component',
    properties: ['label', 'format', 'minDate', 'maxDate', 'disabled'],
  },
  TimePicker: {
    variants: ['input', 'inline'],
    sizes: ['sm', 'md', 'lg'],
    description: 'Time selection component',
    properties: ['label', 'format', 'minTime', 'maxTime', 'disabled'],
  },

  // Cards and Containers
  Card: {
    sizes: ['compact', 'default', 'spacious'],
    states: componentStates.card,
    description: 'Container for content with elevation and borders',
    properties: ['elevation', 'clickable', 'selectable', 'header', 'footer', 'loading'],
  },
  Modal: {
    variants: ['dialog', 'alert', 'confirmation'],
    sizes: ['sm', 'md', 'lg'],
    description: 'Overlay dialog for important interactions',
    properties: ['title', 'body', 'actions', 'dismissible', 'width', 'height'],
  },
  Sheet: {
    variants: ['bottom', 'side'],
    sizes: ['compact', 'default', 'full'],
    description: 'Drawer/Sheet component for navigation or content',
    properties: ['title', 'body', 'dismissible', 'backdrop'],
  },

  // Data Display
  Table: {
    features: ['sorting', 'filtering', 'pagination', 'selection', 'export'],
    states: componentStates.table,
    description: 'Tabular data display with interactions',
    properties: ['columns', 'data', 'pageSize', 'selectable', 'expandable'],
  },
  Badge: {
    variants: ['filled', 'outlined', 'dot'],
    states: componentStates.badge,
    sizes: ['sm', 'md', 'lg'],
    description: 'Status indicator or label',
  },
  Chip: {
    variants: ['filled', 'outlined'],
    states: ['default', 'hover', 'selected', 'disabled'],
    description: 'Removable item or filter',
  },
  Progress: {
    variants: ['linear', 'circular'],
    sizes: ['sm', 'md', 'lg'],
    description: 'Progress indicator or loading state',
  },
  Avatar: {
    sizes: ['xs', 'sm', 'md', 'lg', 'xl'],
    variants: ['image', 'initials', 'icon'],
    description: 'User profile image or identifier',
  },

  // Navigation
  Tabs: {
    variants: ['line', 'pill', 'button'],
    sizes: ['sm', 'md', 'lg'],
    description: 'Tabbed navigation between related content',
    properties: ['activeTab', 'items', 'scrollable'],
  },
  Breadcrumbs: {
    variants: ['slash', 'arrow', 'bullet'],
    description: 'Navigation hierarchy indicator',
  },
  Navigation: {
    variants: ['sidebar', 'top', 'bottom'],
    description: 'Main navigation component',
  },
  LanguageSwitcher: {
    languages: ['en', 'ml'],
    description: 'Language selection component',
  },

  // Specialized Components
  ActivityRatingControl: {
    scale: '1-5',
    description: 'Rate activity performance (1-5 stars)',
    properties: ['value', 'onChange', 'readOnly', 'size'],
  },
  BehaviorRatingControl: {
    scale: '1-5',
    description: 'Rate student behavior',
    properties: ['value', 'onChange', 'readOnly', 'size'],
  },
  StudentSelector: {
    description: 'Select one or multiple students',
    properties: ['value', 'onChange', 'multiple', 'searchable', 'filterable'],
  },
  DailyLogForm: {
    description: 'Form for logging daily activities',
    fields: [
      'studentId',
      'activityType',
      'duration',
      'performanceRating',
      'behaviorRating',
      'notes',
      'attachments',
    ],
  },
  LeaderboardCard: {
    description: 'Display student ranking and progress',
    properties: ['rank', 'student', 'score', 'trend', 'badges'],
  },
  ProgressChart: {
    types: ['line', 'bar', 'area', 'pie'],
    description: 'Visualize student progress over time',
  },
  HeatmapCalendar: {
    description: 'Activity contribution calendar heatmap',
    properties: ['year', 'data', 'onDateClick'],
  },
  BadgeDisplay: {
    description: 'Display earned badges',
    properties: ['badges', 'size', 'animated'],
  },

  // Utility Components
  Alert: {
    variants: ['success', 'warning', 'error', 'info'],
    description: 'Alert message display',
  },
  Toast: {
    variants: ['success', 'warning', 'error', 'info'],
    description: 'Temporary notification message',
  },
  SkeletonLoader: {
    variants: ['text', 'card', 'image', 'custom'],
    description: 'Loading placeholder',
  },
  EmptyState: {
    description: 'Display when no content available',
    properties: ['icon', 'title', 'description', 'action'],
  },
};

export default componentSpecs;
