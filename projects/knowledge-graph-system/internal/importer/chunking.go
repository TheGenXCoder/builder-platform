package importer

import (
	"fmt"
	"log"
	"regexp"
	"strings"
	"time"
)

// ChunkOptions configures the chunking behavior
type ChunkOptions struct {
	MinExchangesPerBlock int  // Minimum exchanges per block (default: 1)
	MaxExchangesPerBlock int  // Maximum exchanges per block (default: 15)
	TargetExchanges      int  // Target exchanges per block (default: 4, range 3-5)
	RespectBoundaries    bool // Don't split mid-milestone (default: true)
}

// DefaultChunkOptions returns sensible defaults
func DefaultChunkOptions() ChunkOptions {
	return ChunkOptions{
		MinExchangesPerBlock: 1,
		MaxExchangesPerBlock: 15,
		TargetExchanges:      4,
		RespectBoundaries:    true,
	}
}

// ChunkDocument converts a ParsedDocument into PreBlocks using intelligent chunking
func ChunkDocument(doc *ParsedDocument, opts ChunkOptions) ([]PreBlock, error) {
	if doc == nil {
		return nil, fmt.Errorf("document is nil")
	}

	log.Printf("[CHUNK] Processing file: %s (type: %s)", doc.Source.FilePath, doc.Source.FileType)

	// Validate options
	if opts.MinExchangesPerBlock < 1 {
		opts.MinExchangesPerBlock = 1
	}
	if opts.MaxExchangesPerBlock < opts.MinExchangesPerBlock {
		opts.MaxExchangesPerBlock = 15
	}
	if opts.TargetExchanges < 3 || opts.TargetExchanges > 5 {
		opts.TargetExchanges = 4
	}

	// Route to appropriate chunking strategy based on file type
	switch doc.Source.FileType {
	case "conversation-log":
		return chunkConversationLog(doc, opts)
	case "spec", "doc", "readme", "mission":
		log.Printf("[CHUNK] Routing to documentation chunker for type: %s", doc.Source.FileType)
		return chunkDocumentation(doc, opts)
	case "working-file":
		return chunkWorkingFile(doc, opts)
	default:
		log.Printf("[CHUNK] ERROR: Unsupported file type: %s", doc.Source.FileType)
		return nil, fmt.Errorf("unsupported file type: %s", doc.Source.FileType)
	}
}

// chunkConversationLog handles conversation log files with milestone-based chunking
func chunkConversationLog(doc *ParsedDocument, opts ChunkOptions) ([]PreBlock, error) {
	log.Printf("[CHUNK] Processing conversation log: %s", doc.Source.FilePath)
	log.Printf("[CHUNK] Total sections parsed: %d", len(doc.Sections))

	// Log section structure
	for i, section := range doc.Sections {
		log.Printf("[CHUNK] Section[%d]: Level=%d, Title=%q, ContentLen=%d, Children=%d",
			i, section.Level, section.Title, len(section.Content), len(section.Children))
	}

	// Extract session metadata from document
	sessionTopic := extractSessionTopic(doc)
	sessionDate := extractSessionDate(doc)
	sessionID := generateSessionID(doc.Source.FilePath, sessionDate)

	log.Printf("[CHUNK] Session metadata: Topic=%q, Date=%v, ID=%s", sessionTopic, sessionDate, sessionID)

	// Extract exchanges from milestone sections
	exchanges := extractExchangesFromSections(doc.Sections)

	log.Printf("[CHUNK] Extracted %d exchanges from sections", len(exchanges))

	if len(exchanges) == 0 {
		return nil, fmt.Errorf("no exchanges found in conversation log")
	}

	// Decide on chunking strategy based on exchange count
	var blocks []PreBlock

	if len(exchanges) <= opts.TargetExchanges*2 {
		// Small session: Single block
		blocks = []PreBlock{
			createPreBlock(
				sessionTopic,
				exchanges,
				doc,
				sessionID,
				sessionDate,
				1, // chunk number
				1, // total chunks
			),
		}
	} else {
		// Large session: Split into multiple blocks
		blocks = splitIntoBlocks(
			sessionTopic,
			exchanges,
			doc,
			sessionID,
			sessionDate,
			opts,
		)
	}

	return blocks, nil
}

