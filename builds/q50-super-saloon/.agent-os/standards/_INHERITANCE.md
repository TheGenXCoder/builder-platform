# Q50 Super Saloon - Spec Inheritance Documentation

**Subproject:** Q50 Super Saloon (Automotive Domain)
**Hierarchy Level:** 3 (Subproject)
**Last Updated:** 2025-10-15
**Status:** Active

---

## Inheritance Chain

This subproject inherits from THREE levels:

```
Level 1: System (~/.agent-os/profiles/default/)
    ↓
Level 2: Project (~/personal/builder-platform/agent-os/)
    ↓
Level 3: THIS SUBPROJECT (builds/q50-super-saloon/.agent-os/)
```

### What Each Level Provides

**Level 1 - System (BuilderMethods Agent-OS):**
- Universal coding standards
- Base precision language rules
- Fact verification workflow
- Context management
- Frontend/backend/testing standards

**Level 2 - Project (Builder Platform):**
- Authoritative Craftsman voice
- Domain-agnostic quality philosophy
- 95%+ confidence requirement
- Source tier hierarchy (Tier 1/2/3)
- 20% conversation logging trigger
- Graph RAG vision
- Cost-conscious quality principles
- Gentleman's Weapon philosophy

**Level 3 - Subproject (Q50 Super Saloon - THIS LEVEL):**
- Automotive-specific source examples
- VR30/7AT/AWD technical requirements
- Build-specific verification procedures
- Automotive domain terminology
- Performance testing standards

---

## Standards Hierarchy

### Inherited Standards (Automatically Apply)

All standards from Level 1 and Level 2 apply to this subproject:

**From System:**
- `~/.agent-os/profiles/default/standards/global/precision-language.md`
- `~/.agent-os/profiles/default/standards/global/fact-verification.md`
- `~/.agent-os/profiles/default/standards/global/context-management.md`
- `~/.agent-os/profiles/default/standards/global/coding-style.md`
- All other global, frontend, backend, testing standards

**From Builder Platform:**
- `~/personal/builder-platform/agent-os/standards/builder-platform/fact-verification.md`
- `~/personal/builder-platform/agent-os/standards/builder-platform/writing-style.md`
- `~/personal/builder-platform/agent-os/standards/builder-platform/conversation-logging.md`

**From Platform Source Files:**
- `~/personal/builder-platform/platform/standards/fact-verification-protocol.md`
- `~/personal/builder-platform/platform/standards/writing-style-guide.md`
- `~/personal/builder-platform/platform/standards/conversation-logging-system.md`

### Subproject Extensions (This Level Adds)

**Automotive-Specific Standards:**
- `./standards/automotive/vr30-specifications.md` - VR30DDTT engine specs and verification
- `./standards/automotive/source-tiers-automotive.md` - Automotive domain source tier examples
- `./standards/automotive/performance-testing.md` - Track/dyno testing standards

**Build-Specific:**
- Technical requirements specific to Q50 platform
- Verification procedures for forced induction claims
- Performance target definitions
- Cost-benefit analysis standards for modifications

---

## How Inheritance Works

### Additive by Default

Subproject standards ADD to parent standards, they don't replace them.

**Example:**
- **System says:** "Quantify all performance claims"
- **Project adds:** "95%+ confidence required for build decisions"
- **Subproject adds:** "VR30 boost claims require Tier 1 source (FSM) or 2+ Tier 2 sources (tuning shops)"

All three apply. Subproject is most specific, but doesn't override parents.

### When Overrides Are Necessary

**RARE cases where subproject must override parent:**

Must be marked `**OVERRIDE**` with clear rationale.

**Example (hypothetical):**
```markdown
**OVERRIDE:** Automotive domain uses "horsepower" abbreviation "hp" on first reference.

**Rationale:** Industry-standard abbreviation universally understood in automotive context. Full "horsepower" spelling adds no clarity and reduces readability in technical specifications.

**Original (from system):** "Spell out units on first reference"
**New (subproject):** "Use 'hp' for horsepower in automotive technical docs"
```

### Conflict Resolution

If specs appear to conflict:

