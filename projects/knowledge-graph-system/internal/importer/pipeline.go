package importer

import (
	"bufio"
	"context"
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/TheGenXCoder/knowledge-graph/internal/core"
	"github.com/TheGenXCoder/knowledge-graph/internal/importer/parsers"
	"github.com/TheGenXCoder/knowledge-graph/pkg/types"
	"github.com/google/uuid"
)

// RunImport executes the full import pipeline
func RunImport(ctx context.Context, kg core.KnowledgeGraph, opts ImportOptions) (*ImportReport, error) {
	report := &ImportReport{
		StartedAt: time.Now(),
		Errors:    []ImportError{},
	}

	// Stage 1: Discovery
	if opts.ShowProgress {
		fmt.Println("Discovering files...")
	}

	sources, err := Discover(opts)
	if err != nil {
		return nil, fmt.Errorf("discovery failed: %w", err)
	}
	report.SourcesFound = len(sources)

	if opts.ShowProgress {
		fmt.Printf("✓ Found %d files\n\n", len(sources))
	}

	if len(sources) == 0 {
		report.CompletedAt = time.Now()
		return report, nil
	}

	// Stage 2: Classification
	if opts.ShowProgress {
		fmt.Println("Classifying sources...")
	}

	for i := range sources {
		if err := ClassifySource(&sources[i], "auto", nil); err != nil {
			report.Errors = append(report.Errors, ImportError{
				Source:  sources[i],
				Stage:   "classification",
				Message: "Failed to classify source",
				Error:   err,
			})
		}
	}

	if opts.ShowProgress {
		fmt.Printf("✓ Classified %d sources\n\n", len(sources))
	}

	// Stage 3: Parsing
	if opts.ShowProgress {
		fmt.Println("Parsing documents...")
	}

	var parsedDocs []ParsedDocument
	processed := 0
	for _, source := range sources {
		if opts.ShowProgress && processed%10 == 0 {
			progress := float64(processed) / float64(len(sources)) * 100
			bar := progressBar(progress, 20)
			fmt.Printf("\r[%s] %.0f%% (%d/%d files)", bar, progress, processed, len(sources))
		}

		doc, err := parseSource(source)
		if err != nil {
			report.Errors = append(report.Errors, ImportError{
				Source:  source,
				Stage:   "parse",
				Message: "Failed to parse source",
				Error:   err,
			})
			report.Failed++
			processed++
			continue
		}

		parsedDocs = append(parsedDocs, *doc)
		report.SourcesParsed++
		processed++
	}

	if opts.ShowProgress {
		bar := progressBar(100, 20)
		fmt.Printf("\r[%s] 100%% (%d/%d files)\n", bar, len(parsedDocs), len(sources))
		fmt.Printf("✓ Parsed %d documents\n\n", len(parsedDocs))
	}

	// Stage 4: Chunking
	if opts.ShowProgress {
		fmt.Println("Chunking into blocks...")
	}

	chunkOpts := DefaultChunkOptions()
	var preBlocks []PreBlock

	for _, doc := range parsedDocs {
		blocks, err := ChunkDocument(&doc, chunkOpts)
		if err != nil {
			report.Errors = append(report.Errors, ImportError{
				Source:  doc.Source,
				Stage:   "chunk",
				Message: "Failed to chunk document",
				Error:   err,
			})
			continue
		}
		preBlocks = append(preBlocks, blocks...)
	}

	report.BlocksCreated = len(preBlocks)

	if opts.ShowProgress {
		fmt.Printf("✓ Created %d blocks from %d files\n\n", len(preBlocks), len(parsedDocs))
	}

	// Stage 5: Deduplication
	if opts.ShowProgress {
		fmt.Println("Deduplication...")
	}

	decisions, err := DeduplicateBlocks(ctx, kg, preBlocks)
	if err != nil {
		return nil, fmt.Errorf("deduplication failed: %w", err)
	}

	report.Decisions = decisions
	for _, d := range decisions {
		switch d.Action {
		case "insert":
			report.Inserted++
		case "update":
			report.Updated++
		case "skip":
			report.Skipped++
		}
	}

	if opts.ShowProgress {
		fmt.Printf("✓ %d new blocks\n", report.Inserted)
		fmt.Printf("✓ %d updates\n", report.Updated)
		fmt.Printf("✓ %d skipped (unchanged)\n\n", report.Skipped)
	}

	// Dry-run preview
	if opts.DryRun {
		if opts.ShowProgress {
			fmt.Println("=== DRY RUN - No changes made ===")
			showPreview(decisions, opts.PreviewCount)
			showClassificationSummary(sources)
		}
		report.CompletedAt = time.Now()
		return report, nil
	}

	// Stage 6: Import to database
	if opts.ShowProgress {
		fmt.Println("Importing to database...")
	}

	imported := 0
	total := report.Inserted + report.Updated

	for i, decision := range decisions {
		if decision.Action == "skip" {
			continue
		}

		if opts.ShowProgress && i%10 == 0 && total > 0 {
			progress := float64(imported) / float64(total) * 100
			bar := progressBar(progress, 20)
			fmt.Printf("\r[%s] %.0f%% (%d/%d blocks)", bar, progress, imported, total)
		}

		if err := importBlock(ctx, kg, decision); err != nil {
			report.Errors = append(report.Errors, ImportError{
				Source:  ImportSource{FilePath: decision.PreBlock.SourceFile},
				Stage:   "import",
				Message: fmt.Sprintf("Failed to import block: %s", decision.PreBlock.Topic),
				Error:   err,
			})
			report.Failed++
			continue
		}

		imported++
	}

	if opts.ShowProgress {
		progress := 100.0
		if total > 0 {
			progress = float64(imported) / float64(total) * 100
		}
		fmt.Printf("\r[%s] %.0f%% (%d/%d blocks)\n\n", progressBar(progress, 20), progress, imported, total)
	}

	report.CompletedAt = time.Now()

	if opts.ShowProgress {
		fmt.Println("Import complete! ✅")
		elapsed := report.CompletedAt.Sub(report.StartedAt)
		fmt.Printf("Time: %.1fs\n", elapsed.Seconds())
		fmt.Printf("Blocks: %d\n", imported)
		if len(report.Errors) > 0 {
			fmt.Printf("\n⚠️  %d errors occurred (see report for details)\n", len(report.Errors))
		}
	}

	return report, nil
}

