# Knowledge Graph Import System

## Overview

The import system provides hash-based deduplication and intelligent import decisions for conversation logs, specifications, documentation, and working files.

## Architecture

```
┌─────────────────┐
│  Source Files   │
│  (.md files)    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  File Discovery │ ← Discovery.go
│  & Hashing      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Deduplication  │ ← Deduplication.go
│  (Hash Check)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Import Decision │ → Insert / Update / Skip
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  ImportBlock()  │ ← postgres.go
│  Database Ops   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Import History  │
│  Tracking       │
└─────────────────┘
```

## Components

### 1. Deduplication Logic (`deduplication.go`)

**Purpose:** Determine what action to take for each PreBlock based on import history.

**Key Function:**
```go
func DeduplicateBlocks(ctx context.Context, kg core.KnowledgeGraph, preBlocks []PreBlock) ([]ImportDecision, error)
```

**Decision Logic:**

1. **Query Import History** for `(source_file, file_hash)`
2. **Decision Tree:**
   - **NOT FOUND** → `"insert"` (new file)
   - **FOUND with SAME hash** → `"skip"` (unchanged)
   - **FOUND with DIFFERENT hash:**
     - If **immutable** (conversation-log) → `"skip"` (cannot update)
     - If **updateable** (spec, doc) → `"update"` (reimport)

**Special Rules:**
- **Conversation Logs:** IMMUTABLE - never update existing blocks
- **Specs/Docs:** UPDATEABLE - reimport if hash changed
- **Working Files:** UPDATEABLE - reimport if hash changed

### 2. Import Functions (`postgres.go`)

**Purpose:** Insert PreBlocks into database with full transaction support.

**Key Function:**
```go
func (p *PostgresDB) ImportBlock(ctx context.Context, preBlock interface{}, batchID uuid.UUID) (*types.Block, error)
```

**Import Process:**

1. **Get/Create Organization** (from env `KG_ORG` or default "personal")
2. **Get/Create Project** (from directory path)
3. **Generate Embeddings** (block topic + exchanges)
4. **Insert Block** with:
   - Organization ID, Project ID
   - Visibility, Source tracking
   - Import batch ID
   - Vector embedding
5. **Insert Exchanges** with embeddings
6. **Insert Tags** (if provided)
7. **Update Import History** (mark as completed)

**Transaction Guarantees:**
- All-or-nothing: rollback on any failure
- Import history updated atomically
- Consistent state maintained

### 3. Import History Tracking

**Database Table:** `import_history`

**Fields:**
```sql
CREATE TABLE import_history (
    id UUID PRIMARY KEY,
    source_file TEXT NOT NULL,
    file_hash TEXT NOT NULL,
    imported_at TIMESTAMP,
    updated_at TIMESTAMP,
    block_count INT,
    import_type TEXT,           -- "conversation-log", "spec", "doc"
    status TEXT,                 -- "in-progress", "completed", "failed"
    visibility TEXT,             -- "public", "org-private", "individual"
    source_classification TEXT,  -- "public-web", "private-repo", "client-data"
    organization_id UUID,
    error_message TEXT,
    UNIQUE(source_file, file_hash)
);
```

**Purpose:**
- Track what files have been imported
- Detect file changes via hash comparison
- Enable idempotent reimports
- Support multi-organization isolation

### 4. Helper Functions

**Organization Management:**
```go
func (p *PostgresDB) GetOrCreateOrganization(ctx context.Context, name, tier string) (*Organization, error)
```

**Import History Queries:**
```go
func (p *PostgresDB) QueryImportHistory(ctx context.Context, sourceFile, fileHash string) (*ImportHistoryRecord, error)
func (p *PostgresDB) QueryBlocksBySource(ctx context.Context, sourceFile string) ([]BlockSourceRecord, error)
```

**Batch Management:**
```go
func (p *PostgresDB) CreateImportBatch(ctx context.Context, sourceFile, fileHash, importType, visibility, sourceClass string, orgID *uuid.UUID) (uuid.UUID, error)
```

## Usage Example

### Complete Import Workflow

```go
package main

import (
    "context"
    "github.com/TheGenXCoder/knowledge-graph/internal/db"
    "github.com/TheGenXCoder/knowledge-graph/internal/importer"
)

func ImportConversationLog(ctx context.Context, kg *db.PostgresDB, logFile string) error {
    // 1. Parse source file into PreBlocks
    preBlocks := []importer.PreBlock{
        {
            Topic: "Import System Implementation",
            Exchanges: []importer.PreExchange{
                {
                    Question: "How does deduplication work?",
                    Answer: "Uses hash-based detection...",
                },
            },
            SourceFile: logFile,
            SourceType: "conversation-log",
            SourceHash: "abc123...",
            Visibility: "org-private",
        },
    }

    // 2. Deduplicate
    decisions, err := importer.DeduplicateBlocks(ctx, kg, preBlocks)
    if err != nil {
        return err
    }

    // 3. Create import batch
    batchID, err := kg.CreateImportBatch(ctx,
        logFile,
        preBlocks[0].SourceHash,
        "conversation-log",
        "org-private",
        "private-repo",
        nil, // Use default org
    )
    if err != nil {
        return err
    }

    // 4. Import new/updated blocks
    for _, decision := range decisions {
        if decision.Action == "insert" {
            _, err := kg.ImportBlock(ctx, decision.PreBlock, batchID)
            if err != nil {
                return err
            }
        }
    }

    return nil
}
```

