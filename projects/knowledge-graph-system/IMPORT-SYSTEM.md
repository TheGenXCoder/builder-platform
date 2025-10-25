# Knowledge Graph Import System

CLI commands and attribution system for importing knowledge into the knowledge graph.

## Features

- **Automatic File Discovery**: Recursively finds conversation logs, specs, and documentation
- **Visibility Classification**: Automatically determines public vs. private content
- **Source Attribution**: Extracts and formats source URLs for public knowledge
- **Import History**: Tracks all imports with deduplication
- **Dry-run Mode**: Preview imports before executing
- **Multi-project Support**: Import into specific projects

## CLI Commands

### Import Files

```bash
./knowledge import <directory> [flags]
```

**Flags:**
- `--dry-run` - Preview import without making changes
- `--visibility <vis>` - Override visibility (public, org-private, individual, auto)
- `--type <types>` - File types to import (logs, specs, docs, all)
- `--exclude <patterns>` - Exclude patterns
- `--progress` - Show progress bar (default: true)
- `--verbose` - Detailed logging

**Examples:**

```bash
# Dry-run preview
./knowledge import conversation-logs/ --dry-run

# Import conversation logs only
./knowledge import /path/to/logs --type logs

# Import with visibility override
./knowledge import /path/to/docs --visibility public

# Import with exclusions
./knowledge import . --exclude "*.test.md,draft-*"
```

### Import Statistics

```bash
./knowledge import stats
```

Shows:
- Total imports
- Total blocks created
- Last import time
- Breakdown by type (logs, specs, docs)
- Breakdown by visibility (public, org-private, individual)

**Example Output:**

```
Import Statistics:

Total imports: 3
Total blocks: 347
Last import: 2025-10-25 10:30

By type:
  conversation-log: 312 blocks
  spec: 23 blocks
  doc: 12 blocks

By visibility:
  org-private: 335 blocks
  public: 12 blocks
```

### Import History

```bash
./knowledge import history [--limit 10]
```

Shows recent imports with:
- File name and path
- Import timestamp
- Type (logs, specs, docs)
- Number of blocks created
- Status (completed, failed)
- Visibility classification

**Example Output:**

```
Recent imports (showing last 10):

1. session-2025-10-24-2200.md
   Imported: 2025-10-25 10:30
   Type: conversation-log
   Blocks: 47
   Status: completed
   Visibility: org-private

2. api-specification.md
   Imported: 2025-10-24 15:22
   Type: spec
   Blocks: 12
   Status: completed
   Visibility: public
   Classification: public-web
```

## Attribution System

### Automatic Attribution

For blocks with public sources, the system:

1. **Extracts Source URLs** from file content during classification
2. **Generates Attribution Text** based on the URL domain
3. **Stores in Database** (`source_url`, `source_attribution` fields)
4. **Displays in Search** with superscript indicator

### Attribution Format

URLs are automatically formatted based on the source:

- **Stack Overflow**: `Source: Stack Overflow - [URL]`
- **GitHub**: `Source: GitHub - [URL]`
- **Documentation**: `Source: Documentation - [URL]`
- **Medium**: `Source: Medium - [URL]`
- **DEV Community**: `Source: DEV Community - [URL]`
- **Other**: `Source: [URL]`

### Search Results with Attribution

```
1. PostgreSQL Performance Tuning (relevance: 0.95) ⁱ
   Source: Stack Overflow - https://stackoverflow.com/questions/...
   Created: 2025-10-24
   Exchanges: 5
   Preview: How do I optimize PostgreSQL queries?
```

The superscript `ⁱ` indicates the block has source attribution.

## Visibility Classification

### Automatic Classification

The system automatically determines visibility based on:

1. **Public URLs in Content**:
   - Stack Overflow, GitHub (public repos), documentation sites
   - Classified as `public` with `source_classification: public-web`

2. **Paywall Content**:
   - Medium membership, Patreon, Substack
   - Classified as `org-private` with `source_classification: paywall-content`

3. **Directory Patterns**:
   - `/work/`, `/client-*/`, `/uta/` → `org-private` (client data)
   - `/personal/`, `/home/`, `~/Documents` → `individual` (personal)

4. **Manual Tags**:
   - `#public` tag → `public`
   - `#private` or `#confidential` → `org-private`

5. **Default**:
   - Auto mode defaults to `org-private` for safety

### Visibility Levels

- **public**: Public knowledge, can be shared across organizations
- **org-private**: Organization-specific, not shared outside org
- **individual**: Personal knowledge, user-specific

## File Discovery

### Supported File Types

**Conversation Logs** (`--type logs`):
- Pattern: `session-*.md`
- Classification: Based on content and directory

**Specifications** (`--type specs`):
- Patterns: `*-spec.md`, `*-specification.md`
- Classification: Usually org-private unless tagged

