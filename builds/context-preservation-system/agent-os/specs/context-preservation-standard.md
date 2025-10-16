# CONTEXT PRESERVATION STANDARD v1.0

**System-Level Standard for Claude Code Context Management**

**Last Updated:** October 15, 2025
**Status:** Specification

---

## Core Principle

**Context loss is unacceptable. Preserve proactively, recover gracefully.**

Every Claude Code session generates decisions, work, and momentum. Context preservation ensures zero data loss through continuous monitoring, automatic preservation, and recovery mechanisms.

**If context exists, context persists.**

---

## Context Monitoring Requirements

### Real-Time Awareness

**Claude Code MUST continuously monitor context usage:**

1. **Internal Awareness**
   - Track current context usage percentage
   - Know proximity to auto-compact threshold
   - Anticipate preservation triggers

2. **User Communication**
   - Display current context usage in status
   - Warn proactively at threshold approaches
   - Never silently approach limits

3. **Proactive Triggers**
   - 70% threshold: Issue warning to user
   - 80% threshold: Automatic preservation + compact
   - 90% threshold: SHOULD NEVER REACH (preservation at 80% prevents this)

### Threshold Definitions

**Context Usage Thresholds:**

| Threshold | Action | Rationale |
|-----------|--------|-----------|
| 0-69% | Normal operation | Ample headroom for work |
| 70% | Warning issued | Give user heads-up |
| 80% | **AUTOMATIC PRESERVATION + COMPACT** | Prevent data loss |
| 90%+ | **FAILURE STATE** | Should never reach (80% trigger prevents) |

**Why 80% Auto-Compact:**
- Provides 20% safety buffer before 100% limit
- Prevents auto-compact from starting before preservation completes
- Ensures logging finishes before context exhausted
- Better to compact early than lose context at 100%

---

## Preservation Mechanisms

### 1. Working File (.working.md)

**Purpose:** Current session state for immediate recovery

**Location:** `[project-root]/.working.md`

**Update Triggers:**
- Every 15 minutes during active work
- After major user decisions or direction changes
- Before risky operations (large file reads, PDF parsing, etc.)
- At 70% context warning
- At 80% preservation trigger (before compact)

**Required Contents:**
```markdown
# Working Context - [ISO-8601 timestamp]

**Status:** [Active / Checkpointed / Pre-Error-Dump / Ready-for-Compact]
**Context Usage:** [X%]
**Session Duration:** [HH:MM]

---

## Session Overview

**Project:** [Project name or "Builder Platform"]
**Initial Goal:** [User's original request]
**Current Focus:** [What's being worked on right now]

---

## Progress Summary

### Completed
- [✅ Task 1 with brief outcome]
- [✅ Task 2 with brief outcome]

### In Progress
- [🔄 Current task with current status]

### Pending
- [⏳ Next task]
- [⏳ Following task]

---

## Key Decisions Made

1. **[Decision topic]:** [What was decided and why]
2. **[Decision topic]:** [What was decided and why]

---

## Files Modified This Session

**Created:**
- `path/to/file.ext` - [Purpose]

**Modified:**
- `path/to/file.ext` - [What changed]

**Git Status:**
```
[Output of git status --short]
```

---

## Important Context

**User Preferences/Corrections:**
- [Any user teaching moments or corrections]

**Technical Decisions:**
- [Architecture choices, tech stack decisions]

**Blockers/Issues:**
- [Any problems encountered]

---

## Recovery Instructions

**If Claude Code crashed or became unusable:**

1. **Review This File:**
   - Last completed task: [task name]
   - Current work state: [description]
   - Next step planned: [next action]

2. **Check Git Status:**
   ```bash
   cd [project-root]
   git status
   git diff
   ```

3. **Resume Session:**
   - Start new Claude Code session
   - Say: "I need to recover context from .working.md"
   - Continue from: [last completed task]

4. **Files to Review:**
   - This file (.working.md)
   - Session log: `conversation-logs/[YYYY-MM]/session-[timestamp].md`
   - Git commits from this session

---

**Next Checkpoint:** [timestamp + 15 minutes] or at 80% context usage
```

### 2. Session Logs (conversation-logs/)

**Purpose:** Complete session history for long-term preservation

**Location:** `conversation-logs/[YYYY-MM]/session-[timestamp].md`

**Format:** `session-2025-10-15-1430.md` (YYYY-MM-DD-HHMM)

**Update Pattern:** Incremental appends throughout session

