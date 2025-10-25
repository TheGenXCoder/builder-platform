# Real-World User Scenarios for Future Features

**Purpose:** Capture actual usage scenarios from user's day-to-day work to inform Week 2+ feature development.

**Captured:** 2025-10-22 while user works on API middleware project

---

## Scenario 1: Report Format Amnesia

**Date:** 2025-10-22
**Project:** API Middleware
**Priority:** Week 2

### What Happened

**Session 1 (Yesterday Evening):**
1. User: "Give me an HTML report"
2. Claude: Generates thorough HTML test report
3. User: Reads, loves format ("LOVED it's format"), finds issues, fixes them
4. Session ends

**Session 2 (Next Morning):**
1. System: "Test run completed"
2. User: "Can I see the report"
3. Claude: Generates MD report (completely different format)
4. User: Expected HTML report like yesterday, got something totally different

### What Should Have Happened

**After test completion:**
```
Claude (proactive):
"Test run completed successfully.

Here's your HTML test report (same format you approved yesterday):
[HTML report with updated values]

I've also created a project slash command:
/test-report-html - Generate test report in your preferred format

This ensures we maintain consistency across sessions."
```

### User Decisions on Behavior

**1. Report Generation:**
- a. Should NOT have to ask for report after test completion
- b. When asked, should understand from context to use same format with new values

**2. Format Preference:**
- User explicitly said "LOVED it's format"
- System should infer: HTML is preferred for test reports in this project
- Not global preference, scoped to test reports

**3. Session Continuity:**
- Yesterday evening → this morning = same work session
- Should automatically link related sessions

**4. Preference Communication:**
- User: "Infer preference from 'LOVED it's format'"
- Expected response: "I've generated the test report in the format you were most recently approving of. I've also created a slash command /test-html for the project to insure we continue to use this."

### Required Capabilities

**Week 1 (Must Have):**
- ✅ Preference Learning (capture "LOVED it's format" → HTML for test reports)
- ✅ Reference Resolution ("the report" → specific HTML report from yesterday)
- ✅ Session Continuity (yesterday → today = same work session)
- ✅ Format Consistency (don't randomly change formats)

**Week 2 (Important, Not Critical):**
- ⏸️ Pattern Recognition (test completion → auto-generate report)
- ⏸️ Workflow Codification (auto-create slash commands like /test-report-html)
- ⏸️ Proactive Action (generate report without being asked)

### Technical Implementation Notes

**Preference Storage:**
```
Preference {
    Type: "report-format",
    Context: "test-reports",
    Scope: "api-middleware-project",
    Value: "HTML",
    Template: [actual HTML structure],
    Confidence: 0.95,
    Evidence: "User explicitly said 'LOVED it's format'",
    CreatedAt: "2025-10-22"
}
```

**Pattern Recognition (Week 2):**
```
WorkflowPattern {
    Trigger: "test completion message",
    Action: "generate report",
    Format: "HTML",
    Project: "api-middleware",
    Confidence: 0.9,
    Examples: [list of times this pattern occurred]
}
```

**Reference Resolution:**
```
Query: "Can I see the report"
Context:
- Just said "test completed"
- Previous pattern: test → report
- Recent entity: HTML report from yesterday
- Same project: API middleware
Resolution: HTML test report from Session 1
```

---

## Scenario 2: Autonomous Alpha Discovery ("Seeking Alpha")

**Date:** 2025-10-22
**Project:** API Middleware (and all future work)
**Priority:** Week 3-4

### What Happened

User working through dev session. Same error happens multiple times with different attempted fixes. System doesn't recognize the stuck pattern.

### What Should Have Happened

```
Attempt 1: Error parsing XML → Try fix A → Still fails
Attempt 2: Same error → Try fix B → Still fails
Attempt 3: Same pattern detected

System (proactive):
"Hey, we've tried this a couple times. I just found a post on
Reddit that isn't quite the same, but rhymes. Let's see what
we can derive from it:

[Relevant solution from Reddit/Stack Overflow/GitHub]

Should we try this approach?"
```

### Core Concept

**"Seeking Alpha" - Proactive Solution Discovery**
- System watches for stuck patterns (iterating without progress)
- Autonomously searches external sources (Reddit, Stack Overflow, GitHub Issues)
- Finds "rhymes" (similar problems, not exact matches)
- Presents findings proactively
- Learns what sources/patterns work over time

### User Context

"As an investor, stocks/options specifically, I'm always looking for 'alpha'. What if there's a sub process of this platform that proactively is seeking alpha."

This is about finding NON-OBVIOUS solutions by recognizing patterns and hunting laterally.

### Required Capabilities (Week 3-4)

- Stuck pattern detection (N failed attempts on same/similar error)
- External search integration (Reddit, Stack Overflow, GitHub)
- Fuzzy matching ("rhymes with" not exact match)
- Confidence scoring (when to speak up vs stay quiet)
- Learning from success (which sources/users are valuable)
- Background research (don't interrupt flow)

### Notes

- Week 3-4 feature, but architecture must support from Week 1
- Block storage enables pattern detection
- Relationship tracking shows we've tried X, Y, Z
- This could be MAJOR product differentiator
- "AI that hunts for solutions" vs "AI with memory"

### Open Questions (Answer When Building Week 3-4)

Details about trigger thresholds, search scope, interruption behavior, confidence levels, cost controls, learning mechanisms - all to be determined during implementation.

"Dad, what's that?" - Don't over-design before we need it.

---

## Scenario 3: [Next scenario to be captured]

**Date:** TBD
**Project:** TBD
**Priority:** TBD

### What Happened

[Capture next scenario here]

---

## Patterns Emerging

**As more scenarios captured, look for:**
- Common preference types (formats, workflows, tools)
- Common reference resolution challenges
- Session continuity patterns
- Proactive action opportunities

**This document informs:**
- Week 2 feature prioritization
- Week 3+ roadmap refinement
- Real user needs vs assumed needs
- Success metrics (what actually matters)

---

**Keep capturing scenarios as they happen in real work.**
