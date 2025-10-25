# Quick Reference: Import System

## Basic Import Workflow

```go
import (
    "context"
    "github.com/TheGenXCoder/knowledge-graph/internal/db"
    "github.com/TheGenXCoder/knowledge-graph/internal/importer"
)

func ImportFile(ctx context.Context, kg *db.PostgresDB, sourceFile string) error {
    // 1. Parse file into PreBlocks (parser not shown)
    preBlocks := parseFile(sourceFile)

    // 2. Deduplicate
    decisions, err := importer.DeduplicateBlocks(ctx, kg, preBlocks)
    if err != nil {
        return err
    }

    // 3. Create batch
    batchID, err := kg.CreateImportBatch(ctx,
        sourceFile,
        preBlocks[0].SourceHash,
        preBlocks[0].SourceType,
        "org-private",
        "private-repo",
        nil, // default org
    )
    if err != nil {
        return err
    }

    // 4. Import new blocks
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

## Decision Types

| Action | Meaning | When Used |
|--------|---------|-----------|
| `insert` | Import new block | File never seen before |
| `skip` | Do nothing | File unchanged (hash match) OR immutable source type changed |
| `update` | Reimport block | File changed AND source type is updateable |

## Source Types

| Type | Immutable? | Update Behavior |
|------|-----------|-----------------|
| `conversation-log` | ✅ YES | Never update, always skip |
| `spec` | ❌ NO | Reimport if hash changed |
| `doc` | ❌ NO | Reimport if hash changed |
| `working-file` | ❌ NO | Reimport if hash changed |

## Decision Filtering

```go
// Get only insertions
inserts := importer.FilterByAction(decisions, "insert")

// Get only updates
updates := importer.FilterByAction(decisions, "update")

// Get summary
summary := importer.SummarizeDecisions(decisions)
fmt.Printf("Insert: %d, Update: %d, Skip: %d\n",
    summary["insert"], summary["update"], summary["skip"])
```

## Creating PreBlocks

```go
import "time"

preBlock := importer.PreBlock{
    Topic: "My Conversation Topic",
    Exchanges: []importer.PreExchange{
        {
            Question: "What is X?",
            Answer: "X is...",
            Timestamp: time.Now(),
            ModelUsed: "claude-sonnet-4",
        },
    },
    Metadata: map[string]interface{}{
        "session_id": "abc123",
    },
    Tags: []string{"tag1", "tag2"},
    ProjectPath: "/path/to/project",
    SourceFile: "/path/to/file.md",
    SourceType: "conversation-log",
    SourceHash: "sha256-hash-here",
    StartedAt: time.Now(),
    CompletedAt: &now,
    Visibility: "org-private",
}
```

## Import History Queries

```go
// Check if file was already imported
record, err := kg.QueryImportHistory(ctx, sourceFile, fileHash)
if err == sql.ErrNoRows {
    // File never imported
}

// Find all blocks from a source file
blocks, err := kg.QueryBlocksBySource(ctx, sourceFile)
```

## Organization Management

```go
// Create/get organization
org, err := kg.GetOrCreateOrganization(ctx, "my-org", "team")

// Use environment variable
// export KG_ORG="my-org"
// Will auto-create if needed
```

## Error Handling

```go
block, err := kg.ImportBlock(ctx, preBlock, batchID)
if err != nil {
    // Transaction rolled back automatically
    // Import history marked as "failed"
    return fmt.Errorf("import failed: %w", err)
}
```

## Import Batch Tracking

```go
// Create batch (status: "in-progress")
batchID, err := kg.CreateImportBatch(ctx, ...)

// Import blocks
// (automatically updates status to "completed" on success)
kg.ImportBlock(ctx, preBlock, batchID)

// On failure, status → "failed" with error message
```

## Visibility Levels

| Level | Description |
|-------|-------------|
| `public` | Shareable across organizations |
| `org-private` | Organization-only access |
| `individual` | Single user access |
| `anonymized` | Sanitized for sharing |

## Common Patterns

### Import with Progress

```go
insertions := importer.FilterByAction(decisions, "insert")
for i, decision := range insertions {
    fmt.Printf("[%d/%d] Importing: %s\n", i+1, len(insertions), decision.PreBlock.Topic)
    _, err := kg.ImportBlock(ctx, decision.PreBlock, batchID)
    if err != nil {
        fmt.Printf("ERROR: %v\n", err)
        continue
    }
}
```

### Dry Run

```go
decisions, err := importer.DeduplicateBlocks(ctx, kg, preBlocks)
summary := importer.SummarizeDecisions(decisions)

fmt.Printf("Would insert: %d blocks\n", summary["insert"])
fmt.Printf("Would skip: %d blocks\n", summary["skip"])

// Don't call ImportBlock() - just show what would happen
```

### Batch Import Multiple Files

```go
for _, sourceFile := range sourceFiles {
    preBlocks := parseFile(sourceFile)
    decisions, _ := importer.DeduplicateBlocks(ctx, kg, preBlocks)

    batchID, _ := kg.CreateImportBatch(ctx, sourceFile, ...)

    for _, decision := range decisions {
        if decision.Action == "insert" {
            kg.ImportBlock(ctx, decision.PreBlock, batchID)
        }
    }
}
```

## Testing Helpers

```go
// Create sample PreBlock
sample := importer.CreateSamplePreBlock(
    "Test Topic",
    "/path/to/file.md",
    "conversation-log",
)

// Print decision details
importer.PrintImportDecision(decision)
```

## Key Files

- **Core Logic:** `/internal/importer/deduplication.go`
- **Import Functions:** `/internal/db/postgres.go`
- **Types:** `/internal/importer/types.go`
- **Examples:** `/internal/importer/example_import.go`
- **Docs:** `/docs/import-system.md`

## Quick Tips

1. **Always deduplicate first** - Don't import without checking
2. **Use transactions** - ImportBlock handles this automatically
3. **Check decision reasons** - Understanding why helps debugging
4. **Filter by action** - Process insert/update/skip separately
5. **Track batch IDs** - Essential for audit trail
6. **Set visibility correctly** - Can't change after import
7. **Conversation logs are immutable** - Design accordingly
