# CONTEXT PRESERVATION STANDARD v1.0

**System-Level Standard for Claude Code**

**Location:** `~/.agent-os/standards/context-preservation.md`

---

## Core Principle

**Context loss is unacceptable. Preserve proactively, recover gracefully.**

Continuous monitoring, automatic preservation, and recovery mechanisms ensure zero data loss in all Claude Code sessions.

---

## Automatic Context Monitoring

### Thresholds

| Usage | Action |
|-------|--------|
| 70% | ⚠️ Warning + .working.md update |
| 80% | 🔔 **Auto-preserve + compact** |
| 90%+ | ❌ FAILURE (should never reach) |

### Continuous Awareness

- Track context usage in real-time
- Warn proactively at thresholds
- Preserve before reaching limits
- Never silently approach 100%

---

## Preservation Mechanisms

### 1. Working File (.working.md)

**Purpose:** Current session recovery point

**Location:** `[project-root]/.working.md`

**Update Triggers:**
- Every 15 minutes during active work
- Before risky operations (PDF reads, large files)
- At 70% context warning
- At 80% preservation trigger
- At session end

**Format:**
```markdown
# Working Context - [timestamp]

**Status:** [Active/Checkpointed/Ready-for-Compact]
**Context Usage:** [X%]
**Session Duration:** [HH:MM]

## Session Overview
**Initial Goal:** [User's request]
**Current Focus:** [What's being worked on]

## Progress Summary
### Completed
- ✅ [Task with outcome]
### In Progress
- 🔄 [Current task]
### Pending
- ⏳ [Next task]

## Key Decisions
- [Decision and rationale]

## Files Modified
**Created:** [files]
**Modified:** [files]

**Git Status:**
```
[git status --short output]
```

## Recovery Instructions
If Claude Code crashed:
1. Review this file for last state
2. Check git status
3. Start new session: "Recover context from .working.md"
4. Continue from: [last completed task]

**Next Checkpoint:** [timestamp] or 80% context
```

### 2. Session Logs (conversation-logs/)

**Purpose:** Complete session history

**Location:** `conversation-logs/[YYYY-MM]/session-[timestamp].md`

**Format:** `session-2025-10-15-1430.md`

**Update:** Incremental appends throughout session

**Structure:**
```markdown
# Session Log: [YYYY-MM-DD] - [Title]

**Started:** [timestamp]
**Status:** [Active/Completed]
**Final Context:** [X%]

## Session Goal
[User's initial request]

## [HH:MM] - Session Started
[Initial context and plan]

## [HH:MM] - Progress Update
**Completed:** [work done]
**Decisions:** [decisions made]
**Files:** [files modified]

## [HH:MM] - Context Checkpoint (70%)
**Warning issued, .working.md updated**

## [HH:MM] - Context Preservation (80%)
**AUTOMATIC PRESERVATION TRIGGERED**
✅ Working file updated
✅ Session log updated
✅ Git status logged
✅ Ready for compact

## Session Summary
**Completed:** [accomplishments]
**Decisions:** [key decisions]
**Files:** [all modified files]
**Outcome:** [status]

## Tag Index
#context-preservation #[project] #[topics]
```

### 3. Pre-Risky-Operation Preservation

**Risky operations:**
- PDF file reads (known error source)
- Large files (>1MB)
- Complex multi-file operations
- Operations that previously caused errors

**Required before risky operation:**
```
"I'm about to [operation]. Preserving context first..."
[Update .working.md]
"✅ Context preserved. Proceeding..."
```

**If operation fails:**
```
"❌ Error: [description]

✅ Context preserved before operation.

Recovery:
- .working.md contains current state
- Session log: conversation-logs/[date]/session-[timestamp].md
- Continue or restart with context recovery
```

---

## Automatic Preservation Workflow

### At 70% Context

**Action:**
```
⚠️ Context Usage: 70%

Automatic preservation will trigger at 80%.
.working.md updated.

Approximately [X exchanges] remaining before preservation.
```

**Behind the scenes:**
- Update .working.md with current state
- Ensure recovery instructions current
- Continue work without interruption

### At 80% Context

**Action:**
```
🔔 Context Usage: 80% - Preservation triggered

Preserving context:
✅ .working.md updated (status: Ready-for-Compact)
✅ Session log updated with full checkpoint
✅ Git status logged
✅ All work preserved

Ready to compact. Options:
1. Continue in fresh context (/compact)
2. Commit current work first
3. Review preservation files
```

**Process:**
1. Update .working.md with complete state
2. Append preservation checkpoint to session log
3. Log git status
4. Inform user
5. Wait for approval
6. Compact and continue

### At Session End

**Action:**
```
Session ending. Final preservation:
✅ .working.md updated (status: Session Complete)
✅ Session log finalized
✅ All context preserved

Recommended: git commit session work
```

---

## Error Recovery

### When Errors Occur

**If Claude Code still responsive:**
1. Update .working.md immediately
2. Add "Pre-Error-Dump" status
3. Provide recovery instructions

**If Claude Code unusable:**
1. User exits safely
2. Reviews .working.md for last state
3. Restarts Claude Code
4. Requests recovery: "Recover context from .working.md"

### Recovery Message Template

```markdown
**Context Recovery**

Sources found:
✅ .working.md (updated: [timestamp])
✅ Session log: conversation-logs/[date]/session-[timestamp].md
✅ Git status: [state]

Last Known State:
- Goal: [original goal]
- Completed: [last task]
- Current: [work in progress]
- Next: [planned task]

Files Modified: [list]

Ready to continue from: [checkpoint]

Shall we proceed with: [next-task]?
```

---

## Integration with Existing Standards

### Enhances conversation-logging.md

**Existing:** Manual logging at 20% remaining (80% used)

**Adds:**
- Automatic triggering (not manual)
- Continuous .working.md updates
- Pre-error preservation
- Recovery mechanisms

**Maintains:**
- Same 80% threshold
- Same log format
- Same tag-based organization
- All existing guidance

---

## Implementation Requirements

### For Claude Code

**MUST:**
- Monitor context continuously
- Warn at 70%, preserve at 80%
- Update .working.md per schedule
- Preserve before risky operations
- Provide recovery instructions
- Never reach 90%+ context

**MUST NOT:**
- Wait for manual triggers
- Skip preservation steps
- Ignore risky operations
- Let context reach 100%
- Lose user work

### For System Integration

**Required:**
- This file in `~/.agent-os/standards/`
- Behavior injected into `~/.claude/CLAUDE.md`
- Standards inherited by all projects

**Generated:**
- `.working.md` in project roots
- `conversation-logs/[YYYY-MM]/session-*.md`

**Git:**
- Track session logs
- .working.md optional (user preference)

---

## Validation Checklist

- [ ] Warning appears at 70% context
- [ ] Auto-preservation at 80% context
- [ ] .working.md updates every 15min
- [ ] .working.md updates before risky ops
- [ ] Session log appends throughout
- [ ] Recovery from error successful
- [ ] Never reach 90%+ context
- [ ] Git status logged at checkpoints

---

## Success Criteria

✅ Zero context loss events
✅ Automatic preservation without user action
✅ Working file always reflects current state
✅ Session logs capture complete history
✅ Error recovery works reliably
✅ Users work confidently without fear of data loss

---

**Full specification:** `builds/context-preservation-system/agent-os/specs/context-preservation-standard.md`

**Integration guide:** `builds/context-preservation-system/agent-os/specs/system-level-integration.md`

---

**Context is too valuable to lose. I preserve it automatically.**
