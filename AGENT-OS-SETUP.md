# Agent-OS Setup & Hierarchical Spec Inheritance System

**Builder Platform - Agent-OS Integration Guide**

**Last Updated:** 2025-10-15
**Status:** Active System Documentation

---

## Overview

This project implements a **three-level hierarchical spec inheritance system** combining BuilderMethods Agent-OS with Builder Platform's domain-agnostic quality methodology.

**Key Principle:** Children inherit from parents and add to, but rarely override.

---

## Three-Level Hierarchy

```
Level 1: System (~/.agent-os/)
    ↓ inherits from
Level 2: Project (builder-platform/agent-os/)
    ↓ inherits from
Level 3: Subproject (builds/*/. agent-os/)
```

### Level 1: System (~/.agent-os/)

**Location:** `~/.agent-os/profiles/default/`

**Scope:** Universal standards across ALL projects on this system

**Provides:**
- BuilderMethods Agent-OS base installation
- Global coding standards (architectural-decisions, coding-style, commenting)
- Base precision language standards
- Universal fact verification workflow
- Context management principles
- Frontend/backend/testing standards (components, API, models, queries, etc.)

**Managed By:** BuilderMethods Agent-OS installation script

**Updated Via:** `~/agent-os/scripts/project-update.sh`

---

### Level 2: Project (builder-platform/agent-os/)

**Location:** `/Users/BertSmith/personal/builder-platform/agent-os/`

**Scope:** Builder Platform-specific standards applying to ALL builds/subprojects

**Inherits From:** Level 1 (System)

**Extends With:**
- Authoritative Craftsman voice and tone
- Domain-agnostic quality methodology
- 95%+ confidence requirement
- Source tier hierarchy (Tier 1/2/3) with domain examples
- 20% conversation logging trigger
- Graph RAG architecture vision
- Cost-conscious quality philosophy
- Gentleman's Weapon concept

**Key Files:**
- `agent-os/config.yml` - Project configuration
- `agent-os/standards/_INHERITANCE.md` - Inheritance documentation
- `agent-os/standards/builder-platform/fact-verification.md` - References `platform/standards/fact-verification-protocol.md`
- `agent-os/standards/builder-platform/writing-style.md` - References `platform/standards/writing-style-guide.md`
- `agent-os/standards/builder-platform/conversation-logging.md` - References `platform/standards/conversation-logging-system.md`

**Platform Source Files (Referenced in Place):**
- `platform/standards/fact-verification-protocol.md` - SOURCE for fact verification
- `platform/standards/writing-style-guide.md` - SOURCE for writing standards
- `platform/standards/conversation-logging-system.md` - SOURCE for logging system

**Claude Code Integration:**
- `.claude/commands/agent-os/` - Agent-OS commands (new-spec, create-spec, implement-spec, plan-product)
- `.claude/agents/agent-os/` - Specialized agents (spec-writer, researcher, implementers, verifiers)

---

### Level 3: Subproject (builds/*/.agent-os/)

**Location:** `builds/<project-name>/.agent-os/`

**Scope:** Domain-specific standards for individual builds

**Inherits From:**
- Level 1 (System via Level 2)
- Level 2 (Project)

**Extends With:**
- Domain-specific technical requirements (automotive, culinary, etc.)
- Project-specific verification procedures
- Specialized knowledge and terminology
- Build-specific workflows

**Example - Q50 Super Saloon:**
- `builds/q50-super-saloon/.agent-os/config.yml` - Subproject config with inheritance chain
- `builds/q50-super-saloon/.agent-os/standards/_INHERITANCE.md` - Subproject inheritance docs
- `builds/q50-super-saloon/.agent-os/standards/automotive/source-tiers-automotive.md` - Automotive source examples

---

## Directory Structure