// parseSource parses a file into a structured document
func parseSource(source ImportSource) (*ParsedDocument, error) {
	content, err := readFileForParsing(source.FilePath)
	if err != nil {
		return nil, fmt.Errorf("failed to read file: %w", err)
	}

	// Use specialized parser for conversation logs
	if source.FileType == "conversation-log" {
		parser := parsers.NewConversationLogParser()
		return parser.Parse(source, content)
	}

	// Fallback to generic markdown parser
	doc := &ParsedDocument{
		Source:   source,
		Metadata: make(map[string]interface{}),
		Sections: []Section{},
	}

	// Parse markdown structure
	sections, metadata := parseMarkdownStructure(content)
	doc.Sections = sections
	doc.Metadata = metadata

	return doc, nil
}

// parseMarkdownStructure parses markdown content into hierarchical sections
func parseMarkdownStructure(content string) ([]Section, map[string]interface{}) {
	metadata := extractFrontmatter(content)
	lines := strings.Split(content, "\n")

	var rootSections []Section
	var sectionStack []*Section

	currentContent := strings.Builder{}

	for i, line := range lines {
		// Detect headers
		if strings.HasPrefix(line, "#") {
			// Save accumulated content to current section
			if len(sectionStack) > 0 {
				sectionStack[len(sectionStack)-1].Content = currentContent.String()
				currentContent.Reset()
			}

			level := 0
			for _, ch := range line {
				if ch == '#' {
					level++
				} else {
					break
				}
			}

			title := strings.TrimSpace(strings.TrimPrefix(line, strings.Repeat("#", level)))

			section := Section{
				Level:   level,
				Title:   title,
				Content: "",
				Line:    i + 1,
			}

			// Pop stack to correct level
			for len(sectionStack) >= level {
				sectionStack = sectionStack[:len(sectionStack)-1]
			}

			// Add to parent or root
			if len(sectionStack) == 0 {
				rootSections = append(rootSections, section)
				sectionStack = append(sectionStack, &rootSections[len(rootSections)-1])
			} else {
				parent := sectionStack[len(sectionStack)-1]
				parent.Children = append(parent.Children, section)
				lastChild := &parent.Children[len(parent.Children)-1]
				sectionStack = append(sectionStack, lastChild)
			}
		} else {
			// Accumulate content
			if line != "" || currentContent.Len() > 0 {
				currentContent.WriteString(line + "\n")
			}
		}
	}

	// Save final content
	if len(sectionStack) > 0 {
		sectionStack[len(sectionStack)-1].Content = currentContent.String()
	}

	return rootSections, metadata
}

// extractFrontmatter extracts YAML frontmatter from markdown
func extractFrontmatter(content string) map[string]interface{} {
	metadata := make(map[string]interface{})

	if !strings.HasPrefix(content, "---\n") {
		return metadata
	}

	parts := strings.SplitN(content[4:], "\n---\n", 2)
	if len(parts) < 1 {
		return metadata
	}

	// Simple key: value parsing
	for _, line := range strings.Split(parts[0], "\n") {
		if kv := strings.SplitN(line, ":", 2); len(kv) == 2 {
			key := strings.TrimSpace(kv[0])
			value := strings.TrimSpace(kv[1])
			metadata[key] = value
		}
	}

	return metadata
}

