# Import System Specification

**Status:** Design Phase
**Target:** Week 1.5 - 2.0
**Priority:** Table Stakes (Required for Market)

---

## The Problem

**Table Stakes Requirement:** Users will NOT accept "start with empty knowledge base."

Every user has:
- Years of conversation logs
- Existing documentation
- Specifications and decisions
- README files and wikis
- Code comments and commit messages

**The expectation:** "Import my existing knowledge and make it searchable."

**Our position:** Import is not optional. It's the entry point.

---

## Design Principles

### 1. Source-Aware
- Track where every block came from
- Preserve original file paths
- Enable updates when source changes
- Support reimport without duplication

### 2. Format-Agnostic
- Markdown (primary)
- Plain text
- Code files (comments/docstrings)
- Git logs
- Future: PDFs, web pages, etc.

### 3. Intelligent Chunking
- Respect natural boundaries (sessions, sections, functions)
- Optimal block size (3-5 exchanges equivalent)
- Preserve relationships between chunks
- Link related blocks automatically

### 4. Quality-First
- Dry-run preview before import
- Validation and error reporting
- Progress tracking
- Rollback capability
- Deduplication

### 5. Incremental
- Import new files only
- Update changed files
- Skip unchanged files
- Resume on failure

---

## Import Sources (Prioritized)

### Priority 1: Conversation Logs

**Format:** Structured Markdown
**Location:** `conversation-logs/YYYY-MM/session-*.md`
**Value:** Immediate searchable Q&A history

**Structure:**
```markdown
# Session Log: YYYY-MM-DD - [Title]

**Project:** [project-name]
**Started:** [timestamp]

## Session Goal
[User's intent]

## [HH:MM] - [Milestone/Decision]
**Progress:** [Work completed]
**Decisions:** [Technical decisions]
**Files:** [Created/modified]

## Session Summary
**Completed:** [Accomplishments]
**Outcome:** [Result]

## Tag Index
#tag1 #tag2 #tag3
```

**Mapping to Blocks:**
- **Topic:** Session title or Session Goal
- **Exchanges:** Milestone sections → Q&A pairs
  - Question: Milestone title
  - Answer: Progress + Decisions + Files
- **Metadata:**
  - `source_file`: Original log path
  - `source_type`: "conversation-log"
  - `session_date`: From filename
  - `session_id`: From filename
  - `outcome`: From summary
- **Tags:** Extract from Tag Index section
- **Project:** From session metadata

**Chunking Strategy:**
- One block per session (natural boundary)
- If session >10 exchanges, split by major milestones
- Preserve session_id across chunks

**Example Block:**
```json
{
  "topic": "Knowledge Graph Week 1 Implementation",
  "project_id": "knowledge-graph-system",
  "exchanges": [
    {
      "question": "Setting up PostgreSQL with pgvector",
      "answer": "Upgraded from PostgreSQL 14 to 17. Created schema with 768-dim vectors.",
      "timestamp": "2025-10-24T22:00:00Z"
    },
    {
      "question": "Fixed dimension mismatch error",
      "answer": "Changed VECTOR(384) to VECTOR(768) in schema. Test passed at 67ms.",
      "timestamp": "2025-10-24T22:22:00Z"
    }
  ],
  "metadata": {
    "source_file": "conversation-logs/2025-10/session-2025-10-24-2200.md",
    "source_type": "conversation-log",
    "session_date": "2025-10-24",
    "outcome": "Week 1 Complete - All tests passing"
  },
  "tags": ["postgresql", "pgvector", "week-1"]
}
```

---

### Priority 2: Working Files (.working.md)

**Format:** Structured Markdown
**Location:** `<project-root>/.working.md`
**Value:** Current session state, recent decisions