**Required Structure:**
```markdown
# Session Log: [YYYY-MM-DD] - [Session Title]

**Project:** [Project name]
**Started:** [ISO-8601 timestamp]
**Status:** [Active / Completed / Recovered]
**Final Context Usage:** [X%]

---

## Session Goal

[User's initial request or goal for this session]

---

## [HH:MM] - Session Started

**Initial Context:**
- [What was the starting point?]
- [What files/info were read initially?]

**Plan:**
- [How did we plan to approach this?]

---

## [HH:MM] - [Milestone/Decision/Update]

**Progress:**
- [What was accomplished?]
- [What files were created/modified?]

**Decisions:**
- [Any technical or strategic decisions made?]

**Learnings:**
- [Any corrections, teaching moments, or discoveries?]

---

## [HH:MM] - Context Checkpoint (70% Warning)

**Context Status:** 70% used, 30% remaining

**Work Preserved:**
- [Summary of work up to this point]

**Continuing with:** [What's next]

---

## [HH:MM] - Context Preservation (80% Trigger)

**Context Status:** 80% used, 20% remaining

**AUTOMATIC PRESERVATION TRIGGERED:**
1. ✅ Working file updated: `.working.md`
2. ✅ Session log updated: this file
3. ✅ Git status checked and logged
4. ✅ Ready for context compact

**Work Summary:**
- [Complete summary of session work]
- [All decisions made]
- [All files created/modified]

**Next Steps After Compact:**
- [What to do when resuming]

---

## Session Summary

**Completed:**
- [Major accomplishments]

**Decisions:**
- [Key decisions made]

**Files:**
- [All files created/modified]

**Outcome:**
- [Success / Partial / Needs-Continuation]

---

## Tag Index

#context-preservation #[project-tags] #[topic-tags] #[decision-tags]

---

**Session Duration:** [HH:MM]
**Context Usage:** [Final %]
**Compacted:** [Yes/No - timestamp if yes]
```

### 3. Pre-Risky-Operation Dumps

**Risky Operations Include:**
- Reading PDF files (known to cause errors)
- Reading very large files (>1MB)
- Complex multi-file operations
- Web fetches that might fail
- Any operation that has caused errors before

**Required Action Before Risky Operation:**
```markdown
[Proactive preservation message to user:]

"I'm about to [risky operation]. Let me update .working.md first
in case of errors..."

[Update .working.md with current state]

"✅ Context preserved to .working.md. Proceeding with [operation]..."
```

**If Operation Fails:**
```markdown
"❌ Error occurred: [error description]

✅ Context was preserved before this operation.

Recovery options:
1. Review .working.md for current state
2. Continue session from last checkpoint
3. If Claude Code is unstable, exit and restart with /resume or
   by saying 'Recover context from .working.md'

Current working file: .working.md
Session log: conversation-logs/[date]/session-[timestamp].md
"
```

---

## Automatic Preservation Workflow

### 70% Context Warning

**Trigger:** Context usage reaches 70%

**Action Sequence:**
1. **Warn User:**
   ```
   ⚠️ Context Usage: 70%

   I'll automatically preserve and compact at 80%.
   Current work will be saved to .working.md and session log.

   We have room for approximately [X more exchanges] before
   preservation triggers.
   ```

2. **Update Working File:**
   - Refresh .working.md with current state
   - Ensure recovery instructions current

3. **Continue Work:**
   - No interruption needed
   - User can keep working

### 80% Context Preservation

**Trigger:** Context usage reaches 80%

**Action Sequence:**
1. **Announce Preservation:**
   ```
   🔔 Context Usage: 80% - Automatic preservation triggered

   Preserving context before compacting...
   ```

2. **Update Working File:**
   - Complete .working.md update
   - Set status: "Ready-for-Compact"
   - Include full recovery instructions

3. **Update Session Log:**
   - Append "Context Preservation (80% Trigger)" section
   - Full session summary up to this point
   - List all files modified
   - Document all decisions

4. **Check Git Status:**
   - Log current git status
   - Note any uncommitted changes
   - Include in both .working.md and session log

5. **Inform User:**
   ```
   ✅ Context preserved:
   - Working file: .working.md
   - Session log: conversation-logs/[date]/session-[timestamp].md
   - Git status logged

   Ready to compact. Would you like to:
   1. Continue in new context (I'll /compact)
   2. Commit current work first
   3. Review preservation before compacting
   ```

