package parsers

import (
	"fmt"
	"regexp"
	"strings"
	"time"

	"github.com/TheGenXCoder/knowledge-graph/internal/importtypes"
)

// ConversationLogParser parses conversation log markdown files
type ConversationLogParser struct{}

// NewConversationLogParser creates a new conversation log parser
func NewConversationLogParser() *ConversationLogParser {
	return &ConversationLogParser{}
}

// Parse parses a conversation log file into a ParsedDocument
func (p *ConversationLogParser) Parse(source importtypes.ImportSource, content string) (*importtypes.ParsedDocument, error) {
	doc := &importtypes.ParsedDocument{
		Source:   source,
		Metadata: make(map[string]interface{}),
		Sections: []importtypes.Section{},
	}

	// Parse metadata from header
	metadata, title, err := p.parseHeader(content)
	if err != nil {
		return nil, fmt.Errorf("failed to parse header: %w", err)
	}
	doc.Metadata = metadata

	// Parse sections
	sections, err := p.parseSections(content)
	if err != nil {
		return nil, fmt.Errorf("failed to parse sections: %w", err)
	}
	doc.Sections = sections

	// Extract tags from Tag Index section
	tags := p.extractTags(content)
	if len(tags) > 0 {
		doc.Metadata["tags"] = tags
	}

	// Store title
	if title != "" {
		doc.Metadata["title"] = title
	}

	return doc, nil
}

// parseHeader extracts metadata from the document header
func (p *ConversationLogParser) parseHeader(content string) (map[string]interface{}, string, error) {
	metadata := make(map[string]interface{})
	lines := strings.Split(content, "\n")

	var title string
	inHeader := false
	headerEnd := 0

	for i, line := range lines {
		trimmed := strings.TrimSpace(line)

		// Check for H1 title
		if strings.HasPrefix(trimmed, "# ") {
			title = strings.TrimPrefix(trimmed, "# ")
			// Extract date and description from title
			if matches := regexp.MustCompile(`^Session Log: (.+?) - (.+)$`).FindStringSubmatch(title); len(matches) == 3 {
				metadata["session_date_str"] = matches[1]
				metadata["session_description"] = matches[2]

				// Try to parse the date
				if date, err := p.parseDate(matches[1]); err == nil {
					metadata["session_date"] = date
				}
			}
			inHeader = true
			continue
		}

		// Look for metadata in bold key: value format
		if inHeader && strings.HasPrefix(trimmed, "**") {
			if matches := regexp.MustCompile(`^\*\*([^:]+):\*\*\s*(.+)$`).FindStringSubmatch(trimmed); len(matches) == 3 {
				key := strings.ToLower(strings.ReplaceAll(strings.TrimSpace(matches[1]), " ", "_"))
				value := strings.TrimSpace(matches[2])

				// Parse specific fields
				switch key {
				case "started":
					if t, err := p.parseTimestamp(value); err == nil {
						metadata[key] = t
					} else {
						metadata[key] = value
					}
				case "context_usage":
					metadata[key] = value
				case "session_duration":
					metadata[key] = value
				default:
					metadata[key] = value
				}
			}
		}

		// Check for end of header (horizontal rule or empty lines before first section)
		if inHeader && (trimmed == "---" || (trimmed == "" && i > 5)) {
			headerEnd = i
			break
		}
	}

	// Extract session goal if present
	if goalSection := p.extractSectionContent(content, "Session Goal"); goalSection != "" {
		metadata["session_goal"] = strings.TrimSpace(goalSection)
	}

	// Extract session summary if present
	if summarySection := p.extractSectionContent(content, "Session Summary"); summarySection != "" {
		metadata["session_summary"] = strings.TrimSpace(summarySection)
	}

	// Extract outcome if present
	if outcomeMatch := regexp.MustCompile(`\*\*Outcome:\*\*\s*(.+)`).FindStringSubmatch(content); len(outcomeMatch) == 2 {
		metadata["outcome"] = strings.TrimSpace(outcomeMatch[1])
	}

	_ = headerEnd // Track where header ends for future use

	return metadata, title, nil
}

