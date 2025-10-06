# CONVERSATION LOGGING SYSTEM v1.0

**The Builder Platform - Context Preservation Standard**

**Last Updated:** October 4, 2024

---

## Core Principle

**Never lose context. Log early, log often.**

Context is the lifeblood of the Builder Platform. Every conversation contains decisions, lessons, and knowledge that must be preserved. Conservative logging triggers prevent data loss.

**If in doubt, log it out.**

---

## Critical System Understanding: Auto-Compact

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

## Authoritative Metric: User-Visible Auto-Compact

### The Metric Conflict Problem

**Two potential metrics exist:**
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

### Example Conflict

**Scenario:**
- Internal counter shows: 135k / 200k tokens (32% remaining)
- Status bar shows: "Context left until auto-compact: 5%"

**Correct action:**
- **Use 5% as authoritative**
- Log immediately (already past 20% threshold)
- Investigate discrepancy later if needed
- Do NOT trust calculation over observed metric

---

## Logging Trigger Conditions

**Create conversation log when ANY of these conditions met:**

### Trigger 1: Context Threshold (PRIMARY)
- **20% context remaining** (based on user-visible auto-compact metric)
- Check status bar, not internal calculations
- When you see "Context left until auto-compact: 20%" or less → LOG NOW

### Trigger 2: Time Elapsed
- **2 hours of conversation**
- Even if context usage is low
- Prevents losing multi-hour sessions if context suddenly spikes

### Trigger 3: Major Decision Point
- Platform decisions (car choice, build path, major direction change)
- Critical lessons learned (like today's precision standards)
- Significant failures and their solutions
- **Don't wait for threshold** - log important decisions immediately

### Trigger 4: Manual Request
- User asks for context dump
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
- `2024-10/2024-10-03-initial-planning.md`
- `2024-10/2024-10-04-quality-standards-refinement.md`
- `2024-10/2024-10-04-critical-data-conflict-lesson.md`

### Required Sections

**Every conversation log must include:**

```markdown
# Conversation Log: YYYY-MM-DD - Title

**Project:** [Project name]
**Date:** [Date]
**Session Type:** [Planning / Research / Quality / Lessons Learned / etc.]
**Participants:** [Owner name], Claude

---

## Executive Summary

[2-3 paragraph summary of session outcomes]

---

## [Session-Specific Sections]

[Key decisions, lessons learned, problems solved, etc.]

---

## Tag Index

#tag1 #tag2 #tag3 #tag4

---

**Status:** [Session status]
**Confidence:** [Overall confidence in documentation]
```

### Content Requirements

**What to capture:**
- **Decisions made** (platform choices, build paths, direction changes)
- **Lessons learned** (especially failures and their solutions)
- **Critical conversations** (owner teaching moments, precision standards)
- **Technical details** (specs researched, corrections made, conflicts resolved)
- **Key quotes** (owner's philosophy, teaching moments, memorable statements)
- **Action items** (what's next, pending tasks, research required)
- **Files created/modified** (with git commit references)

**What to emphasize:**
- Owner's corrections and teaching moments (these are gold)
- Failures and how they were fixed (learning opportunities)
- Process improvements (like today's verification protocol)
- Philosophy development (gentleman's weapon, precision standards, etc.)

**Tagging for Graph RAG:**
- Comprehensive tag index at end of log
- Include topic tags (#quality-standards, #RS4, #S7)
- Include lesson tags (#lessons-learned, #critical-failure)
- Include process tags (#fact-verification, #conversation-logging)
- Include platform tags (#platform-evolution, #decision-points)

---

## Logging Process Workflow

### Step 1: Recognize Trigger

**Monitor constantly:**
- Status bar "Context left until auto-compact: X%"
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
- Owner's teaching moments
- Technical details and corrections
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

### Step 4: Commit to Git

**Commit message should include:**
- Brief description of session
- Key outcomes or lessons
- Context status when logged
- Primary tags

**Example:**
```
git commit -m "Add conversation log: Quality standards refinement

Context: Logged at 20% remaining per auto-compact metric

Key outcomes:
- Language precision standards created
- Fact verification protocol implemented
- Critical RS4 failure documented

Tags: #quality-standards #fact-verification #lessons-learned"
```

### Step 5: Acknowledge Completion

**Inform user:**
- Log created and committed
- Current context status
- Ready to continue or start fresh

---

## Data Loss Prevention

### Conservative Triggers Save Context

**Why 20% buffer matters:**
- Logging consumes context (reading conversation, generating summary)
- Git operations add overhead
- Unexpected spikes can occur during logging
- Better to have too many logs than lose one critical decision

**Cost of logging too early:** Slightly more files (trivial)
**Cost of logging too late:** Lost context, lost decisions, lost lessons (UNACCEPTABLE)

**Philosophy:** Err on side of preservation.

### When Logging Fails

**If context runs out during logging:**
- Partial log is better than no log
- Commit what you have immediately
- Note in commit: "Partial log - context exhausted"
- User can review and fill gaps from their memory

**Prevention:**
- Respect 20% trigger strictly
- Don't defer when threshold hit
- Manual trigger on major decisions (don't wait)

---

## Integration with Platform Architecture

### Current State (File-Based)

**Markdown logs in dated folders:**
```
conversation-logs/
├── 2024-10/
│   ├── 2024-10-03-initial-planning.md
│   ├── 2024-10-04-quality-standards-refinement.md
│   └── 2024-10-04-critical-data-conflict-lesson.md
└── [future months]/
```

**Searchable via:**
- Grep for keywords
- Tag searches
- File naming conventions
- Full-text search

### Future State (Graph RAG)

**When graph database implemented:**
- Logs become nodes in knowledge graph
- Tags become relationships
- Entities extracted (cars, specs, decisions, lessons)
- Semantic search across all logs
- Context retrieval based on topic/theme

**Preparation for future:**
- Comprehensive tagging now
- Consistent formatting
- Entity-rich summaries
- Cross-reference related logs

---

## Examples

### Example 1: Context Threshold Trigger

**Scenario:**
- Conversation ongoing about platform decisions
- Status bar shows: "Context left until auto-compact: 18%"
- Reached 20% threshold

**Action:**
```
User: [Status bar shows 18% remaining]
Assistant: "I see we're at 18% context remaining. I should create a conversation log now to preserve our decisions about platform choice and DCT requirements. One moment while I document this session."

[Creates comprehensive log]
[Commits to git]