// chunkDocumentation handles spec and doc files (Week 2+)
func chunkDocumentation(doc *ParsedDocument, opts ChunkOptions) ([]PreBlock, error) {
	log.Printf("[CHUNK-DOC] Processing documentation: %s", doc.Source.FilePath)
	log.Printf("[CHUNK-DOC] Total sections: %d", len(doc.Sections))

	// Extract document title (usually from first H1 or filename)
	docTitle := extractDocumentTitle(doc)
	log.Printf("[CHUNK-DOC] Document title: %q", docTitle)

	// Extract all meaningful sections (H2+) as individual blocks
	blocks := extractDocumentationBlocks(doc, docTitle)

	log.Printf("[CHUNK-DOC] Created %d blocks from documentation", len(blocks))
	return blocks, nil
}

// chunkWorkingFile handles .working.md files (Week 2+)
func chunkWorkingFile(doc *ParsedDocument, opts ChunkOptions) ([]PreBlock, error) {
	// Placeholder for future implementation
	// Will extract current state, decisions, and file modifications
	return nil, fmt.Errorf("working file chunking not yet implemented")
}

// extractSessionTopic extracts the session topic/title from metadata or first H1
func extractSessionTopic(doc *ParsedDocument) string {
	// Check metadata first
	if topic, ok := doc.Metadata["session_title"].(string); ok && topic != "" {
		return topic
	}
	if goal, ok := doc.Metadata["session_goal"].(string); ok && goal != "" {
		return goal
	}

	// Fallback to first H1 section title
	for _, section := range doc.Sections {
		if section.Level == 1 && section.Title != "" {
			// Clean up the title (remove "Session Log: YYYY-MM-DD - " prefix if present)
			title := section.Title
			re := regexp.MustCompile(`^Session Log:\s*\d{4}-\d{2}-\d{2}\s*-\s*`)
			title = re.ReplaceAllString(title, "")
			return strings.TrimSpace(title)
		}
	}

	return "Untitled Session"
}

// extractSessionDate extracts the session date from metadata or filename
func extractSessionDate(doc *ParsedDocument) time.Time {
	// Check metadata first
	if date, ok := doc.Metadata["session_date"].(time.Time); ok {
		return date
	}
	if startedAt, ok := doc.Metadata["started_at"].(time.Time); ok {
		return startedAt
	}

	// Try to parse from filename (e.g., session-2025-10-15-1600.md)
	re := regexp.MustCompile(`session-(\d{4})-(\d{2})-(\d{2})-(\d{2})(\d{2})`)
	matches := re.FindStringSubmatch(doc.Source.FilePath)
	if len(matches) == 6 {
		// Parse: YYYY-MM-DD-HHMM
		dateStr := fmt.Sprintf("%s-%s-%sT%s:%s:00Z",
			matches[1], matches[2], matches[3], matches[4], matches[5])
		if t, err := time.Parse(time.RFC3339, dateStr); err == nil {
			return t
		}
	}

	// Fallback to file modification time
	return doc.Source.LastModified
}

// generateSessionID creates a unique session identifier
func generateSessionID(filePath string, date time.Time) string {
	// Extract filename without extension
	parts := strings.Split(filePath, "/")
	filename := parts[len(parts)-1]
	filename = strings.TrimSuffix(filename, ".md")

	// Use filename as session ID (e.g., "session-2025-10-15-1600")
	if strings.HasPrefix(filename, "session-") {
		return filename
	}

	// Fallback to date-based ID
	return fmt.Sprintf("session-%s", date.Format("2006-01-02-1504"))
}

