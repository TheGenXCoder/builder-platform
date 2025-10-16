# SYSTEM-LEVEL INTEGRATION SPECIFICATION

**Context Preservation System → System-Level Agent-OS Standards**

**Version:** 1.0
**Date:** October 15, 2025

---

## Objective

Install context preservation standards as system-level defaults that apply to ALL Claude Code sessions automatically.

**No per-project configuration. Universal behavior.**

---

## Installation Locations

### Primary Standard Location

**File:** `~/.agent-os/standards/context-preservation.md`

**Content:** Core context preservation standard (condensed version)

**Purpose:** System-level standard inherited by all Agent-OS project installations

### Global Instruction Integration

**File:** `~/.claude/CLAUDE.md`

**Addition:** Context preservation behavior section

**Purpose:** Inject preservation requirements into Claude Code's global instructions

---

## ~/.agent-os/standards/context-preservation.md

**This file contains:**

1. **Core Principle** - Context loss is unacceptable
2. **Threshold Requirements** - 70% warn, 80% preserve
3. **Working File Spec** - .working.md format and update triggers
4. **Session Log Spec** - conversation-logs/ format and structure
5. **Error Recovery** - Procedures when crashes occur
6. **Integration Notes** - How this enhances existing standards

**Key Content (Condensed):**
```markdown
# CONTEXT PRESERVATION STANDARD

## Core Requirements

**Automatic Context Monitoring:**
- 70% usage → Warning
- 80% usage → Preserve + Compact
- Continuous .working.md updates
- Session logs in conversation-logs/

**Preservation Triggers:**
- Every 15 minutes during active work
- Before risky operations (PDF read, large files)
- At 70% warning
- At 80% auto-preservation
- At session end

**Working File:** `.working.md`
- Current session state
- Recovery instructions
- Git status
- Todo list state

**Session Logs:** `conversation-logs/[YYYY-MM]/session-[timestamp].md`
- Full session history
- Incremental appends
- Preservation checkpoints

**Error Recovery:**
1. Context preserved proactively
2. .working.md contains recovery point
3. Session log contains full history
4. Git tracks all changes
5. Resume work without data loss

See full specification: [link to detailed spec]
```

---

## ~/.claude/CLAUDE.md Integration

**Section to Add:**

```markdown
# Context Preservation (System-Level Standard)

**Automatic Context Management for All Sessions**

## Core Behavior Requirements

**I MUST continuously monitor context usage and preserve proactively:**

1. **Context Monitoring:**
   - Track usage in real-time
   - Warn at 70% usage
   - Automatically preserve at 80% usage
   - Never reach 90%+ (80% trigger prevents)

2. **Working File (.working.md):**
   - Update every 15 minutes during active work
   - Update before risky operations (PDF reads, large files)
   - Update at 70% and 80% thresholds
   - Include recovery instructions always
   - Location: Project root

3. **Session Logs (conversation-logs/):**
   - Create on session start: `conversation-logs/[YYYY-MM]/session-[timestamp].md`
   - Append incrementally throughout session
   - Full preservation at 80% threshold
   - Final summary at session end

4. **Preservation Triggers:**
   - **70% Context:** Warn user, update .working.md
   - **80% Context:** Full preservation, then compact
   - **Pre-risky-op:** Update .working.md first
   - **Session end:** Final preservation

5. **Error Recovery:**
   - Before risky operations, preserve context
   - If error occurs, provide recovery instructions
   - Point user to .working.md and session log
   - Enable seamless resume

## Working File Format

```markdown
# Working Context - [timestamp]

**Status:** [Active/Checkpointed/Ready-for-Compact]
**Context Usage:** [X%]

## Session Overview
[Goal and current focus]

## Progress Summary
### Completed
[✅ tasks]
### In Progress
[🔄 current]
### Pending
[⏳ next]

## Key Decisions
[Important decisions made]

## Files Modified
[Git status output]

## Recovery Instructions
[How to resume if error occurs]
```

## Automatic Preservation Workflow

**At 70% Context:**
```
⚠️ Context Usage: 70%
Automatic preservation will trigger at 80%.
.working.md updated. Continuing work...
```

**At 80% Context:**
```
🔔 Context Usage: 80% - Preservation triggered

Preserving context:
✅ .working.md updated
✅ Session log updated
✅ Git status logged

Ready to compact. Continue in fresh context?
```

## Integration with Existing Standards

This enhances conversation-logging.md with automation:
- Same 80% threshold (was "20% remaining")
- Adds automatic triggering
- Adds .working.md for immediate recovery
- Adds pre-error preservation

## Validation

✅ Context warning at 70%
✅ Auto-preservation at 80%
✅ .working.md current
✅ Session log complete
✅ Error recovery works
✅ Never lose context

---

**Context preservation is automatic, not manual. I preserve proactively.**
```

---

## Implementation Steps

### Step 1: Create System-Level Standard

```bash
# Ensure ~/.agent-os/standards/ exists
mkdir -p ~/.agent-os/standards/

# Copy condensed standard
cp [spec-file] ~/.agent-os/standards/context-preservation.md
```

### Step 2: Update Global Instructions

```bash
# Backup existing CLAUDE.md
cp ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.backup

# Append context preservation section
cat context-preservation-claude-section.md >> ~/.claude/CLAUDE.md
```

### Step 3: Validate Installation

**Check files exist:**
```bash
ls -lh ~/.agent-os/standards/context-preservation.md
ls -lh ~/.claude/CLAUDE.md
```

**Verify content:**
- Open CLAUDE.md, confirm new section present
- Open context-preservation.md, confirm standard readable

### Step 4: Test Behavior

**Start new Claude Code session in test project:**

1. **Check automatic behavior:**
   - Does Claude Code mention context monitoring?
   - Does .working.md get created?

2. **Simulate 70% threshold:**
   - Do lots of work to approach threshold
   - Verify warning appears
   - Verify .working.md updates

3. **Test recovery:**
   - Create .working.md with test content
   - Exit Claude Code
   - Restart and request recovery
   - Verify context restored from .working.md

---

## Rollback Procedure

**If issues occur:**

```bash
# Restore CLAUDE.md
cp ~/.claude/CLAUDE.md.backup ~/.claude/CLAUDE.md

# Remove standard (optional)
rm ~/.agent-os/standards/context-preservation.md
```

**Restart Claude Code to apply rollback.**

---

## Success Criteria

**Installation is successful when:**

✅ `~/.agent-os/standards/context-preservation.md` exists and is readable
✅ `~/.claude/CLAUDE.md` contains context preservation section
✅ New Claude Code sessions automatically mention context monitoring
✅ .working.md gets created and updated automatically
✅ Session logs appear in conversation-logs/
✅ 70% warning appears when context approaches threshold
✅ 80% preservation triggers automatically
✅ Error recovery works (test with simulated crash)

---

## Maintenance

**Updating the standard:**

1. Edit `~/.agent-os/standards/context-preservation.md`
2. Update `~/.claude/CLAUDE.md` section if needed
3. Restart Claude Code to apply changes
4. Test with validation checklist

**Versioning:**

- Track changes in git
- Document version updates in standard file header
- Test after changes

---

## Distribution

**Sharing with other users:**

1. Provide installation script
2. Include both files (standard + CLAUDE.md section)
3. Include validation checklist
4. Document rollback procedure

**Potential BuilderMethods contribution:**

- Once validated in real-world use
- After Phase 3 (real-world validation)
- With comprehensive documentation
- As optional enhancement to Agent-OS

---

**This integration makes context preservation the default behavior for all Claude Code sessions, not an opt-in feature.**
