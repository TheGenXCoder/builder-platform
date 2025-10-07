'use client'

/**
 * Home Page - Domain Theme Demo
 *
 * TypeScript + React example: Client component, hooks, event handlers
 */

import { useDomainTheme, DomainAccent } from '@/components/providers/domain-theme-provider'
import { ThemeToggle } from '@/components/theme-toggle'
import { Button } from '@/components/ui/button'
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import type { DomainType } from '@/lib/design-tokens'
import { toast } from 'sonner'

export default function Home() {
  const { domain, theme, setDomain } = useDomainTheme()

  // Event handler with TypeScript type
  const handleDomainChange = (newDomain: DomainType) => {
    setDomain(newDomain)
    toast.success(`Domain changed to ${theme.name}`, {
      description: theme.description,
    })
  }

  return (
    <main className="min-h-screen bg-background p-8">
      <div className="mx-auto max-w-4xl space-y-8">
        {/* Header with Theme Toggle */}
        <div className="flex items-start justify-between">
          <div className="space-y-2">
            <h1 className="text-4xl font-bold tracking-tight">
              The Builder Platform
            </h1>
            <p className="text-muted-foreground text-lg">
              Domain-agnostic expert content creation with knowledge compounding
            </p>
          </div>
          <ThemeToggle />
        </div>

        {/* Domain Selection */}
        <Card>
          <CardHeader>
            <CardTitle>Select Your Domain</CardTitle>
            <CardDescription>
              Choose your area of expertise. The UI adapts to your domain.
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex flex-wrap gap-3">
              <Button
                variant={domain === 'AUTOMOTIVE' ? 'default' : 'outline'}
                onClick={() => handleDomainChange('AUTOMOTIVE')}
              >
                🏎️ Automotive
              </Button>
              <Button
                variant={domain === 'CULINARY' ? 'default' : 'outline'}
                onClick={() => handleDomainChange('CULINARY')}
              >
                👨‍🍳 Culinary
              </Button>
              <Button
                variant={domain === 'WOODWORKING' ? 'default' : 'outline'}
                onClick={() => handleDomainChange('WOODWORKING')}
              >
                🪵 Woodworking
              </Button>
              <Button
                variant={domain === 'CUSTOM' ? 'default' : 'outline'}
                onClick={() => handleDomainChange('CUSTOM')}
              >
                ⚙️ Custom
              </Button>
            </div>

            <div className="rounded-lg border p-4 space-y-2">
              <div className="flex items-center gap-2">
                <Badge>Current Domain</Badge>
                <DomainAccent className="font-semibold text-lg">
                  {theme.name}
                </DomainAccent>
              </div>
              <p className="text-sm text-muted-foreground">
                {theme.description}
              </p>
              <div className="flex items-center gap-2 text-xs font-mono">
                <span className="text-muted-foreground">Accent Color:</span>
                <div
                  className="h-4 w-16 rounded border"
                  style={{ backgroundColor: theme.accent }}
                />
                <code className="text-muted-foreground">{theme.accent}</code>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* TypeScript Features Demo */}
        <Card>
          <CardHeader>
            <CardTitle>TypeScript in Action</CardTitle>
            <CardDescription>
              Hover over variables in your editor to see type inference
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-3 font-mono text-sm">
              <div className="rounded bg-muted p-3">
                <code>
                  <span className="text-muted-foreground">// Type inference</span>
                  <br />
                  <span className="text-blue-500">const</span>{' '}
                  <span className="text-yellow-500">domain</span> ={' '}
                  <span className="text-green-500">'{domain}'</span>
                  <br />
                  <span className="text-muted-foreground">
                    // TypeScript knows domain is DomainType
                  </span>
                </code>
              </div>

              <div className="rounded bg-muted p-3">
                <code>
                  <span className="text-muted-foreground">// Type safety</span>
                  <br />
                  <span className="text-blue-500">const</span>{' '}
                  <span className="text-yellow-500">theme</span> ={' '}
                  <span className="text-purple-500">domainThemes</span>[domain]
                  <br />
                  <span className="text-muted-foreground">
                    // TypeScript provides autocomplete for theme.accent, theme.name, etc.
                  </span>
                </code>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Stack Info */}
        <Card>
          <CardHeader>
            <CardTitle>Tech Stack</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid gap-2 sm:grid-cols-2">
              <div className="space-y-1">
                <Badge variant="outline">Framework</Badge>
                <p className="text-sm">Next.js 15 + React 19</p>
              </div>
              <div className="space-y-1">
                <Badge variant="outline">Language</Badge>
                <p className="text-sm">TypeScript</p>
              </div>
              <div className="space-y-1">
                <Badge variant="outline">Styling</Badge>
                <p className="text-sm">Tailwind CSS 4 + ShadCN/UI</p>
              </div>
              <div className="space-y-1">
                <Badge variant="outline">Database</Badge>
                <p className="text-sm">PostgreSQL + Prisma</p>
              </div>
              <div className="space-y-1">
                <Badge variant="outline">UI Font</Badge>
                <p className="text-sm font-sans">Inter (this text)</p>
              </div>
              <div className="space-y-1">
                <Badge variant="outline">Reading Font</Badge>
                <p className="text-sm font-serif">Merriweather (this text)</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </main>
  )
}
