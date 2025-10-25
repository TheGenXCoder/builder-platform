package importer

import (
	"fmt"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestChunkDocument_SmallSession tests chunking of a small session (3 exchanges → 1 block)
func TestChunkDocument_SmallSession(t *testing.T) {
	doc := createTestConversationLog(3, "Small Session Test")
	opts := DefaultChunkOptions()

	blocks, err := ChunkDocument(doc, opts)

	require.NoError(t, err)
	assert.Len(t, blocks, 1, "Small session should produce 1 block")

	block := blocks[0]
	assert.Equal(t, "Small Session Test", block.Topic)
	assert.Len(t, block.Exchanges, 3)
	assert.Equal(t, doc.Source.FilePath, block.SourceFile)
	assert.Equal(t, "conversation-log", block.SourceType)
	assert.Equal(t, doc.Source.FileHash, block.SourceHash)

	// Check metadata
	assert.Contains(t, block.Metadata, "session_id")
	assert.Contains(t, block.Metadata, "chunk_number")
	assert.Equal(t, 1, block.Metadata["chunk_number"])
	assert.Equal(t, 1, block.Metadata["total_chunks"])
	assert.Equal(t, 3, block.Metadata["exchange_count"])
}

// TestChunkDocument_MediumSession tests chunking of a medium session (7 exchanges → 1 block)
func TestChunkDocument_MediumSession(t *testing.T) {
	doc := createTestConversationLog(7, "Medium Session Test")
	opts := DefaultChunkOptions()

	blocks, err := ChunkDocument(doc, opts)

	require.NoError(t, err)
	assert.Len(t, blocks, 1, "Medium session should produce 1 block")

	block := blocks[0]
	assert.Equal(t, "Medium Session Test", block.Topic)
	assert.Len(t, block.Exchanges, 7)
}

// TestChunkDocument_LargeSession tests chunking of a large session (15 exchanges → 2-3 blocks)
func TestChunkDocument_LargeSession(t *testing.T) {
	doc := createTestConversationLog(15, "Large Session Test")
	opts := DefaultChunkOptions()

	blocks, err := ChunkDocument(doc, opts)

	require.NoError(t, err)
	assert.GreaterOrEqual(t, len(blocks), 2, "Large session should produce 2+ blocks")
	assert.LessOrEqual(t, len(blocks), 4, "Should not over-chunk")

	// Verify all exchanges are preserved
	totalExchanges := 0
	for _, block := range blocks {
		totalExchanges += len(block.Exchanges)
	}
	assert.Equal(t, 15, totalExchanges, "All exchanges should be preserved")

	// Verify chunk metadata
	for i, block := range blocks {
		assert.Contains(t, block.Metadata, "chunk_number")
		assert.Equal(t, i+1, block.Metadata["chunk_number"])
		assert.Equal(t, len(blocks), block.Metadata["total_chunks"])
		assert.Contains(t, block.Topic, "Large Session Test")
	}
}

// TestChunkDocument_VeryLargeSession tests chunking of a very large session (30 exchanges)
func TestChunkDocument_VeryLargeSession(t *testing.T) {
	doc := createTestConversationLog(30, "Very Large Session")
	opts := DefaultChunkOptions()

	blocks, err := ChunkDocument(doc, opts)

	require.NoError(t, err)
	assert.GreaterOrEqual(t, len(blocks), 5, "Very large session should produce 5+ blocks")

	// Verify exchange distribution
	for _, block := range blocks {
		exchangeCount := len(block.Exchanges)
		assert.GreaterOrEqual(t, exchangeCount, opts.MinExchangesPerBlock,
			"Block should have at least MinExchangesPerBlock")
		assert.LessOrEqual(t, exchangeCount, opts.MaxExchangesPerBlock,
			"Block should not exceed MaxExchangesPerBlock")
	}
}

// TestChunkDocument_MinimumExchanges tests handling of minimum exchanges constraint
func TestChunkDocument_MinimumExchanges(t *testing.T) {
	doc := createTestConversationLog(1, "Single Exchange")
	opts := DefaultChunkOptions()

	blocks, err := ChunkDocument(doc, opts)

	require.NoError(t, err)
	assert.Len(t, blocks, 1)
	assert.Len(t, blocks[0].Exchanges, 1)
}

// TestChunkDocument_MaximumExchanges tests respecting maximum exchanges per block
func TestChunkDocument_MaximumExchanges(t *testing.T) {
	doc := createTestConversationLog(20, "Max Test")
	opts := ChunkOptions{
		MinExchangesPerBlock: 1,
		MaxExchangesPerBlock: 5,
		TargetExchanges:      4,
		RespectBoundaries:    true,
	}

	blocks, err := ChunkDocument(doc, opts)

	require.NoError(t, err)

	// No block should exceed MaxExchangesPerBlock
	for i, block := range blocks {
		assert.LessOrEqual(t, len(block.Exchanges), opts.MaxExchangesPerBlock,
			"Block %d exceeds MaxExchangesPerBlock", i)
	}
}

// TestExtractSessionTopic tests session topic extraction
func TestExtractSessionTopic(t *testing.T) {
	tests := []struct {
		name     string
		doc      *ParsedDocument
		expected string
	}{
		{
			name: "From H1 with prefix",
			doc: &ParsedDocument{
				Metadata: make(map[string]interface{}),
				Sections: []Section{
					{Level: 1, Title: "Session Log: 2025-10-15 - Context Preservation System"},
				},
			},
			expected: "Context Preservation System",
		},
		{
			name: "From metadata session_title",
			doc: &ParsedDocument{
				Metadata: map[string]interface{}{
					"session_title": "Test Session Title",
				},
			},
			expected: "Test Session Title",
		},
		{
			name: "From metadata session_goal",
			doc: &ParsedDocument{
				Metadata: map[string]interface{}{
					"session_goal": "Implement Feature X",
				},
			},
			expected: "Implement Feature X",
		},
		{
			name: "Fallback to Untitled",
			doc: &ParsedDocument{
				Metadata: make(map[string]interface{}),
				Sections: []Section{},
			},
			expected: "Untitled Session",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			topic := extractSessionTopic(tt.doc)
			assert.Equal(t, tt.expected, topic)
		})
	}
}

