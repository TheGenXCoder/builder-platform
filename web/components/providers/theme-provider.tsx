'use client'

/**
 * Theme Provider (Dark/Light Mode)
 *
 * Wraps next-themes for system/dark/light mode support
 */

import { ThemeProvider as NextThemesProvider } from 'next-themes'
import type { ThemeProviderProps } from 'next-themes'

export function ThemeProvider({ children, ...props }: ThemeProviderProps) {
  return <NextThemesProvider {...props}>{children}</NextThemesProvider>
}
