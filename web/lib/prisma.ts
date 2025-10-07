/**
 * Prisma Client Singleton
 *
 * Prevents multiple instances in development (hot reload)
 * Best practice for Next.js applications
 */

import { PrismaClient } from '@prisma/client'

// TypeScript type augmentation for global object
const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined
}

// Create singleton instance
export const prisma = globalForPrisma.prisma ?? new PrismaClient({
  log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
})

// In development, store instance on global to survive hot reloads
if (process.env.NODE_ENV !== 'production') {
  globalForPrisma.prisma = prisma
}

// Export types from Prisma for use throughout the app
export * from '@prisma/client'