// TestExtractSessionDate tests session date extraction
func TestExtractSessionDate(t *testing.T) {
	expectedTime := time.Date(2025, 10, 15, 16, 0, 0, 0, time.UTC)

	tests := []struct {
		name     string
		doc      *ParsedDocument
		expected time.Time
	}{
		{
			name: "From metadata session_date",
			doc: &ParsedDocument{
				Metadata: map[string]interface{}{
					"session_date": expectedTime,
				},
			},
			expected: expectedTime,
		},
		{
			name: "From metadata started_at",
			doc: &ParsedDocument{
				Metadata: map[string]interface{}{
					"started_at": expectedTime,
				},
			},
			expected: expectedTime,
		},
		{
			name: "From filename",
			doc: &ParsedDocument{
				Metadata: make(map[string]interface{}),
				Source: ImportSource{
					FilePath: "/path/to/session-2025-10-15-1600.md",
				},
			},
			expected: expectedTime,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			date := extractSessionDate(tt.doc)
			assert.Equal(t, tt.expected.Format(time.RFC3339), date.Format(time.RFC3339))
		})
	}
}

// TestExtractExchangesFromSections tests milestone extraction
func TestExtractExchangesFromSections(t *testing.T) {
	sections := []Section{
		{
			Level: 1,
			Title: "Session Log: 2025-10-15",
		},
		{
			Level:   2,
			Title:   "Session Goal",
			Content: "This is a metadata section and should be skipped",
		},
		{
			Level:   2,
			Title:   "16:00 - Session Started",
			Content: "User requested feature implementation",
			Children: []Section{
				{
					Level:   3,
					Title:   "Progress",
					Content: "Created project structure",
				},
				{
					Level:   3,
					Title:   "Decisions",
					Content: "Use Go for implementation",
				},
			},
		},
		{
			Level:   2,
			Title:   "16:15 - Feature Implementation",
			Content: "Implemented core feature",
		},
	}

	exchanges := extractExchangesFromSections(sections)

	assert.Len(t, exchanges, 2, "Should extract 2 exchanges (skip metadata section)")

	// First exchange
	assert.Equal(t, "Session Started", exchanges[0].Question)
	assert.Contains(t, exchanges[0].Answer, "User requested feature implementation")
	assert.Contains(t, exchanges[0].Answer, "**Progress:**")
	assert.Contains(t, exchanges[0].Answer, "Created project structure")

	// Second exchange
	assert.Equal(t, "Feature Implementation", exchanges[1].Question)
	assert.Equal(t, "Implemented core feature", exchanges[1].Answer)
}

