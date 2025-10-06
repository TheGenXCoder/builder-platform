# TECHNICAL ARCHITECTURE SPECIFICATION v1.0
**The Builder Platform - System Design & Implementation Details**

**Last Updated:** October 6, 2024
**Status:** Implementation-Ready
**Target:** Scalable to 1,000+ SMEs, domain-agnostic platform

---

## Architecture Overview

### System Components

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENT LAYER                            │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Next.js 14 App (React 18 + TypeScript)                   │  │
│  │ - ShadCN/UI Components (Radix + Tailwind)                │  │
│  │ - Framer Motion (Animations)                             │  │
│  │ - Tiptap (Rich Text Editor)                              │  │
│  │ - D3/Cytoscape (Graph Visualization)                     │  │
│  │ - TanStack Query (Data Fetching/Caching)                 │  │
│  │ - Zustand (Client State Management)                      │  │
│  └──────────────────────────────────────────────────────────┘  │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                │ HTTPS
                                │
┌───────────────────────────────▼─────────────────────────────────┐
│                      APPLICATION LAYER                          │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Next.js API Routes (Serverless Functions)                │  │
│  │ - Authentication (NextAuth.js/Clerk)                     │  │
│  │ - REST API Endpoints                                     │  │
│  │ - GraphQL API (optional future)                          │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────┬─────────────────────────┬─────────────────────┘
                  │                         │
                  │                         │
┌─────────────────▼───────────┐  ┌──────────▼──────────────────────┐
│    DATA LAYER (SQL)         │  │  GRAPH LAYER (Neo4j)            │
│  ┌──────────────────────┐   │  │  ┌─────────────────────────┐   │
│  │ PostgreSQL           │   │  │  │ Neo4j Graph Database    │   │
│  │ - Users              │   │  │  │ - Knowledge Nodes       │   │
│  │ - Projects           │   │  │  │ - Fact Relationships    │   │
│  │ - Research           │   │  │  │ - Domain Connections    │   │
│  │ - Facts              │   │  │  │ - Pattern Detection     │   │
│  │ - Content            │   │  │  │                         │   │
│  │ - Conversation Logs  │   │  │  │ Cypher Query Engine     │   │
│  │                      │   │  │  └─────────────────────────┘   │
│  │ Prisma ORM           │   │  │                                │
│  └──────────────────────┘   │  └────────────────────────────────┘
└──────────────────────────────┘
                  │
                  │
┌─────────────────▼───────────────────────────────────────────────┐
│                     STORAGE LAYER                               │
│  - Cloudinary / AWS S3 (Media: images, videos, documents)      │
│  - File System (Conversation logs backup: Markdown files)      │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow Example: Verifying a Fact

```
1. User clicks "Verify Fact" (Client)
   ↓
2. Verification Dialog Opens (ShadCN Dialog component)
   ↓
3. User selects Tier 1, confidence 95%, adds tags
   ↓
4. User clicks "Verify ✓"
   ↓
5. POST /api/facts/verify (Next.js API Route)
   {
     claim: "VR30 bore x stroke: 86mm x 86mm",
     source: "Factory Service Manual",
     tier: 1,
     confidence: 95,
     tags: ["VR30", "engine-specs", "bore-stroke"]
   }
   ↓
6. API Route validates request
   ↓
7. Create fact in PostgreSQL (Prisma)
   INSERT INTO facts (claim, source, tier, confidence, ...)
   ↓
8. Create node in Neo4j (Neo4j Driver)
   CREATE (f:Fact {id, claim, tier, confidence})
   CREATE (f)-[:TAGGED_WITH]->(tag:Tag {name})
   CREATE (f)-[:BELONGS_TO]->(project:Project)
   ↓
9. Return success response + fact ID
   ↓
10. Client updates UI:
    - Celebration animation (Framer Motion)
    - Fact appears in findings list
    - Research spec checkbox checked
    - Toast notification
    - Mini-graph preview shows new node
   ↓
11. TanStack Query invalidates cache, refetches data
```

---

## Technology Stack (Detailed)

### Front-End

**Next.js 14**
- **Version:** 14.x (App Router, Server Components, Server Actions)
- **Why:** Industry standard, excellent DX, built-in API routes, optimized performance, Vercel deployment
- **Features Used:**
  - App Router (file-based routing)
  - Server Components (reduce client bundle size)
  - Server Actions (form submissions without API routes)
  - Image Optimization (next/image)
  - Font Optimization (next/font)
  - Streaming (loading.tsx for instant feedback)

