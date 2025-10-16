# Context Management Protocol

**Universal Session Management Standard**

**Last Updated:** 2025-10-13
**Status:** Core Standard
**Applies To:** All AI-assisted development sessions, conversation logging, and knowledge preservation

---

## Core Principle

**Never lose context. Log early, log often.**

Context is the lifeblood of productive AI-assisted development. Every session contains decisions, lessons, and knowledge that must be preserved.

**If in doubt, log it out.**

---

## Critical Understanding: Auto-Compact

### What Auto-Compact Means

**Auto-compact begins at 0%** = Context compression starts automatically
- **This is TOO LATE to save full context**
- Compaction happens BEFORE logging can complete
- Substantial context may be lost
- Summaries created during compaction miss details

**Therefore:** Logging must occur WITH BUFFER before auto-compact triggers.

### The 20% Rule

**Conservative safety margin required:**
- Log when context reaches **80% usage** (20% remaining)
- This ensures logging completes BEFORE auto-compact begins
- Provides buffer for:
  - Summary generation
  - File writes
  - Git commits
  - Unexpected context spikes during logging process

**Why 20% is necessary:**
- Logging itself consumes context
- Summary creation requires reading prior conversation
- Git operations add overhead
- Better to log at 20% than lose data at 0%

---

## Authoritative Metric

### The Metric Conflict Problem

**Two potential metrics may exist:**
1. **Internal token counter** (e.g., 135,417 / 200,000 tokens)
2. **User-visible "Context left until auto-compact: X%"**

**These may not align.**

### Which Is Authoritative?

**The user-visible "auto-compact" metric is ALWAYS authoritative.**

**Why:**
- Directly measures actual system state
- Reflects true proximity to auto-compact trigger
- User can verify status independently
- Internal counters may not account for system overhead

**When metrics conflict:**
- Trust the auto-compact percentage
- Do NOT calculate from token counts
- Acknowledge the discrepancy
- Use conservative (lower) estimate

---

## Logging Trigger Conditions

**Create conversation log when ANY of these conditions met:**

### Trigger 1: Context Threshold (PRIMARY)
- **20% context remaining** (based on user-visible auto-compact metric)
- Check status indicator, not internal calculations
- When you see "20%" or less → LOG NOW

### Trigger 2: Time Elapsed
- **2 hours of conversation**
- Even if context usage is low
- Prevents losing multi-hour sessions if context suddenly spikes

### Trigger 3: Major Decision Point
- Architecture decisions (framework choice, major direction change)
- Critical lessons learned (debugging insights, process improvements)
- Significant failures and their solutions
- **Don't wait for threshold** - log important decisions immediately

### Trigger 4: Manual Request
- User asks for context save
- "Let's save this conversation"
- Override all thresholds - log immediately

**Rule:** Whichever trigger hits FIRST, log it.

---

## Conversation Log Format

### File Naming Convention

```
conversation-logs/YYYY-MM/YYYY-MM-DD-brief-description.md
```

**Examples:**
- `2025-10/2025-10-13-agent-os-standards-setup.md`
- `2025-10/2025-10-13-authentication-implementation.md`
- `2025-10/2025-10-13-performance-optimization-debugging.md`

### Required Sections

**Every conversation log must include:**

```markdown
# Conversation Log: YYYY-MM-DD - Title

**Project:** [Project name]
**Date:** [Date]
**Session Type:** [Planning / Implementation / Debugging / Research / etc.]
**Participants:** [Names or roles]

---

## Executive Summary

[2-3 paragraph summary of session outcomes]

---

## Key Decisions

[Architecture decisions, technology choices, approach selections]

---

## Implementation Details

[What was built, changed, or configured]

---

## Lessons Learned

[Problems encountered, debugging insights, what worked/didn't work]

---

## Next Steps

[Action items, pending tasks, follow-up needed]

---

## Files Modified

[List of files created/modified with brief description]

---

## Tag Index

#tag1 #tag2 #tag3 #tag4

---

**Status:** [Complete / In Progress / Blocked]
**Confidence:** [High / Medium / Low - overall confidence in documentation]
```

### Content Requirements

