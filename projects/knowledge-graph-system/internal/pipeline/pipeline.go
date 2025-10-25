package pipeline

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"github.com/TheGenXCoder/knowledge-graph/internal/db"
	"github.com/TheGenXCoder/knowledge-graph/internal/importer"
	"github.com/google/uuid"
)

// Pipeline orchestrates the import process
type Pipeline struct {
	db             *db.PostgresDB
	organizationID *uuid.UUID
}

// NewPipeline creates a new import pipeline
func NewPipeline(database *db.PostgresDB, orgID *uuid.UUID) *Pipeline {
	return &Pipeline{
		db:             database,
		organizationID: orgID,
	}
}

// RunImport executes the complete import pipeline
func (p *Pipeline) RunImport(ctx context.Context, opts importer.ImportOptions) (*importer.ImportReport, error) {
	report := &importer.ImportReport{
		StartedAt: time.Now(),
	}

	// 1. Discover files
	sources, err := importer.Discover(opts)
	if err != nil {
		return report, fmt.Errorf("discovery failed: %w", err)
	}
	report.SourcesFound = len(sources)

	// 2. Classify sources (visibility, attribution)
	defaultVisibility := "org-private"
	for i := range sources {
		if err := importer.ClassifySource(&sources[i], defaultVisibility, p.organizationID); err != nil {
			report.Errors = append(report.Errors, importer.ImportError{
				Source:  sources[i],
				Stage:   "classification",
				Message: "Failed to classify source",
				Error:   err,
			})
			continue
		}
	}

	// 3. Parse documents (TODO: implement parsers)
	// For now, just count sources as parsed
	report.SourcesParsed = len(sources)

	// 4. Dry run: preview mode
	if opts.DryRun {
		// Generate preview report
		report.CompletedAt = time.Now()
		return report, nil
	}

	// 5. Import blocks to database (TODO: implement)
	report.CompletedAt = time.Now()
	return report, nil
}

// GetImportStats returns import statistics
func (p *Pipeline) GetImportStats(ctx context.Context) (*ImportStats, error) {
	stats := &ImportStats{
		ByType:       make(map[string]int),
		ByVisibility: make(map[string]int),
	}

	// Get total imports
	err := p.db.QueryRow(ctx, `SELECT COUNT(*) FROM import_history WHERE status = 'completed'`).Scan(&stats.TotalImports)
	if err != nil {
		return stats, fmt.Errorf("failed to get total imports: %w", err)
	}

	// Get total blocks created from imports
	err = p.db.QueryRow(ctx, `SELECT COALESCE(SUM(block_count), 0) FROM import_history WHERE status = 'completed'`).Scan(&stats.TotalBlocks)
	if err != nil {
		return stats, fmt.Errorf("failed to get total blocks: %w", err)
	}

	// Get last import time
	var lastImport sql.NullTime
	err = p.db.QueryRow(ctx, `SELECT MAX(imported_at) FROM import_history WHERE status = 'completed'`).Scan(&lastImport)
	if err == nil && lastImport.Valid {
		stats.LastImport = lastImport.Time
	}

	// Get counts by type
	rows, err := p.db.Query(ctx, `
		SELECT import_type, COALESCE(SUM(block_count), 0)
		FROM import_history
		WHERE status = 'completed'
		GROUP BY import_type
	`)
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var importType string
			var count int
			if err := rows.Scan(&importType, &count); err == nil {
				stats.ByType[importType] = count
			}
		}
	}

	// Get counts by visibility
	rows, err = p.db.Query(ctx, `
		SELECT visibility, COALESCE(SUM(block_count), 0)
		FROM import_history
		WHERE status = 'completed'
		GROUP BY visibility
	`)
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var visibility string
			var count int
			if err := rows.Scan(&visibility, &count); err == nil {
				stats.ByVisibility[visibility] = count
			}
		}
	}

	return stats, nil
}

// GetImportHistory returns recent import history
func (p *Pipeline) GetImportHistory(ctx context.Context, limit int) ([]ImportHistoryEntry, error) {
	if limit <= 0 {
		limit = 10
	}

	rows, err := p.db.Query(ctx, `
		SELECT id, source_file, file_hash, imported_at, block_count, import_type,
		       status, visibility, source_classification, organization_id
		FROM import_history
		ORDER BY imported_at DESC
		LIMIT $1
	`, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to query import history: %w", err)
	}
	defer rows.Close()

	var history []ImportHistoryEntry
	for rows.Next() {
		var entry ImportHistoryEntry
		var sourceClass sql.NullString

		err := rows.Scan(
			&entry.ID,
			&entry.SourceFile,
			&entry.FileHash,
			&entry.ImportedAt,
			&entry.BlockCount,
			&entry.ImportType,
			&entry.Status,
			&entry.Visibility,
			&sourceClass,
			&entry.OrganizationID,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan import history: %w", err)
		}

		if sourceClass.Valid {
			entry.SourceClassification = sourceClass.String
		}

		history = append(history, entry)
	}

	return history, nil
}

// ImportStats represents import statistics
type ImportStats struct {
	TotalImports  int
	TotalBlocks   int
	LastImport    time.Time
	ByType        map[string]int
	ByVisibility  map[string]int
}

// ImportHistoryEntry represents a single import record
type ImportHistoryEntry struct {
	ID                  uuid.UUID
	SourceFile          string
	FileHash            string
	ImportedAt          time.Time
	BlockCount          int
	ImportType          string
	Status              string
	Visibility          string
	SourceClassification string
	OrganizationID      *uuid.UUID
}