// TestIsMetadataSection tests metadata section detection
func TestIsMetadataSection(t *testing.T) {
	tests := []struct {
		title    string
		expected bool
	}{
		{"Session Goal", true},
		{"Session Overview", true},
		{"Progress Summary", true},
		{"Key Decisions", true},
		{"Session Summary", true},
		{"Tag Index", true},
		{"16:00 - Session Started", false},
		{"Implementation Details", false},
		{"Feature Work", false},
	}

	for _, tt := range tests {
		t.Run(tt.title, func(t *testing.T) {
			result := isMetadataSection(tt.title)
			assert.Equal(t, tt.expected, result)
		})
	}
}

// TestExtractMilestoneTitle tests milestone title extraction
func TestExtractMilestoneTitle(t *testing.T) {
	tests := []struct {
		input    string
		expected string
	}{
		{"16:00 - Session Started", "Session Started"},
		{"16:15 - Feature Implementation", "Feature Implementation"},
		{"9:30 - Morning Sync", "Morning Sync"},
		{"No timestamp here", "No timestamp here"},
		{"  16:45  -  Cleanup  ", "Cleanup"},
	}

	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			result := extractMilestoneTitle(tt.input)
			assert.Equal(t, tt.expected, result)
		})
	}
}

// TestExtractTimestampFromTitle tests timestamp extraction
func TestExtractTimestampFromTitle(t *testing.T) {
	now := time.Now()

	tests := []struct {
		title        string
		expectedHour int
		expectedMin  int
	}{
		{"16:00 - Session Started", 16, 0},
		{"16:15 - Feature Implementation", 16, 15},
		{"9:30 - Morning Sync", 9, 30},
	}

	for _, tt := range tests {
		t.Run(tt.title, func(t *testing.T) {
			result := extractTimestampFromTitle(tt.title)
			assert.Equal(t, tt.expectedHour, result.Hour())
			assert.Equal(t, tt.expectedMin, result.Minute())
			assert.Equal(t, now.Year(), result.Year())
			assert.Equal(t, now.Month(), result.Month())
			assert.Equal(t, now.Day(), result.Day())
		})
	}
}

// TestExtractTags tests tag extraction from metadata
func TestExtractTags(t *testing.T) {
	tests := []struct {
		name     string
		metadata map[string]interface{}
		expected []string
	}{
		{
			name: "String slice",
			metadata: map[string]interface{}{
				"tags": []string{"context-preservation", "agent-os", "testing"},
			},
			expected: []string{"context-preservation", "agent-os", "testing"},
		},
		{
			name: "Interface slice",
			metadata: map[string]interface{}{
				"tags": []interface{}{"tag1", "tag2"},
			},
			expected: []string{"tag1", "tag2"},
		},
		{
			name: "Tag index string",
			metadata: map[string]interface{}{
				"tag_index": "#context-preservation #agent-os #system-standards",
			},
			expected: []string{"context-preservation", "agent-os", "system-standards"},
		},
		{
			name:     "No tags",
			metadata: map[string]interface{}{},
			expected: []string{},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := extractTags(tt.metadata)
			assert.Equal(t, tt.expected, result)
		})
	}
}

// TestParseTagIndex tests tag index parsing
func TestParseTagIndex(t *testing.T) {
	tests := []struct {
		input    string
		expected []string
	}{
		{
			"#context-preservation #agent-os #testing",
			[]string{"context-preservation", "agent-os", "testing"},
		},
		{
			"#tag1, #tag2; #tag3.",
			[]string{"tag1", "tag2", "tag3"},
		},
		{
			"No hashtags here",
			[]string{},
		},
		{
			"#single",
			[]string{"single"},
		},
	}

	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			result := parseTagIndex(tt.input)
			if len(tt.expected) == 0 {
				assert.Empty(t, result)
			} else {
				assert.Equal(t, tt.expected, result)
			}
		})
	}
}

// TestExtractProjectPath tests project path extraction
func TestExtractProjectPath(t *testing.T) {
	tests := []struct {
		input    string
		expected string
	}{
		{
			"/Users/bert/project/conversation-logs/2025-10/session.md",
			"/Users/bert/project",
		},
		{
			"/path/to/project/specs/feature.md",
			"/path/to/project",
		},
		{
			"/path/to/project/docs/readme.md",
			"/path/to/project",
		},
		{
			"/path/to/project/builds/feature/spec.md",
			"/path/to/project",
		},
		{
			"/some/random/path/file.md",
			"/some/random",
		},
	}

	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			result := extractProjectPath(tt.input)
			assert.Equal(t, tt.expected, result)
		})
	}
}

