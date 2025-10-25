# Next Session: Week 1.5 Import Implementation

**Status:** Foundation Complete ✅ | Implementation Pending ⏳

**Last Session:** 2025-10-25
**Commit:** 05696eb - Multi-Tenant Foundation & Import System Design

---

## What Was Built (Foundation Complete)

### 1. Multi-Tenant Architecture ✅

**Database Schema:**
```sql
- organizations (tenant isolation)
- blocks.visibility (public/org-private/individual)
- blocks.organization_id (tenant scoping)
- blocks.source_url + source_attribution (citations)
- import_history with visibility tracking
- public_knowledge (community pool - Week 2+)
```

**Applied to database:** ✅ All schema changes live

### 2. Source Classification System ✅

**Auto-detection:**
- Public URLs (stackoverflow, github, docs) → `public`
- Paywall URLs → `org-private`
- Client directories (/work/, /uta/) → `org-private`
- Personal directories → `individual`
- Manual tags (#public, #private) → respected
- Git remote analysis (prepared)

**File:** `internal/importer/classification.go`

### 3. Configuration System ✅

**Organization detection:**
- `.env` file: `KG_ORG=personal` (default if missing)
- Single-tenant mode for Week 1.5
- Multi-tenant ready for production

**File:** `.env.example`

### 4. Import Types & Foundation ✅

**Files:**
- `internal/importer/types.go` - Core types with visibility
- `internal/importer/discovery.go` - File scanning
- `agent-os/specs/import-system.md` - Complete 600+ line spec

---

## What Needs to Be Built (Next Session)

### Remaining Components (~2 hours)

**1. Conversation Log Parser (30 min)**
```go
File: internal/importer/parsers/conversation_log.go

Tasks:
- Parse session metadata (Project, Started, Status)
- Extract Session Goal
- Parse milestone sections → Q&A pairs
- Extract tags from Tag Index
- Build PreBlock with exchanges
```

**Sample input format:**
```markdown
# Session Log: 2025-10-15 - Title

**Project:** builder-platform
**Started:** 2025-10-15T16:00:00-07:00

## Session Goal
[User's intent]

## 16:00 - Milestone Title
**Progress:** [Work completed]
**Decisions:** [Technical decisions]

## Tag Index
#tag1 #tag2 #tag3
```

**2. Chunking Logic (20 min)**
```go
File: internal/importer/chunking.go

Tasks:
- Target 3-5 exchanges per block
- Split sessions >10 exchanges
- Preserve session_id across chunks
- Respect natural boundaries
```

**3. Deduplication (15 min)**
```go
File: internal/importer/deduplication.go

Tasks:
- Check source_file + source_hash in import_history
- Compare file hashes (new vs existing)
- Return decisions: insert/update/skip
- Conversation logs = immutable (never update)
```

**4. Pipeline Orchestrator (20 min)**
```go
File: internal/importer/pipeline.go

Tasks:
- Discover → Parse → Chunk → Deduplicate → Import
- Progress reporting
- Error handling
- Batch processing
```

**5. CLI Commands (15 min)**
```go
File: cmd/knowledge/import.go

Commands:
- ./knowledge import <dir> [--dry-run] [--visibility override]
- ./knowledge import stats
- ./knowledge import history
```

**6. Attribution System (10 min)**
```go
Tasks:
- Extract source URLs from public blocks
- Format citation text
- Store in blocks.source_url + source_attribution
- Display as (ⁱ) link in search results
```

**7. Testing (10 min)**
```bash
Tasks:
- Import conversation-logs/2025-10/
- Search for "PostgreSQL setup"
- Verify blocks created correctly
- Verify visibility classification
- Check sub-60s import time
```

---

## Key Design Decisions (Already Locked)

**From last session:**

1. **Block size:** Medium (3-5 exchanges)
2. **Reimport:** Hash-based (smart updates)
3. **Large files:** Chunk into multiple blocks
4. **Preview:** 5 sample blocks in dry-run
5. **Org detection:** .env file (`KG_ORG=personal`)
6. **Public source detection:** URLs + tags + git + manual override
7. **Classification:** Auto-detect with user override
8. **Default visibility:** Smart detection (enables network effects!)
9. **Attribution:** Single-char link (ⁱ) to source

**Critical insight from user:**
> "If I make the default A [org-private], I am basically accepting that
> no one would share their data, especially publicly available."

**Smart defaults enable network effects** - this is the winning strategy.

---

## How to Resume

### Option A: Build All Components (Recommended)

**Single session, ~2 hours:**
```
1. Build conversation log parser
2. Build chunking logic
3. Build deduplication
4. Build pipeline orchestrator
5. Add CLI commands
6. Add attribution system
7. Test with October logs
```

**Deliverable:**
```bash
./knowledge import conversation-logs/2025-10/ --dry-run
# Preview shows 5 sample blocks with visibility classification

./knowledge import conversation-logs/2025-10/
# Imports in <60s, creates searchable blocks

./knowledge search "PostgreSQL setup"
# Finds Week 1 session, shows (ⁱ) attribution if from public source
```

### Option B: Incremental Build

**Build and test one component at a time:**
```
Session 1: Parser + test
Session 2: Chunking + pipeline + test
Session 3: CLI + attribution + full test
```

### Option C: Use Existing Logs as Test Data

**Start with parser, immediately test against real data:**
```
Find: /Users/BertSmith/personal/builder-platform/conversation-logs/2025-10/
Parse: session-2025-10-24-knowledge-graph-genesis.md
Extract: Blocks with visibility = "org-private" (no public URLs)
Import: Single file first, verify database
Then: Batch import all October logs
```

---

## Success Criteria (Week 1.5 Complete)

**Must Have:**
- ✅ Import all October conversation logs
- ✅ Search finds relevant sessions
- ✅ No duplicates on reimport
- ✅ <60s for full October import
- ✅ Dry-run preview works (5 samples)
- ✅ Visibility auto-classification works
- ✅ Attribution preserved for public sources

**Deliverable CLI:**
```bash
./knowledge import conversation-logs/ --dry-run
./knowledge import conversation-logs/
./knowledge search "PostgreSQL setup"
./knowledge import stats
```

---

## Context from Last Session

**User Profile:**
- 50-year-old second-act founder
- CTO/Cloud Architect/Consultant
- Part-time builder with job constraints
- Multi-client work (UTA + others)
- Privacy-focused, compliance-aware
- Building for 5-10 year infrastructure play

**User's Vision:**
- Public knowledge sharing (network effects)
- Organization-private isolation (compliance)
- Individual workspaces (personal research)
- Anonymized contributions (opt-in patterns)
- Enterprise-ready from Day 1

**User's Workflow:**
- Ghostty + tmux (Claude left, Neovim top-right, terminal bottom-right)
- Heavy tmux + neovim user
- Multiple projects simultaneously (aerospace, builder-platform, etc.)
- Dotfiles managed with Stow

**Communication Style:**
- Prefers direct, technical discussion
- Values well-reasoned design decisions
- Asks clarifying questions when needed
- Appreciates comprehensive specs before code
- "We are spec driven, period"

---

## Files to Review Before Starting

**Schema:**
- `schema.sql` (lines 105-178) - Multi-tenant foundation

**Types:**
- `internal/importer/types.go` - ImportSource, PreBlock with visibility

**Classification:**
- `internal/importer/classification.go` - Auto-detection logic

**Spec:**
- `agent-os/specs/import-system.md` - Complete design (600+ lines)

**Example Log:**
- `conversation-logs/2025-10/session-2025-10-15-1600.md` - Real format

---

## Quick Start Command (Next Session)

```
Resume from: Week 1.5 Import Implementation
Last commit: 05696eb
Read: NEXT-SESSION.md (this file)
Build: Conversation log parser first
Test against: conversation-logs/2025-10/
Goal: Import working in ~2 hours
```

**Ready to build.** Foundation is solid. Implementation is straightforward. 🎯