**Documentation** (`--type docs`):
- Patterns: `README.md`, `MISSION.md`, `*.md`
- Classification: Based on content URLs

**Working Files** (`--type working`):
- Pattern: `.working.md`
- Classification: Always individual

### Default Exclusions

- `.git/*`
- `node_modules/*`
- `*.test.md`

Override with `--exclude` flag.

## Database Schema

### Import History Table

```sql
CREATE TABLE import_history (
    id UUID PRIMARY KEY,
    source_file TEXT NOT NULL,
    file_hash TEXT NOT NULL,
    imported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    block_count INT NOT NULL,
    import_type TEXT NOT NULL,
    status TEXT DEFAULT 'completed',
    visibility TEXT DEFAULT 'org-private',
    source_classification TEXT,
    organization_id UUID REFERENCES organizations(id),
    UNIQUE(source_file, file_hash)
);
```

### Block Attribution Fields

```sql
ALTER TABLE blocks ADD COLUMN source_url TEXT;
ALTER TABLE blocks ADD COLUMN source_attribution TEXT;
ALTER TABLE blocks ADD COLUMN visibility TEXT DEFAULT 'org-private';
ALTER TABLE blocks ADD COLUMN source_file TEXT;
ALTER TABLE blocks ADD COLUMN source_type TEXT;
ALTER TABLE blocks ADD COLUMN source_hash TEXT;
```

## Implementation Details

### Import Pipeline

1. **Discovery**: `importer.Discover()` - Find all matching files
2. **Classification**: `importer.ClassifySource()` - Determine visibility and attribution
3. **Parsing**: Parse file content into PreBlocks (TODO: Week 2)
4. **Deduplication**: Check against existing imports by file hash
5. **Attribution**: `AddAttributionToPreBlock()` - Add source URLs
6. **Import**: Convert to Blocks and save to database
7. **History**: Record in import_history table

### Key Files

- `cmd/knowledge/import.go` - CLI commands
- `internal/pipeline/pipeline.go` - Import orchestration
- `internal/importer/discovery.go` - File discovery
- `internal/importer/classification.go` - Visibility and source classification
- `internal/importer/attribution.go` - Attribution generation
- `internal/importer/types.go` - Import data structures

## Next Steps (Week 2)

- [ ] Implement conversation log parser
- [ ] Implement spec/doc parsers
- [ ] Add progress bars during import
- [ ] Implement actual block creation (currently dry-run only)
- [ ] Add import validation and error recovery
- [ ] Support incremental updates (reimport changed files)
- [ ] Add git remote detection for public repo classification

## Usage Examples

### Import Conversation Logs

```bash
# Preview first
./knowledge import conversation-logs/ --dry-run --type logs

# Actually import
./knowledge import conversation-logs/ --type logs
```

### Import Public Documentation

```bash
# Import public docs with explicit visibility
./knowledge import external-docs/ --visibility public --type docs
```

### Import Client Work

```bash
# Import from client directory (auto-classified as org-private)
./knowledge import /work/client-acme/specs/ --type specs
```

### Check Import Status

```bash
# View statistics
./knowledge import stats

# View recent history
./knowledge import history --limit 20
```

### Search with Attribution

```bash
# Search will show attribution for public sources
./knowledge search "postgresql performance"

# Output includes:
# 1. PostgreSQL Optimization ⁱ
#    Source: Stack Overflow - https://stackoverflow.com/...
```

## Attribution Best Practices

1. **Always Preserve Source URLs**: Include original URLs in conversation logs
2. **Tag Public Content**: Use `#public` tag for manually-contributed public knowledge
3. **Verify Attribution**: Check that source URLs are correctly extracted
4. **Update Classifications**: Re-import files if visibility needs to change
5. **Monitor Import History**: Regular check for failed imports or misclassifications

## Troubleshooting

### Files Not Discovered

- Check file patterns match (e.g., `session-*.md` for logs)
- Verify exclude patterns aren't too broad
- Use `--verbose` flag to see discovery details

### Wrong Visibility Classification

- Use `--visibility` flag to override
- Add manual tags (`#public`, `#private`) to files
- Check directory patterns in `classification.go`

### Missing Attribution

- Ensure URLs are present in file content
- Check URL patterns in `publicURLPatterns`
- Verify URLs aren't behind paywalls

### Import Failures

- Check `import history` for error messages
- Verify database connection
- Check file permissions
- Use `--verbose` for detailed error logs

## Performance

- **Discovery**: O(n) where n = number of files
- **Classification**: O(1) per file (first 200 lines only)
- **Import**: Batched in groups of 10 (configurable)
- **Deduplication**: Hash-based, O(1) lookup

Large directories (1000+ files) should complete in seconds for discovery and classification.