**React 18**
- **Version:** 18.x
- **Why:** Component model, hooks, concurrent features
- **Features Used:**
  - Suspense (loading states)
  - Concurrent Rendering (smooth animations)
  - useTransition (non-blocking state updates)

**TypeScript**
- **Version:** 5.x
- **Why:** Type safety prevents bugs, better DX with autocomplete
- **Configuration:**
  - Strict mode enabled
  - Path aliases (@/components, @/lib, @/app)
  - Type inference maximized

**ShadCN/UI**
- **Version:** Latest (updated monthly)
- **Why:** Beautiful defaults, Radix UI primitives, full customization, you own the code
- **Components Used:** Command, Tabs, Badge, Card, Dialog, Sheet, Progress, Toast, Accordion, Separator, Tooltip, Slider
- **Customization:** Domain theming via CSS custom properties

**Tailwind CSS**
- **Version:** 3.x
- **Why:** Utility-first, consistent design system, fast development
- **Configuration:**
  - Custom colors (domain themes)
  - Custom fonts (Inter, Merriweather, JetBrains Mono)
  - Custom animations (spring physics via Tailwind plugins)
  - 8px base spacing scale

**Framer Motion**
- **Version:** 10.x
- **Why:** Best animation library for React, spring physics, gesture support
- **Use Cases:**
  - Celebration animations (confetti, bounce)
  - Page transitions
  - Graph node animations
  - Micro-interactions (button press, card hover)

**Tiptap**
- **Version:** 2.x
- **Why:** Headless rich text editor, extensible, ProseMirror-based
- **Extensions:**
  - Starter Kit (basic formatting)
  - Citation (custom extension for inline citations)
  - Slash Commands (trigger verification search)
  - Collaboration (future multi-user editing)

**D3.js / Cytoscape.js**
- **Version:** D3 v7 or Cytoscape 3.x (decision: test both in Week 13)
- **Why D3:** Full control, beautiful custom visualizations, web standard
- **Why Cytoscape:** Built for graphs, easier for complex networks, better performance at scale
- **Decision Criteria:**
  - If custom visualization needed: D3
  - If standard graph with 1,000+ nodes: Cytoscape

**TanStack Query (React Query)**
- **Version:** 5.x
- **Why:** Best data fetching library, caching, optimistic updates, auto-refetch
- **Features Used:**
  - Query caching (5-minute default)
  - Optimistic updates (verification feels instant)
  - Infinite queries (conversation log timeline)
  - Devtools (debugging in development)

**Zustand**
- **Version:** 4.x
- **Why:** Lightweight state management, simpler than Redux, no boilerplate
- **State:**
  - User preferences (theme, domain)
  - UI state (sidebar open/closed, modals)
  - Form state (verification dialog)

### Back-End

**Next.js API Routes**
- **Why:** Serverless, co-located with front-end, easy deployment
- **Structure:**
  ```
  app/api/
  ├── auth/
  │   ├── [...nextauth]/route.ts  (NextAuth.js)
  ├── projects/
  │   ├── route.ts                (GET list, POST create)
  │   ├── [id]/route.ts           (GET single, PUT update, DELETE)
  ├── facts/
  │   ├── verify/route.ts         (POST verify fact)
  │   ├── [id]/route.ts           (GET, PUT, DELETE)
  ├── graph/
  │   ├── nodes/route.ts          (GET knowledge graph nodes)
  │   ├── connections/route.ts    (GET relationships)
  ├── logs/
  │   ├── route.ts                (GET list, POST create)
  ```

**Prisma ORM**
- **Version:** 5.x
- **Why:** Type-safe database access, migrations, excellent DX
- **Features:**
  - Schema-first design
  - Auto-generated TypeScript types
  - Relation handling (users → projects → facts)
  - Migration system (version control for database)
  - Prisma Studio (database GUI for development)

**NextAuth.js OR Clerk**
- **Decision:** Evaluate both, choose one by Week 2
- **NextAuth.js Pros:** Free, flexible, full control
- **Clerk Pros:** Beautiful UI, easier onboarding, managed service
- **Decision Criteria:** If budget allows, use Clerk (better UX). Otherwise NextAuth.js.
- **Features Needed:**
  - Email/password authentication
  - OAuth (Google, GitHub)
  - Session management
  - Profile management

### Databases