// importBlock saves a PreBlock to the database
func importBlock(ctx context.Context, kg core.KnowledgeGraph, decision ImportDecision) error {
	pb := decision.PreBlock

	// Get or create project
	project, err := kg.GetOrCreateProject(ctx, extractProjectName(pb.ProjectPath), pb.ProjectPath)
	if err != nil {
		return fmt.Errorf("failed to get/create project: %w", err)
	}

	// Create Block
	block := &types.Block{
		ID:            uuid.New(),
		ProjectID:     project.ID,
		Topic:         pb.Topic,
		StartedAt:     pb.StartedAt,
		CompletedAt:   pb.CompletedAt,
		ExchangeCount: len(pb.Exchanges),
		Metadata: map[string]interface{}{
			"source_file": pb.SourceFile,
			"source_type": pb.SourceType,
			"source_hash": pb.SourceHash,
			"tags":        pb.Tags,
		},
	}

	// Add visibility metadata
	if pb.Visibility != "" {
		block.Metadata["visibility"] = pb.Visibility
	}
	if pb.OrganizationID != nil {
		block.Metadata["organization_id"] = pb.OrganizationID.String()
	}
	if pb.SourceURL != "" {
		block.Metadata["source_url"] = pb.SourceURL
		block.Metadata["source_attribution"] = pb.SourceAttribution
	}

	// Save block (this will generate embedding)
	if err := kg.SaveBlock(ctx, block); err != nil {
		return fmt.Errorf("failed to save block: %w", err)
	}

	// Save exchanges
	for i, ex := range pb.Exchanges {
		exchange := &types.Exchange{
			ID:        uuid.New(),
			BlockID:   block.ID,
			Sequence:  i + 1,
			Question:  ex.Question,
			Answer:    ex.Answer,
			Timestamp: ex.Timestamp,
			ModelUsed: ex.ModelUsed,
		}

		if err := kg.SaveExchange(ctx, exchange); err != nil {
			return fmt.Errorf("failed to save exchange %d: %w", i+1, err)
		}
	}

	return nil
}

// extractProjectName extracts a project name from a path
func extractProjectName(path string) string {
	// Extract last directory component
	parts := strings.Split(strings.TrimSuffix(path, "/"), "/")
	if len(parts) > 0 {
		return parts[len(parts)-1]
	}
	return "unknown-project"
}

// progressBar generates a visual progress bar
func progressBar(percent float64, width int) string {
	filled := int(percent / 100.0 * float64(width))
	if filled > width {
		filled = width
	}
	empty := width - filled

	return strings.Repeat("█", filled) + strings.Repeat("░", empty)
}

// showPreview displays sample blocks from decisions
func showPreview(decisions []ImportDecision, count int) {
	fmt.Println("=== Sample Blocks ===")

	shown := 0
	for _, d := range decisions {
		if shown >= count {
			break
		}

		if d.Action == "insert" || d.Action == "update" {
			pb := d.PreBlock
			fmt.Printf("Topic: %s\n", pb.Topic)
			fmt.Printf("Source: %s\n", pb.SourceFile)
			fmt.Printf("Exchanges: %d\n", len(pb.Exchanges))
			fmt.Printf("Tags: %v\n", pb.Tags)
			fmt.Printf("Visibility: %s\n", pb.Visibility)
			if len(pb.Exchanges) > 0 {
				fmt.Printf("\nFirst Exchange:\n")
				fmt.Printf("Q: %s\n", truncate(pb.Exchanges[0].Question, 80))
				fmt.Printf("A: %s\n", truncate(pb.Exchanges[0].Answer, 80))
			}
			fmt.Println("\n---")
			shown++
		}
	}
}

// showClassificationSummary displays visibility classification summary
func showClassificationSummary(sources []ImportSource) {
	fmt.Println("\n=== Classification Summary ===")

	counts := make(map[string]int)
	for _, s := range sources {
		counts[s.Visibility]++
	}

	for vis, count := range counts {
		fmt.Printf("%s: %d files\n", vis, count)
	}
}

// truncate truncates a string to maxLen with ellipsis
func truncate(s string, maxLen int) string {
	if len(s) <= maxLen {
		return s
	}
	return s[:maxLen-3] + "..."
}

// readFileForParsing reads file content for parsing
func readFileForParsing(filePath string) (string, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return "", err
	}
	defer file.Close()

	var content strings.Builder
	scanner := bufio.NewScanner(file)

	// Increase buffer size for large files
	buf := make([]byte, 0, 64*1024)
	scanner.Buffer(buf, 1024*1024) // 1MB max line

	for scanner.Scan() {
		content.WriteString(scanner.Text())
		content.WriteString("\n")
	}

	if err := scanner.Err(); err != nil {
		return "", err
	}

	return content.String(), nil
}