```
builder-platform/
├── agent-os/                                    # LEVEL 2: Project
│   ├── config.yml                               # Project agent-os config
│   ├── standards/
│   │   ├── _INHERITANCE.md                      # Inheritance system docs
│   │   ├── global/                              # From ~/.agent-os (copied)
│   │   │   ├── precision-language.md
│   │   │   ├── fact-verification.md
│   │   │   ├── context-management.md
│   │   │   └── [18 other global/frontend/backend/testing standards]
│   │   └── builder-platform/                    # Platform extensions
│   │       ├── fact-verification.md             # → references platform/standards/
│   │       ├── writing-style.md                 # → references platform/standards/
│   │       └── conversation-logging.md          # → references platform/standards/
│   └── workflows/                               # From ~/.agent-os (if customized)
│
├── .claude/                                     # Claude Code integration
│   ├── commands/agent-os/                       # Slash commands
│   │   ├── new-spec.md
│   │   ├── create-spec.md
│   │   ├── implement-spec.md
│   │   └── plan-product.md
│   └── agents/agent-os/                         # Specialized agents
│       ├── spec-initializer.md
│       ├── spec-researcher.md
│       ├── spec-writer.md
│       ├── spec-verifier.md
│       ├── [implementer agents]
│       └── [verifier agents]
│
├── platform/                                    # Platform source files
│   ├── standards/                               # SOURCE (referenced by agent-os)
│   │   ├── fact-verification-protocol.md
│   │   ├── writing-style-guide.md
│   │   └── conversation-logging-system.md
│   └── specifications/
│       ├── ui-ux-specification.md
│       ├── tech-architecture-spec.md
│       └── feature-implementation-plan.md
│
└── builds/
    └── q50-super-saloon/                        # LEVEL 3: Subproject
        ├── .agent-os/
        │   ├── config.yml                       # Subproject config (inherits from parent)
        │   └── standards/
        │       ├── _INHERITANCE.md              # Subproject inheritance docs
        │       └── automotive/                  # Domain-specific
        │           ├── source-tiers-automotive.md
        │           ├── vr30-specifications.md
        │           └── performance-testing.md
        ├── research/
        ├── content/
        └── build-log/
```

---

## Inheritance Mechanism

### Reference in Place (Not Copy)

**Children reference parent specs, they don't copy them.**

Example header in child spec:

```markdown
# Automotive Domain Source Tiers

**Inherits From:**
- System: `~/.agent-os/profiles/default/standards/global/fact-verification.md`
- Project: `~/personal/builder-platform/agent-os/standards/builder-platform/fact-verification.md`
- Project Source: `~/personal/builder-platform/platform/standards/fact-verification-protocol.md`

**Spec Level:** Subproject (Q50 Super Saloon - Automotive Domain)

---

## Inherited Standards

[Brief summary of what is inherited]

---

## Subproject Extensions

[Automotive-specific additions - examples, procedures, etc.]

---

## No Overrides

This spec ADDS domain-specific detail but does NOT override parent requirements.
```

### Additive by Default

Children ADD to parents, rarely override.

**Example:**
- **System:** "Quantify all performance claims"
- **Project:** "95%+ confidence required for build decisions"
- **Subproject:** "VR30 boost claims require Tier 1 source OR 2+ Tier 2 sources"

All three apply. Most specific provides detail, doesn't replace.

### Explicit Overrides

**RARE cases requiring override must be marked:**

```markdown
**OVERRIDE:** [Specific thing being overridden]
**Rationale:** [Why this override is necessary]
**Original (parent spec):** [What parent said]
**New (this level):** [What this changes it to]
```

**Example (hypothetical):**
```markdown
**OVERRIDE:** Automotive domain uses "hp" abbreviation on first reference.

**Rationale:** Industry-standard abbreviation universally understood. Full "horsepower" adds no clarity.

**Original:** "Spell out units on first reference"
**New:** "Use 'hp' for horsepower in automotive technical docs"
```

---

## Usage Guide

### For AI Agents

**When performing tasks in Builder Platform:**

