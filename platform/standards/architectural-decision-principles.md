# Architectural Decision Principles

**The Builder Platform - Technical Decision-Making Framework**

**Last Updated:** October 7, 2024
**Status:** Core Platform Standard
**Applies To:** All technical architecture, vendor selection, infrastructure, and integration decisions

---

## Core Philosophy

**"Never back the cat into a corner."**

Every architectural decision must be reversible. We optimize for **flexibility over premature optimization**, **adaptability over vendor lock-in**, and **learning over dogma**.

---

## The 2-Way Door Principle

### Origin

Borrowed from Amazon's Leadership Principles:

- **1-Way Door Decision:** Irreversible. Going through it closes the door behind you. Requires extensive analysis, consensus, slow deliberation.
- **2-Way Door Decision:** Reversible. Don't like the outcome? Walk back through. Make these fast, experiment, learn.

**Most decisions are 2-way doors disguised as 1-way doors.**

### Platform Application

**Default Assumption:** Every technical decision is (or can be made) a 2-way door.

**How to create 2-way doors:**
1. **Abstraction layers** - Own the interface, swap implementations
2. **Standard protocols** - Use open standards, avoid proprietary formats
3. **Data portability** - Always own your data, clean export paths
4. **Adapter patterns** - Pluggable components, dependency injection
5. **Feature flags** - Test new approaches alongside existing ones

**When 1-way doors are acceptable:**
- Core platform differentiators (knowledge graph architecture, verification methodology)
- Fundamental language/framework choices with massive migration costs
- **MUST document why it's 1-way and what alternatives were considered**

---

## Decision Framework

### Before Any Major Technical Decision:

**1. Identify the door type:**
```
[ ] 2-way door (reversible)
[ ] 1-way door (irreversible)
[ ] Disguised 2-way door (looks irreversible but can be made reversible)
```

**2. For disguised 2-way doors, design the escape hatch:**
```
- What abstraction layer makes this reversible?
- What's the cost of that abstraction? (hours, complexity, performance)
- What's the cost of being locked in? (vendor pricing, technical debt, lost opportunity)
- Does abstraction cost < lock-in risk? → Build abstraction
```

**3. Document the decision:**
```
Decision: [What we're choosing]
Type: [2-way door / 1-way door]
Escape Hatch: [How we reverse this if needed]
Cost of Abstraction: [X hours, Y complexity]
Cost of Lock-in: [Vendor pricing, migration difficulty, lost flexibility]
Decision Date: [YYYY-MM-DD]
Review Date: [When we'll reassess this decision]
```

---

## Real-World Examples

### Example 1: Authentication Provider

**Decision:** NextAuth.js vs Clerk

**Door Type:** Disguised 2-way door (looks like vendor lock-in, but abstraction layer makes it reversible)

**Escape Hatch Design:**
```typescript
// Own the auth interface
interface AuthProvider {
  signIn(credentials: Credentials): Promise<User>
  signOut(): Promise<void>
  getSession(): Promise<Session | null>
  getCurrentUser(): Promise<User | null>
}

// Pluggable adapters
class NextAuthAdapter implements AuthProvider { ... }
class ClerkAdapter implements AuthProvider { ... }

// Application code only uses OUR interface
const auth = getAuthProvider()
const user = await auth.getCurrentUser()
```

**Cost of Abstraction:** +2 hours (Week 2), thin wrapper interface

**Cost of Lock-in:**
- NextAuth: 40+ hours to migrate away, security maintenance burden
- Clerk: $4k-6k/year at scale, vendor dependency, data sovereignty concerns

**Decision:** Start with NextAuth + abstraction layer
- Own data from day 1 (aligns with platform promise)
- No pricing surprises at scale
- Can swap to Clerk adapter in 2 hours if auth maintenance becomes burden
- **User decides WHEN to switch, not forced by market conditions**

**Review Date:** Month 3 (reassess if auth maintenance burden exceeds expectation)

---

### Example 2: Database Choice

**Decision:** PostgreSQL + Prisma

**Door Type:** 2-way door (with effort)

**Escape Hatch:**
- Prisma supports multiple databases (PostgreSQL, MySQL, SQLite, MongoDB)
- Schema migrations portable across databases
- ORM abstracts database-specific SQL
- Cost to switch databases: ~5-10 hours for schema adjustments, ~2-5 hours testing

**Why this is acceptable:**
- PostgreSQL is open source (no vendor lock-in)
- Can self-host or use any managed provider (AWS RDS, Railway, Supabase, Neon)
- Prisma ORM provides database portability
- **We own the data, can export anytime**

---

### Example 3: UI Component Library

**Decision:** ShadCN/UI

**Door Type:** True 2-way door

**Why:**
- Components copied into YOUR codebase (not npm dependency)
- Built on Radix UI primitives (can use Radix directly if needed)
- Tailwind CSS classes (easy to migrate to any CSS framework)
- No vendor, no versioning lock-in
- **You own the code, modify freely**

**Cost to switch:** Low (components are just React + Tailwind, easily portable)

---

## Anti-Patterns to Avoid