// TestExtractModelUsed tests model extraction from content
func TestExtractModelUsed(t *testing.T) {
	tests := []struct {
		content  string
		expected string
	}{
		{
			"Using claude-3.5-sonnet model for this task",
			"claude-3.5-sonnet",
		},
		{
			"Model: gpt-4-turbo",
			"gpt-4-turbo",
		},
		{
			"using llama-3.1 model",
			"llama-3.1",
		},
		{
			"No model mentioned here",
			"",
		},
	}

	for _, tt := range tests {
		t.Run(tt.content, func(t *testing.T) {
			result := extractModelUsed(tt.content)
			assert.Equal(t, tt.expected, result)
		})
	}
}

// TestChunkDocument_NilDocument tests error handling for nil document
func TestChunkDocument_NilDocument(t *testing.T) {
	opts := DefaultChunkOptions()
	blocks, err := ChunkDocument(nil, opts)

	assert.Error(t, err)
	assert.Nil(t, blocks)
	assert.Contains(t, err.Error(), "nil")
}

// TestChunkDocument_UnsupportedFileType tests error handling for unsupported types
func TestChunkDocument_UnsupportedFileType(t *testing.T) {
	doc := &ParsedDocument{
		Source: ImportSource{
			FileType: "unknown-type",
		},
	}
	opts := DefaultChunkOptions()

	blocks, err := ChunkDocument(doc, opts)

	assert.Error(t, err)
	assert.Nil(t, blocks)
	assert.Contains(t, err.Error(), "unsupported file type")
}

// TestChunkDocument_NoExchanges tests error handling for logs with no exchanges
func TestChunkDocument_NoExchanges(t *testing.T) {
	doc := &ParsedDocument{
		Source: ImportSource{
			FileType: "conversation-log",
			FilePath: "/test/session.md",
		},
		Metadata: make(map[string]interface{}),
		Sections: []Section{
			{Level: 1, Title: "Empty Session"},
			{Level: 2, Title: "Session Goal", Content: "Metadata only"},
		},
	}
	opts := DefaultChunkOptions()

	blocks, err := ChunkDocument(doc, opts)

	assert.Error(t, err)
	assert.Nil(t, blocks)
	assert.Contains(t, err.Error(), "no exchanges found")
}

// TestChunkDocument_VisibilityPreservation tests visibility metadata preservation
func TestChunkDocument_VisibilityPreservation(t *testing.T) {
	orgID := uuid.New()
	doc := createTestConversationLog(5, "Visibility Test")
	doc.Source.Visibility = "org-private"
	doc.Source.OrganizationID = &orgID

	opts := DefaultChunkOptions()
	blocks, err := ChunkDocument(doc, opts)

	require.NoError(t, err)
	require.Len(t, blocks, 1)

	block := blocks[0]
	assert.Equal(t, "org-private", block.Visibility)
	assert.Equal(t, &orgID, block.OrganizationID)
}

// Helper function to create test conversation logs
func createTestConversationLog(exchangeCount int, topic string) *ParsedDocument {
	sections := []Section{
		{Level: 1, Title: fmt.Sprintf("Session Log: 2025-10-15 - %s", topic)},
		{Level: 2, Title: "Session Goal", Content: "Test session goal"},
	}

	// Create milestone sections (exchanges)
	baseTime := time.Date(2025, 10, 15, 16, 0, 0, 0, time.UTC)
	for i := 0; i < exchangeCount; i++ {
		timestamp := baseTime.Add(time.Duration(i*15) * time.Minute)
		title := fmt.Sprintf("%02d:%02d - Milestone %d",
			timestamp.Hour(), timestamp.Minute(), i+1)

		sections = append(sections, Section{
			Level:   2,
			Title:   title,
			Content: fmt.Sprintf("Content for milestone %d", i+1),
			Children: []Section{
				{
					Level:   3,
					Title:   "Progress",
					Content: fmt.Sprintf("Progress update %d", i+1),
				},
			},
		})
	}

	return &ParsedDocument{
		Source: ImportSource{
			FilePath:     "/test/conversation-logs/session-2025-10-15-1600.md",
			FileType:     "conversation-log",
			LastModified: baseTime,
			FileHash:     "test-hash-123",
			Visibility:   "public",
		},
		Metadata: map[string]interface{}{
			"session_title": topic,
			"session_date":  baseTime,
			"tags":          []string{"test", "chunking"},
		},
		Sections: sections,
	}
}
