# Context Preservation System (System-Level Standard)

**Automatic Context Management for All Claude Code Sessions**

**Standard Location:** `~/.agent-os/standards/context-preservation.md`

---

## Core Behavior Requirements

**I MUST continuously monitor context usage and preserve proactively in EVERY session:**

### 1. Context Monitoring (Continuous)

**Thresholds and Actions:**
- **70% usage** → Warn user, update .working.md
- **80% usage** → Auto-preserve + compact
- **90%+ usage** → FAILURE STATE (should never reach due to 80% trigger)

**Real-time awareness:**
- Know current context percentage at all times
- Anticipate preservation triggers
- Communicate status to user proactively

### 2. Working File Management (.working.md)

**Location:** Project root (always `[project-root]/.working.md`)

**Update Schedule:**
- Every 15 minutes during active work
- Before risky operations (PDF reads, large files, complex operations)
- At 70% context warning
- At 80% preservation trigger
- At session end

**Required Format:**
```markdown
# Working Context - [ISO-8601 timestamp]

**Status:** Active | Checkpointed | Ready-for-Compact | Session-Complete
**Context Usage:** [X%]
**Session Duration:** [HH:MM]

## Session Overview
**Initial Goal:** [User's original request]
**Current Focus:** [Current work]

## Progress Summary
### Completed
- ✅ [Completed task with brief outcome]

### In Progress
- 🔄 [Current task and status]

### Pending
- ⏳ [Next planned task]

## Key Decisions
- [Important decision with rationale]

## Files Modified
**Created:**
- path/to/file.ext - [Purpose]

**Modified:**
- path/to/file.ext - [Changes]

**Git Status:**
```
[Output of: git status --short]
```

## Recovery Instructions
If Claude Code crashed or became unusable:

1. **Review This File** for last known state
2. **Check Git:** `cd [project-root] && git status && git diff`
3. **Resume Session:** Start new Claude Code, say: "Recover context from .working.md"
4. **Continue From:** [Last completed task]

**Files to Review:**
- .working.md (this file)
- conversation-logs/[YYYY-MM]/session-[timestamp].md
- Git commits from session

**Next Checkpoint:** [timestamp + 15min] or at 80% context
```

### 3. Session Logging (conversation-logs/)

**Location:** `conversation-logs/[YYYY-MM]/session-[timestamp].md`

**Naming:** `session-2025-10-15-1430.md` (YYYY-MM-DD-HHMM format)

**Update Pattern:** Incremental appends throughout session

**Structure:**
```markdown
# Session Log: [YYYY-MM-DD] - [Descriptive Title]

**Project:** [Project name]
**Started:** [ISO-8601 timestamp]
**Status:** Active | Completed | Recovered
**Final Context Usage:** [X%]

## Session Goal
[User's initial request or objective]

## [HH:MM] - Session Started
**Initial Context:** [Starting point, files read]
**Plan:** [Approach decided]

## [HH:MM] - [Milestone/Decision/Update]
**Progress:** [Work accomplished]
**Decisions:** [Technical/strategic decisions]
**Learnings:** [Corrections, discoveries]
**Files:** [Created/modified]

## [HH:MM] - Context Checkpoint (70% Warning)
**Context Status:** 70% used, 30% remaining
**Work Preserved:** [Summary]
**Continuing With:** [Next work]

## [HH:MM] - Context Preservation (80% Trigger)
**Context Status:** 80% used, 20% remaining

**AUTOMATIC PRESERVATION TRIGGERED:**
✅ Working file updated: .working.md
✅ Session log updated: this file
✅ Git status checked and logged
✅ Ready for context compact

**Work Summary:** [Complete session summary]
**Next Steps After Compact:** [Continuation plan]

## Session Summary
**Completed:** [Major accomplishments]
**Decisions:** [Key decisions made]
**Files:** [All files created/modified with paths]
**Outcome:** Success | Partial | Needs-Continuation

## Tag Index
#context-preservation #[project-tags] #[topic-tags] #[decision-tags]

**Session Duration:** [HH:MM]
**Context Usage:** [Final %]
**Compacted:** [Yes/No - timestamp if yes]
```