**PostgreSQL**
- **Version:** 15.x
- **Why:** Reliable, ACID-compliant, excellent for relational data, pgvector for future AI features
- **Hosting:** Railway (development/staging), AWS RDS (production if scaling beyond Railway)
- **Schema Design:** See Database Schemas section below

**Neo4j**
- **Version:** 5.x (Community or Aura)
- **Why:** Purpose-built for graph queries, Cypher query language expressive, relationship traversal fast
- **Hosting:** Neo4j Aura (managed service, free tier for development)
- **Graph Model:** See Graph Database Schema section below

### Infrastructure & DevOps

**Vercel**
- **Why:** Next.js optimized, global edge network, zero-config deployment
- **Features:**
  - Automatic deployments (push to main branch)
  - Preview deployments (each PR gets URL)
  - Analytics (Core Web Vitals)
  - Edge Functions (API routes run at edge)

**Railway OR Render**
- **Why:** Easy database hosting, automatic backups, migration support
- **Services:**
  - PostgreSQL instance
  - Redis (future caching layer)
- **Fallback:** AWS RDS if outgrowing managed services

**Neo4j Aura**
- **Why:** Managed Neo4j, free tier for development, scales to production
- **Plan:** Start with free tier (4GB storage), upgrade when needed

**Cloudinary OR AWS S3**
- **Decision:** Cloudinary (easier image optimization). Fallback: S3 + CloudFront.
- **Why Cloudinary:** Auto image optimization, transformations (resize, format conversion), CDN included
- **Storage:** User-uploaded media (project images, profile photos, content images)

**GitHub Actions**
- **Why:** CI/CD integrated with GitHub, free for public repos
- **Workflows:**
  - Run tests on PR (Vitest for unit tests, Playwright for E2E)
  - Lint check (ESLint, Prettier)
  - Type check (tsc --noEmit)
  - Deploy to staging (merge to develop branch)
  - Deploy to production (merge to main branch)

### Monitoring & Analytics

**Vercel Analytics**
- **Why:** Built-in, tracks Core Web Vitals, page speed
- **Metrics:** LCP, FID, CLS, TTFB

**Sentry**
- **Why:** Error tracking, performance monitoring, release tracking
- **Integration:** Automatic source maps, Next.js SDK
- **Alerts:** Slack notifications for critical errors

**PostHog OR Mixpanel**
- **Decision:** PostHog (open-source, self-hostable if needed)
- **Why:** Product analytics, user behavior tracking, feature flags
- **Events Tracked:**
  - User sign up
  - First verification completed
  - Fact verified (with tier, confidence)
  - Content published (with confidence score)
  - Knowledge graph viewed
  - Connection suggestion accepted

**Prisma Studio**
- **Why:** Database GUI for development, inspect data easily
- **Usage:** Development only (not exposed in production)

---

## Database Schemas

### PostgreSQL Schema (Prisma)

