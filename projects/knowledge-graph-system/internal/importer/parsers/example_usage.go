package parsers

import (
	"fmt"
	"os"

	"github.com/TheGenXCoder/knowledge-graph/internal/importtypes"
)

// ExampleUsage demonstrates how to use the conversation log parser
func ExampleUsage() {
	parser := NewConversationLogParser()

	// Example file
	filePath := "/Users/BertSmith/personal/builder-platform/conversation-logs/2025-10/session-2025-10-15-1600.md"

	content, err := os.ReadFile(filePath)
	if err != nil {
		fmt.Printf("Error reading file: %v\n", err)
		return
	}

	source := importtypes.ImportSource{
		FilePath: filePath,
		FileType: "conversation-log",
	}

	doc, err := parser.Parse(source, string(content))
	if err != nil {
		fmt.Printf("Error parsing: %v\n", err)
		return
	}

	// Display parsed information
	fmt.Println("=== Conversation Log Parser - Example Output ===")
	fmt.Println()

	fmt.Println("📄 Metadata:")
	fmt.Printf("  Title: %s\n", doc.Metadata["title"])
	fmt.Printf("  Project: %s\n", doc.Metadata["project"])
	fmt.Printf("  Status: %s\n", doc.Metadata["status"])
	fmt.Printf("  Started: %v\n", doc.Metadata["started"])

	if goal, ok := doc.Metadata["session_goal"].(string); ok && len(goal) > 0 {
		fmt.Printf("\n🎯 Session Goal:\n  %s\n", goal[:min(len(goal), 100)]+"...")
	}

	if tags, ok := doc.Metadata["tags"].([]string); ok && len(tags) > 0 {
		fmt.Printf("\n🏷️  Tags: %v\n", tags)
	}

	fmt.Printf("\n📚 Structure:\n  Total Sections: %d\n", countSections(doc.Sections))

	// Show some sections
	fmt.Println("\n📑 Sample Sections:")
	displaySections(doc.Sections, 0, 5)

	// Extract milestones
	milestones := parser.ParseMilestones(string(content))
	if len(milestones) > 0 {
		fmt.Printf("\n⏱️  Milestones: %d found\n", len(milestones))
		for i, m := range milestones {
			if i >= 3 {
				break // Show first 3
			}
			fmt.Printf("  %s - %s\n", m.Timestamp, m.Title)
		}
	}

	// Extract decisions
	decisions := parser.ExtractKeyDecisions(string(content))
	if len(decisions) > 0 {
		fmt.Printf("\n🔑 Key Decisions: %d found\n", len(decisions))
		for i, d := range decisions {
			if i >= 2 {
				break // Show first 2
			}
			preview := d
			if len(preview) > 60 {
				preview = preview[:60] + "..."
			}
			fmt.Printf("  %d. %s\n", i+1, preview)
		}
	}

	// Extract files
	files := parser.ExtractFilesModified(string(content))
	if len(files["created"]) > 0 || len(files["modified"]) > 0 {
		fmt.Printf("\n📁 Files:\n")
		if len(files["created"]) > 0 {
			fmt.Printf("  Created: %d\n", len(files["created"]))
		}
		if len(files["modified"]) > 0 {
			fmt.Printf("  Modified: %d\n", len(files["modified"]))
		}
	}

	fmt.Println("\n✅ Parsing complete!")
}

func countSections(sections []importtypes.Section) int {
	count := len(sections)
	for _, s := range sections {
		count += countSections(s.Children)
	}
	return count
}

func displaySections(sections []importtypes.Section, depth, limit int) {
	displayed := 0
	for _, s := range sections {
		if displayed >= limit {
			return
		}
		indent := ""
		for i := 0; i < depth; i++ {
			indent += "  "
		}
		fmt.Printf("  %s- [H%d] %s\n", indent, s.Level, s.Title)
		displayed++
		if len(s.Children) > 0 {
			displaySections(s.Children, depth+1, limit-displayed)
		}
	}
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