**Structure:**
```markdown
# Working Context - [timestamp]

**Status:** Active | Checkpointed | Ready-for-Compact

## Session Overview
**Initial Goal:** [Goal]
**Current Focus:** [Current work]

## Progress Summary
### Completed
- ✅ [Task with outcome]

### In Progress
- 🔄 [Current task]

## Key Decisions
- [Decision with rationale]

## Files Modified
**Created:**
- path/to/file.ext - [Purpose]

**Modified:**
- path/to/file.ext - [Changes]
```

**Mapping to Blocks:**
- **Topic:** Initial Goal or Current Focus
- **Exchanges:**
  - Completed tasks → Q&A pairs (Task → Outcome)
  - Key Decisions → Q&A pairs (Decision → Rationale)
- **Metadata:**
  - `source_file`: `.working.md` path
  - `source_type`: "working-file"
  - `status`: From Status field
  - `files_modified`: From Files Modified section
- **Project:** Detect from directory path

**Special Handling:**
- Only import if Status = "Checkpointed" or "Session-Complete"
- Skip if Status = "Active" (incomplete)
- Update existing block if reimporting same session

---

### Priority 3: Specifications

**Format:** Hierarchical Markdown
**Location:** `agent-os/specs/`, `builds/*/specs/`, `projects/*/specs/`
**Value:** Architecture decisions, requirements, design docs

**Structure:**
```markdown
# [Specification Title]

## Overview
[High-level description]

## Architecture
### Component A
[Design details]

### Component B
[Design details]

## Implementation
### Step 1: [Task]
[Requirements]

### Step 2: [Task]
[Requirements]
```