```prisma
// schema.prisma

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// ─────────────────────────────────────────────────
// USERS & AUTHENTICATION
// ─────────────────────────────────────────────────

model User {
  id            String    @id @default(cuid())
  email         String    @unique
  name          String?
  image         String?   // Profile photo URL
  domain        String    @default("automotive") // Primary domain preference
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt

  // Relations
  accounts      Account[]
  sessions      Session[]
  projects      Project[]
  facts         Fact[]
  logs          ConversationLog[]

  @@index([email])
}

model Account {
  id                String  @id @default(cuid())
  userId            String
  type              String
  provider          String
  providerAccountId String
  refresh_token     String? @db.Text
  access_token      String? @db.Text
  expires_at        Int?
  token_type        String?
  scope             String?
  id_token          String? @db.Text
  session_state     String?

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([provider, providerAccountId])
  @@index([userId])
}

model Session {
  id           String   @id @default(cuid())
  sessionToken String   @unique
  userId       String
  expires      DateTime
  user         User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId])
}

// ─────────────────────────────────────────────────
// PROJECTS & RESEARCH
// ─────────────────────────────────────────────────

model Project {
  id              String   @id @default(cuid())
  name            String
  domain          String   // automotive, culinary, woodworking, custom
  researchFocus   String   @db.Text
  contentGoals    Json     // {articles: true, videos: true, presentations: false}
  status          String   @default("active") // active, completed, archived
  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt

  userId          String
  user            User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  // Relations
  researchSpecs   ResearchSpec[]
  facts           Fact[]
  content         Content[]
  media           Media[]

  @@index([userId])
  @@index([domain])
}

model ResearchSpec {
  id              String   @id @default(cuid())
  projectId       String
  section         String   // "VR30DDTT Engine", "Cassoulet Variants"
  items           Json     // [{title: "Bore x Stroke", checked: true}, ...]
  progress        Int      @default(0) // 0-100%
  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt

  project         Project  @relation(fields: [projectId], references: [id], onDelete: Cascade)

  @@index([projectId])
}

model Fact {
  id              String   @id @default(cuid())
  claim           String   @db.Text
  source          String   @db.Text
  sourceTier      Int      // 1, 2, 3
  confidence      Int      // 0-100
  tags            String[] // ["VR30", "engine-specs", "bore-stroke"]
  verified        Boolean  @default(false)
  verifiedAt      DateTime?
  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt

  userId          String
  user            User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  projectId       String
  project         Project  @relation(fields: [projectId], references: [id], onDelete: Cascade)

  // Relations
  citations       Citation[]

  @@index([userId])
  @@index([projectId])
  @@index([sourceTier])
  @@index([verified])
}

// ─────────────────────────────────────────────────
// CONTENT & CITATIONS
// ─────────────────────────────────────────────────

model Content {
  id              String   @id @default(cuid())
  title           String
  body            String   @db.Text // Rich text (Tiptap JSON or HTML)
  type            String   // article, video_script, presentation
  status          String   @default("draft") // draft, review, published
  wordCount       Int      @default(0)
  confidence      Int      @default(0) // 0-100 (calculated from citations)
  publishedAt     DateTime?
  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt

  projectId       String
  project         Project  @relation(fields: [projectId], references: [id], onDelete: Cascade)

  // Relations
  citations       Citation[]

  @@index([projectId])
  @@index([status])
}

model Citation {
  id              String   @id @default(cuid())
  contentId       String
  factId          String
  position        Int      // Position in content (for ordering)

  content         Content  @relation(fields: [contentId], references: [id], onDelete: Cascade)
  fact            Fact     @relation(fields: [factId], references: [id], onDelete: Cascade)

  @@index([contentId])
  @@index([factId])
}

// ─────────────────────────────────────────────────
// MEDIA & ASSETS
// ─────────────────────────────────────────────────

model Media {
  id              String   @id @default(cuid())
  url             String   // Cloudinary URL
  type            String   // image, video, document
  filename        String
  size            Int      // Bytes
  metadata        Json?    // {width, height, format, etc.}
  createdAt       DateTime @default(now())

  projectId       String
  project         Project  @relation(fields: [projectId], references: [id], onDelete: Cascade)

  @@index([projectId])
  @@index([type])
}

// ─────────────────────────────────────────────────
// CONVERSATION LOGS
// ─────────────────────────────────────────────────

model ConversationLog {
  id              String   @id @default(cuid())
  title           String
  sessionType     String   // Planning, Research, Quality, Lessons Learned
  summary         String   @db.Text
  keyOutcomes     Json     // Array of key points
  tags            String[]
  contextStatus   String   // "Logged at 20% remaining"
  fileUrl         String?  // Markdown file URL (backup)
  createdAt       DateTime @default(now())

  userId          String
  user            User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId])
  @@index([tags])
  @@index([createdAt])
}
```

### Neo4j Graph Schema

**Nodes:**

```cypher
// Fact Node
(:Fact {
  id: String (UUID),
  claim: String,
  source: String,
  tier: Integer (1, 2, 3),
  confidence: Integer (0-100),
  verified: Boolean,
  createdAt: DateTime
})

// Project Node
(:Project {
  id: String (UUID),
  name: String,
  domain: String,
  createdAt: DateTime
})

// Tag Node
(:Tag {
  name: String
})

// Decision Node (for important platform/build decisions)
(:Decision {
  id: String (UUID),
  description: String,
  rationale: String,
  createdAt: DateTime
})

// Lesson Node (for failures/corrections/learnings)
(:Lesson {
  id: String (UUID),
  title: String,
  failure: String,
  correction: String,
  standard: String,
  createdAt: DateTime
})
```

**Relationships:**

```cypher
// Fact belongs to Project
(:Fact)-[:BELONGS_TO]->(:Project)

// Fact tagged with Tag
(:Fact)-[:TAGGED_WITH]->(:Tag)

// Fact relates to another Fact (methodology connection)
(:Fact)-[:RELATED_TO {similarity: Float}]->(:Fact)

// Decision informs Fact
(:Decision)-[:INFORMS]->(:Fact)

// Lesson produces Standard (captured as Fact)
(:Lesson)-[:PRODUCES]->(:Fact)

// Project uses Facts
(:Project)-[:USES]->(:Fact)

// Cross-domain pattern
(:Fact)-[:SAME_METHODOLOGY]->(:Fact)
// Where facts from different domains use same verification approach
```

