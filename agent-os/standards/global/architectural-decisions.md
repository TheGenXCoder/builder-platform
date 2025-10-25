# Architectural Decision Principles

**Universal Technical Decision-Making Framework**

**Last Updated:** 2025-10-13
**Status:** Core Standard
**Applies To:** All technical architecture, vendor selection, infrastructure, and integration decisions

---

## Core Philosophy

**"Never back the cat into a corner."**

Every architectural decision must be reversible. Optimize for **flexibility over premature optimization**, **adaptability over vendor lock-in**, and **learning over dogma**.

---

## The 2-Way Door Principle

### Origin

Borrowed from Amazon's Leadership Principles:

- **1-Way Door Decision:** Irreversible. Going through closes the door behind you. Requires extensive analysis.
- **2-Way Door Decision:** Reversible. Don't like the outcome? Walk back through. Make these fast.

**Most decisions are 2-way doors disguised as 1-way doors.**

### Application

**Default Assumption:** Every technical decision is (or can be made) a 2-way door.

**How to create 2-way doors:**
1. **Abstraction layers** - Own the interface, swap implementations
2. **Standard protocols** - Use open standards, avoid proprietary formats
3. **Data portability** - Always own your data, clean export paths
4. **Adapter patterns** - Pluggable components, dependency injection
5. **Feature flags** - Test new approaches alongside existing ones

**When 1-way doors are acceptable:**
- Core platform differentiators (unique algorithms, novel approaches)
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

## Real-World Application Patterns

### Example: Authentication Provider

**Decision:** Self-hosted vs Managed Service

**Door Type:** Disguised 2-way door (abstraction layer makes it reversible)

**Escape Hatch Design:**
```typescript
// Own the auth interface
interface AuthProvider {
  signIn(credentials: Credentials): Promise<User>
  signOut(): Promise<void>
  getSession(): Promise<Session | null>
}

// Pluggable adapters
class SelfHostedAdapter implements AuthProvider { ... }
class ManagedServiceAdapter implements AuthProvider { ... }

// Application code only uses YOUR interface
const auth = getAuthProvider()
```

**Cost of Abstraction:** +2-4 hours upfront
**Cost of Lock-in:** 40+ hours migration + vendor pricing risks

---

### Example: Database Choice

**Decision:** PostgreSQL + ORM

**Door Type:** 2-way door (with effort)

**Escape Hatch:**
- ORM abstracts database-specific SQL
- Schema migrations portable across databases
- Can switch databases: ~5-10 hours for schema adjustments

**Why acceptable:**
- PostgreSQL is open source (no vendor lock-in)
- Can self-host or use any managed provider
- **You own the data, can export anytime**

---

## Anti-Patterns to Avoid

### ❌ Proprietary Data Formats
**Bad:** Storing data in vendor-specific format
**Good:** Open standards, exportable formats

### ❌ Tightly Coupled Vendor SDKs
**Bad:** Sprinkling vendor calls throughout codebase
**Good:** Vendor hidden behind YOUR interface

### ❌ "We'll Migrate Later" Mentality
**Bad:** "Let's use [vendor] now, we can always migrate"
**Reality:** Migration costs grow exponentially
**Good:** Build abstraction NOW (2 hours), swap adapters LATER (2 hours)

### ❌ Framework Lock-In Without Portability
**Bad:** Building business logic inside framework-specific features
**Good:** Business logic in pure code, framework as thin adapter

---

## Data Ownership Guidelines

### Non-Negotiable Rule

**User/business data MUST live in systems you control.**

**Acceptable external dependencies:**
- Authentication metadata (if synced to your DB)
- Media storage (with export paths)
- Analytics (supplementary, not primary source of truth)

**Unacceptable:**
- Core data in vendor database without local copy
- Critical relationships managed by proprietary service
- Content locked in vendor system without export API

---

## Vendor Selection Criteria

When evaluating ANY vendor or service:

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
- Document lessons learned

**Before Major Milestones:**
- MVP launch: Confirm all escape hatches functional
- Public launch: Test scaling without forced vendor upgrades
- Growth phase: Optimize costs, consider self-hosting high-cost services

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

## Code Review Questions

**When reviewing PRs that introduce dependencies:**

1. "Is this a 2-way door or 1-way door?"
2. "What's our escape hatch if this vendor/library doesn't work out?"
3. "Should we add an abstraction layer?"
4. "Does this lock us into proprietary formats or APIs?"
5. "Can a new developer understand how to swap this out?"

---

## The Meta-Principle

**This document itself is a 2-way door.**

Don't agree with these principles? Adapt them. Find a better framework? Adopt it.

**The only 1-way door: The commitment to building systems that avoid backing ourselves (and our users) into corners.**

---

## References

- **Amazon 2-Way Door Principle:** Jeff Bezos 2015 Shareholder Letter
- **Dependency Inversion Principle:** SOLID design patterns
- **Adapter Pattern:** Gang of Four Design Patterns

---

**Status:** Living document. Update as you encounter new decision types and learn from experience.