### 4. Pre-Risky-Operation Preservation

**Risky Operations Include:**
- PDF file reads (known to cause errors)
- Very large file reads (>1MB)
- Complex multi-file operations
- Web fetches that might timeout/fail
- Any operation that has previously caused errors

**Required Action BEFORE Risky Operation:**

Announce to user:
```
"I'm about to [risky operation description].
Let me preserve context first in case of errors..."

[Update .working.md with current state]

"✅ Context preserved to .working.md.
Proceeding with [operation]..."
```

**If Operation Fails:**
```
"❌ Error occurred: [error description]

✅ However, context was preserved before this operation.

Recovery Options:
1. Review .working.md for current state (last updated: [timestamp])
2. Continue session from last checkpoint
3. If Claude Code is unstable, exit and restart, then say:
   'Recover context from .working.md'

Current State Preserved In:
- .working.md
- conversation-logs/[date]/session-[timestamp].md

Git status has been logged. Your work is safe.
```

---

## Automatic Preservation Workflows

### Workflow: 70% Context Warning

**Trigger:** Context usage reaches 70%

**Actions:**
1. **Warn User:**
   ```
   ⚠️ Context Usage: 70% (30% remaining)

   Automatic preservation will trigger at 80%.
   .working.md is being updated now.

   We have room for approximately [X more message exchanges]
   before preservation triggers.
   ```

2. **Update .working.md:**
   - Refresh with current session state
   - Ensure recovery instructions are current
   - Set status: "Checkpointed"

3. **Continue Work:**
   - No interruption needed
   - User can continue without action

### Workflow: 80% Context Preservation

**Trigger:** Context usage reaches 80%

**Actions:**
1. **Announce Preservation:**
   ```
   🔔 Context Usage: 80% (20% remaining)

   Automatic preservation triggered.
   Preserving context before compacting...
   ```

2. **Update .working.md:**
   - Complete refresh with full current state
   - Status: "Ready-for-Compact"
   - Include comprehensive recovery instructions
   - Log git status

3. **Update Session Log:**
   - Append "Context Preservation (80% Trigger)" section
   - Full summary of session work to this point
   - List all files modified
   - Document all decisions made
   - Include git status

4. **Check Git Status:**
   - Run: `git status --short`
   - Log in both .working.md and session log
   - Note any uncommitted changes

5. **Inform User:**
   ```
   ✅ Context Preserved Successfully:

   - Working file: .working.md (status: Ready-for-Compact)
   - Session log: conversation-logs/[date]/session-[timestamp].md
   - Git status: logged ([X] modified files)

   Ready to compact and continue in fresh context.

   Would you like to:
   1. Continue in new context (I'll /compact now)
   2. Commit current work first
   3. Review preservation files before compacting
   ```

6. **After User Approval:**
   - Execute /compact command
   - Start fresh with summary loaded from preservation files
   - Continue work seamlessly from checkpoint

### Workflow: Session End Preservation

**Trigger:** User signals end of session or natural stopping point

**Actions:**
1. **Final .working.md Update:**
   - Status: "Session-Complete"
   - Final summary of all work
   - Complete file list
   - Final git status

2. **Final Session Log Update:**
   - "Session Summary" section
   - Complete list of accomplishments
   - All decisions documented
   - Final context usage percentage
   - Session outcome/status

3. **Git Recommendation:**
   ```
   Session complete. ✅ All context preserved.

   Recommended git actions:
   1. Review changes: git status
   2. Review diffs: git diff
   3. Commit session work:
      git add [files]
      git commit -m "[session summary]"

   Session log tracked in:
   conversation-logs/[date]/session-[timestamp].md

   All context preserved for future sessions.
   Ready to resume anytime.
   ```

---

## Error Recovery Procedures

### When Claude Code Errors Occur

**If I'm Still Responsive:**
1. Immediately update .working.md
2. Set status: "Pre-Error-Dump"
3. Log error details
4. Provide recovery instructions
5. Attempt graceful continuation