1. **Check if it's actually an extension** (adding detail) vs override (changing requirement)
2. **Extensions are normal** - more specific guidance for domain
3. **True overrides must have `**OVERRIDE**` marker** with rationale
4. **If unmarked conflict:** It's a documentation bug - needs fixing

---

## Usage Guidelines

### For Agents Working on Q50 Build

**When performing tasks:**

1. **Start at THIS level** - Read q50-super-saloon/.agent-os/standards first
2. **Follow inheritance chain** - If spec references parent, read parent next
3. **Apply all levels** - System + Project + Subproject all apply
4. **Respect specificity** - Most specific (subproject) provides detail, not replacement

**Example: Fact Verification**

Reading order:
1. `./standards/automotive/source-tiers-automotive.md` (THIS LEVEL - most specific)
2. `~/personal/builder-platform/agent-os/standards/builder-platform/fact-verification.md` (Project)
3. `~/personal/builder-platform/platform/standards/fact-verification-protocol.md` (Project source)
4. `~/.agent-os/profiles/default/standards/global/fact-verification.md` (System)

Result: Combine all four. Use automotive-specific tier examples, apply 95%+ rule, follow base workflow.

### For Humans Updating Specs

**When adding new subproject standards:**

1. **Check parent specs first** - Don't duplicate what's already inherited
2. **Reference, don't copy** - Use inheritance headers pointing to parents
3. **Add domain-specific detail** - Examples, procedures, terminology
4. **Document any overrides** - Make explicit and justified

---

## Subproject-Specific Context

### Build Vision
600-800hp gentleman's weapon. Friday night gala, Saturday morning track terror.

### Build Philosophy
- 80/20 street/track split
- Understated elegance with undeniable capability
- Cost-conscious quality (KW coilovers, pull-a-part control arms)
- Everything verified, documented, shared

### Technical Focus Areas
- VR30DDTT forced induction limits
- 7AT power handling capacity
- AWD system characteristics
- Suspension geometry optimization
- Cost-benefit analysis for modifications

### Verification Requirements
All VR30 performance claims require:
- Tier 1 source (Factory Service Manual, OEM TSB), OR
- 2+ Tier 2 sources (established tuning shops with documented builds)

95%+ confidence on:
- Power handling limits (engine, transmission, driveline)
- Forced induction thresholds
- Cost estimates for modifications
- Performance targets and timelines

---

## File Organization

```
builds/q50-super-saloon/
├── .agent-os/                          # Subproject agent-os
│   ├── config.yml                      # Subproject config
│   └── standards/
│       ├── _INHERITANCE.md             # This file
│       └── automotive/                 # Domain-specific standards
│           ├── vr30-specifications.md
│           ├── source-tiers-automotive.md
│           └── performance-testing.md
│
├── research/                           # Research specifications
│   ├── technical-research-spec.md
│   └── historical-research-spec.md
│
├── content/                            # Content creation
├── build-log/                          # Build planning and progress
└── media/                              # Photos, videos, graphics
```

---

## Benefits of This Hierarchy

**For This Build:**
1. **Automotive expertise** - Domain-specific guidance without rewriting universal standards
2. **Consistency** - Same quality standards as all Builder Platform work
3. **Traceability** - Clear chain showing where requirements come from
4. **Efficiency** - Don't duplicate universal standards, just extend them

**For Future Builds:**
5. **Template** - Other automotive builds can reference these same extensions
6. **Cross-domain learning** - Culinary or woodworking builds use same structure, different domain
7. **Platform improvement** - Lessons learned here improve parent specs for all projects

---

## Questions or Issues?

**If inheritance chain is unclear:**
1. Check `_INHERITANCE.md` at each level (this file, project level, system level)
2. Verify all referenced parent specs are accessible
3. Look for `**OVERRIDE**` markers if specs seem to conflict

**If specs conflict:**
1. Determine if it's extension (adding detail) or override (changing requirement)
2. If override, check for `**OVERRIDE**` marker and rationale
3. If unmarked conflict, it's a bug - document and fix

---

**The hierarchy serves the build. Specs exist to ensure quality, not create bureaucracy.**

**If standards conflict with good outcomes, document the learning and improve the standards.**