**Mapping to Blocks:**
- **Chunking:** Split by H2 sections (## headers)
- **Topic:** H1 + H2 (e.g., "Week 1 Core System - Architecture")
- **Exchanges:** H3 subsections → Q&A pairs
  - Question: H3 header
  - Answer: Content under H3
- **Metadata:**
  - `source_file`: Spec file path
  - `source_type`: "specification"
  - `spec_section`: H2 section name
- **Relationships:** Link all blocks from same spec file

**Example Chunking:**

Source: `agent-os/specs/week-1-core-system.md`

→ Block 1:
- Topic: "Week 1 Core System - Architecture"
- Exchanges: [Database Schema, Core API, Search Implementation]

→ Block 2:
- Topic: "Week 1 Core System - Implementation"
- Exchanges: [Setup PostgreSQL, Build Go API, Create MCP Server]

→ Relationship: "derived-from" linking Block 2 → Block 1

---

### Priority 4: Product Documentation

**Format:** Markdown
**Location:** `agent-os/product/`, `*/README.md`, `*/MISSION.md`
**Value:** Strategic context, product vision, roadmaps

**Structure:** Variable (mission, roadmap, tech stack, etc.)

**Mapping to Blocks:**
- **Chunking:** Split by H2 sections
- **Topic:** Document type + Section (e.g., "Product Mission - Vision")
- **Exchanges:** H3 subsections → Q&A pairs
- **Metadata:**
  - `source_file`: Doc file path
  - `source_type`: "product-doc" | "readme" | "mission"
  - `doc_section`: H2 section name

**Special Handling:**
- README files: Topic = "Project: {name} - {section}"
- Link all product docs to project
- Tag with: #product, #strategy, #roadmap

---

### Priority 5: Code Files (Week 3+)

**Format:** Language-specific (Go, Python, JavaScript, etc.)
**Location:** `**/*.go`, `**/*.py`, `**/*.js`, etc.
**Value:** Implementation details, API documentation

**Mapping to Blocks:**
- **Chunking:** By function/class/module
- **Topic:** "{FileName} - {FunctionName}"
- **Exchanges:**
  - Question: Function signature
  - Answer: Docstring/comments + implementation summary
- **Metadata:**
  - `source_file`: Code file path
  - `source_type`: "code"
  - `language`: Detected language
  - `function_name`: Function/class name

**Not for Week 1.5-2.0** (complexity, requires AST parsing)

---

### Priority 6: Git Commits (Week 3+)

**Format:** Git log
**Location:** `.git/`
**Value:** Historical decisions, evolution context

**Mapping to Blocks:**
- **Topic:** Commit message (first line)
- **Exchanges:**
  - Question: "What changed in commit {hash}?"
  - Answer: Commit body + file diffs summary
- **Metadata:**
  - `source_type`: "git-commit"
  - `commit_hash`: SHA
  - `author`: Commit author
  - `timestamp`: Commit date

**Not for Week 1.5-2.0** (lower value, more complexity)

---

## Import Pipeline Architecture

### Stage 1: Discovery

**Input:** Directory path, file patterns
**Output:** List of files to import

```go
type ImportSource struct {
    FilePath     string
    FileType     string // "conversation-log", "spec", "readme", etc.
    LastModified time.Time
    FileHash     string // For deduplication
}

func DiscoverSources(rootDir string, opts DiscoveryOptions) ([]ImportSource, error)
```

**Features:**
- Recursive directory scanning
- Glob pattern matching
- File type detection
- Exclude patterns (.git, node_modules, etc.)
- Respect .gitignore
- Hash calculation for deduplication

**CLI:**
```bash
./knowledge import discover /path/to/project --type logs,specs,docs
```

---

### Stage 2: Parsing

**Input:** ImportSource
**Output:** Parsed document structure

```go
type ParsedDocument struct {
    Source      ImportSource
    Metadata    map[string]interface{}
    Sections    []Section
}

type Section struct {
    Level    int    // H1=1, H2=2, etc.
    Title    string
    Content  string
    Children []Section
}

func ParseDocument(source ImportSource) (*ParsedDocument, error)
```

**Parsers:**
- **MarkdownParser** (primary)
  - Parse headers (H1-H6)
  - Extract metadata (frontmatter, structured sections)
  - Preserve hierarchy
- **ConversationLogParser** (specialized)
  - Recognize session structure
  - Extract timestamps
  - Parse milestone sections
  - Extract tags
- **WorkingFileParser** (specialized)
  - Parse status
  - Extract completed/pending tasks
  - Extract decisions
- **PlainTextParser** (fallback)
  - Paragraph-based chunking
  - No structure preservation

**CLI:**
```bash
./knowledge import parse /path/to/file.md --preview
```

---

### Stage 3: Chunking

**Input:** ParsedDocument
**Output:** Blocks (pre-embedding)

```go
type PreBlock struct {
    Topic       string
    Exchanges   []Exchange
    Metadata    map[string]interface{}
    Tags        []string
    ProjectPath string
}

func ChunkDocument(doc *ParsedDocument, opts ChunkOptions) ([]PreBlock, error)
```

**Chunking Strategies:**

**1. Session-Based (Conversation Logs):**
- One block per session
- Split if >10 exchanges
- Preserve session_id across chunks

**2. Section-Based (Specs, Docs):**
- One block per H2 section
- Merge small sections (<2 exchanges)
- Link related blocks from same doc

**3. Natural Boundary (Working Files):**
- One block per checkpoint
- Group related decisions

**4. Size-Based (Fallback):**
- Target 3-5 exchanges per block
- Respect paragraph boundaries
- Overlap 20% for context

**Quality Rules:**
- Minimum block size: 1 exchange
- Maximum block size: 15 exchanges
- Preserve relationships between chunks
- Track original section/line numbers

**CLI:**
```bash
./knowledge import chunk /path/to/file.md --strategy session --preview
```

---

### Stage 4: Deduplication

**Input:** PreBlocks
**Output:** New or updated blocks

```go
type ImportDecision struct {
    Action     string // "insert", "update", "skip"
    PreBlock   *PreBlock
    ExistingID *uuid.UUID
    Reason     string
}

func DeduplicateBlocks(preBlocks []PreBlock) ([]ImportDecision, error)
```

**Deduplication Strategy:**

**Primary Key:** `source_file` + `source_section`

**Decision Logic:**
1. Check if source_file exists in database
2. If NO → Action: "insert" (new block)
3. If YES → Compare file hash
   - Same hash → Action: "skip" (unchanged)
   - Different hash → Action: "update" (file changed)

**Update Strategy:**
- Preserve original block ID
- Update topic, exchanges, embedding
- Increment version number
- Track update timestamp
- Keep original created_at

**Special Cases:**
- Working files: Always update if status changed
- Conversation logs: Never update (immutable history)
- Specs/docs: Update if file modified

**CLI:**
```bash
./knowledge import deduplicate --dry-run
```

---

### Stage 5: Enrichment (Week 2 Integration)

**Input:** PreBlocks
**Output:** Enriched PreBlocks (with tags, relationships)

```go
func EnrichBlocks(preBlocks []PreBlock) ([]PreBlock, error) {
    // Week 2 feature integration:
    // - Auto-tag extraction using local LLM
    // - Relationship inference
    // - Cross-reference detection
}
```

**Week 1.5:** Skip enrichment (manual tags only)
**Week 2:** Add auto-tagging and relationship inference

---

### Stage 6: Import

**Input:** Import Decisions
**Output:** Saved blocks in database

```go
func ExecuteImport(decisions []ImportDecision) (*ImportReport, error)
```

**Import Process:**
1. Get or create project
2. For each decision:
   - Insert: Create new block + exchanges + embeddings
   - Update: Update existing block + regenerate embeddings
   - Skip: Log skip reason
3. Generate import report
4. Update import metadata table

**Import Metadata Table:**
```sql
CREATE TABLE import_history (
    id UUID PRIMARY KEY,
    source_file TEXT NOT NULL,
    file_hash TEXT NOT NULL,
    imported_at TIMESTAMP NOT NULL,
    block_count INT NOT NULL,
    import_type TEXT, -- "conversation-log", "spec", etc.
    UNIQUE(source_file, file_hash)
);
```

**CLI:**
```bash
./knowledge import execute --from-decisions decisions.json
```

---

## CLI Interface

### Discovery Commands

```bash
# Discover all importable files
./knowledge import discover <directory> [options]

Options:
  --type <types>        File types (logs,specs,docs,working,all)
  --exclude <patterns>  Exclude patterns (glob)
  --output <file>       Save discovered files to JSON

Examples:
  ./knowledge import discover ~/builder-platform --type logs
  ./knowledge import discover . --type all --exclude "node_modules/*"
```

### Import Commands

```bash
# Full import pipeline (discover → parse → chunk → deduplicate → import)
./knowledge import <directory> [options]

Options:
  --type <types>        File types to import (default: all)
  --dry-run            Preview without importing
  --skip-duplicates    Skip deduplication (force insert)
  --update-only        Only update existing blocks
  --exclude <patterns> Exclude file patterns
  --batch-size <n>     Process N files at a time (default: 10)
  --progress           Show progress bar
  --verbose            Detailed logging

Examples:
  ./knowledge import ~/builder-platform --type logs --dry-run
  ./knowledge import . --type specs,docs --progress
  ./knowledge import conversation-logs/ --update-only
```

### Granular Commands (For Debugging)

```bash
# Parse single file
./knowledge import parse <file> --preview

# Chunk document
./knowledge import chunk <file> --strategy <strategy> --preview

# Check for duplicates
./knowledge import deduplicate <file> --dry-run

# Import specific file
./knowledge import file <file> [--force-update]
```

### Report Commands

```bash
# Show import history
./knowledge import history [--limit 10]

# Show import stats
./knowledge import stats

# Reimport changed files
./knowledge import sync <directory>
```

---

## Progress Reporting

**Real-time Progress:**
```
Discovering files...
✓ Found 47 conversation logs
✓ Found 12 specifications
✓ Found 8 README files

Parsing documents...
[████████████████░░░░] 80% (67/84 files)
Current: conversation-logs/2025-10/session-2025-10-24.md

Chunking into blocks...
✓ Created 134 blocks from 67 files

Deduplication...
✓ 89 new blocks
✓ 23 updates
✓ 22 skipped (unchanged)

Generating embeddings...
[██████████████████░░] 90% (121/134 blocks)
Current: "Week 1 Core System - Architecture"

Importing to database...
✓ Inserted 89 blocks
✓ Updated 23 blocks
✓ Total: 112 blocks imported

Import complete! ✅
Time: 45.2s
Blocks: 112
Projects: 3
```

---

## Error Handling

**Validation Errors:**
- Invalid file format → Skip file, log warning
- Parse failure → Skip file, log error
- Missing required fields → Skip block, log error

**Database Errors:**
- Connection failure → Retry 3x, then fail
- Unique constraint → Log and skip
- Embedding generation failure → Retry, fallback to empty

**Recovery:**
- Save progress after each batch
- Resume from last successful batch
- Export failed files for manual review

**CLI:**
```bash
# Resume failed import
./knowledge import resume <import-id>

# Review failed files
./knowledge import failures <import-id>
```

---

## Quality Control

### Dry-Run Mode

**Preview before import:**
```bash
./knowledge import ~/builder-platform --dry-run

Preview:
  Files to import: 67
  Estimated blocks: 134
  New: 89
  Updates: 23
  Skipped: 22

Sample blocks:
  1. "Knowledge Graph Week 1 Implementation"
     - 5 exchanges
     - Tags: #postgresql, #pgvector, #week-1
     - Source: conversation-logs/2025-10/session-2025-10-24.md

  2. "Week 1 Core System - Architecture"
     - 8 exchanges
     - Tags: #architecture, #design
     - Source: agent-os/specs/week-1-core-system.md

Proceed with import? [y/N]
```

### Validation

**Pre-import validation:**
- File format check
- Required fields present
- Valid project path
- No circular relationships

**Post-import validation:**
- Verify block count matches
- Check embeddings generated
- Validate relationships
- Ensure project associations

---

## Rollback Capability

**Import Transactions:**
```sql
CREATE TABLE import_batches (
    id UUID PRIMARY KEY,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    status TEXT, -- "in-progress", "completed", "rolled-back"
    file_count INT,
    block_count INT
);
```

**Rollback:**
```bash
# Rollback last import
./knowledge import rollback

# Rollback specific import
./knowledge import rollback <import-id>
```

**Implementation:**
- Track import_batch_id on each block
- Delete blocks WHERE import_batch_id = <id>
- Restore previous versions if updated

---

## Implementation Plan

### Week 1.5: Conversation Logs Import (Priority 1)

**Scope:**
- Implement full pipeline for conversation logs only
- CLI: discover, parse, chunk, deduplicate, import
- Dry-run and progress reporting
- Error handling and validation

**Deliverables:**
```bash
./knowledge import conversation-logs/ --dry-run
./knowledge import conversation-logs/ --progress
./knowledge import stats
```

**Success Metric:**
- Import all `conversation-logs/2025-10/*.md`
- Search works across imported sessions
- Sub-60s for full October import

**Files to Create:**
- `internal/importer/discovery.go`
- `internal/importer/parsers/conversation_log.go`
- `internal/importer/chunking.go`
- `internal/importer/deduplication.go`
- `internal/importer/pipeline.go`
- `cmd/knowledge/import.go` (CLI commands)
- `schema.sql` (add import_history table)

**Testing:**
- Unit tests for each parser
- Integration test: full import pipeline
- Test with real conversation logs

**Dogfooding:**
- Import October 2025 sessions
- Search for "PostgreSQL setup"
- Verify results include Week 1 session

---

### Week 2: Specs + Docs Import (Priority 2-4)

**Scope:**
- Add parsers for specs, docs, working files
- Implement enrichment (auto-tag, relationships)
- Batch processing optimization
- Resume on failure

**Deliverables:**
```bash
./knowledge import . --type all
./knowledge import sync .  # Reimport changed files
```

---

### Week 3+: Code + Git (Priority 5-6)

**Scope:**
- Code file parsing (AST-based)
- Git commit import
- Advanced relationship inference

**Deliverables:**
```bash
./knowledge import --type code
./knowledge import --type git
```

---

## Open Questions (For Design Discussion)

### 1. Block Size Trade-offs

**Question:** What's the optimal block size for search quality vs. precision?

**Options:**
- A) Small blocks (1-3 exchanges): More precise search, more results
- B) Medium blocks (3-5 exchanges): Balanced
- C) Large blocks (5-10 exchanges): More context, fewer results

