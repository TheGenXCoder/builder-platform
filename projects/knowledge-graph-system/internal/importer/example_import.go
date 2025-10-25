package importer

import (
	"context"
	"fmt"
	"time"

	"github.com/TheGenXCoder/knowledge-graph/internal/db"
	"github.com/google/uuid"
)

// ExampleImportWorkflow demonstrates the complete import workflow
// This is a reference implementation showing how all the pieces fit together
func ExampleImportWorkflow(ctx context.Context, kg *db.PostgresDB, sourceFile string, preBlocks []PreBlock) error {
	fmt.Println("=== Knowledge Graph Import Workflow ===")

	// Step 1: Calculate file hash
	fileHash, err := calculateFileHash(sourceFile)
	if err != nil {
		return fmt.Errorf("failed to calculate file hash: %w", err)
	}
	fmt.Printf("1. File Hash: %s\n", fileHash[:8])

	// Step 2: Deduplicate blocks
	fmt.Println("\n2. Deduplication Analysis:")
	decisions, err := DeduplicateBlocks(ctx, kg, preBlocks)
	if err != nil {
		return fmt.Errorf("deduplication failed: %w", err)
	}

	summary := SummarizeDecisions(decisions)
	fmt.Printf("   - Insert: %d blocks\n", summary["insert"])
	fmt.Printf("   - Update: %d blocks\n", summary["update"])
	fmt.Printf("   - Skip:   %d blocks\n", summary["skip"])

	// Step 3: Create import batch
	fmt.Println("\n3. Creating Import Batch:")
	var visibility, sourceClass string
	var orgID *uuid.UUID

	if len(preBlocks) > 0 {
		visibility = preBlocks[0].Visibility
		sourceClass = "private-repo" // Default
		orgID = preBlocks[0].OrganizationID
	} else {
		visibility = "org-private"
	}

	batchID, err := kg.CreateImportBatch(ctx, sourceFile, fileHash,
		preBlocks[0].SourceType, visibility, sourceClass, orgID)
	if err != nil {
		return fmt.Errorf("failed to create import batch: %w", err)
	}
	fmt.Printf("   Batch ID: %s\n", batchID)

	// Step 4: Import blocks
	fmt.Println("\n4. Importing Blocks:")
	insertDecisions := FilterByAction(decisions, "insert")
	for i, decision := range insertDecisions {
		fmt.Printf("   [%d/%d] Importing: %s\n", i+1, len(insertDecisions), decision.PreBlock.Topic)

		block, err := kg.ImportBlock(ctx, decision.PreBlock, batchID)
		if err != nil {
			fmt.Printf("   ERROR: %v\n", err)
			continue
		}

		fmt.Printf("   ✓ Created block %s with %d exchanges\n", block.ID, len(block.Exchanges))
	}

	// Step 5: Handle updates (if any)
	updateDecisions := FilterByAction(decisions, "update")
	if len(updateDecisions) > 0 {
		fmt.Printf("\n5. Updates: %d blocks need updating\n", len(updateDecisions))
		for _, decision := range updateDecisions {
			fmt.Printf("   - %s: %s\n", decision.PreBlock.SourceFile, decision.Reason)
		}
	}

	// Step 6: Summary
	skippedDecisions := FilterByAction(decisions, "skip")
	if len(skippedDecisions) > 0 {
		fmt.Printf("\n6. Skipped: %d blocks (unchanged)\n", len(skippedDecisions))
	}

	fmt.Println("\n=== Import Complete ===")
	return nil
}

// CreateSamplePreBlock creates a sample PreBlock for testing
func CreateSamplePreBlock(topic, sourceFile, sourceType string) PreBlock {
	now := time.Now()
	completed := now.Add(5 * time.Minute)

	return PreBlock{
		Topic: topic,
		Exchanges: []PreExchange{
			{
				Question:  "What is the purpose of this system?",
				Answer:    "This is a knowledge graph system for storing and retrieving conversation blocks.",
				Timestamp: now,
				ModelUsed: "claude-sonnet-4",
			},
			{
				Question:  "How does deduplication work?",
				Answer:    "Deduplication uses hash-based detection to identify unchanged files.",
				Timestamp: now.Add(1 * time.Minute),
				ModelUsed: "claude-sonnet-4",
			},
		},
		Metadata: map[string]interface{}{
			"session_id": "example-001",
			"context":    "development",
		},
		Tags:           []string{"knowledge-graph", "deduplication", "import"},
		ProjectPath:    "/Users/BertSmith/personal/builder-platform",
		SourceFile:     sourceFile,
		SourceType:     sourceType,
		SourceHash:     "sample-hash-abc123",
		StartedAt:      now,
		CompletedAt:    &completed,
		Visibility:     "org-private",
		OrganizationID: nil, // Will use default
	}
}

// PrintImportDecision prints a human-readable import decision
func PrintImportDecision(decision ImportDecision) {
	fmt.Printf("Decision: %s\n", decision.Action)
	fmt.Printf("  Source: %s\n", decision.PreBlock.SourceFile)
	fmt.Printf("  Type:   %s\n", decision.PreBlock.SourceType)
	fmt.Printf("  Topic:  %s\n", decision.PreBlock.Topic)
	fmt.Printf("  Reason: %s\n", decision.Reason)
	if decision.ExistingID != nil {
		fmt.Printf("  Existing Block: %s\n", *decision.ExistingID)
	}
	fmt.Println()
}