6. **After User Approval:**
   - Execute /compact
   - Start fresh with summary from preservation
   - Continue work seamlessly

### Session End Preservation

**Trigger:** User signals session end or natural stopping point

**Action Sequence:**
1. **Final Working File Update:**
   - Status: "Session Complete"
   - Final summary

2. **Final Session Log Update:**
   - Session Summary section
   - Final context usage
   - Outcome/status

3. **Git Recommendation:**
   ```
   Session complete. Recommended git actions:

   1. Review changes: git status
   2. Commit session work: git add [files] && git commit
   3. Session log is tracked: conversation-logs/[date]/...

   All context preserved for future sessions.
   ```

---

## Error Recovery Procedures

### When Claude Code Errors Occur

**Immediate Action:**
1. **Don't Panic:** Context was preserved proactively
2. **Don't Exit Yet:** Try to preserve additional context if possible
3. **Preserve Now:** Update .working.md if Claude Code still responsive

**If Claude Code Becomes Unusable:**
1. **Exit safely**
2. **Review .working.md** - Contains last known state
3. **Review session log** - Contains full session history
4. **Check git status** - See what was modified
5. **Restart Claude Code**
6. **Resume:** Say "I need to recover context from .working.md"

### Recovery Message Template

When user requests recovery:

```markdown
I'll help you recover from [error/crash/context-loss].

**Context Sources Found:**
✅ Working file: .working.md (last updated: [timestamp])
✅ Session log: conversation-logs/[date]/session-[timestamp].md
✅ Git status: [clean / X modified files]

**Last Known State:**
- Session goal: [goal]
- Last completed: [task]
- Current focus was: [work]
- Next planned: [next-task]

**Files Modified:**
[list from .working.md]

**Ready to continue from: [last-checkpoint]**

Shall we continue with [next-planned-task]?
```

---

## Integration with Existing Standards

### Enhances conversation-logging.md

**Existing standard (conversation-logging.md) says:**
- Log at 20% remaining (80% used)
- Manual trigger required
- Format specified for logs

**This standard adds:**
- **Automatic** preservation at 80% (not manual)
- **Continuous** .working.md updates (not just at threshold)
- **Error recovery** mechanisms (new capability)
- **Pre-risky-operation** dumps (new safety)

**Compatibility:**
- Maintains 80% threshold (was "20% remaining")
- Uses same log format for session logs
- Adds .working.md as complementary mechanism
- All conversation-logging.md guidance still applies

---

## Implementation Requirements

### For Claude Code (Me)

**I MUST:**
1. Monitor context usage continuously
2. Warn at 70%, preserve at 80%
3. Update .working.md per trigger schedule
4. Preserve before risky operations
5. Provide recovery instructions when errors occur
6. Never reach 90% context (80% trigger prevents this)
7. Make preservation automatic and seamless

**I MUST NOT:**
1. Wait for manual triggers (automate it)
2. Skip preservation steps (all are required)
3. Proceed with risky operations without preservation
4. Let context reach 100% (catastrophic)
5. Lose user work due to crashes

### For System Integration

**Required Files:**
- `~/.agent-os/standards/context-preservation.md` (this file)
- `~/.claude/CLAUDE.md` (inject preservation behavior)
- Standards must be inherited by all projects

**Auto-Generated Files:**
- `.working.md` in project root
- `conversation-logs/[YYYY-MM]/session-[timestamp].md`

**Git Tracking:**
- Both .working.md and conversation-logs/ should be tracked
- Commit session logs at session end
- .working.md can be in .gitignore or tracked (user preference)

---

## Success Criteria

**This standard is successful when:**

✅ Zero context loss events occur
✅ Users work confidently without fear of data loss
✅ Preservation happens automatically without user action
✅ Errors result in recovery, not data loss
✅ 80% trigger prevents 90%+ context usage
✅ Working file always reflects current state
✅ Session logs capture complete history

---

## Validation Checklist

**To validate this standard is working:**

- [ ] Context warning appears at 70%
- [ ] Automatic preservation triggers at 80%
- [ ] .working.md updates every 15 minutes during active work
- [ ] .working.md updates before risky operations
- [ ] Session log appends throughout session
- [ ] Recovery from simulated error successful
- [ ] User can resume work from .working.md without data loss
- [ ] Git status logged at preservation points
- [ ] Never reach 90%+ context usage

---

**This standard makes context loss impossible through proactive automation, not hopeful manual processes.**

**Context is too valuable to lose. Preserve it.**