**Recommendation:** Start with B (3-5), make configurable

---

### 2. Reimport Strategy

**Question:** When user reimports same directory, what's the expected behavior?

**Options:**
- A) Skip everything (fast, no updates)
- B) Check file hashes, update changed files (smart)
- C) Always reimport (slow, duplicate risk)

**Recommendation:** B (hash-based incremental)

---

### 3. Large File Handling

**Question:** How to handle very large files (10MB+ markdown docs)?

**Options:**
- A) Reject files over size limit
- B) Chunk into multiple blocks
- C) Summarize with LLM before importing

**Recommendation:** B for Week 1.5, consider C for Week 2

---

### 4. Relationship Auto-Detection

**Question:** Should we auto-detect relationships during import?

**Examples:**
- File A references File B → "related-to"
- Session builds on previous session → "derived-from"
- Spec → Implementation session → "implements"

**Options:**
- A) Not in Week 1.5 (manual relationships only)
- B) Simple pattern matching (file references)
- C) LLM-based inference (Week 2)

**Recommendation:** A for Week 1.5, C for Week 2

---

### 5. Preview Granularity

**Question:** How much detail in dry-run preview?

**Options:**
- A) Just counts (N files, N blocks)
- B) Sample blocks (first 3)
- C) Full preview (all blocks, paginated)