### Decision Filtering

```go
// Get only blocks that need insertion
insertions := importer.FilterByAction(decisions, "insert")

// Get summary counts
summary := importer.SummarizeDecisions(decisions)
fmt.Printf("Insert: %d, Update: %d, Skip: %d\n",
    summary["insert"], summary["update"], summary["skip"])
```

## Error Handling

### Import Failures

**Transaction Rollback:**
- If any step fails during `ImportBlock()`, the entire transaction is rolled back
- Import history is marked as "failed" with error message
- Database remains in consistent state

**Partial Import Recovery:**
```go
// Import history tracks status per batch
batchID, _ := kg.CreateImportBatch(...)  // status: "in-progress"
err := kg.ImportBlock(...)                // If succeeds: status → "completed"
                                          // If fails: status → "failed"
```

**Retry Strategy:**
- Failed imports can be retried with same batch ID
- Or create new batch for clean retry
- Import history maintains full audit trail

## Multi-Organization Support

### Organization Isolation

**Default Organization:**
```bash
export KG_ORG="acme-corp"  # Use specific org
# Or leave unset to use "personal" org
```

**Organization Creation:**
```go
org, err := kg.GetOrCreateOrganization(ctx, "acme-corp", "enterprise")
```

**Visibility Levels:**
- `"public"` - Shareable across organizations
- `"org-private"` - Organization-only access
- `"individual"` - Single user access
- `"anonymized"` - Sanitized for sharing

### Project Association

Projects are automatically created from directory paths and associated with organizations:

```go
// Auto-creates project from path
project, err := kg.GetOrCreateProjectTx(ctx, tx,
    "/Users/BertSmith/personal/builder-platform",
    orgID,
)
```

## Performance Considerations

### Embedding Generation

**Cost:**
- 1 embedding per block (topic + exchanges)
- 1 embedding per exchange (question + answer)
- Uses Ollama nomic-embed-text (768 dimensions)

**Optimization:**
- Batch embedding generation (future)
- Cache embeddings for repeated imports
- Async embedding generation (Week 2+)

### Database Operations

**Indexes Used:**
- `idx_import_history_source_file` - Fast deduplication lookups
- `idx_blocks_source` - Quick source file queries
- `idx_blocks_embedding` - HNSW vector search

**Transaction Size:**
- 1 transaction per block import
- Keeps lock duration minimal
- Enables parallel imports (future)

## Testing

### Unit Tests

```go
func TestDeduplicateBlocks(t *testing.T) {
    // Test new file → insert
    // Test unchanged file → skip
    // Test changed file → update (if updateable)
    // Test changed conversation-log → skip (immutable)
}
```

### Integration Tests

```go
func TestCompleteImportWorkflow(t *testing.T) {
    // 1. Import new file
    // 2. Verify blocks created
    // 3. Reimport same file → all skipped
    // 4. Modify file
    // 5. Reimport → updates processed
}
```

## Future Enhancements

### Week 2+

- **Batch Import API** - Import multiple files in one transaction
- **Update Implementation** - Actually update blocks (currently only detects)
- **Async Processing** - Background embedding generation
- **Import Metrics** - Track import performance and statistics
- **Validation** - Pre-import validation of PreBlocks
- **Conflict Resolution** - Handle concurrent imports

### Week 3+

- **Public Knowledge Pool** - Import from public sources (Stack Overflow, GitHub, docs)
- **Source Attribution** - Automatic citation generation
- **Compliance Checking** - PII detection, HIPAA/SOC2/GDPR validation
- **Smart Updates** - Incremental updates instead of full reimport

## Summary

The import system provides:

✅ **Hash-based deduplication** - Skip unchanged files
✅ **Intelligent decisions** - Insert/Update/Skip based on source type
✅ **Transaction safety** - All-or-nothing imports
✅ **Import history** - Full audit trail
✅ **Multi-organization** - Isolation and visibility control
✅ **Source tracking** - Know where blocks came from
✅ **Immutability rules** - Conversation logs never change

This enables **idempotent imports** and **intelligent reimports** as source files evolve.