**Example Queries:**

```cypher
// Find all facts related to VR30
MATCH (f:Fact)-[:TAGGED_WITH]->(t:Tag {name: "VR30"})
RETURN f

// Find facts related to a specific fact (connection discovery)
MATCH (f1:Fact {id: $factId})-[:RELATED_TO]-(f2:Fact)
RETURN f2
ORDER BY f2.confidence DESC
LIMIT 5

// Find cross-domain methodology patterns
MATCH (f1:Fact)-[:BELONGS_TO]->(p1:Project {domain: "automotive"})
MATCH (f2:Fact)-[:BELONGS_TO]->(p2:Project {domain: "culinary"})
MATCH (f1)-[:SAME_METHODOLOGY]-(f2)
RETURN f1, f2, p1.name, p2.name

// Get knowledge graph for user (all facts + relationships)
MATCH (p:Project {userId: $userId})
MATCH (p)-[:USES]->(f:Fact)
OPTIONAL MATCH (f)-[r:RELATED_TO]-(f2:Fact)
RETURN p, f, r, f2
LIMIT 500

// Time-lapse query (facts created over time)
MATCH (f:Fact)
WHERE f.createdAt >= $startDate AND f.createdAt <= $endDate
RETURN f
ORDER BY f.createdAt ASC
```

**Sync Strategy (PostgreSQL → Neo4j):**

1. When fact verified in PostgreSQL (via Prisma):
   ```typescript
   // After Prisma create
   await prisma.fact.create({ data: { ... } })

   // Create node in Neo4j
   await neo4jSession.run(`
     CREATE (f:Fact {
       id: $id,
       claim: $claim,
       tier: $tier,
       confidence: $confidence,
       createdAt: datetime($createdAt)
     })
   `, { id, claim, tier, confidence, createdAt })
   ```

2. Create relationships:
   ```typescript
   // Tag relationships
   for (const tag of tags) {
     await neo4jSession.run(`
       MERGE (t:Tag {name: $tag})
       MATCH (f:Fact {id: $factId})
       CREATE (f)-[:TAGGED_WITH]->(t)
     `, { tag, factId })
   }

   // Project relationship
   await neo4jSession.run(`
     MATCH (p:Project {id: $projectId})
     MATCH (f:Fact {id: $factId})
     CREATE (f)-[:BELONGS_TO]->(p)
   `, { projectId, factId })
   ```

3. Background job for relationship detection:
   ```typescript
   // Run nightly (find related facts by tag similarity, methodology patterns)
   // Use vector embeddings (pgvector) for semantic similarity
   // Create RELATED_TO edges in Neo4j
   ```

---

## API Design

### REST Endpoints

**Authentication:**
```
POST   /api/auth/signup        Create account
POST   /api/auth/signin        Login
POST   /api/auth/signout       Logout
GET    /api/auth/session       Get current session
```

**Projects:**
```
GET    /api/projects           List user's projects
POST   /api/projects           Create new project
GET    /api/projects/:id       Get single project
PUT    /api/projects/:id       Update project
DELETE /api/projects/:id       Delete project
GET    /api/projects/:id/stats Get project stats (facts count, confidence avg)
```

**Facts (Verification):**
```
GET    /api/facts                   List facts (filterable by project, tier, tags)
POST   /api/facts/verify            Verify new fact
GET    /api/facts/:id               Get single fact
PUT    /api/facts/:id               Update fact
DELETE /api/facts/:id               Delete fact
GET    /api/facts/search?q=VR30     Search facts (full-text)
GET    /api/facts/related/:id       Get related facts (from graph)
```

**Content:**
```
GET    /api/content              List content
POST   /api/content              Create content
GET    /api/content/:id          Get single content
PUT    /api/content/:id          Update content
DELETE /api/content/:id          Delete content
POST   /api/content/:id/publish  Publish content
GET    /api/content/:id/export   Export (Markdown, PDF)
```

**Knowledge Graph:**
```
GET    /api/graph/nodes          Get all nodes for user
GET    /api/graph/connections    Get relationships
GET    /api/graph/search?q=VR30  Search graph
GET    /api/graph/timeline?from=2024-10-01&to=2024-10-31  Time-lapse data
```