**What to capture:**
- **Decisions made** (technology choices, architectural decisions, direction changes)
- **Lessons learned** (especially failures and debugging insights)
- **Critical conversations** (key insights, problem-solving approaches)
- **Technical details** (configurations, code patterns, gotchas discovered)
- **Action items** (what's next, pending tasks, research required)
- **Files created/modified** (with git commit references if applicable)

**What to emphasize:**
- Problem-solving breakthroughs
- Failures and how they were fixed (learning opportunities)
- Process improvements discovered
- Non-obvious solutions that required research

**Tagging for Future Retrieval:**
- Technology tags (#postgresql, #typescript, #docker)
- Topic tags (#authentication, #performance, #deployment)
- Lesson tags (#debugging, #optimization, #gotcha)
- Project tags (#project-name, #feature-name)

---

## Logging Process Workflow

### Step 1: Recognize Trigger

**Monitor constantly:**
- Context indicator (auto-compact percentage)
- Time elapsed in conversation
- Major decisions being made

**When trigger hits:**
- Acknowledge it immediately
- Don't defer "just one more thing"
- Log takes priority

### Step 2: Create Summary

**Comprehensive but concise:**
- Executive summary (what happened, outcomes)
- Key decisions and rationale
- Lessons learned (especially failures)
- Technical details and configurations
- Next steps and pending tasks

**Include context:**
- Why decisions were made
- What led to lessons learned
- How problems were discovered and solved

### Step 3: Write Log File

**File location:**
```
conversation-logs/YYYY-MM/YYYY-MM-DD-description.md
```

**Follow format template (see above)**

### Step 4: Commit to Git (if in git repository)

**Commit message should include:**
- Brief description of session
- Key outcomes or lessons
- Context status when logged

**Example:**
```
git commit -m "Add conversation log: Agent OS standards setup

Context: Logged at 18% remaining

Key outcomes:
- Created architectural-decisions.md standard
- Created precision-language.md standard
- Created fact-verification.md standard
- Created context-management.md standard

Session: Standards migration from builder-platform project"
```

### Step 5: Acknowledge Completion

**Inform user:**
- Log created and committed (if applicable)
- Current context status
- Ready to continue or start fresh

### Step 6: Compact After Logging (CRITICAL)

**ONLY compact/start fresh AFTER logging is complete.**

**The 20% trigger workflow:**
1. Trigger hits at 20% remaining
2. Complete logging process (Steps 1-5)
3. Verify log is saved/committed
4. **THEN** compact/start new conversation

**Why this order matters:**
- Auto-compact at 0% = context loss before logging completes
- 20% buffer ensures logging finishes before auto-compact triggers
- Compacting after logging = total context preservation
- All decisions, lessons, and work captured before reset

**NEVER:**
- Compact before logging completes
- Risk context loss by deferring logging
- Continue working when at/near 20% without logging first

---

## Data Loss Prevention

### Conservative Triggers Save Context

**Why 20% buffer matters:**
- Logging consumes context (reading conversation, generating summary)
- File operations add overhead
- Unexpected spikes can occur during logging
- Better to have too many logs than lose one critical session

**Cost of logging too early:** Slightly more files (trivial)
**Cost of logging too late:** Lost context, lost decisions, lost lessons (UNACCEPTABLE)

**Philosophy:** Err on side of preservation.

### When Logging Fails

**If context runs out during logging:**
- Partial log is better than no log
- Save what you have immediately
- Note: "Partial log - context exhausted"
- User can review and fill gaps from memory

**Prevention:**
- Respect 20% trigger strictly
- Don't defer when threshold hit
- Manual trigger on major decisions (don't wait)

---

## Integration with Knowledge Management

### Current State (File-Based)

**Markdown logs in dated folders:**
```
conversation-logs/
├── 2025-10/
│   ├── 2025-10-13-agent-os-standards-setup.md
│   ├── 2025-10-13-authentication-implementation.md
│   └── 2025-10-14-performance-debugging.md
└── [future months]/
```

**Searchable via:**
- grep/ripgrep for keywords
- Tag searches
- File naming conventions
- Full-text search

### Future Enhancement Ideas

**Potential improvements:**
- Automated tagging from conversation content
- Cross-referencing related sessions
- Knowledge graph connections (decisions → outcomes)
- Searchable index of all logs
- AI-assisted retrieval ("find sessions about authentication")

---

## Examples

### Example 1: Context Threshold Trigger

**Scenario:**
- Working on complex implementation
- Status shows: "Context remaining: 18%"
- Reached 20% threshold

**Action:**
```
Assistant: "I see we're at 18% context remaining. I should create a conversation log now to preserve our implementation progress and debugging insights. One moment while I document this session."

[Creates comprehensive log]
[Commits to git if applicable]
[Informs user log is complete]
```

### Example 2: Major Decision Trigger

**Scenario:**
- Making critical architecture decision (e.g., choosing authentication approach)
- Decision impacts multiple components
- Context only at 60% but decision is significant

**Action:**
```
Assistant: "This is a significant architectural decision about authentication. Let me create a conversation log now to document the decision rationale and alternatives considered, even though we're only at 60% context usage."

[Creates log focused on decision]
[Can continue working after log complete]
```

---

## Quick Reference

**When to log:**
- ✅ Context at 20% or less
- ✅ 2 hours elapsed
- ✅ Major decision made
- ✅ User requests it

**What to include:**
- ✅ Executive summary
- ✅ Key decisions with rationale
- ✅ Implementation details
- ✅ Lessons learned
- ✅ Next steps
- ✅ Files modified
- ✅ Relevant tags

**After logging:**
- ✅ Verify log is saved
- ✅ Commit to git (if applicable)
- ✅ Then continue or start fresh

---

**Remember: Never lose context. Log early, log often.**