// extractExchangesFromSections converts milestone sections into Q&A exchanges
func extractExchangesFromSections(sections []Section) []PreExchange {
	var exchanges []PreExchange

	log.Printf("[EXTRACT] Processing %d sections", len(sections))

	for i, section := range sections {
		log.Printf("[EXTRACT] Section[%d]: Level=%d, Title=%q, ContentLen=%d, Children=%d",
			i, section.Level, section.Title, len(section.Content), len(section.Children))

		// Skip H1 headers (document title) but process their children
		if section.Level == 1 {
			log.Printf("[EXTRACT] Skipping H1 section: %q, but processing %d children", section.Title, len(section.Children))
			childExchanges := extractExchangesFromSections(section.Children)
			exchanges = append(exchanges, childExchanges...)
			continue
		}

		// Skip metadata sections
		if isMetadataSection(section.Title) {
			log.Printf("[EXTRACT] Skipping metadata section: %q", section.Title)
			// But still process children
			childExchanges := extractExchangesFromSections(section.Children)
			exchanges = append(exchanges, childExchanges...)
			continue
		}

		// Extract timestamp from section title (handles both formats):
		// "16:05 - Title" or "Phase 1: Title (~13:00)"
		timestamp := extractTimestampFromTitle(section.Title)

		// Extract milestone title (question)
		question := extractMilestoneTitle(section.Title)

		// Extract answer from section content
		answer := buildAnswerFromSection(section)

		log.Printf("[EXTRACT] Extracted - Question=%q (len=%d), Answer=%q... (len=%d)",
			question, len(question), truncateForLog(answer, 60), len(answer))

		if question != "" && answer != "" {
			log.Printf("[EXTRACT] ✓ Adding exchange: %q", question)
			exchanges = append(exchanges, PreExchange{
				Question:  question,
				Answer:    answer,
				Timestamp: timestamp,
				ModelUsed: extractModelUsed(section.Content),
			})
		} else {
			log.Printf("[EXTRACT] ✗ Skipping exchange - question empty=%v, answer empty=%v",
				question == "", answer == "")
		}

		// Recursively process children sections
		childExchanges := extractExchangesFromSections(section.Children)
		exchanges = append(exchanges, childExchanges...)
	}

	log.Printf("[EXTRACT] Returning %d total exchanges", len(exchanges))
	return exchanges
}

// isMetadataSection returns true if the section is metadata (not a milestone)
func isMetadataSection(title string) bool {
	metadataSections := []string{
		"Session Goal",
		"Session Arc",
		"Session Overview",
		"Progress Summary",
		"Key Decisions",
		"Files Modified",
		"Recovery Instructions",
		"Session Summary",
		"Tag Index",
	}

	titleLower := strings.ToLower(strings.TrimSpace(title))
	for _, meta := range metadataSections {
		if strings.Contains(titleLower, strings.ToLower(meta)) {
			return true
		}
	}

	return false
}

// extractTimestampFromTitle extracts timestamp from milestone title
// Example: "16:05 - Claude Code Capabilities Research" → 16:05
func extractTimestampFromTitle(title string) time.Time {
	now := time.Now()

	// Match HH:MM format at start of title: "16:05 - Title"
	re1 := regexp.MustCompile(`^(\d{1,2}):(\d{2})`)
	if matches := re1.FindStringSubmatch(title); len(matches) == 3 {
		timeStr := fmt.Sprintf("%04d-%02d-%02dT%s:%s:00Z",
			now.Year(), now.Month(), now.Day(), matches[1], matches[2])
		if t, err := time.Parse(time.RFC3339, timeStr); err == nil {
			return t
		}
	}

	// Match (~HH:MM) format in parentheses: "Phase 1: Title (~13:00)"
	re2 := regexp.MustCompile(`\(~(\d{1,2}):(\d{2})\)`)
	if matches := re2.FindStringSubmatch(title); len(matches) == 3 {
		timeStr := fmt.Sprintf("%04d-%02d-%02dT%s:%s:00Z",
			now.Year(), now.Month(), now.Day(), matches[1], matches[2])
		if t, err := time.Parse(time.RFC3339, timeStr); err == nil {
			return t
		}
	}

	return now
}

