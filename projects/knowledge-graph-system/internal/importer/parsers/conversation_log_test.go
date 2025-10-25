package parsers

import (
	"os"
	"testing"
	"time"

	"github.com/TheGenXCoder/knowledge-graph/internal/importer"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// countAllSections counts sections recursively including children
func countAllSections(sections []importer.Section) int {
	count := len(sections)
	for _, section := range sections {
		count += countAllSections(section.Children)
	}
	return count
}

func TestConversationLogParser_Parse(t *testing.T) {
	parser := NewConversationLogParser()

	testContent := `# Session Log: 2025-10-15 - Context Preservation System Implementation

**Project:** Builder Platform - Context Preservation System
**Started:** 2025-10-15T16:00:00-07:00
**Status:** Active
**Current Context Usage:** ~35%

---

## Session Goal

Design and implement a system-level context preservation standard for Claude Code.

**User's Pain Point:**
- Claude Code errors corrupt context
- Exit clears context
- No recovery mechanism

---

## 16:00 - Session Started

**Initial Context:**
User requested proactive context preservation system.

**Plan:**
1. Plan the product
2. Create specifications
3. Implement system-level standards

---

## 16:10 - Project Structure Created

**Action:** Created context-preservation-system project

**Created:**
- builds/context-preservation-system/ (project root)
- Installed Agent-OS

---

## Key Decisions Made

1. **Standards-Driven Architecture**
   - Decision: Use Agent-OS standards
   - Rationale: Claude Code doesn't have external hook system

2. **Two-File Preservation System**
   - Decision: .working.md + session logs
   - Rationale: Quick recovery + complete history

---

## Session Summary

**Accomplished:**
✅ Designed comprehensive context preservation system
✅ Created complete product planning

**Outcome:** Success - System fully implemented

---

## Tag Index

#context-preservation #builder-platform #system-level-standards

---

**Session Duration:** ~2 hours 15 minutes
**Context Usage:** ~48%
`

	source := importer.ImportSource{
		FilePath: "/test/session-2025-10-15-1600.md",
		FileType: "conversation-log",
	}

	doc, err := parser.Parse(source, testContent)
	require.NoError(t, err)
	require.NotNil(t, doc)

	// Check metadata
	assert.Equal(t, "2025-10-15", doc.Metadata["session_date_str"])
	assert.Equal(t, "Context Preservation System Implementation", doc.Metadata["session_description"])
	assert.Equal(t, "Builder Platform - Context Preservation System", doc.Metadata["project"])
	assert.Equal(t, "Active", doc.Metadata["status"])
	assert.Contains(t, doc.Metadata["session_goal"], "system-level context preservation")

	// Check timestamp parsing
	started, ok := doc.Metadata["started"].(time.Time)
	assert.True(t, ok)
	assert.Equal(t, 2025, started.Year())
	assert.Equal(t, time.October, started.Month())
	assert.Equal(t, 15, started.Day())

	// Check tags
	tags, ok := doc.Metadata["tags"].([]string)
	assert.True(t, ok)
	assert.Contains(t, tags, "context-preservation")
	assert.Contains(t, tags, "builder-platform")
	assert.Contains(t, tags, "system-level-standards")

	// Check sections
	assert.Greater(t, len(doc.Sections), 0)

	// Find specific sections (they are nested under H1)
	var sessionGoalSection *importer.Section
	var milestoneSection *importer.Section

	// Iterate through all sections and their children
	var findSections func(sections []importer.Section)
	findSections = func(sections []importer.Section) {
		for i := range sections {
			section := &sections[i]
			if section.Title == "Session Goal" {
				sessionGoalSection = section
			}
			if section.Title == "16:00 - Session Started" {
				milestoneSection = section
			}
			if len(section.Children) > 0 {
				findSections(section.Children)
			}
		}
	}
	findSections(doc.Sections)

	assert.NotNil(t, sessionGoalSection)
	assert.Equal(t, 2, sessionGoalSection.Level)
	assert.Contains(t, sessionGoalSection.Content, "Design and implement")

	assert.NotNil(t, milestoneSection)
	assert.Equal(t, 2, milestoneSection.Level)
	assert.Contains(t, milestoneSection.Content, "User requested")
}

func TestConversationLogParser_ParseRealFile(t *testing.T) {
	// Test against real conversation log file
	filePath := "/Users/BertSmith/personal/builder-platform/conversation-logs/2025-10/session-2025-10-15-1600.md"

	// Skip if file doesn't exist (CI environment)
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		t.Skip("Real conversation log file not found")
	}

	content, err := os.ReadFile(filePath)
	require.NoError(t, err)

	parser := NewConversationLogParser()
	source := importer.ImportSource{
		FilePath: filePath,
		FileType: "conversation-log",
	}

	doc, err := parser.Parse(source, string(content))
	require.NoError(t, err)
	require.NotNil(t, doc)

	// Verify key metadata extracted
	assert.NotEmpty(t, doc.Metadata["session_date_str"])
	assert.NotEmpty(t, doc.Metadata["session_description"])
	assert.NotEmpty(t, doc.Metadata["project"])

	// Verify sections parsed (note: sections may be hierarchical)
	totalSections := countAllSections(doc.Sections)
	assert.Greater(t, totalSections, 5, "Should have multiple sections")

	// Verify tags extracted
	tags, ok := doc.Metadata["tags"].([]string)
	assert.True(t, ok)
	assert.Greater(t, len(tags), 0, "Should have tags")

	t.Logf("Parsed %d sections and %d tags", len(doc.Sections), len(tags))
}

