# Conversation Log Parser

Parses conversation log markdown files into structured `ParsedDocument` objects for import into the knowledge graph system.

## Overview

The conversation log parser handles markdown files that follow the Builder Platform's session logging format. It extracts metadata, sections, milestones, decisions, and file modifications from conversation logs.

## Features

- **Metadata Extraction**: Parses session metadata (project, started time, status, etc.)
- **Hierarchical Sections**: Builds hierarchical section structures from markdown headings
- **Timestamp Parsing**: Handles multiple date/time formats (ISO-8601, RFC3339, etc.)
- **Tag Extraction**: Extracts hashtags from Tag Index sections
- **Milestone Parsing**: Identifies timestamped milestones (e.g., "16:00 - Session Started")
- **Key Decisions**: Extracts numbered decision lists from Key Decisions sections
- **File Tracking**: Identifies created and modified files from session logs

## Usage

```go
package main

import (
    "github.com/TheGenXCoder/knowledge-graph/internal/importer"
    "github.com/TheGenXCoder/knowledge-graph/internal/importer/parsers"
)

func main() {
    parser := parsers.NewConversationLogParser()

    source := importer.ImportSource{
        FilePath: "conversation-logs/2025-10/session-2025-10-15-1600.md",
        FileType: "conversation-log",
    }

    content := readFileContent(source.FilePath)

    doc, err := parser.Parse(source, content)
    if err != nil {
        panic(err)
    }

    // Access parsed data
    fmt.Println("Session:", doc.Metadata["session_description"])
    fmt.Println("Sections:", len(doc.Sections))
    fmt.Println("Tags:", doc.Metadata["tags"])
}
```

## Input Format

The parser expects conversation logs in this format:

```markdown
# Session Log: 2025-10-15 - Context Preservation System Implementation

**Project:** Builder Platform - Context Preservation System
**Started:** 2025-10-15T16:00:00-07:00
**Status:** Active

---

## Session Goal

Design and implement a system-level context preservation standard.

## 16:00 - Session Started

**Initial Context:**
User requested proactive context preservation system.

## 16:10 - Project Structure Created

**Action:** Created context-preservation-system project

## Key Decisions Made

1. **Standards-Driven Architecture**
   - Decision: Use Agent-OS standards
   - Rationale: Robust approach

2. **Two-File Preservation System**
   - Decision: .working.md + session logs
   - Impact: Better recovery

## Files Created/Modified This Session

**Created:**
- `builds/context-preservation-system/mission.md` - Product vision
- `~/.agent-os/standards/context.md` - Standard file

**Modified:**
- `~/.claude/CLAUDE.md` - Added integration section
- `.working.md` - Updated session state

## Tag Index

#context-preservation #builder-platform #system-level-standards
```

## Output Structure

### ParsedDocument

```go
type ParsedDocument struct {
    Source   ImportSource              // File information
    Metadata map[string]interface{}    // Extracted metadata
    Sections []Section                 // Hierarchical sections
}
```

### Metadata Fields

Extracted metadata includes:

- `title`: Full document title
- `session_date_str`: Date string from title (e.g., "2025-10-15")
- `session_date`: Parsed time.Time of session date
- `session_description`: Description from title
- `project`: Project name
- `started`: Session start time (time.Time)
- `status`: Session status (Active, Completed, etc.)
- `session_goal`: Content from Session Goal section
- `session_summary`: Content from Session Summary section
- `outcome`: Session outcome if present
- `tags`: Array of hashtags from Tag Index

### Section Structure

```go
type Section struct {
    Level    int        // Heading level (1-6)
    Title    string     // Section title
    Content  string     // Section content
    Children []Section  // Nested subsections
    Line     int        // Source line number
}
```

Sections are hierarchically structured based on markdown heading levels.

## Additional Methods

### ParseMilestones

Extracts timestamped milestone sections:

```go
milestones := parser.ParseMilestones(content)
// Returns: []Milestone{
//     {Timestamp: "16:00", Title: "Session Started", Content: "..."},
//     {Timestamp: "16:10", Title: "Project Created", Content: "..."},
// }
```

### ExtractKeyDecisions

Extracts numbered decision items:

```go
decisions := parser.ExtractKeyDecisions(content)
// Returns: []string{
//     "**Standards-Driven Architecture** Decision: Use Agent-OS standards...",
//     "**Two-File Preservation System** Decision: .working.md + session logs...",
// }
```

### ExtractFilesModified

Extracts created and modified file paths:

```go
files := parser.ExtractFilesModified(content)
// Returns: map[string][]string{
//     "created": []string{
//         "builds/context-preservation-system/mission.md",
//         "~/.agent-os/standards/context.md",
//     },
//     "modified": []string{
//         "~/.claude/CLAUDE.md",
//         ".working.md",
//     },
// }
```

## Date/Time Parsing

The parser handles multiple formats:

- **Dates**: `2006-01-02`, `January 2, 2006`, `01/02/2006`
- **Timestamps**: `2006-01-02T15:04:05-07:00` (RFC3339), `2006-01-02 15:04:05`

## Error Handling

The parser is resilient to format variations:

- Missing sections are handled gracefully
- Invalid dates/times don't cause failures
- Empty content returns valid (but empty) ParsedDocument
- Malformed sections are skipped

## Testing

Comprehensive test suite includes:

- Full document parsing
- Real file parsing (tests against actual conversation logs)
- Milestone extraction
- Key decision extraction
- File modification tracking
- Date/time parsing
- Hierarchical structure building
- Tag extraction
- Empty content handling
- Complex nesting scenarios

Run tests:

```bash
go test -v ./internal/importer/parsers/...
```

## Format Variations

The parser handles variations in conversation log format:

- With or without horizontal rules (`---`)
- Optional metadata fields
- Variable timestamp formats
- Different section naming conventions
- Nested subsections at any depth
- Multiple line breaks between sections

## Integration

The parser integrates with the knowledge graph import pipeline:

1. **Discovery**: Files identified as "conversation-log" type
2. **Parsing**: ConversationLogParser.Parse() creates ParsedDocument
3. **Chunking**: ParsedDocument converted to PreBlocks
4. **Import**: PreBlocks imported to knowledge graph

## Future Enhancements

Potential improvements:

- Extract conversation exchanges (Q&A pairs) directly
- Identify participants in multi-person conversations
- Parse code blocks and link to files
- Extract links to other documents
- Semantic analysis of decisions
- Automatic categorization of milestones

## License

Part of the Knowledge Graph System - Builder Platform