// extractMilestoneTitle extracts the milestone title without timestamp
// Example: "16:05 - Claude Code Capabilities Research" → "Claude Code Capabilities Research"
// Example: "Phase 1: Title (~13:00)" → "Phase 1: Title"
func extractMilestoneTitle(title string) string {
	// Remove timestamp prefix (HH:MM - ) with flexible whitespace
	re1 := regexp.MustCompile(`^\s*\d{1,2}:\d{2}\s+-\s+`)
	title = re1.ReplaceAllString(title, "")

	// Remove timestamp suffix in parentheses: (~HH:MM)
	re2 := regexp.MustCompile(`\s*\(~\d{1,2}:\d{2}\)`)
	title = re2.ReplaceAllString(title, "")

	return strings.TrimSpace(title)
}

// buildAnswerFromSection constructs the answer from section content and structure
func buildAnswerFromSection(section Section) string {
	var parts []string

	// Add main content
	if section.Content != "" {
		parts = append(parts, strings.TrimSpace(section.Content))
	}

	// Add structured subsections (Action, Progress, Decisions, Files, etc.)
	for _, child := range section.Children {
		if child.Level == 3 && child.Content != "" {
			// Format: **SubsectionTitle:**\nContent
			subsection := fmt.Sprintf("**%s:**\n%s", child.Title, strings.TrimSpace(child.Content))
			parts = append(parts, subsection)
		}
	}

	return strings.Join(parts, "\n\n")
}

// extractModelUsed extracts model information from content if present
func extractModelUsed(content string) string {
	// Look for model mentions in content
	// Patterns are ordered from most specific to least specific
	patterns := []string{
		`(?:model|using|with)\s*[:=]?\s*([a-z0-9][a-z0-9\-\.]+)(?:\s+model)?`,
		`([a-z0-9]+(?:-[a-z0-9]+)+)\s+model`,
		`claude[- ]([0-9]+(?:\.[0-9]+)?(?:[a-z\-]+)*)`,
	}

	contentLower := strings.ToLower(content)
	for _, pattern := range patterns {
		re := regexp.MustCompile(pattern)
		if matches := re.FindStringSubmatch(contentLower); len(matches) > 1 {
			model := strings.TrimSpace(matches[1])
			// Validate it looks like a model name (not a common word)
			if len(model) > 2 && strings.Contains(model, "-") {
				return model
			}
		}
	}

	return "" // Unknown/not specified
}

// splitIntoBlocks splits exchanges into multiple PreBlocks
func splitIntoBlocks(
	baseTopic string,
	exchanges []PreExchange,
	doc *ParsedDocument,
	sessionID string,
	sessionDate time.Time,
	opts ChunkOptions,
) []PreBlock {
	var blocks []PreBlock
	totalExchanges := len(exchanges)

	// Calculate optimal chunk size
	chunkSize := opts.TargetExchanges
	if totalExchanges/chunkSize > 5 {
		// Too many chunks, increase chunk size slightly
		chunkSize = opts.TargetExchanges + 1
	}

	// Split into chunks
	for i := 0; i < totalExchanges; i += chunkSize {
		end := i + chunkSize
		if end > totalExchanges {
			end = totalExchanges
		}

		// Adjust end if we'd leave too few exchanges in last chunk
		remaining := totalExchanges - end
		if remaining > 0 && remaining < opts.MinExchangesPerBlock {
			end = totalExchanges // Include remaining in current chunk
		}

		chunkExchanges := exchanges[i:end]
		chunkNumber := (i / chunkSize) + 1
		totalChunks := (totalExchanges + chunkSize - 1) / chunkSize

		// Create topic with chunk context
		topic := baseTopic
		if totalChunks > 1 {
			// Add temporal context from first/last exchange in chunk
			firstTitle := extractMilestoneTitle(chunkExchanges[0].Question)
			topic = fmt.Sprintf("%s (Part %d: %s)", baseTopic, chunkNumber, firstTitle)
		}

		blocks = append(blocks, createPreBlock(
			topic,
			chunkExchanges,
			doc,
			sessionID,
			sessionDate,
			chunkNumber,
			totalChunks,
		))
	}

	return blocks
}