**Conversation Logs:**
```
GET    /api/logs                 List logs
POST   /api/logs                 Create log
GET    /api/logs/:id             Get single log
DELETE /api/logs/:id             Delete log
GET    /api/logs/export/:id      Export log (Markdown, PDF)
```

### API Response Format

**Success:**
```json
{
  "success": true,
  "data": {
    "id": "clxyz123",
    "claim": "VR30 bore x stroke: 86mm x 86mm",
    "tier": 1,
    "confidence": 95
  }
}
```

**Error:**
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Confidence must be between 0 and 100",
    "field": "confidence"
  }
}
```

### Rate Limiting

**Strategy:** Token bucket algorithm
**Limits:**
- Anonymous: 10 requests/minute
- Authenticated: 100 requests/minute
- Premium users (future): 500 requests/minute

**Implementation:** Upstash Redis (serverless, Vercel-compatible)

---

## Security

### Authentication & Authorization

**Session Management:**
- HTTP-only cookies (not accessible via JavaScript)
- Secure flag (HTTPS only)
- SameSite=Lax (CSRF protection)
- 30-day expiration (refresh on activity)

**Password Requirements:**
- Minimum 8 characters
- At least 1 uppercase, 1 lowercase, 1 number
- bcrypt hashing (cost factor: 12)

**OAuth Providers:**
- Google
- GitHub
- (Future: Twitter, LinkedIn)

**Authorization:**
- Row-level security (users can only access their own projects/facts)
- Prisma middleware enforces user scoping:
  ```typescript
  prisma.$use(async (params, next) => {
    if (params.model === 'Project' && params.action === 'findMany') {
      params.args.where = { ...params.args.where, userId: currentUserId }
    }
    return next(params)
  })
  ```

### Data Validation

**Input Validation:**
- Zod schemas for all API endpoints
- Example:
  ```typescript
  const verifyFactSchema = z.object({
    claim: z.string().min(10).max(1000),
    source: z.string().min(5).max(500),
    tier: z.number().int().min(1).max(3),
    confidence: z.number().int().min(0).max(100),
    tags: z.array(z.string()).max(10)
  })
  ```

**Output Sanitization:**
- HTML sanitization for rich text (DOMPurify)
- SQL injection prevention (Prisma parameterized queries)
- XSS prevention (React escapes by default, sanitize user-generated HTML)

### API Security

**CORS:**
- Allowed origins: production domain, staging domain, localhost (dev)
- Credentials: true (cookies)

**CSRF Protection:**
- NextAuth.js handles CSRF tokens automatically
- Double-submit cookie pattern

**Rate Limiting:**
- See Rate Limiting section above
- 429 status code when exceeded

---

## Performance Optimization

### Front-End

**Code Splitting:**
- Route-based (automatic with Next.js App Router)
- Component-based (dynamic imports for heavy components):
  ```typescript
  const KnowledgeGraphCanvas = dynamic(() => import('@/components/KnowledgeGraphCanvas'), {
    loading: () => <GraphSkeleton />,
    ssr: false // Graph rendering client-only
  })
  ```

**Image Optimization:**
- next/image (automatic WebP, lazy loading, responsive sizes)
- Cloudinary transformations (resize, format, quality)
- Blur placeholders (LQIP)

**Font Optimization:**
- next/font (self-hosted fonts, no external requests)
- Font subsetting (only characters used)
- Swap display strategy (show fallback immediately)

**Caching:**
- TanStack Query (5-minute default cache)
- Service Worker (future: offline support)
- CDN (Vercel Edge Network)

**Bundle Size:**
- Tree shaking (Tailwind purges unused CSS)
- Component lazy loading
- Target: <200KB initial JS bundle

### Back-End

**Database Optimization:**
- Indexed columns (see @@index in Prisma schema)
- Connection pooling (Prisma default: 10 connections)
- Query optimization (select only needed fields, avoid N+1 queries)

**Neo4j Performance:**
- Indexed properties (id, tags, createdAt)
- Limit query results (500 nodes max for visualization)
- Pagination for large result sets

**Caching Strategy:**
- Redis for:
  - Session storage
  - Rate limiting
  - API response caching (facts list, graph nodes)
- Cache invalidation on data mutation

**API Response Time Targets:**
- GET requests: <200ms (p95)
- POST requests: <500ms (p95)
- Graph queries: <1s (p95)

---

## Deployment Strategy

### Environments

**Development:**
- Local machine
- PostgreSQL: Docker container
- Neo4j: Docker container or Neo4j Desktop
- Next.js: `npm run dev`

**Staging:**
- Vercel preview deployment (automatic per PR)
- Railway PostgreSQL
- Neo4j Aura (free tier)
- Domain: staging.builderplatform.com

**Production:**
- Vercel production deployment
- Railway PostgreSQL (or AWS RDS if scaling)
- Neo4j Aura (paid tier)
- Domain: builderplatform.com

### CI/CD Pipeline

**GitHub Actions Workflow:**

```yaml
name: CI/CD