func TestConversationLogParser_ParseMilestones(t *testing.T) {
	parser := NewConversationLogParser()

	testContent := `# Session Log: 2025-10-22

## 13:00 - Session Started

Initial work on project.

**Key points:**
- Started planning
- Created structure

## 13:30 - Architecture Deep Dive

Discussed technical approach.

## 14:00 - The Revelation

Everything changed.

## Session Summary

Completed successfully.
`

	milestones := parser.ParseMilestones(testContent)

	require.Len(t, milestones, 3)

	assert.Equal(t, "13:00", milestones[0].Timestamp)
	assert.Equal(t, "Session Started", milestones[0].Title)
	assert.Contains(t, milestones[0].Content, "Initial work")

	assert.Equal(t, "13:30", milestones[1].Timestamp)
	assert.Equal(t, "Architecture Deep Dive", milestones[1].Title)
	assert.Contains(t, milestones[1].Content, "technical approach")

	assert.Equal(t, "14:00", milestones[2].Timestamp)
	assert.Equal(t, "The Revelation", milestones[2].Title)
	assert.Contains(t, milestones[2].Content, "Everything changed")
}

func TestConversationLogParser_ExtractKeyDecisions(t *testing.T) {
	parser := NewConversationLogParser()

	testContent := `# Session Log

## Key Decisions Made

1. **Standards-Driven Architecture**
   - Decision: Use Agent-OS standards
   - Rationale: Robust approach

2. **Two-File Preservation System**
   - Decision: .working.md + session logs
   - Impact: Better recovery

3. Simple decision without formatting

## Other Content

Not relevant.
`

	decisions := parser.ExtractKeyDecisions(testContent)

	require.Len(t, decisions, 3)
	assert.Contains(t, decisions[0], "Standards-Driven Architecture")
	assert.Contains(t, decisions[1], "Two-File Preservation System")
	assert.Contains(t, decisions[2], "Simple decision")
}

func TestConversationLogParser_ExtractFilesModified(t *testing.T) {
	parser := NewConversationLogParser()

	testContent := `# Session Log

## Files Created/Modified This Session

**Created:**
- builds/context-preservation-system/mission.md - Product vision
- ` + "`" + `builds/specs/standard.md` + "`" + ` - Specification
- ~/.agent-os/standards/context.md

**Modified:**
- ~/.claude/CLAUDE.md - Added integration section
- ` + "`" + `.working.md` + "`" + ` - Updated session state

## Other Content
Not relevant.
`

	files := parser.ExtractFilesModified(testContent)

	require.Contains(t, files, "created")
	require.Contains(t, files, "modified")

	assert.Len(t, files["created"], 3)
	assert.Contains(t, files["created"], "builds/context-preservation-system/mission.md")
	assert.Contains(t, files["created"], "builds/specs/standard.md")
	assert.Contains(t, files["created"], "~/.agent-os/standards/context.md")

	assert.Len(t, files["modified"], 2)
	assert.Contains(t, files["modified"], "~/.claude/CLAUDE.md")
	assert.Contains(t, files["modified"], ".working.md")
}

func TestConversationLogParser_DateParsing(t *testing.T) {
	parser := NewConversationLogParser()

	testCases := []struct {
		name     string
		dateStr  string
		expected time.Time
	}{
		{
			name:     "ISO date",
			dateStr:  "2025-10-15",
			expected: time.Date(2025, 10, 15, 0, 0, 0, 0, time.UTC),
		},
		{
			name:     "ISO datetime",
			dateStr:  "2025-10-15T16:00:00-07:00",
			expected: time.Date(2025, 10, 15, 16, 0, 0, 0, time.FixedZone("", -7*3600)),
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			parsed, err := parser.parseDate(tc.dateStr)
			if err != nil {
				// Try parseTimestamp instead
				parsed, err = parser.parseTimestamp(tc.dateStr)
			}
			require.NoError(t, err)
			assert.Equal(t, tc.expected.Year(), parsed.Year())
			assert.Equal(t, tc.expected.Month(), parsed.Month())
			assert.Equal(t, tc.expected.Day(), parsed.Day())
		})
	}
}