// createPreBlock constructs a PreBlock from exchanges and metadata
func createPreBlock(
	topic string,
	exchanges []PreExchange,
	doc *ParsedDocument,
	sessionID string,
	sessionDate time.Time,
	chunkNumber, totalChunks int,
) PreBlock {
	// Build metadata
	metadata := make(map[string]interface{})

	// Copy source metadata
	for k, v := range doc.Metadata {
		metadata[k] = v
	}

	// Add chunk-specific metadata
	metadata["session_id"] = sessionID
	metadata["session_date"] = sessionDate
	metadata["chunk_number"] = chunkNumber
	metadata["total_chunks"] = totalChunks
	metadata["exchange_count"] = len(exchanges)

	// Extract tags from metadata if present
	tags := extractTags(doc.Metadata)

	// Determine start and completion times
	startedAt := sessionDate
	if len(exchanges) > 0 {
		startedAt = exchanges[0].Timestamp
	}

	var completedAt *time.Time
	if len(exchanges) > 0 {
		t := exchanges[len(exchanges)-1].Timestamp
		completedAt = &t
	}

	// Extract project path from file path
	projectPath := extractProjectPath(doc.Source.FilePath)

	return PreBlock{
		Topic:       topic,
		Exchanges:   exchanges,
		Metadata:    metadata,
		Tags:        tags,
		ProjectPath: projectPath,
		SourceFile:  doc.Source.FilePath,
		SourceType:  doc.Source.FileType,
		SourceHash:  doc.Source.FileHash,
		StartedAt:   startedAt,
		CompletedAt: completedAt,

		// Visibility and organization
		Visibility:     doc.Source.Visibility,
		OrganizationID: doc.Source.OrganizationID,
	}
}

// extractTags extracts tags from metadata
func extractTags(metadata map[string]interface{}) []string {
	// Check for tags in metadata
	if tags, ok := metadata["tags"].([]string); ok {
		return tags
	}
	if tags, ok := metadata["tags"].([]interface{}); ok {
		result := make([]string, 0, len(tags))
		for _, tag := range tags {
			if str, ok := tag.(string); ok {
				result = append(result, str)
			}
		}
		return result
	}

	// Parse tag index from content if present
	if tagIndex, ok := metadata["tag_index"].(string); ok {
		return parseTagIndex(tagIndex)
	}

	return []string{}
}

// parseTagIndex parses tags from tag index string
// Example: "#context-preservation #agent-os #system-standards"
func parseTagIndex(tagIndex string) []string {
	var tags []string

	// Split by whitespace and extract hashtags
	parts := strings.Fields(tagIndex)
	for _, part := range parts {
		if strings.HasPrefix(part, "#") {
			tag := strings.TrimPrefix(part, "#")
			tag = strings.Trim(tag, ".,;:")
			if tag != "" {
				tags = append(tags, tag)
			}
		}
	}

	return tags
}

// extractProjectPath extracts project path from file path
// Example: "/path/to/project/conversation-logs/session.md" → "/path/to/project"
func extractProjectPath(filePath string) string {
	// Look for common project markers
	markers := []string{
		"/conversation-logs/",
		"/specs/",
		"/docs/",
		"/builds/",
	}

	for _, marker := range markers {
		if idx := strings.Index(filePath, marker); idx != -1 {
			return filePath[:idx]
		}
	}

	// Fallback: parent directory of file
	parts := strings.Split(filePath, "/")
	if len(parts) > 2 {
		return strings.Join(parts[:len(parts)-2], "/")
	}

	return filePath
}

// truncateForLog truncates a string for logging purposes
func truncateForLog(s string, maxLen int) string {
	if len(s) <= maxLen {
		return s
	}
	return s[:maxLen] + "..."
}

// extractDocumentTitle gets the document title from H1 or metadata
func extractDocumentTitle(doc *ParsedDocument) string {
	// Try metadata first
	if title, ok := doc.Metadata["title"].(string); ok && title != "" {
		return title
	}

	// Try first H1 section
	for _, section := range doc.Sections {
		if section.Level == 1 {
			return section.Title
		}
	}

	// Fallback to filename
	parts := strings.Split(doc.Source.FilePath, "/")
	filename := parts[len(parts)-1]
	return strings.TrimSuffix(filename, ".md")
}

