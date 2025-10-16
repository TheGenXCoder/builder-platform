# Context Preservation System Tech Stack

**Version:** 1.0
**Last Updated:** 2025-10-15

---

## Core Technologies

### Standards Framework
- **Agent-OS 2.0.3** - Spec-driven standards for agent behavior
- **Markdown** - All standards, specifications, and logs
- **Git** - Version control for session logs and working files

### Integration Points
- **~/.agent-os/** - System-level standards directory
- **~/.claude/CLAUDE.md** - Global Claude Code instructions
- **~/.claude/settings.json** - Configuration (future use)

### File Formats
- **Markdown (.md)** - Human-readable, git-friendly, searchable
- **JSON (.json)** - Structured data where needed (minimal)

---

## Architecture Decisions

### Why Standards-Driven (Not External Scripts)?

**Reality Check:**
Claude Code doesn't have external hook system like git hooks.

**Solution:**
Standards guide Claude Code's behavior directly. I AM the hook system.

**Advantages:**
- Natural integration with Agent-OS methodology
- No fragile external dependencies
- Robust to Claude Code updates
- Works within existing architecture

### Why System-Level (~/.agent-os/)?

**Goal:** Default behavior for ALL Claude Code sessions.

**Implementation:**
- Standards in ~/.agent-os/standards/ apply globally
- Inherited by all project-level Agent-OS installations
- No per-project configuration needed
- Universal context preservation

### Why Markdown Logs?

**Requirements:**
- Human-readable for review
- Git-friendly for version control
- Searchable with standard tools (grep, etc.)
- Compatible with future Graph RAG (parse into nodes)

**Format:**
Session logs and working files both use markdown.

### Why .working.md in Project Root?

**Purpose:** Current session recovery point.

**Location:** Project root (visible, obvious, always accessible)

**Update Cadence:**
- After major decisions
- Every 15 minutes during active work
- Before risky operations (large file reads, PDF parsing)
- At 70%/80% context thresholds

---

## Context Preservation Components

### 1. Context Monitoring
**Technology:** Claude Code's internal context awareness
**Method:** I monitor my own context usage in real-time
**Thresholds:** 70% warning, 80% preservation trigger

### 2. Working File (.working.md)
**Location:** `[project-root]/.working.md`
**Update:** Continuous throughout session
**Purpose:** Current session state for error recovery
**Format:**
```markdown
# Working Context - [timestamp]

## Current Session Summary
[What's happening right now]

## Active Tasks
[Todo list state]

## Files Modified
[Git status]

## Recovery Instructions
[How to resume if error occurs]
```

### 3. Session Logs
**Location:** `conversation-logs/[YYYY-MM]/session-[timestamp].md`
**Update:** Incremental appends throughout session
**Purpose:** Complete session history
**Format:**
```markdown
# Session Log: [date] - [start-time]

## [timestamp] - Session Started
[Initial goals]

## [timestamp] - Progress Update
[Work completed]

## [timestamp] - Context Checkpoint (80%)
[Preservation trigger]
```

### 4. Error Recovery
**Mechanism:** Pre-operation context dumps
**Files:** .working.md + session log
**Instructions:** Embedded in working file
**Recovery Time:** < 2 minutes from error to resumed work

---

## Integration with Builder Platform

### Existing Standards Enhanced
- `conversation-logging.md` - Add automation, working file, error recovery
- `fact-verification-protocol.md` - No changes needed
- `writing-style-guide.md` - No changes needed

### New Standards Created
- `context-preservation.md` - Core preservation standard
- `context-monitoring.md` - Threshold and trigger specifications
- `error-recovery.md` - Recovery procedures

### File Structure
```
~/.agent-os/
├── standards/
│   ├── context-preservation.md (NEW)
│   ├── context-monitoring.md (NEW)
│   └── error-recovery.md (NEW)

~/.claude/
├── CLAUDE.md (ENHANCED - add preservation behavior)
└── settings.json (unchanged)

[project-root]/
├── .working.md (AUTO-GENERATED)
└── conversation-logs/
    └── [YYYY-MM]/
        └── session-[timestamp].md (AUTO-GENERATED)
```

---

## Future Architecture

### Graph RAG Integration (Phase 4+)
- Session logs become knowledge graph nodes
- .working.md states captured as temporal snapshots
- Neo4j for graph storage
- Vector embeddings for semantic search

### Intelligent Context Management
- Learn user's context usage patterns
- Predict when preservation needed
- Optimize threshold triggers per user
- Adaptive preservation cadence

---

## Tech Stack Rationale

| Decision | Rationale |
|----------|-----------|
| Standards-driven | Works within Claude Code's architecture |
| System-level (~/.agent-os/) | Universal default behavior |
| Markdown logs | Human-readable, git-friendly, future-proof |
| .working.md in root | Obvious location for recovery |
| Git tracking | Version control + recovery mechanism |
| No external scripts | Robust, integrated, maintainable |

---

**Tech Philosophy:**

**"Use what exists, enhance what's needed, don't build what doesn't belong."**

We work within Claude Code's architecture, not against it.