**Recommendation:** B (sample blocks)

---

## Success Criteria

### Week 1.5 (Conversation Logs Import)

**Must Have:**
- ✅ Import all October conversation logs
- ✅ Search finds relevant sessions
- ✅ No duplicates on reimport
- ✅ <60s for full October import
- ✅ Dry-run preview works

**Nice to Have:**
- Progress bar
- Error recovery
- Import stats command

---

### Week 2 (Full Import)

**Must Have:**
- ✅ Import specs, docs, working files
- ✅ Auto-tag extraction
- ✅ Relationship inference
- ✅ Batch processing (100+ files)
- ✅ Resume on failure

**Nice to Have:**
- Rollback capability
- Import diff (what changed)
- Web UI preview

---

## Market Positioning

**Messaging:**

❌ **Wrong:** "Start fresh, build your knowledge base from scratch"

✅ **Right:** "Import your existing knowledge in minutes. Years of context, instantly searchable."

**Competitive Advantage:**
- Obsidian: Manual organization
- Notion: No semantic search
- DevDocs: External sources only
- **Us:** Import existing knowledge + semantic search + relationship graph

**Demo Script:**
1. "Here's 3 years of conversation logs..."
2. `./knowledge import conversation-logs/ --progress`
3. "45 seconds later: 347 blocks, instantly searchable"
4. `./knowledge search "How did we solve authentication?"`
5. "Finds relevant session from 2 years ago"

---

## Next Steps

**Immediate (This Session):**
1. ✅ Review this spec
2. ✅ Discuss open questions
3. ✅ Validate approach
4. ✅ Approve for implementation

**Week 1.5 Implementation:**
1. Create import_history table
2. Build conversation log parser
3. Implement chunking logic
4. Build deduplication
5. CLI import commands
6. Test with real logs
7. Dogfood: Import October sessions

**Week 2 Enhancement:**
1. Add spec/doc parsers
2. Integrate auto-tagging
3. Add relationship inference
4. Batch optimization
5. Resume capability

---

**This spec is ready for review and discussion.** 🎯