// extractDocumentationBlocks converts documentation sections into PreBlocks
func extractDocumentationBlocks(doc *ParsedDocument, docTitle string) []PreBlock {
	var blocks []PreBlock

	// Process all top-level sections
	for _, section := range doc.Sections {
		// Skip H1 but process its children
		if section.Level == 1 {
			for _, child := range section.Children {
				block := createDocumentationBlock(doc, docTitle, child)
				if block != nil {
					blocks = append(blocks, *block)
				}
			}
		} else {
			// H2+ sections at root level
			block := createDocumentationBlock(doc, docTitle, section)
			if block != nil {
				blocks = append(blocks, *block)
			}
		}
	}

	return blocks
}

// createDocumentationBlock creates a PreBlock from a documentation section
func createDocumentationBlock(doc *ParsedDocument, docTitle string, section Section) *PreBlock {
	// Skip empty sections
	if section.Title == "" {
		return nil
	}

	log.Printf("[CHUNK-DOC] Creating block for section: %q (level: %d, content: %d chars)",
		section.Title, section.Level, len(section.Content))

	// Build comprehensive content including children
	content := section.Content
	if len(section.Children) > 0 {
		content += "\n\n"
		for _, child := range section.Children {
			content += fmt.Sprintf("### %s\n%s\n\n", child.Title, child.Content)
		}
	}

	// Create a single "exchange" where the section title is the question
	// and the content is the answer
	exchange := PreExchange{
		Question:  section.Title,
		Answer:    strings.TrimSpace(content),
		Timestamp: doc.Source.LastModified,
		ModelUsed: "documentation",
	}

	// Only create block if we have content
	if exchange.Answer == "" {
		log.Printf("[CHUNK-DOC] Skipping section %q - no content", section.Title)
		return nil
	}

	// Extract tags from content (simple keyword extraction)
	tags := extractDocumentationTags(doc, section)

	block := &PreBlock{
		Topic:       fmt.Sprintf("%s: %s", docTitle, section.Title),
		Exchanges:   []PreExchange{exchange},
		Tags:        tags,
		ProjectPath: extractProjectPath(doc.Source.FilePath),
		SourceFile:  doc.Source.FilePath,
		SourceType:  doc.Source.FileType,
		SourceHash:  doc.Source.FileHash,
		StartedAt:   doc.Source.LastModified,
		CompletedAt: &doc.Source.LastModified,
		Visibility:  doc.Source.Visibility,
		OrganizationID: doc.Source.OrganizationID,
		Metadata: map[string]interface{}{
			"section_level": section.Level,
			"section_title": section.Title,
			"doc_title":     docTitle,
		},
	}

	return block
}

// extractDocumentationTags extracts relevant tags from documentation
func extractDocumentationTags(doc *ParsedDocument, section Section) []string {
	tags := []string{}

	// Add document type tag
	tags = append(tags, doc.Source.FileType)

	// Extract from metadata if available
	if docTags, ok := doc.Metadata["tags"].([]string); ok {
		tags = append(tags, docTags...)
	}

	// Add common keywords from title and content
	keywords := extractKeywords(section.Title + " " + section.Content)
	tags = append(tags, keywords...)

	return deduplicateTags(tags)
}

// extractKeywords does simple keyword extraction from text
func extractKeywords(text string) []string {
	// Lowercase and split on whitespace/punctuation
	text = strings.ToLower(text)
	
	// Common technical keywords to look for
	keywords := []string{}
	technicalTerms := []string{
		"api", "database", "frontend", "backend", "deployment", "testing",
		"authentication", "authorization", "cache", "queue", "migration",
		"docker", "kubernetes", "postgres", "redis", "nginx", "react",
		"golang", "python", "typescript", "javascript", "sql",
	}

	for _, term := range technicalTerms {
		if strings.Contains(text, term) {
			keywords = append(keywords, term)
		}
	}

	return keywords
}

// deduplicateTags removes duplicate tags
func deduplicateTags(tags []string) []string {
	seen := make(map[string]bool)
	result := []string{}
	
	for _, tag := range tags {
		tag = strings.TrimSpace(strings.ToLower(tag))
		if tag != "" && !seen[tag] {
			seen[tag] = true
			result = append(result, tag)
		}
	}
	
	return result
}
