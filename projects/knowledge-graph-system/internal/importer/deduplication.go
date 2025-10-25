package importer

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/TheGenXCoder/knowledge-graph/internal/core"
	"github.com/TheGenXCoder/knowledge-graph/internal/db"
	"github.com/google/uuid"
)

// DeduplicateBlocks checks if blocks already exist using hash-based detection
// Returns import decisions for each PreBlock indicating whether to insert, update, or skip
func DeduplicateBlocks(ctx context.Context, kg core.KnowledgeGraph, preBlocks []PreBlock) ([]ImportDecision, error) {
	decisions := make([]ImportDecision, 0, len(preBlocks))

	// Get access to the underlying database for import history queries
	// We need to cast to PostgresDB to access the database connection
	postgresKG, ok := kg.(interface {
		QueryImportHistory(ctx context.Context, sourceFile, fileHash string) (*db.ImportHistoryRecord, error)
		QueryBlocksBySource(ctx context.Context, sourceFile string) ([]db.BlockSourceRecord, error)
	})
	if !ok {
		return nil, fmt.Errorf("knowledge graph does not support import history queries")
	}

	for i := range preBlocks {
		preBlock := &preBlocks[i]
		decision, err := deduplicateBlock(ctx, postgresKG, preBlock)
		if err != nil {
			return nil, fmt.Errorf("failed to deduplicate block from %s: %w", preBlock.SourceFile, err)
		}
		decisions = append(decisions, decision)
	}

	return decisions, nil
}

// deduplicateBlock determines the import action for a single PreBlock
func deduplicateBlock(ctx context.Context, kg interface {
	QueryImportHistory(ctx context.Context, sourceFile, fileHash string) (*db.ImportHistoryRecord, error)
	QueryBlocksBySource(ctx context.Context, sourceFile string) ([]db.BlockSourceRecord, error)
}, preBlock *PreBlock) (ImportDecision, error) {

	// Step 1: Check import_history for (source_file, file_hash)
	historyRecord, err := kg.QueryImportHistory(ctx, preBlock.SourceFile, preBlock.SourceHash)
	if err != nil && err != sql.ErrNoRows {
		return ImportDecision{}, fmt.Errorf("failed to query import history: %w", err)
	}

	// Case 1: File never imported before (NOT found)
	if err == sql.ErrNoRows || historyRecord == nil {
		return ImportDecision{
			Action:   "insert",
			PreBlock: preBlock,
			Reason:   "new file - never imported before",
		}, nil
	}

	// Case 2: File found with SAME hash (unchanged)
	if historyRecord.FileHash == preBlock.SourceHash {
		// Apply special rules for conversation logs vs specs/docs
		if isImmutableSourceType(preBlock.SourceType) {
			return ImportDecision{
				Action:   "skip",
				PreBlock: preBlock,
				Reason:   fmt.Sprintf("unchanged %s file (immutable) - hash match", preBlock.SourceType),
			}, nil
		}
		// Even for updateable types, if hash matches, nothing changed
		return ImportDecision{
			Action:   "skip",
			PreBlock: preBlock,
			Reason:   fmt.Sprintf("unchanged %s file - hash match", preBlock.SourceType),
		}, nil
	}

	// Case 3: File found with DIFFERENT hash (file changed)
	// Check special rules before deciding to update
	if isImmutableSourceType(preBlock.SourceType) {
		// Conversation logs are IMMUTABLE - never update, always skip or insert new
		return ImportDecision{
			Action:   "skip",
			PreBlock: preBlock,
			Reason:   fmt.Sprintf("%s files are immutable - cannot update existing content", preBlock.SourceType),
		}, nil
	}

	// For updateable types (specs, docs, working files), proceed with update
	// Find the existing blocks to update
	existingBlocks, err := kg.QueryBlocksBySource(ctx, preBlock.SourceFile)
	if err != nil {
		return ImportDecision{}, fmt.Errorf("failed to query existing blocks: %w", err)
	}

	var existingID *uuid.UUID
	if len(existingBlocks) > 0 {
		existingID = &existingBlocks[0].BlockID
	}

	return ImportDecision{
		Action:      "update",
		PreBlock:    preBlock,
		ExistingID:  existingID,
		Reason:      fmt.Sprintf("%s file changed - hash mismatch (old: %s, new: %s)", preBlock.SourceType, historyRecord.FileHash[:8], preBlock.SourceHash[:8]),
		SourceBlock: nil, // Will be populated during import
	}, nil
}

// isImmutableSourceType returns true for source types that should never be updated
func isImmutableSourceType(sourceType string) bool {
	switch sourceType {
	case "conversation-log":
		return true
	case "spec", "doc", "working-file":
		return false
	default:
		// Default to immutable for safety
		return true
	}
}

// Note: ImportHistoryRecord and BlockSourceRecord are defined in internal/db package

// FilterByAction returns only the decisions matching the given action
func FilterByAction(decisions []ImportDecision, action string) []ImportDecision {
	filtered := make([]ImportDecision, 0)
	for _, d := range decisions {
		if d.Action == action {
			filtered = append(filtered, d)
		}
	}
	return filtered
}

// SummarizeDecisions returns counts for each action type
func SummarizeDecisions(decisions []ImportDecision) map[string]int {
	summary := map[string]int{
		"insert": 0,
		"update": 0,
		"skip":   0,
	}
	for _, d := range decisions {
		summary[d.Action]++
	}
	return summary
}