1. **Identify your context level:**
   - Project-wide task → Start at Level 2 (agent-os/standards/)
   - Subproject-specific → Start at Level 3 (builds/*/.agent-os/standards/)

2. **Read inheritance chain:**
   - Start at most specific (current level)
   - Follow `**Inherits From:**` headers
   - Read all referenced parent specs

3. **Apply all levels additively:**
   - System + Project + Subproject (if applicable)
   - Most specific provides detail, not replacement
   - Respect `**OVERRIDE**` markers if present

4. **Example workflow for fact verification in Q50 build:**
   ```
   1. Read builds/q50-super-saloon/.agent-os/standards/automotive/source-tiers-automotive.md
   2. Follow inheritance to agent-os/standards/builder-platform/fact-verification.md
   3. Follow reference to platform/standards/fact-verification-protocol.md
   4. Follow inheritance to ~/.agent-os/profiles/default/standards/global/fact-verification.md
   5. Apply all four: Automotive examples + 95% rule + platform workflow + base principles
   ```

### For Humans

**When adding new standards:**

1. **Check inheritance chain first** - Don't duplicate what's inherited
2. **Reference parent specs** - Use inheritance headers
3. **Add domain-specific detail** - Examples, procedures, terminology
4. **Document overrides explicitly** - Mark with `**OVERRIDE**` and rationale

**When creating new subproject:**

1. **Create .agent-os/ directory** in project root
2. **Add config.yml** with inheritance chain
3. **Create standards/_INHERITANCE.md** documenting hierarchy
4. **Add domain-specific standards** as needed
5. **Reference parent specs** in inheritance headers

---

## Agent-OS Commands

**Available via Claude Code:**

- `/new-spec` - Initialize new specification with basic structure
- `/create-spec` - Create comprehensive specification (multi-agent workflow)
- `/implement-spec` - Implement specification with task breakdown
- `/plan-product` - Plan product with mission, roadmap, tech stack

**All commands respect inheritance hierarchy and Builder Platform standards.**

---

## Specialized Agents

**Available in .claude/agents/agent-os/:**

**Specification Workflow:**
- `spec-initializer` - Initialize spec structure
- `spec-researcher` - Research for spec creation
- `spec-writer` - Write comprehensive specs
- `spec-verifier` - Verify spec quality and completeness

**Implementation Workflow:**
- `api-engineer` - API implementation
- `database-engineer` - Database implementation
- `ui-designer` - UI/UX implementation
- `testing-engineer` - Test implementation
- `frontend-verifier` - Frontend verification
- `backend-verifier` - Backend verification
- `implementation-verifier` - Overall verification

**All agents follow Builder Platform standards (voice, fact verification, precision language).**

---

## Validation

### Verify Inheritance Chain

**Check each level:**

1. **System level exists:**
   ```bash
   ls -la ~/.agent-os/profiles/default/standards/
   ```

2. **Project level installed:**
   ```bash
   ls -la agent-os/standards/
   ls -la .claude/commands/agent-os/
   ls -la .claude/agents/agent-os/
   ```

3. **Subproject level (if applicable):**
   ```bash
   ls -la builds/q50-super-saloon/.agent-os/standards/
   ```

### Verify Spec Headers

**All project and subproject specs should have:**
- `**Inherits From:**` section listing parent specs
- `**Spec Level:**` designation (Project or Subproject)
- `**Last Updated:**` date
- Inheritance description (what's inherited, what's added)

### Test Agent Understanding

**Ask agent to summarize standards:**
- "What are the fact verification requirements for this project?"
- "What source tier should I use for VR30 power claims?"
- "What's the conversation logging trigger?"

**Agent should combine all levels in response.**

---

## Maintenance

### Updating System Level (~/.agent-os/)

```bash
cd ~/agent-os
git pull  # If agent-os is git-managed
# OR follow BuilderMethods update instructions
```

**Then update project:**
```bash
cd ~/personal/builder-platform
~/agent-os/scripts/project-update.sh
```

### Updating Project Level

**Edit platform source files:**
- `platform/standards/fact-verification-protocol.md`
- `platform/standards/writing-style-guide.md`
- `platform/standards/conversation-logging-system.md`

**Agent-os wrapper files automatically reference updated sources.**

### Updating Subproject Level

**Edit subproject standards directly:**
- `builds/q50-super-saloon/.agent-os/standards/automotive/*.md`

**No propagation needed - changes are local to subproject.**

---

## Benefits

### For Solo Developer

1. **Consistency:** Same quality standards across all projects
2. **Efficiency:** Don't rewrite universal standards for each project
3. **Specialization:** Domain-specific guidance without duplication
4. **Scalability:** Add new projects/domains without starting from scratch
5. **Quality:** System-level standards ensure baseline across everything

### For Platform

1. **D.R.Y.:** Standards defined once, referenced everywhere
2. **Traceability:** Clear chain showing where requirements come from
3. **Flexibility:** Each level extends without duplicating
4. **Maintainability:** Update parent, all children inherit improvements
5. **Knowledge Compounding:** Lessons learned improve standards for all projects

---

## Common Questions

**Q: Do I need to read all three levels for every task?**
A: Agents should read the inheritance chain. Humans can usually start at the most specific level and follow references as needed.

**Q: What if specs conflict?**
A: Check if it's an extension (adding detail) vs override (changing requirement). Extensions are normal. Overrides must have `**OVERRIDE**` marker with rationale. If unmarked conflict, it's a documentation bug.

**Q: Can I add project-specific standards without subproject?**
A: Yes. Project-level standards apply to all builds. Subproject standards are optional for domain-specific extensions.

**Q: How do I know which level to add a new standard?**
A:
- Universal across ALL projects? → System level (rare, usually BuilderMethods adds these)
- Builder Platform-specific, applies to all builds? → Project level
- Domain-specific (automotive, culinary, etc.)? → Subproject level

**Q: What happens if I update a platform source file (platform/standards/)?**
A: Agent-os wrapper files reference them in place, so updates automatically apply. No additional steps needed.

---

## Next Steps

1. **Read `agent-os/standards/_INHERITANCE.md`** for project-level hierarchy details
2. **Review `.claude/commands/agent-os/`** for available slash commands
3. **Explore `.claude/agents/agent-os/`** for specialized agents
4. **Check subproject examples** (e.g., `builds/q50-super-saloon/.agent-os/`)
5. **Use `/new-spec` or `/create-spec`** to start leveraging the system

---

**The hierarchy exists to serve quality. Specs exist to ensure excellence, not create bureaucracy.**

**When standards enable good outcomes, they're working. When they conflict with good outcomes, document the learning and improve the standards.**