on:
  pull_request:
  push:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm ci
      - run: npm run type-check
      - run: npm run lint
      - run: npm run test
      - run: npm run build

  deploy-staging:
    if: github.ref == 'refs/heads/develop'
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: vercel/action@v2
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          vercel-args: '--prod'
          working-directory: ./

  deploy-production:
    if: github.ref == 'refs/heads/main'
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: vercel/action@v2
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          vercel-args: '--prod'
          alias: builderplatform.com
```

### Database Migrations

**Process:**
1. Create migration: `npx prisma migrate dev --name add_fact_table`
2. Review generated SQL
3. Test migration on staging
4. Apply to production: `npx prisma migrate deploy` (in CI/CD)

**Rollback Strategy:**
- Keep migration history in git
- Manual rollback if needed: create reverse migration
- Database backups (Railway automatic daily backups)

---

## Monitoring & Observability

### Error Tracking (Sentry)

**Events Tracked:**
- Unhandled exceptions
- API errors (500s)
- Database errors
- Neo4j connection errors

**Alerts:**
- Slack notification for critical errors
- Email for error rate spike (>10/minute)

### Performance Monitoring (Vercel Analytics + Sentry)

**Metrics:**
- Core Web Vitals (LCP, FID, CLS)
- API response times
- Database query times
- Graph query times

**Alerts:**
- LCP >2.5s (warn)
- API p95 >1s (warn)
- Error rate >1% (critical)

### Product Analytics (PostHog)

**Events:**
```typescript
// Track verification
posthog.capture('fact_verified', {
  tier: 1,
  confidence: 95,
  domain: 'automotive'
})

// Track connection suggestion accepted
posthog.capture('connection_accepted', {
  from_project: 'Q50',
  to_project: 'S7',
  cross_domain: false
})