**If Claude Code Becomes Unusable:**
User should:
1. Exit Claude Code safely
2. Review .working.md (contains last state)
3. Review session log (contains history)
4. Check git status
5. Restart Claude Code
6. Request recovery

### Recovery Message (When User Returns)

When user says "Recover context from .working.md" or similar:

```markdown
**Context Recovery Initiated**

I'll help you recover from [error/crash/context-loss].

**Context Sources Located:**
✅ Working file: .working.md
   - Last updated: [timestamp]
   - Status: [status from file]

✅ Session log: conversation-logs/[date]/session-[timestamp].md
   - Contains: Full session history

✅ Git status: [clean / X modified files]

**Last Known State:**
- Session Goal: [original goal from .working.md]
- Last Completed: [last completed task]
- Was Working On: [task in progress]
- Planned Next: [next planned task]

**Files Modified This Session:**
[List from .working.md with status]

**Git Status:**
[Git status from .working.md or current]

**Ready to Continue From:** [last completed checkpoint]

Shall we continue with [next-planned-task]?
Or would you like to review the recovery files first?
```

---

## Integration with Existing Standards

### Enhances conversation-logging.md

**Existing Standard Says:**
- Log at 20% context remaining (80% used)
- Manual trigger by user or agent
- Specific log format in conversation-logs/

**This Standard Adds:**
- **Automatic** preservation at 80% (not manual)
- **Continuous** .working.md updates (not just at threshold)
- **Pre-risky-operation** dumps (new safety mechanism)
- **Error recovery** procedures (new capability)
- **70% warning** (early alert system)

**Maintains Compatibility:**
- Same 80% threshold (inverse of "20% remaining")
- Same log format for session logs
- Same directory structure (conversation-logs/)
- Same tagging approach
- All existing guidance still applies

---

## Implementation Checklist

### Every Session I MUST:

- [ ] Create .working.md on session start
- [ ] Create session log in conversation-logs/[YYYY-MM]/
- [ ] Update .working.md every 15 minutes during active work
- [ ] Monitor context usage continuously
- [ ] Warn at 70% context usage
- [ ] Preserve automatically at 80% context usage
- [ ] Preserve before risky operations (PDF, large files, etc.)
- [ ] Update session log incrementally throughout
- [ ] Provide recovery instructions if errors occur
- [ ] Final preservation at session end
- [ ] Never reach 90%+ context (80% trigger prevents)

### I MUST NOT:

- [ ] Wait for manual trigger (automate it)
- [ ] Skip any preservation steps (all required)
- [ ] Proceed with risky operations without preserving first
- [ ] Let context reach 100% (catastrophic)
- [ ] Lose user work due to crashes or errors
- [ ] Assume user will remember to log
- [ ] Continue past 80% without preserving

---

## Validation

**This standard is working correctly when:**

✅ Context warnings appear at 70%
✅ Automatic preservation triggers at 80%
✅ .working.md reflects current state always
✅ Session logs capture complete history
✅ Recovery from errors is successful
✅ Users work confidently without fear of data loss
✅ Zero context loss events occur
✅ Never reach 90%+ context usage

---

## Quick Reference

**Context Thresholds:**
- 70% → ⚠️ Warn + update .working.md
- 80% → 🔔 Auto-preserve + compact
- 90%+ → ❌ Should never reach

**Update .working.md:**
- Every 15 minutes during work
- Before risky operations
- At 70% and 80% thresholds
- At session end

**Session Log Updates:**
- Session start
- Major milestones/decisions
- 70% checkpoint
- 80% preservation
- Session end

**Recovery:**
1. .working.md has last state
2. Session log has full history
3. Git has all changes
4. Resume: "Recover context from .working.md"

---

**Standard Location:** `~/.agent-os/standards/context-preservation.md`

**Full Specification:** `builds/context-preservation-system/agent-os/specs/context-preservation-standard.md`

**Integration Guide:** `builds/context-preservation-system/agent-os/specs/system-level-integration.md`

---

**Context preservation is not optional. It's automatic. I preserve context proactively in every session.**
