/**
 * Design Tokens
 *
 * Central source of truth for design system values
 * TypeScript example: const, types, enums, objects
 */

// Domain types (matches Prisma enum)
export type DomainType = 'AUTOMOTIVE' | 'CULINARY' | 'WOODWORKING' | 'CUSTOM'

// Typography scale
export const typography = {
  // Font families
  fonts: {
    ui: 'var(--font-inter)',
    reading: 'var(--font-merriweather)',
    code: 'var(--font-jetbrains-mono)',
  },

  // Font sizes (in rem)
  sizes: {
    xs: '0.75rem',    // 12px
    sm: '0.875rem',   // 14px
    base: '1rem',     // 16px
    lg: '1.125rem',   // 18px
    xl: '1.25rem',    // 20px
    '2xl': '1.5rem',  // 24px
    '3xl': '1.875rem', // 30px
    '4xl': '2.25rem',  // 36px
  },

  // Line heights
  leading: {
    tight: '1.25',
    normal: '1.5',
    relaxed: '1.75',
    loose: '2',
  },
} as const // 'as const' makes this deeply readonly

// Color system
export const colors = {
  // Domain-specific accent colors
  automotive: 'oklch(0.55 0.15 240)', // Precision blue
  culinary: 'oklch(0.55 0.15 30)',    // Warm terracotta
  woodworking: 'oklch(0.45 0.10 70)', // Natural wood tone

  // Tier badges (source verification)
  tiers: {
    tier1: 'oklch(0.65 0.18 142)',  // Green - Primary authoritative
    tier2: 'oklch(0.75 0.18 85)',   // Yellow - Trusted industry
    tier3: 'oklch(0.65 0.18 240)',  // Blue - Community validated
  },
} as const

// Spacing scale (matches Tailwind defaults)
export const spacing = {
  xs: '0.25rem',  // 4px
  sm: '0.5rem',   // 8px
  md: '1rem',     // 16px
  lg: '1.5rem',   // 24px
  xl: '2rem',     // 32px
  '2xl': '3rem',  // 48px
  '3xl': '4rem',  // 64px
} as const

// Animation timing
export const transitions = {
  fast: '120ms cubic-bezier(0.4, 0, 0.2, 1)',
  base: '150ms cubic-bezier(0.4, 0, 0.2, 1)',
  slow: '180ms cubic-bezier(0.4, 0, 0.2, 1)',
  spring: '300ms cubic-bezier(0.34, 1.56, 0.64, 1)', // Bounce effect for celebrations
} as const

// Border radius
export const radius = {
  sm: '0.425rem',   // 6.8px
  md: '0.625rem',   // 10px
  lg: '0.825rem',   // 13.2px
  xl: '1.025rem',   // 16.4px
  full: '9999px',   // Fully rounded
} as const

// Domain theme configurations
export const domainThemes = {
  AUTOMOTIVE: {
    accent: colors.automotive,
    name: 'Automotive',
    description: 'Precision engineering and performance',
  },
  CULINARY: {
    accent: colors.culinary,
    name: 'Culinary',
    description: 'Technique, tradition, and flavor',
  },
  WOODWORKING: {
    accent: colors.woodworking,
    name: 'Woodworking',
    description: 'Craftsmanship and natural materials',
  },
  CUSTOM: {
    accent: 'oklch(0.55 0.15 180)', // Neutral cyan
    name: 'Custom',
    description: 'Your domain, your expertise',
  },
} as const

// Type helper: Extract domain theme type
export type DomainTheme = typeof domainThemes[DomainType]

// Confidence levels (for fact verification)
export const confidenceLevels = {
  low: 0,      // 0-50%
  medium: 50,  // 50-80%
  high: 80,    // 80-95%
  verified: 95, // 95%+ (platform standard)
} as const

// Export all tokens as single object
export const designTokens = {
  typography,
  colors,
  spacing,
  transitions,
  radius,
  domainThemes,
  confidenceLevels,
} as const