// Track graph visualization viewed
posthog.capture('graph_viewed', {
  nodes_visible: 127,
  time_spent_seconds: 45
})
```

**Dashboards:**
- User acquisition funnel
- Verification workflow completion rate
- Knowledge graph growth over time
- Feature usage (which features used most)

---

## Testing Strategy

### Unit Tests (Vitest)

**Coverage Target:** 80%+

**What to Test:**
- Utility functions (confidence calculation, tag parsing)
- React components (rendering, user interactions)
- API route handlers (validation, business logic)

**Example:**
```typescript
describe('calculateConfidence', () => {
  it('returns 100 for all Tier 1 sources', () => {
    const facts = [
      { tier: 1, confidence: 95 },
      { tier: 1, confidence: 100 }
    ]
    expect(calculateConfidence(facts)).toBe(97.5)
  })
})
```

### Integration Tests (Playwright)

**Critical Flows:**
- Sign up → Create project → Verify first fact → See celebration
- Write content → Insert citation → Publish
- View knowledge graph → Click node → See details

**Example:**
```typescript
test('verification workflow', async ({ page }) => {
  await page.goto('/projects/123/research')
  await page.click('text=Verify Fact')
  await page.fill('[name=claim]', 'VR30 bore: 86mm')
  await page.selectOption('[name=tier]', '1')
  await page.fill('[name=confidence]', '95')
  await page.click('text=Verify ✓')

  // Assert celebration shown
  await expect(page.locator('text=Fact verified!')).toBeVisible()

  // Assert fact appears in list
  await expect(page.locator('text=VR30 bore: 86mm')).toBeVisible()
})
```

### Load Testing (k6)

**Scenarios:**
- 100 concurrent users verifying facts
- 50 concurrent users viewing graph (500 nodes)
- 200 requests/second to API

**Target:** p95 response time <1s under load

---

## Scalability Plan

### Current Architecture (0-1,000 users)

- Next.js on Vercel (scales automatically)
- Railway PostgreSQL (16GB RAM, 4 CPU)
- Neo4j Aura (4GB storage, grows to 16GB)
- Cloudinary (100GB bandwidth/month)

### Future Scaling (1,000-10,000 users)

**Database:**
- PostgreSQL: Migrate to AWS RDS (vertical scaling to 64GB RAM)
- Neo4j: Upgrade to larger Aura instance or self-hosted cluster
- Add read replicas (PostgreSQL) for analytics queries

**Caching:**
- Redis cluster (Upstash or AWS ElastiCache)
- Cache frequently accessed facts, graph nodes
- CDN for static assets (already handled by Vercel)

**API:**
- Consider separating API from Next.js (dedicated NestJS backend)
- Horizontal scaling (multiple API instances behind load balancer)
- GraphQL layer for complex queries (reduce over-fetching)

### Future Scaling (10,000+ users)

**Microservices:**
- Authentication service (separate from main API)
- Graph service (dedicated Neo4j query layer)
- Background job service (fact relationship detection, analytics)

**Event-Driven Architecture:**
- Message queue (RabbitMQ or AWS SQS)
- Fact verified → emit event → background worker creates graph node
- Decouple synchronous operations

**Database Sharding:**
- Shard PostgreSQL by user ID (if single instance bottleneck)
- Neo4j federation (if graph grows too large for single instance)

---

## Cost Estimates

### MVP (10 users, Month 1-3)

| Service | Plan | Cost/Month |
|---|---|---|
| Vercel | Hobby (free) | $0 |
| Railway PostgreSQL | 8GB RAM | $20 |
| Neo4j Aura | Free tier | $0 |
| Cloudinary | Free tier (25GB) | $0 |
| GitHub Actions | Free (public repo) | $0 |
| Sentry | Free tier (5k errors/mo) | $0 |
| PostHog | Free tier (1M events/mo) | $0 |
| **Total** | | **$20/month** |

### Growth (100 users, Month 4-6)

| Service | Plan | Cost/Month |
|---|---|---|
| Vercel | Pro | $20 |
| Railway PostgreSQL | 16GB RAM | $50 |
| Neo4j Aura | Paid tier (8GB) | $65 |
| Cloudinary | Paid tier (100GB) | $50 |
| Sentry | Paid tier | $26 |
| PostHog | Paid tier | $0 (still free) |
| **Total** | | **$211/month** |

### Scale (1,000 users, Month 7-12)

| Service | Plan | Cost/Month |
|---|---|---|
| Vercel | Pro | $20 |
| AWS RDS PostgreSQL | 32GB RAM | $250 |
| Neo4j Aura | 16GB | $130 |
| Cloudinary | Enterprise | $200 |
| Sentry | Paid tier | $89 |
| PostHog | Paid tier | $450 |
| Upstash Redis | Pro | $50 |
| **Total** | | **$1,189/month** |

**Revenue Target:** $29/user/month → 1,000 users = $29,000/month revenue
**Gross Margin:** $29k - $1.2k = $27.8k (96% margin)

---

## Security Checklist

- [ ] HTTPS enforced (Vercel automatic)
- [ ] Environment variables secure (Vercel encrypted)
- [ ] Database credentials rotated quarterly
- [ ] API rate limiting enabled
- [ ] Input validation (Zod schemas)
- [ ] Output sanitization (DOMPurify for rich text)
- [ ] CORS configured correctly
- [ ] CSRF protection (NextAuth.js)
- [ ] XSS prevention (React escaping)
- [ ] SQL injection prevention (Prisma parameterized)
- [ ] Authentication secure (HTTP-only cookies, bcrypt)
- [ ] Authorization enforced (row-level security)
- [ ] Dependency scanning (Dependabot)
- [ ] Security headers (Helmet.js or Next.js config)
- [ ] Regular security audits (quarterly)

---

## Next Steps

**Week 1 Actions:**
1. Initialize Next.js 14 project
2. Set up PostgreSQL (Railway) + Prisma
3. Install ShadCN/UI
4. Create base design system (colors, fonts, spacing)
5. Set up GitHub Actions CI/CD
6. Deploy to Vercel (staging environment)

**Week 2 Actions:**
7. Implement authentication (choose NextAuth.js or Clerk)
8. Create user profile flow
9. Build dashboard layout
10. Test on real devices

---

**Document Status:** Implementation-ready. Team can begin development immediately with complete technical specification.

**Dependencies:** This spec assumes UI/UX specification and feature implementation plan are approved.
