'use client' // Required for React Context in Next.js 13+

/**
 * Domain Theme Provider
 *
 * Manages domain-specific theming throughout the app
 * TypeScript + React example: Context API, custom hooks, type safety
 */

import { createContext, useContext, useState, useEffect } from 'react'
import type { DomainType, DomainTheme } from '@/lib/design-tokens'
import { domainThemes } from '@/lib/design-tokens'

// Context type definition
interface DomainThemeContextType {
  domain: DomainType
  theme: DomainTheme
  setDomain: (domain: DomainType) => void
}

// Create context with undefined default (will error if used outside provider)
const DomainThemeContext = createContext<DomainThemeContextType | undefined>(undefined)

// Provider props type
interface DomainThemeProviderProps {
  children: React.ReactNode
  initialDomain?: DomainType
}

/**
 * Domain Theme Provider Component
 *
 * Wraps app to provide domain theme context
 */
export function DomainThemeProvider({
  children,
  initialDomain = 'CUSTOM',
}: DomainThemeProviderProps) {
  // State with TypeScript type inference
  const [domain, setDomain] = useState<DomainType>(initialDomain)

  // Derived state - theme object based on domain
  const theme = domainThemes[domain]

  // Apply accent color to CSS variable when domain changes
  useEffect(() => {
    // Update CSS custom property for domain accent color
    document.documentElement.style.setProperty('--accent-domain', theme.accent)
  }, [theme.accent])

  // Context value (memoized would be better for performance, but keeping simple for now)
  const value: DomainThemeContextType = {
    domain,
    theme,
    setDomain,
  }

  return (
    <DomainThemeContext.Provider value={value}>
      {children}
    </DomainThemeContext.Provider>
  )
}

/**
 * Custom hook to access domain theme context
 *
 * TypeScript example: Type guards, error handling
 *
 * Usage:
 * ```tsx
 * const { domain, theme, setDomain } = useDomainTheme()
 * ```
 */
export function useDomainTheme(): DomainThemeContextType {
  const context = useContext(DomainThemeContext)

  // Type guard: Ensure hook is used within provider
  if (context === undefined) {
    throw new Error('useDomainTheme must be used within DomainThemeProvider')
  }

  return context
}

/**
 * Helper component: Domain-aware accent color
 *
 * Example usage:
 * ```tsx
 * <DomainAccent className="text-xl font-bold">
 *   Q50 Super Saloon
 * </DomainAccent>
 * ```
 */
interface DomainAccentProps {
  children: React.ReactNode
  className?: string
}

export function DomainAccent({ children, className = '' }: DomainAccentProps) {
  return (
    <span className={className} style={{ color: 'var(--accent-domain)' }}>
      {children}
    </span>
  )
}
