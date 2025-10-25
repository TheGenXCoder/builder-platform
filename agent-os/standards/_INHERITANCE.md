# Agent-OS Spec Inheritance System

**Builder Platform Hierarchical Specification System**

**Last Updated:** 2025-10-15
**Status:** Core System Documentation

---

## Inheritance Hierarchy

This project implements a **three-level hierarchical spec inheritance system**:

```
Level 1: System (~/.agent-os/)
    ↓ inherits from
Level 2: Project (~/personal/builder-platform/agent-os/)
    ↓ inherits from
Level 3: Subproject (builds/*/. agent-os/)
```

### Inheritance Principles

1. **Reference in Place**: Child specs reference parent specs, they don't copy them
2. **Additive by Default**: Children ADD to parent specs, rarely override
3. **Explicit Overrides**: Any override must be marked with `**OVERRIDE**` and include rationale
4. **Transparency**: All inheritance relationships must be documented in spec headers

---

## Level 1: System (~/.agent-os/)

**Location:** `~/.agent-os/profiles/default/`

**Scope:** Universal standards across ALL projects on this system

**Source:** BuilderMethods Agent-OS base installation

**Standards Included:**
- Global coding standards (architectural-decisions, coding-style, commenting, etc.)
- Precision language standards
- Fact verification protocols
- Context management
- Tech stack conventions
- Frontend standards (components, CSS, accessibility, responsive)
- Backend standards (API, models, queries, migrations)
- Testing standards

**When to Reference:**
All project-level and subproject-level specs should reference applicable system-level standards.

---

## Level 2: Project (agent-os/ in this repository)

**Location:** `/Users/BertSmith/personal/builder-platform/agent-os/`

**Scope:** Builder Platform-specific standards that apply to ALL builds/subprojects

**Inherits From:** Level 1 (System)

**Extends With:**
- Domain-agnostic quality methodologies
- Builder Platform-specific verification workflows
- Platform conventions and patterns
- Cross-domain knowledge compounding principles

**Standards Include:**
- Enhanced fact verification (extends system with source tier hierarchy)
- Writing style guide (domain-agnostic language precision)
- Conversation logging system (platform-specific context preservation)
- Quality standards for multi-domain content creation

**Platform-Specific Standards Location:**
`platform/standards/` - These are the SOURCE files that agent-os references

---

## Level 3: Subproject (builds/*/.agent-os/)

**Location:** `builds/<project-name>/.agent-os/`

**Scope:** Domain-specific standards for individual builds (automotive, culinary, etc.)

**Inherits From:**
- Level 1 (System via Level 2)
- Level 2 (Project)

**Extends With:**
- Domain-specific technical requirements
- Project-specific verification procedures
- Specialized knowledge and terminology
- Build-specific workflows

**Examples:**
- `builds/q50-super-saloon/.agent-os/` - Automotive domain standards
- `builds/cassoulet-study/.agent-os/` - Culinary domain standards

---

## Spec Inheritance Header Format

All project and subproject specs MUST include an inheritance header:

```markdown
# [Standard Name]

**Inherits From:**
- System: `~/.agent-os/profiles/default/standards/[category]/[file].md`
- Project: `~/personal/builder-platform/agent-os/standards/[file].md`
- (or) Project: `~/personal/builder-platform/platform/standards/[file].md`

**Spec Level:** [Project | Subproject]
**Last Updated:** [Date]
**Status:** [Active | Draft | Deprecated]

---

## Inherited Standards

[Brief summary of what is inherited and from where]

---

## Project/Subproject Extensions

[Additions specific to this level]

---

## Overrides

**OVERRIDE:** [Specific thing being overridden]
**Rationale:** [Why this override is necessary]
**Original:** [What the parent spec said]
**New:** [What this spec changes it to]
```

---

## Usage Guidelines

### For Agents Reading Specs

1. **Start at the current level**: Read the most specific (deepest) spec first
2. **Follow inheritance chain**: If spec references parent, read parent next
3. **Apply additively**: Combine all levels unless explicit override exists
4. **Respect overrides**: If marked `**OVERRIDE**`, child spec takes precedence

### For Humans Writing Specs

1. **Check parent specs first**: Don't duplicate what's already inherited
2. **Reference, don't copy**: Use inheritance headers to point to parent specs
3. **Add, don't replace**: Extensions should be additive unless absolutely necessary
4. **Document overrides**: Make overrides explicit and justified

### For New Projects/Subprojects

1. **Install agent-os at appropriate level**: Use agent-os install script
2. **Create inheritance references**: Add `_INHERITANCE.md` to document hierarchy
3. **Extend, don't duplicate**: Reference parent standards, add domain-specific requirements
4. **Test inheritance chain**: Verify all parent specs are accessible

---

## File Organization

```
builder-platform/
├── agent-os/                               # Level 2: Project
│   ├── config.yml                          # Project config
│   ├── standards/
│   │   ├── _INHERITANCE.md                 # This file
│   │   └── builder-platform/               # Platform-specific extensions
│   │       ├── fact-verification-enhanced.md
│   │       ├── writing-style-guide.md
│   │       └── conversation-logging.md
│   └── workflows/                          # Extended workflows
│
├── platform/                               # Platform source files
│   ├── standards/                          # SOURCE (referenced by agent-os)
│   │   ├── fact-verification-protocol.md
│   │   ├── writing-style-guide.md
│   │   └── conversation-logging-system.md
│   └── specifications/
│
└── builds/
    └── q50-super-saloon/                   # Level 3: Subproject
        └── .agent-os/
            ├── config.yml                  # Subproject config
            └── standards/
                ├── _INHERITANCE.md         # Subproject inheritance doc
                └── automotive/             # Domain-specific
                    ├── vr30-specifications.md
                    └── automotive-verification.md
```

---

## Benefits of This System

1. **D.R.Y. Principle**: Standards defined once, referenced everywhere
2. **Consistency**: System-level standards ensure baseline quality across all projects
3. **Flexibility**: Each level can extend without duplicating
4. **Traceability**: Clear inheritance chain shows where standards come from
5. **Scalability**: Add new projects/subprojects without rewriting standards
6. **Maintainability**: Update parent specs, all children inherit improvements

---

## Validation

To verify inheritance chain is working:

1. **Check spec headers**: All specs have inheritance documentation
2. **Verify file references**: All referenced parent specs exist and are accessible
3. **Test agent understanding**: Ask agent to summarize standards - should include all levels
4. **Audit overrides**: Review all `**OVERRIDE**` markers for necessity

---

## Questions or Issues?

If inheritance chain is unclear or specs conflict:

1. Check `_INHERITANCE.md` at each level
2. Verify parent specs are accessible from current location
3. Look for `**OVERRIDE**` markers explaining conflicts
4. Ensure agent-os installation is up to date at all levels

---

**The hierarchy exists to serve quality. When standards conflict with outcomes, document the learning and improve the standards.**