// parseSections extracts hierarchical sections from the document
func (p *ConversationLogParser) parseSections(content string) ([]importtypes.Section, error) {
	lines := strings.Split(content, "\n")
	var sections []importtypes.Section
	var currentSection *importtypes.Section
	var currentContent strings.Builder

	// Regular expressions for headers
	h1Pattern := regexp.MustCompile(`^# (.+)$`)
	h2Pattern := regexp.MustCompile(`^## (.+)$`)
	h3Pattern := regexp.MustCompile(`^### (.+)$`)
	h4Pattern := regexp.MustCompile(`^#### (.+)$`)

	for lineNum, line := range lines {
		trimmed := strings.TrimSpace(line)

		// Check for headers
		var level int
		var title string

		if matches := h4Pattern.FindStringSubmatch(trimmed); len(matches) == 2 {
			level = 4
			title = matches[1]
		} else if matches := h3Pattern.FindStringSubmatch(trimmed); len(matches) == 2 {
			level = 3
			title = matches[1]
		} else if matches := h2Pattern.FindStringSubmatch(trimmed); len(matches) == 2 {
			level = 2
			title = matches[1]
		} else if matches := h1Pattern.FindStringSubmatch(trimmed); len(matches) == 2 {
			level = 1
			title = matches[1]
		}

		// If we found a header
		if level > 0 {
			// Save previous section if it exists
			if currentSection != nil {
				currentSection.Content = strings.TrimSpace(currentContent.String())
				sections = append(sections, *currentSection)
			}

			// Start new section
			currentSection = &importtypes.Section{
				Level:    level,
				Title:    title,
				Content:  "",
				Children: []importtypes.Section{},
				Line:     lineNum + 1, // 1-indexed
			}
			currentContent.Reset()
		} else if currentSection != nil {
			// Accumulate content for current section
			currentContent.WriteString(line)
			currentContent.WriteString("\n")
		}
	}

	// Save final section
	if currentSection != nil {
		currentSection.Content = strings.TrimSpace(currentContent.String())
		sections = append(sections, *currentSection)
	}

	// Build hierarchical structure
	sections = p.buildHierarchy(sections)

	return sections, nil
}

// buildHierarchy creates a hierarchical structure from flat sections
func (p *ConversationLogParser) buildHierarchy(sections []importtypes.Section) []importtypes.Section {
	if len(sections) == 0 {
		return sections
	}

	var result []importtypes.Section
	var stack []*importtypes.Section

	for i := range sections {
		section := sections[i]

		// Pop stack until we find a parent level
		for len(stack) > 0 && stack[len(stack)-1].Level >= section.Level {
			stack = stack[:len(stack)-1]
		}

		if len(stack) == 0 {
			// Top-level section
			result = append(result, section)
			stack = append(stack, &result[len(result)-1])
		} else {
			// Child section
			parent := stack[len(stack)-1]
			parent.Children = append(parent.Children, section)
			stack = append(stack, &parent.Children[len(parent.Children)-1])
		}
	}

	return result
}

// extractTags finds and extracts tags from the Tag Index section
func (p *ConversationLogParser) extractTags(content string) []string {
	var tags []string

	// Look for Tag Index section
	tagPattern := regexp.MustCompile(`(?m)^## Tag Index\s*\n\s*(.+)$`)
	if matches := tagPattern.FindStringSubmatch(content); len(matches) == 2 {
		tagLine := matches[1]
		// Extract all hashtags
		hashtagPattern := regexp.MustCompile(`#([a-zA-Z0-9_-]+)`)
		hashtagMatches := hashtagPattern.FindAllStringSubmatch(tagLine, -1)
		for _, match := range hashtagMatches {
			if len(match) == 2 {
				tags = append(tags, match[1])
			}
		}
	}

	return tags
}

