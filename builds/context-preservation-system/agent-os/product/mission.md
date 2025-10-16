# Context Preservation System Mission

**Version:** 1.0
**Last Updated:** 2025-10-15
**Status:** Planning

---

## Product Vision

**Proactive Context Preservation for Claude Code: Zero Data Loss, Total Reliability**

A system-level standard that makes context loss impossible through proactive monitoring, automatic preservation, and graceful recovery. Built into Claude Code's behavior, not bolted on.

**The Problem:**
- Fatal errors (PDF too large, etc.) corrupt Claude Code context
- Context loss means lost decisions, lost work, lost momentum
- Manual logging burden at critical thresholds
- No recovery mechanism when crashes occur
- Demoralizing experience interrupts flow state

**The Solution:**
Standards-driven behavior that makes context preservation automatic, proactive, and reliable.

---

## Core Mission

Transform Claude Code's context management from reactive to proactive through:

1. **Proactive Context Monitoring**
   - Continuous monitoring of context usage
   - Early warning at 70% threshold
   - Automatic preservation at 80% threshold
   - Never reach 100% (auto-compact triggers data loss)

2. **Automatic Session Logging**
   - Continuous `.working.md` updates throughout session
   - Incremental session logs in `conversation-logs/[date]/`
   - Zero manual intervention required
   - Total context preservation from start to finish

3. **Graceful Error Recovery**
   - Context preserved before risky operations
   - Recovery instructions when errors occur
   - `.working.md` provides recovery point
   - Resume work without context loss

4. **Standards-Driven Behavior**
   - Not external hooks (don't exist in Claude Code)
   - Built into Claude Code's operating standards
   - Guides agent behavior proactively
   - System-level defaults for all projects

---

## Product Principles

### Proactive Over Reactive

**"Preserve context before problems occur, not after."**

- Monitor continuously, act early
- 80% threshold prevents 100% auto-compact data loss
- Working file updated throughout session
- Don't wait for manual triggers

### Standards Over Scripts

**"I AM the hook system."**

- Claude Code doesn't have external hook system
- Standards guide my behavior as the agent
- Make preservation automatic through training
- System-level standards apply to all projects

### Zero Data Loss

**"If context was created, context is preserved."**

- No conversation ends without logging
- No error occurs without context dump
- No threshold passes without preservation
- Cost of over-logging: trivial. Cost of under-logging: catastrophic.

### Seamless Integration

**"User shouldn't think about context - it just works."**

- Automatic warnings at thresholds
- Automatic preservation at triggers
- Automatic recovery instructions
- User focuses on work, not context management

---

## Success Metrics

### Reliability Metrics

- **Zero Context Loss Events:** No work lost to crashes or errors
- **100% Session Logging:** Every conversation logged to completion
- **Auto-Compact Prevention:** Never trigger 100% auto-compact
- **Recovery Success Rate:** 100% successful recovery from errors

### User Experience Metrics

- **Flow State Preservation:** No interruptions from manual logging
- **Confidence in System:** User trusts context won't be lost
- **Reduced Cognitive Load:** User doesn't manage context manually
- **Morale Impact:** No demoralization from lost work

### System Metrics

- **Warning Accuracy:** Warnings at 70%, preservation at 80%
- **Working File Currency:** `.working.md` always current
- **Session Log Completeness:** All decisions/work captured
- **Recovery Time:** < 2 minutes from error to resumed work

---

## Product Architecture

### Three-Layer System

**Layer 1: System-Level Standards** (`~/.agent-os/standards/`)
- Context monitoring requirements
- Preservation trigger thresholds
- Working file format and update cadence
- Session log structure
- Error recovery procedures

**Layer 2: Global Configuration** (`~/.claude/CLAUDE.md`)
- Context preservation behavior injected globally
- Applies to all Claude Code sessions
- No per-project configuration needed
- System-level defaults

**Layer 3: Working Files** (Auto-generated)
- `.working.md` in project root (current session state)
- `conversation-logs/[date]/session-[timestamp].md` (full session log)
- Git-tracked for recovery
- Human-readable for review

### Integration with Builder Platform

**Enhances existing conversation-logging.md standard:**
- Keeps 20% threshold guidance (now 80% in inverse)
- Adds automatic triggering (not just manual)
- Adds working file system
- Adds error recovery procedures

**Maintains Agent-OS compatibility:**
- Standards-based approach (Agent-OS native)
- Project-agnostic (system-level defaults)
- Markdown documentation (Agent-OS convention)
- No custom tooling required

---

## Target Outcomes

### For Solo Expert Builder

**Current Pain:**
- Work for hours, hit error, lose everything
- Manual logging burden at critical moments
- No recovery mechanism
- Fear of context loss interrupts flow

**With Context Preservation System:**
- Work confidently knowing context is preserved
- Automatic warnings and preservation
- Instant recovery from errors via `.working.md`
- Flow state maintained, morale protected

### For Builder Platform Reliability

**Platform Goal:**
Enable consistent, high-quality work across sessions without context loss.

**System Delivers:**
- Total context preservation (D.R.Y. principle foundation)
- Knowledge compounding (can't compound lost knowledge)
- Quality consistency (context loss degrades quality)
- Platform reliability (foundation for all work)

---

## Competitive Advantages

### vs Manual Context Management

**Manual Approach:**
- User must remember to log at thresholds
- Easy to miss warning signs
- Manual logging interrupts flow
- Error recovery requires user memory

**Context Preservation System:**
- Automatic monitoring and warnings
- Automatic preservation at thresholds
- Zero interruption (happens in background)
- Error recovery via preserved context files

### vs External Hook Systems

**External Hooks (if they existed):**
- Separate scripts to maintain
- Fragile integration points
- Requires understanding hook system
- May break with Claude Code updates

**Standards-Driven Behavior:**
- Built into agent operating instructions
- No external dependencies
- Natural integration with Claude Code
- Robust to system updates

---

## Non-Goals

**What Context Preservation System IS NOT:**
- A backup system (uses git for that)
- A full conversation replayer (logs are summaries)
- An external monitoring tool (built into agent behavior)
- A performance optimization system (reliability, not speed)

**What We DON'T Optimize For:**
- Minimal logging (over-log is safer than under-log)
- Zero overhead (preservation has tiny cost, huge value)
- Manual control (automation is the goal)
- Cross-session replay (focused on preventing loss, not replaying)

---

## Roadmap Reference

See: `agent-os/product/roadmap.md` for phased implementation plan

---

## Tech Stack Reference

See: `agent-os/product/tech-stack.md` for technology decisions

---

**Mission Statement:**

**"Make context loss impossible through proactive standards-driven preservation, enabling solo expert builders to work confidently without fear of losing progress to crashes, errors, or context window exhaustion."**

---

**Context preservation is not a feature. It's a foundation.**