### ❌ Proprietary Data Formats
**Bad:** Storing knowledge graph in vendor-specific format (Firebase, MongoDB proprietary features)
**Good:** Neo4j with Cypher (open standard, exportable, multiple compatible databases)

### ❌ Tightly Coupled Vendor SDKs
**Bad:** Sprinkling `clerk.users.get()` throughout codebase
**Good:** `auth.getCurrentUser()` with Clerk adapter hidden behind YOUR interface

### ❌ "We'll Migrate Later" Mentality
**Bad:** "Let's use Clerk now, we can always migrate to NextAuth"
**Reality:** Migration costs grow exponentially with user base and feature surface area
**Good:** Build abstraction NOW (2 hours), swap adapters LATER (2 hours)

### ❌ Framework Lock-In Without Portability
**Bad:** Building business logic inside Next.js API routes with Next.js-specific features
**Good:** Business logic in pure TypeScript services, Next.js routes as thin adapters

---

## Platform-Specific Guidelines

### Data Ownership is Non-Negotiable

**Rule:** User data (research, facts, content, conversation logs) MUST live in OUR database.

**Acceptable external dependencies:**
- Authentication metadata (if using Clerk) - synced to our DB
- Media storage (S3, Cloudinary) - with export paths
- Analytics (PostHog, Mixpanel) - supplementary, not primary source of truth

**Unacceptable:**
- Storing verified facts in vendor database without local copy
- Knowledge graph relationships managed by proprietary service
- Content locked in vendor CMS without export API

**The Platform Promise:** "Your knowledge compounds forever, YOU own your data"
**This is 1-way door by design** - if we compromise data ownership, we lose platform identity.

---

## Vendor Selection Criteria

When evaluating ANY vendor or service, ask:

**1. Data Portability**
- ✅ Clean export API (JSON, CSV, SQL dump)
- ✅ No proprietary data formats
- ✅ Documented migration paths

**2. Pricing Transparency**
- ✅ Clear free tier limits
- ✅ Predictable scaling costs
- ✅ No surprise overages or forced upgrades

**3. Open Standards**
- ✅ Uses open protocols (OAuth, OpenID, REST, GraphQL)
- ✅ Avoids proprietary APIs where possible
- ✅ Compatible with multiple implementations

**4. Self-Hosting Option**
- ✅ Can we run this ourselves if vendor disappears?
- ✅ Open source alternative exists?
- ✅ Exit strategy documented?

**5. Abstraction Cost**
- ✅ Can we build thin wrapper? (<5% complexity overhead)
- ✅ Interface stable enough to abstract?
- ✅ Worth the flexibility gained?

---

## Review Process

**Quarterly Review (Every 3 Months):**
- Audit all vendor dependencies
- Reassess 2-way door decisions (should we switch?)
- Update abstraction layers (new providers available?)
- Document lessons learned (what worked, what didn't)

**Before Major Milestones:**
- MVP launch: Confirm all escape hatches functional
- Product Hunt: Test scaling without forced vendor upgrades
- Series A / Revenue: Optimize costs, consider self-hosting high-cost services

---

## Success Metrics

**Good 2-Way Door Architecture:**
- Swapping providers takes hours, not weeks
- Vendor pricing changes don't force immediate action
- Technical debt from abstractions < 10% of codebase
- New team members understand provider boundaries in <1 day

**Bad Architecture (1-Way Door Hell):**
- Vendor announces price increase → forced migration
- Service sunset → scramble to rebuild
- Can't experiment with alternatives without rewriting app
- "Too expensive to change now" = permanent lock-in

---

## Questions to Ask During Code Review

**When reviewing PRs that introduce dependencies:**

1. "Is this a 2-way door or 1-way door?"
2. "What's our escape hatch if this vendor/library doesn't work out?"
3. "Should we add an abstraction layer?"
4. "Does this lock us into proprietary formats or APIs?"
5. "Can a new developer understand how to swap this out?"

---

## The Meta-Principle

**This document itself is a 2-way door.**

Don't agree with these principles? We can adapt them. Find a better framework? We'll adopt it. Discover AWS has improved on this? We'll iterate.

**The only 1-way door: The commitment to building a platform that respects user data ownership and avoids backing ourselves (or our users) into corners.**

---

## References & Further Reading

- **Amazon 2-Way Door Principle:** Jeff Bezos 2015 Shareholder Letter
- **Dependency Inversion Principle:** SOLID design patterns (Uncle Bob)
- **Adapter Pattern:** Gang of Four Design Patterns
- **Data Portability:** GDPR Article 20 (Right to Data Portability)
- **Vendor Lock-In Costs:** "The Economics of Cloud Vendor Lock-In" (various studies)

---

## Tag Index

#architectural-decisions #2-way-doors #vendor-selection #abstraction-layers #data-ownership #reversibility #flexibility #technical-debt #platform-standards #aws-principles #dependency-management #escape-hatches

---

**Status:** Living document. Update as we encounter new decision types and learn from experience.

**Next Review:** 2025-01-07 (Quarterly review after MVP launch)