// extractSectionContent extracts content from a specific section by title
func (p *ConversationLogParser) extractSectionContent(content, sectionTitle string) string {
	// Pattern to match section header and capture content until next same-level header or end
	pattern := regexp.MustCompile(fmt.Sprintf(`(?ms)^## %s\s*\n(.*?)(?:^## |\z)`, regexp.QuoteMeta(sectionTitle)))
	if matches := pattern.FindStringSubmatch(content); len(matches) == 2 {
		return strings.TrimSpace(matches[1])
	}
	return ""
}

// parseDate attempts to parse various date formats
func (p *ConversationLogParser) parseDate(dateStr string) (time.Time, error) {
	formats := []string{
		"2006-01-02",
		"2006-01-02 15:04",
		"2006-01-02T15:04:05",
		"2006-01-02T15:04:05-07:00",
		"2006-01-02T15:04:05Z",
		"2006-01-02 15:04:05",
		"January 2, 2006",
		"Jan 2, 2006",
		"02/01/2006",
		"01/02/2006",
	}

	for _, format := range formats {
		if t, err := time.Parse(format, dateStr); err == nil {
			return t, nil
		}
	}

	return time.Time{}, fmt.Errorf("unable to parse date: %s", dateStr)
}

// parseTimestamp attempts to parse timestamp with various formats
func (p *ConversationLogParser) parseTimestamp(timestamp string) (time.Time, error) {
	// Remove markdown code formatting if present
	timestamp = strings.Trim(timestamp, "`")

	formats := []string{
		time.RFC3339,
		"2006-01-02T15:04:05-07:00",
		"2006-01-02T15:04:05Z",
		"2006-01-02 15:04:05",
		"2006-01-02 15:04",
		"2006-01-02T15:04:05",
	}

	for _, format := range formats {
		if t, err := time.Parse(format, timestamp); err == nil {
			return t, nil
		}
	}

	return time.Time{}, fmt.Errorf("unable to parse timestamp: %s", timestamp)
}

// ParseMilestones extracts milestone/timestamp sections (e.g., "16:00 - Session Started")
func (p *ConversationLogParser) ParseMilestones(content string) []Milestone {
	var milestones []Milestone

	// Pattern for timestamp sections: ## HH:MM - Title
	pattern := regexp.MustCompile(`(?m)^## (\d{1,2}:\d{2})(?: - (.+))?$`)
	lines := strings.Split(content, "\n")

	var currentMilestone *Milestone
	var currentContent strings.Builder

	for _, line := range lines {
		if matches := pattern.FindStringSubmatch(line); len(matches) >= 2 {
			// Save previous milestone
			if currentMilestone != nil {
				currentMilestone.Content = strings.TrimSpace(currentContent.String())
				milestones = append(milestones, *currentMilestone)
			}

			// Start new milestone
			timestamp := matches[1]
			title := ""
			if len(matches) == 3 {
				title = matches[2]
			}

			currentMilestone = &Milestone{
				Timestamp: timestamp,
				Title:     title,
			}
			currentContent.Reset()
		} else if currentMilestone != nil && !strings.HasPrefix(line, "## ") {
			// Accumulate content (but stop at next H2)
			currentContent.WriteString(line)
			currentContent.WriteString("\n")
		}
	}

	// Save final milestone
	if currentMilestone != nil {
		currentMilestone.Content = strings.TrimSpace(currentContent.String())
		milestones = append(milestones, *currentMilestone)
	}

	return milestones
}

// Milestone represents a timestamped section in a conversation log
type Milestone struct {
	Timestamp string // HH:MM format
	Title     string
	Content   string
}

