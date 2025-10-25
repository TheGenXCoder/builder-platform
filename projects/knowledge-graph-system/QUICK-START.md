# Knowledge Graph System - Quick Start

## Installation

```bash
# Build the CLI
go build -o bin/knowledge ./cmd/knowledge

# Add to PATH (optional)
export PATH=$PATH:$(pwd)/bin
```

## Basic Commands

### Search

```bash
# Search the knowledge graph
./bin/knowledge search "postgresql performance"

# Multi-word queries
./bin/knowledge search postgresql query optimization
```

### Import

```bash
# Preview import (dry-run)
./bin/knowledge import conversation-logs/ --dry-run

# Import conversation logs
./bin/knowledge import conversation-logs/ --type logs

# Import all markdown files
./bin/knowledge import /path/to/docs --type all

# Import with custom visibility
./bin/knowledge import docs/ --visibility public
```

### Import Management

```bash
# View import statistics
./bin/knowledge import stats

# View import history
./bin/knowledge import history

# View more history
./bin/knowledge import history --limit 20
```

### Testing

```bash
# Test database connection and embeddings
./bin/knowledge test
```

## Example Workflow

### 1. Import Your Conversation Logs

```bash
# Preview first
./bin/knowledge import ~/conversation-logs --dry-run --type logs

# Actually import
./bin/knowledge import ~/conversation-logs --type logs
```

### 2. Search Your Knowledge

```bash
# Search for specific topics
./bin/knowledge search "how to implement authentication"

# Search for technologies
./bin/knowledge search "postgresql pgvector"

# Search for patterns
./bin/knowledge search "microservices architecture"
```

### 3. Check Import Status

```bash
# View what's been imported
./bin/knowledge import history

# Check statistics
./bin/knowledge import stats
```

## Command Reference

### knowledge

Main CLI entry point.

```bash
knowledge [command]
```

**Commands:**
- `test` - Test database connection and embeddings
- `search <query>` - Search the knowledge graph
- `import <directory>` - Import knowledge from files

### knowledge search

Search the knowledge graph with semantic search.

```bash
knowledge search <query>
```

**Output:**
```
Found 5 results in 87ms

1. PostgreSQL Performance Tuning (relevance: 0.95) ⁱ
   Source: Stack Overflow - https://stackoverflow.com/...
   Created: 2025-10-24 15:30
   Visibility: public
   Exchanges: 5
   Preview: How do I optimize PostgreSQL queries?

2. Database Indexing Strategies (relevance: 0.87)
   Created: 2025-10-23 10:15
   Exchanges: 4
   Preview: What are the best indexing strategies?
```

### knowledge import

Import files into the knowledge graph.

```bash
knowledge import [directory] [flags]
```

**Flags:**
- `--dry-run` - Preview without importing
- `--visibility <vis>` - Override visibility (public, org-private, individual, auto)
- `--type <types>` - File types (logs, specs, docs, all)
- `--exclude <patterns>` - Exclude patterns
- `--progress` - Show progress (default: true)
- `--verbose` - Detailed logging

### knowledge import stats

Show import statistics.

```bash
knowledge import stats
```

### knowledge import history

Show recent imports.

```bash
knowledge import history [--limit N]
```

## File Types

### Conversation Logs

Files matching `session-*.md`:

```bash
conversation-logs/
├── 2024-10/
│   ├── session-2024-10-15-1430.md
│   └── session-2024-10-16-0900.md
└── 2025-10/
    └── session-2025-10-24-2200.md
```

Import with:
```bash
./bin/knowledge import conversation-logs/ --type logs
```

### Specifications

Files matching `*-spec.md` or `*-specification.md`:

```bash
specs/
├── api-specification.md
├── database-spec.md
└── auth-spec.md
```

Import with:
```bash
./bin/knowledge import specs/ --type specs
```

### Documentation

Any `.md` files:

```bash
docs/
├── README.md
├── ARCHITECTURE.md
└── MISSION.md
```

Import with:
```bash
./bin/knowledge import docs/ --type docs
```

## Visibility Levels

### Public

Content from public sources (Stack Overflow, GitHub, documentation):

```bash
# Explicit public import
./bin/knowledge import public-notes/ --visibility public
```

Search results show source attribution:
```
1. React Hooks Guide ⁱ
   Source: GitHub - https://github.com/facebook/react
```

### Org-Private

Organization-specific content (default):

```bash
# Default visibility
./bin/knowledge import work-notes/
```

### Individual

Personal content:

```bash
# Personal notes
./bin/knowledge import ~/personal-notes --visibility individual
```

## Tips

### Preview Before Importing

Always use `--dry-run` first:

```bash
./bin/knowledge import new-directory/ --dry-run
```

### Filter File Types

Import only what you need:

```bash
# Only conversation logs
./bin/knowledge import . --type logs

# Only specs
./bin/knowledge import . --type specs

# Everything
./bin/knowledge import . --type all
```

### Exclude Patterns

Skip unwanted files:

```bash
./bin/knowledge import . --exclude "*.test.md,draft-*,.git/*"
```

### Verbose Output

Debug import issues:

```bash
./bin/knowledge import . --verbose
```

### Check Results

After importing, verify:

```bash
# Check stats
./bin/knowledge import stats

# Check history
./bin/knowledge import history

# Search for imported content
./bin/knowledge search "your topic"
```

## Troubleshooting

### Database Connection Failed

```bash
# Check PostgreSQL is running
pg_isready

# Verify database exists
psql -d knowledge_graph -c "SELECT 1"
```

### No Files Discovered

```bash
# Use verbose mode
./bin/knowledge import . --verbose --dry-run

# Check file patterns
ls session-*.md  # For conversation logs
ls *-spec.md     # For specs
```

### Search Returns No Results

```bash
# Check imports succeeded
./bin/knowledge import stats

# Verify blocks exist
psql -d knowledge_graph -c "SELECT COUNT(*) FROM blocks"

# Check embedding service
./bin/knowledge test
```

### Wrong Visibility

Override with flag:

```bash
./bin/knowledge import . --visibility public
```

Or add tags to files:
```markdown
<!-- #public -->
```

## Next Steps

1. **Import your existing logs**: `./bin/knowledge import conversation-logs/`
2. **Test search**: `./bin/knowledge search "your topic"`
3. **Check what was imported**: `./bin/knowledge import history`
4. **Explore the data**: Use the MCP server for Claude Desktop integration

## Full Documentation

- [Import System Documentation](./IMPORT-SYSTEM.md)
- [Database Schema](./schema.sql)
- [Architecture Overview](./README.md)