func TestConversationLogParser_BuildHierarchy(t *testing.T) {
	parser := NewConversationLogParser()

	flatSections := []importer.Section{
		{Level: 1, Title: "Title", Content: ""},
		{Level: 2, Title: "Section 1", Content: "Content 1"},
		{Level: 3, Title: "Subsection 1.1", Content: "Content 1.1"},
		{Level: 3, Title: "Subsection 1.2", Content: "Content 1.2"},
		{Level: 2, Title: "Section 2", Content: "Content 2"},
	}

	hierarchical := parser.buildHierarchy(flatSections)

	require.Len(t, hierarchical, 1) // Only one H1
	assert.Equal(t, "Title", hierarchical[0].Title)
	assert.Len(t, hierarchical[0].Children, 2) // Two H2 sections

	section1 := hierarchical[0].Children[0]
	assert.Equal(t, "Section 1", section1.Title)
	assert.Len(t, section1.Children, 2) // Two H3 subsections

	assert.Equal(t, "Subsection 1.1", section1.Children[0].Title)
	assert.Equal(t, "Subsection 1.2", section1.Children[1].Title)

	section2 := hierarchical[0].Children[1]
	assert.Equal(t, "Section 2", section2.Title)
	assert.Len(t, section2.Children, 0) // No children
}

func TestConversationLogParser_ExtractTags(t *testing.T) {
	parser := NewConversationLogParser()

	testContent := `# Session Log

Some content here.

## Tag Index

#context-preservation #builder-platform #system-level-standards #agent-os

More content after.
`

	tags := parser.extractTags(testContent)

	require.Len(t, tags, 4)
	assert.Contains(t, tags, "context-preservation")
	assert.Contains(t, tags, "builder-platform")
	assert.Contains(t, tags, "system-level-standards")
	assert.Contains(t, tags, "agent-os")
}

func TestConversationLogParser_ExtractSectionContent(t *testing.T) {
	parser := NewConversationLogParser()

	testContent := `# Session Log

## Session Goal

This is the session goal.
It spans multiple lines.

## Another Section

This is different content.

## Yet Another

More content.
`

	goalContent := parser.extractSectionContent(testContent, "Session Goal")
	assert.Contains(t, goalContent, "This is the session goal")
	assert.Contains(t, goalContent, "It spans multiple lines")
	assert.NotContains(t, goalContent, "This is different content")

	anotherContent := parser.extractSectionContent(testContent, "Another Section")
	assert.Contains(t, anotherContent, "This is different content")
	assert.NotContains(t, anotherContent, "This is the session goal")
}

func TestConversationLogParser_HandleVariations(t *testing.T) {
	parser := NewConversationLogParser()

	// Test with minimal content
	minimalContent := `# Session Log: 2025-10-22 - Minimal Test

## Session Goal
Do something.
`

	source := importer.ImportSource{
		FilePath: "/test/minimal.md",
		FileType: "conversation-log",
	}

	doc, err := parser.Parse(source, minimalContent)
	require.NoError(t, err)
	assert.NotNil(t, doc)
	assert.NotEmpty(t, doc.Metadata["session_description"])

	// Test with no tags
	noTagsContent := `# Session Log: 2025-10-22 - No Tags Test

## Session Goal
Do something else.

## Session Summary
Completed.
`

	doc2, err := parser.Parse(source, noTagsContent)
	require.NoError(t, err)
	assert.NotNil(t, doc2)

	// Tags should not be in metadata if not present
	_, hasTagsKey := doc2.Metadata["tags"]
	assert.False(t, hasTagsKey)
}

func TestConversationLogParser_EmptyContent(t *testing.T) {
	parser := NewConversationLogParser()

	source := importer.ImportSource{
		FilePath: "/test/empty.md",
		FileType: "conversation-log",
	}

	doc, err := parser.Parse(source, "")
	require.NoError(t, err)
	assert.NotNil(t, doc)
	assert.Empty(t, doc.Sections)
}

func TestConversationLogParser_ComplexNesting(t *testing.T) {
	parser := NewConversationLogParser()

	testContent := `# Session Log

## 13:00 - Phase 1

Top level content.

### Technical Details

Some technical content.

#### Implementation

Deep nested content.

### Another Subsection

More content.

## 14:00 - Phase 2

New phase.
`

	doc, err := parser.Parse(importer.ImportSource{FilePath: "/test/nested.md"}, testContent)
	require.NoError(t, err)
	require.NotNil(t, doc)

	// Verify hierarchical structure
	assert.Greater(t, len(doc.Sections), 0)

	// Find Phase 1 section using helper function
	var phase1 *importer.Section
	var findPhase1 func(sections []importer.Section)
	findPhase1 = func(sections []importer.Section) {
		for i := range sections {
			section := &sections[i]
			if section.Title == "13:00 - Phase 1" {
				phase1 = section
				return
			}
			if len(section.Children) > 0 {
				findPhase1(section.Children)
			}
		}
	}
	findPhase1(doc.Sections)

	if phase1 != nil {
		assert.Greater(t, len(phase1.Children), 0, "Phase 1 should have children")
	} else {
		t.Log("Phase 1 section not found in parsed structure")
	}
}