// ExtractKeyDecisions finds and extracts key decisions from the content
func (p *ConversationLogParser) ExtractKeyDecisions(content string) []string {
	decisions := []string{}

	// Look for "Key Decisions" or "Decisions Made" section
	decisionSection := p.extractSectionContent(content, "Key Decisions")
	if decisionSection == "" {
		decisionSection = p.extractSectionContent(content, "Key Decisions Made")
	}
	if decisionSection == "" {
		decisionSection = p.extractSectionContent(content, "Decisions Made")
	}

	if decisionSection != "" {
		// Extract numbered or bulleted items (top-level only)
		lines := strings.Split(decisionSection, "\n")
		var currentDecision strings.Builder
		inDecision := false

		for _, line := range lines {
			trimmed := strings.TrimSpace(line)

			// Check if this is a top-level list item (starts at beginning or with minimal indent)
			isTopLevel := regexp.MustCompile(`^(\d+\.)\s+`).MatchString(trimmed)

			if isTopLevel {
				// Save previous decision if any
				if inDecision && currentDecision.Len() > 0 {
					decisions = append(decisions, strings.TrimSpace(currentDecision.String()))
					currentDecision.Reset()
				}

				// Start new decision (remove list marker)
				decision := regexp.MustCompile(`^(\d+\.)\s+`).ReplaceAllString(trimmed, "")
				currentDecision.WriteString(decision)
				inDecision = true
			} else if inDecision && trimmed != "" && !strings.HasPrefix(trimmed, "-") {
				// Continue previous decision (but not sub-bullets)
				currentDecision.WriteString(" ")
				currentDecision.WriteString(trimmed)
			} else if trimmed == "" && inDecision {
				// Empty line might signal end of decision
				if currentDecision.Len() > 0 {
					decisions = append(decisions, strings.TrimSpace(currentDecision.String()))
					currentDecision.Reset()
					inDecision = false
				}
			}
		}

		// Save final decision
		if inDecision && currentDecision.Len() > 0 {
			decisions = append(decisions, strings.TrimSpace(currentDecision.String()))
		}
	}

	return decisions
}

// ExtractFilesModified finds and extracts files created/modified
func (p *ConversationLogParser) ExtractFilesModified(content string) map[string][]string {
	files := map[string][]string{
		"created":  []string{},
		"modified": []string{},
	}

	// Look for "Files Created/Modified" or similar sections
	filesSection := p.extractSectionContent(content, "Files Created/Modified This Session")
	if filesSection == "" {
		filesSection = p.extractSectionContent(content, "Files Modified")
	}
	if filesSection == "" {
		filesSection = p.extractSectionContent(content, "Files Created")
	}

	if filesSection != "" {
		lines := strings.Split(filesSection, "\n")
		currentCategory := ""

		for _, line := range lines {
			trimmed := strings.TrimSpace(line)

			// Check for category headers
			if strings.HasPrefix(trimmed, "**Created:**") {
				currentCategory = "created"
				continue
			} else if strings.HasPrefix(trimmed, "**Modified:**") {
				currentCategory = "modified"
				continue
			}

			// Extract file paths (lines starting with -, *, or containing backticks)
			if currentCategory != "" && (strings.HasPrefix(trimmed, "-") || strings.HasPrefix(trimmed, "*")) {
				// Remove list markers
				filePath := regexp.MustCompile(`^[-*]\s+`).ReplaceAllString(trimmed, "")

				// Extract from backticks if present
				if matches := regexp.MustCompile("`([^`]+)`").FindStringSubmatch(filePath); len(matches) == 2 {
					filePath = matches[1]
				}

				// Clean up and validate
				filePath = strings.Split(filePath, " - ")[0] // Remove descriptions
				filePath = strings.TrimSpace(filePath)

				// Accept paths with / or starting with . or ~
				if filePath != "" && (strings.Contains(filePath, "/") || strings.HasPrefix(filePath, ".") || strings.HasPrefix(filePath, "~")) {
					files[currentCategory] = append(files[currentCategory], filePath)
				}
			}
		}
	}

	return files
}
