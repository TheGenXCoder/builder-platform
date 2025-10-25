package db

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"time"

	"github.com/TheGenXCoder/knowledge-graph/internal/core"
	"github.com/TheGenXCoder/knowledge-graph/pkg/types"
	"github.com/google/uuid"
	_ "github.com/lib/pq"
	"github.com/pgvector/pgvector-go"
)

type PostgresDB struct {
	db       *sql.DB
	embedder core.Embedder
}

// NewPostgresDB creates a new PostgreSQL knowledge graph
func NewPostgresDB(connStr string, embedder core.Embedder) (*PostgresDB, error) {
	db, err := sql.Open("postgres", connStr)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	// Test connection
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	// Set connection pool settings
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(5 * time.Minute)

	return &PostgresDB{
		db:       db,
		embedder: embedder,
	}, nil
}

// Search performs hybrid semantic + keyword search
func (p *PostgresDB) Search(ctx context.Context, query string, opts types.SearchOptions) (*types.SearchResults, error) {
	start := time.Now()

	// Generate embedding for query
	embedding, err := p.embedder.Embed(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("failed to generate embedding: %w", err)
	}

	// Default limit
	if opts.Limit == 0 {
		opts.Limit = 10
	}

	// Build query with optional project filter
	querySQL := `
		WITH vector_search AS (
			SELECT
				b.id,
				b.project_id,
				b.topic,
				b.started_at,
				b.completed_at,
				b.exchange_count,
				b.metadata,
				b.created_at,
				b.updated_at,
				b.visibility,
				b.organization_id,
				b.source_url,
				b.source_attribution,
				b.source_file,
				b.source_type,
				1 - (b.embedding <=> $1) AS similarity
			FROM blocks b
			WHERE ($2::uuid IS NULL OR b.project_id = $2)
			  AND b.completed_at IS NOT NULL
			ORDER BY b.embedding <=> $1
			LIMIT $3
		),
		keyword_search AS (
			SELECT
				b.id,
				ts_rank(to_tsvector('english', b.topic), plainto_tsquery($4)) AS rank
			FROM blocks b
			WHERE ($2::uuid IS NULL OR b.project_id = $2)
			  AND to_tsvector('english', b.topic) @@ plainto_tsquery($4)
			  AND b.completed_at IS NOT NULL
			ORDER BY rank DESC
			LIMIT $3
		)
		SELECT DISTINCT
			v.id,
			v.project_id,
			v.topic,
			v.started_at,
			v.completed_at,
			v.exchange_count,
			v.metadata,
			v.created_at,
			v.updated_at,
			v.visibility,
			v.organization_id,
			v.source_url,
			v.source_attribution,
			v.source_file,
			v.source_type,
			COALESCE(v.similarity, 0) + COALESCE(k.rank, 0) AS combined_score
		FROM vector_search v
		LEFT JOIN keyword_search k ON v.id = k.id
		ORDER BY combined_score DESC
		LIMIT $3
	`

	var projectID *uuid.UUID
	if opts.ProjectID != nil {
		projectID = opts.ProjectID
	}

	rows, err := p.db.QueryContext(ctx, querySQL,
		pgvector.NewVector(toFloat32(embedding)),
		projectID,
		opts.Limit,
		query,
	)
	if err != nil {
		return nil, fmt.Errorf("search query failed: %w", err)
	}
	defer rows.Close()

	var results []types.SearchResult
	for rows.Next() {
		var block types.Block
		var metadataJSON []byte
		var relevance float64
		var visibility, sourceURL, sourceAttribution, sourceFile, sourceType sql.NullString
		var orgID *uuid.UUID

		err := rows.Scan(
			&block.ID,
			&block.ProjectID,
			&block.Topic,
			&block.StartedAt,
			&block.CompletedAt,
			&block.ExchangeCount,
			&metadataJSON,
			&block.CreatedAt,
			&block.UpdatedAt,
			&visibility,
			&orgID,
			&sourceURL,
			&sourceAttribution,
			&sourceFile,
			&sourceType,
			&relevance,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan block: %w", err)
		}

		// Set nullable fields
		if visibility.Valid {
			block.Visibility = visibility.String
		}
		if orgID != nil {
			block.OrganizationID = orgID
		}
		if sourceURL.Valid {
			block.SourceURL = sourceURL.String
		}
		if sourceAttribution.Valid {
			block.SourceAttribution = sourceAttribution.String
		}
		if sourceFile.Valid {
			block.SourceFile = sourceFile.String
		}
		if sourceType.Valid {
			block.SourceType = sourceType.String
		}

		// Parse metadata
		if len(metadataJSON) > 0 {
			if err := json.Unmarshal(metadataJSON, &block.Metadata); err != nil {
				block.Metadata = make(map[string]interface{})
			}
		}

		// Load exchanges for this block
		exchanges, err := p.getBlockExchanges(ctx, block.ID)
		if err != nil {
			return nil, fmt.Errorf("failed to load exchanges: %w", err)
		}
		block.Exchanges = exchanges

		// Load tags
		tags, err := p.getBlockTags(ctx, block.ID)
		if err != nil {
			return nil, fmt.Errorf("failed to load tags: %w", err)
		}
		block.Tags = tags

		result := types.SearchResult{
			Block:     &block,
			Relevance: relevance,
		}

		// Load N+1 related blocks if requested
		if opts.IncludeNPlus {
			related, err := p.getRelatedBlocks(ctx, block.ID)
			if err != nil {
				return nil, fmt.Errorf("failed to load related blocks: %w", err)
			}
			result.Related = related
		}

		results = append(results, result)
	}

	searchTime := time.Since(start)

	return &types.SearchResults{
		Results:    results,
		TotalFound: len(results),
		SearchTime: searchTime,
	}, nil
}

// SaveBlock saves a conversation block
func (p *PostgresDB) SaveBlock(ctx context.Context, block *types.Block) error {
	// Generate embedding for topic
	topicText := block.Topic
	if len(block.Exchanges) > 0 {
		// Include first exchange for better embedding
		topicText += " " + block.Exchanges[0].Question
	}

	embedding, err := p.embedder.Embed(ctx, topicText)
	if err != nil {
		return fmt.Errorf("failed to generate embedding: %w", err)
	}

	// Serialize metadata
	metadataJSON, err := json.Marshal(block.Metadata)
	if err != nil {
		return fmt.Errorf("failed to marshal metadata: %w", err)
	}

	// Insert block
	block.ID = uuid.New()
	block.CreatedAt = time.Now()
	block.UpdatedAt = time.Now()

	_, err = p.db.ExecContext(ctx, `
		INSERT INTO blocks (id, project_id, topic, started_at, completed_at, exchange_count, embedding, metadata, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
	`, block.ID, block.ProjectID, block.Topic, block.StartedAt, block.CompletedAt,
		block.ExchangeCount, pgvector.NewVector(toFloat32(embedding)), metadataJSON, block.CreatedAt, block.UpdatedAt)

	if err != nil {
		return fmt.Errorf("failed to insert block: %w", err)
	}

	// Save exchanges
	for i, exchange := range block.Exchanges {
		exchange.BlockID = block.ID
		exchange.Sequence = i
		if err := p.SaveExchange(ctx, &exchange); err != nil {
			return fmt.Errorf("failed to save exchange %d: %w", i, err)
		}
	}

	// Extract and save tags
	if len(block.Exchanges) > 0 {
		// Combine all exchanges for tag extraction
		var content string
		for _, ex := range block.Exchanges {
			content += ex.Question + " " + ex.Answer + " "
		}

		tags, err := p.ExtractTags(ctx, content)
		if err != nil {
			// Don't fail the whole operation if tag extraction fails
			fmt.Printf("Warning: failed to extract tags: %v\n", err)
		} else {
			if err := p.saveBlockTags(ctx, block.ID, tags); err != nil {
				return fmt.Errorf("failed to save tags: %w", err)
			}
		}
	}

	return nil
}

// GetBlock retrieves a block by ID
func (p *PostgresDB) GetBlock(ctx context.Context, id uuid.UUID) (*types.Block, error) {
	var block types.Block
	var metadataJSON []byte
	var visibility, sourceURL, sourceAttribution, sourceFile, sourceType sql.NullString
	var orgID *uuid.UUID

	err := p.db.QueryRowContext(ctx, `
		SELECT id, project_id, topic, started_at, completed_at, exchange_count, metadata, created_at, updated_at,
		       visibility, organization_id, source_url, source_attribution, source_file, source_type
		FROM blocks
		WHERE id = $1
	`, id).Scan(
		&block.ID,
		&block.ProjectID,
		&block.Topic,
		&block.StartedAt,
		&block.CompletedAt,
		&block.ExchangeCount,
		&metadataJSON,
		&block.CreatedAt,
		&block.UpdatedAt,
		&visibility,
		&orgID,
		&sourceURL,
		&sourceAttribution,
		&sourceFile,
		&sourceType,
	)

	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("block not found: %s", id)
	}
	if err != nil {
		return nil, fmt.Errorf("failed to query block: %w", err)
	}

	// Set nullable fields
	if visibility.Valid {
		block.Visibility = visibility.String
	}
	if orgID != nil {
		block.OrganizationID = orgID
	}
	if sourceURL.Valid {
		block.SourceURL = sourceURL.String
	}
	if sourceAttribution.Valid {
		block.SourceAttribution = sourceAttribution.String
	}
	if sourceFile.Valid {
		block.SourceFile = sourceFile.String
	}
	if sourceType.Valid {
		block.SourceType = sourceType.String
	}

	// Parse metadata
	if len(metadataJSON) > 0 {
		if err := json.Unmarshal(metadataJSON, &block.Metadata); err != nil {
			block.Metadata = make(map[string]interface{})
		}
	}

	// Load exchanges
	exchanges, err := p.getBlockExchanges(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("failed to load exchanges: %w", err)
	}
	block.Exchanges = exchanges

	// Load tags
	tags, err := p.getBlockTags(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("failed to load tags: %w", err)
	}
	block.Tags = tags

	return &block, nil
}

// GetContextNPlusOne gets N+1 context bundle
func (p *PostgresDB) GetContextNPlusOne(ctx context.Context, blockID uuid.UUID) (*types.ContextBundle, error) {
	// Get primary block
	block, err := p.GetBlock(ctx, blockID)
	if err != nil {
		return nil, err
	}

	// Get related blocks (one hop away)
	related, err := p.getRelatedBlocks(ctx, blockID)
	if err != nil {
		return nil, fmt.Errorf("failed to get related blocks: %w", err)
	}

	return &types.ContextBundle{
		PrimaryBlock:  block,
		RelatedBlocks: related,
		Tags:          block.Tags,
	}, nil
}

// SearchProject searches within a specific project
func (p *PostgresDB) SearchProject(ctx context.Context, projectID uuid.UUID, query string, opts types.SearchOptions) (*types.SearchResults, error) {
	opts.ProjectID = &projectID
	return p.Search(ctx, query, opts)
}

// GetOrCreateProject gets or creates a project
func (p *PostgresDB) GetOrCreateProject(ctx context.Context, name string, directory string) (*types.Project, error) {
	// Try to get existing
	var project types.Project
	err := p.db.QueryRowContext(ctx, `
		SELECT id, name, directory_path, created_at, updated_at
		FROM projects
		WHERE directory_path = $1
	`, directory).Scan(&project.ID, &project.Name, &project.DirectoryPath, &project.CreatedAt, &project.UpdatedAt)

	if err == nil {
		return &project, nil
	}

	if err != sql.ErrNoRows {
		return nil, fmt.Errorf("failed to query project: %w", err)
	}

	// Create new
	project = types.Project{
		ID:            uuid.New(),
		Name:          name,
		DirectoryPath: directory,
		CreatedAt:     time.Now(),
		UpdatedAt:     time.Now(),
	}

	_, err = p.db.ExecContext(ctx, `
		INSERT INTO projects (id, name, directory_path, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5)
	`, project.ID, project.Name, project.DirectoryPath, project.CreatedAt, project.UpdatedAt)

	if err != nil {
		return nil, fmt.Errorf("failed to create project: %w", err)
	}

	return &project, nil
}

// SaveExchange saves an exchange
func (p *PostgresDB) SaveExchange(ctx context.Context, exchange *types.Exchange) error {
	// Generate embedding
	text := exchange.Question + " " + exchange.Answer
	embedding, err := p.embedder.Embed(ctx, text)
	if err != nil {
		return fmt.Errorf("failed to generate embedding: %w", err)
	}

	exchange.ID = uuid.New()
	if exchange.Timestamp.IsZero() {
		exchange.Timestamp = time.Now()
	}

	_, err = p.db.ExecContext(ctx, `
		INSERT INTO exchanges (id, block_id, sequence, question, answer, timestamp, model_used, embedding)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
	`, exchange.ID, exchange.BlockID, exchange.Sequence, exchange.Question, exchange.Answer,
		exchange.Timestamp, exchange.ModelUsed, pgvector.NewVector(toFloat32(embedding)))

	if err != nil {
		return fmt.Errorf("failed to insert exchange: %w", err)
	}

	return nil
}

// ExtractTags uses Ollama to extract tags (Week 1: simple keyword extraction)
func (p *PostgresDB) ExtractTags(ctx context.Context, content string) ([]string, error) {
	// Week 1: Simple keyword extraction (no LLM call to keep it fast)
	// Week 2: Use Ollama for better tag extraction

	// For now, return empty - we'll implement proper tag extraction next
	return []string{}, nil
}

// Close closes the database connection
func (p *PostgresDB) Close() error {
	return p.db.Close()
}

// Query executes a query that returns rows (helper for pipeline)
func (p *PostgresDB) Query(ctx context.Context, query string, args ...interface{}) (*sql.Rows, error) {
	return p.db.QueryContext(ctx, query, args...)
}

// QueryRow executes a query that returns a single row (helper for pipeline)
func (p *PostgresDB) QueryRow(ctx context.Context, query string, args ...interface{}) *sql.Row {
	return p.db.QueryRowContext(ctx, query, args...)
}

// Helper methods

func (p *PostgresDB) getBlockExchanges(ctx context.Context, blockID uuid.UUID) ([]types.Exchange, error) {
	rows, err := p.db.QueryContext(ctx, `
		SELECT id, block_id, sequence, question, answer, timestamp, model_used
		FROM exchanges
		WHERE block_id = $1
		ORDER BY sequence ASC
	`, blockID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var exchanges []types.Exchange
	for rows.Next() {
		var ex types.Exchange
		var modelUsed sql.NullString

		err := rows.Scan(&ex.ID, &ex.BlockID, &ex.Sequence, &ex.Question, &ex.Answer, &ex.Timestamp, &modelUsed)
		if err != nil {
			return nil, err
		}

		if modelUsed.Valid {
			ex.ModelUsed = modelUsed.String
		}

		exchanges = append(exchanges, ex)
	}

	return exchanges, nil
}

func (p *PostgresDB) getBlockTags(ctx context.Context, blockID uuid.UUID) ([]types.Tag, error) {
	rows, err := p.db.QueryContext(ctx, `
		SELECT t.id, t.name, t.created_at
		FROM tags t
		JOIN block_tags bt ON t.id = bt.tag_id
		WHERE bt.block_id = $1
	`, blockID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var tags []types.Tag
	for rows.Next() {
		var tag types.Tag
		if err := rows.Scan(&tag.ID, &tag.Name, &tag.CreatedAt); err != nil {
			return nil, err
		}
		tags = append(tags, tag)
	}

	return tags, nil
}

func (p *PostgresDB) getRelatedBlocks(ctx context.Context, blockID uuid.UUID) ([]*types.Block, error) {
	// Get blocks related via tags (N+1: one hop away)
	rows, err := p.db.QueryContext(ctx, `
		SELECT DISTINCT b.id, b.project_id, b.topic, b.started_at, b.completed_at,
		       b.exchange_count, b.metadata, b.created_at, b.updated_at
		FROM blocks b
		JOIN block_tags bt ON b.id = bt.block_id
		WHERE bt.tag_id IN (
			SELECT tag_id FROM block_tags WHERE block_id = $1
		)
		AND b.id != $1
		AND b.completed_at IS NOT NULL
		LIMIT 5
	`, blockID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var blocks []*types.Block
	for rows.Next() {
		var block types.Block
		var metadataJSON []byte

		err := rows.Scan(
			&block.ID,
			&block.ProjectID,
			&block.Topic,
			&block.StartedAt,
			&block.CompletedAt,
			&block.ExchangeCount,
			&metadataJSON,
			&block.CreatedAt,
			&block.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}

		if len(metadataJSON) > 0 {
			json.Unmarshal(metadataJSON, &block.Metadata)
		}

		blocks = append(blocks, &block)
	}

	return blocks, nil
}

func (p *PostgresDB) saveBlockTags(ctx context.Context, blockID uuid.UUID, tagNames []string) error {
	for _, tagName := range tagNames {
		// Get or create tag
		var tagID uuid.UUID
		err := p.db.QueryRowContext(ctx, `
			INSERT INTO tags (id, name, created_at)
			VALUES ($1, $2, $3)
			ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name
			RETURNING id
		`, uuid.New(), tagName, time.Now()).Scan(&tagID)

		if err != nil {
			// Try to get existing
			err = p.db.QueryRowContext(ctx, `SELECT id FROM tags WHERE name = $1`, tagName).Scan(&tagID)
			if err != nil {
				return fmt.Errorf("failed to get/create tag %s: %w", tagName, err)
			}
		}

		// Link tag to block
		_, err = p.db.ExecContext(ctx, `
			INSERT INTO block_tags (block_id, tag_id, confidence, created_at)
			VALUES ($1, $2, $3, $4)
			ON CONFLICT (block_id, tag_id) DO NOTHING
		`, blockID, tagID, 1.0, time.Now())

		if err != nil {
			return fmt.Errorf("failed to link tag %s to block: %w", tagName, err)
		}
	}

	return nil
}

// ImportBlock imports a PreBlock into the database with full transaction support
// This is used by the importer to insert blocks with source tracking and import history
func (p *PostgresDB) ImportBlock(ctx context.Context, preBlock interface{}, batchID uuid.UUID) (*types.Block, error) {
	// Type assertion to get the actual PreBlock
	pb, ok := preBlock.(interface {
		GetTopic() string
		GetExchanges() []interface{}
		GetMetadata() map[string]interface{}
		GetTags() []string
		GetProjectPath() string
		GetSourceFile() string
		GetSourceType() string
		GetSourceHash() string
		GetStartedAt() time.Time
		GetCompletedAt() *time.Time
		GetVisibility() string
		GetOrganizationID() *uuid.UUID
		GetSourceURL() string
		GetSourceAttribution() string
	})
	if !ok {
		return nil, fmt.Errorf("invalid PreBlock type")
	}

	// Start transaction
	tx, err := p.db.BeginTx(ctx, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback()

	// Step 1: Get or create organization
	orgID := pb.GetOrganizationID()
	if orgID == nil {
		// Use default organization from environment or "personal"
		defaultOrg, err := p.getOrCreateOrganizationTx(ctx, tx, "personal", "individual")
		if err != nil {
			return nil, fmt.Errorf("failed to get default organization: %w", err)
		}
		orgID = &defaultOrg.ID
	}

	// Step 2: Get or create project
	project, err := p.getOrCreateProjectTx(ctx, tx, pb.GetProjectPath(), orgID)
	if err != nil {
		return nil, fmt.Errorf("failed to get/create project: %w", err)
	}

	// Step 3: Generate embedding for block
	topicText := pb.GetTopic()
	exchanges := pb.GetExchanges()
	if len(exchanges) > 0 {
		// Include exchanges for better embedding
		for _, ex := range exchanges {
			if exTyped, ok := ex.(interface{ GetQuestion() string }); ok {
				topicText += " " + exTyped.GetQuestion()
			}
		}
	}

	embedding, err := p.embedder.Embed(ctx, topicText)
	if err != nil {
		return nil, fmt.Errorf("failed to generate embedding: %w", err)
	}

	// Step 4: Insert block
	block := &types.Block{
		ID:            uuid.New(),
		ProjectID:     project.ID,
		Topic:         pb.GetTopic(),
		StartedAt:     pb.GetStartedAt(),
		CompletedAt:   pb.GetCompletedAt(),
		ExchangeCount: len(exchanges),
		Metadata:      pb.GetMetadata(),
		CreatedAt:     time.Now(),
		UpdatedAt:     time.Now(),
	}

	metadataJSON, err := json.Marshal(block.Metadata)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal metadata: %w", err)
	}

	_, err = tx.ExecContext(ctx, `
		INSERT INTO blocks (
			id, project_id, topic, started_at, completed_at, exchange_count,
			embedding, metadata, created_at, updated_at,
			visibility, organization_id, source_url, source_attribution,
			source_file, source_type, source_hash, import_batch_id
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18)
	`, block.ID, block.ProjectID, block.Topic, block.StartedAt, block.CompletedAt,
		block.ExchangeCount, pgvector.NewVector(toFloat32(embedding)), metadataJSON,
		block.CreatedAt, block.UpdatedAt,
		pb.GetVisibility(), orgID, pb.GetSourceURL(), pb.GetSourceAttribution(),
		pb.GetSourceFile(), pb.GetSourceType(), pb.GetSourceHash(), batchID)

	if err != nil {
		return nil, fmt.Errorf("failed to insert block: %w", err)
	}

	// Step 5: Insert exchanges
	for i, ex := range exchanges {
		exTyped, ok := ex.(interface {
			GetQuestion() string
			GetAnswer() string
			GetTimestamp() time.Time
			GetModelUsed() string
		})
		if !ok {
			return nil, fmt.Errorf("invalid exchange type at index %d", i)
		}

		exchange := &types.Exchange{
			ID:        uuid.New(),
			BlockID:   block.ID,
			Sequence:  i,
			Question:  exTyped.GetQuestion(),
			Answer:    exTyped.GetAnswer(),
			Timestamp: exTyped.GetTimestamp(),
			ModelUsed: exTyped.GetModelUsed(),
		}

		// Generate embedding for exchange
		exText := exchange.Question + " " + exchange.Answer
		exEmbedding, err := p.embedder.Embed(ctx, exText)
		if err != nil {
			return nil, fmt.Errorf("failed to generate embedding for exchange %d: %w", i, err)
		}

		_, err = tx.ExecContext(ctx, `
			INSERT INTO exchanges (id, block_id, sequence, question, answer, timestamp, model_used, embedding)
			VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		`, exchange.ID, exchange.BlockID, exchange.Sequence, exchange.Question,
			exchange.Answer, exchange.Timestamp, exchange.ModelUsed,
			pgvector.NewVector(toFloat32(exEmbedding)))

		if err != nil {
			return nil, fmt.Errorf("failed to insert exchange %d: %w", i, err)
		}

		block.Exchanges = append(block.Exchanges, *exchange)
	}

	// Step 6: Insert tags if provided
	tags := pb.GetTags()
	if len(tags) > 0 {
		if err := p.saveBlockTagsTx(ctx, tx, block.ID, tags); err != nil {
			return nil, fmt.Errorf("failed to save tags: %w", err)
		}
	}

	// Step 7: Update import history
	if err := p.updateImportHistoryTx(ctx, tx, batchID, pb.GetSourceFile(), pb.GetSourceHash(), "completed", ""); err != nil {
		return nil, fmt.Errorf("failed to update import history: %w", err)
	}

	// Commit transaction
	if err := tx.Commit(); err != nil {
		return nil, fmt.Errorf("failed to commit transaction: %w", err)
	}

	return block, nil
}

// GetOrCreateOrganization gets or creates an organization by name
func (p *PostgresDB) GetOrCreateOrganization(ctx context.Context, name, tier string) (*Organization, error) {
	return p.getOrCreateOrganizationTx(ctx, p.db, name, tier)
}

// QueryImportHistory queries the import history for a specific source file and hash
func (p *PostgresDB) QueryImportHistory(ctx context.Context, sourceFile, fileHash string) (*ImportHistoryRecord, error) {
	var record ImportHistoryRecord
	err := p.db.QueryRowContext(ctx, `
		SELECT id, source_file, file_hash, imported_at, updated_at, block_count,
		       import_type, status, visibility, source_classification, organization_id
		FROM import_history
		WHERE source_file = $1 AND file_hash = $2
		ORDER BY imported_at DESC
		LIMIT 1
	`, sourceFile, fileHash).Scan(
		&record.ID, &record.SourceFile, &record.FileHash, &record.ImportedAt,
		&record.UpdatedAt, &record.BlockCount, &record.ImportType, &record.Status,
		&record.Visibility, &record.SourceClassification, &record.OrganizationID)

	if err == sql.ErrNoRows {
		return nil, sql.ErrNoRows
	}
	if err != nil {
		return nil, fmt.Errorf("failed to query import history: %w", err)
	}

	return &record, nil
}

// QueryBlocksBySource queries blocks by source file
func (p *PostgresDB) QueryBlocksBySource(ctx context.Context, sourceFile string) ([]BlockSourceRecord, error) {
	rows, err := p.db.QueryContext(ctx, `
		SELECT id, source_file, source_hash, source_type, topic
		FROM blocks
		WHERE source_file = $1
		ORDER BY created_at DESC
	`, sourceFile)
	if err != nil {
		return nil, fmt.Errorf("failed to query blocks by source: %w", err)
	}
	defer rows.Close()

	var records []BlockSourceRecord
	for rows.Next() {
		var record BlockSourceRecord
		if err := rows.Scan(&record.BlockID, &record.SourceFile, &record.SourceHash, &record.SourceType, &record.Topic); err != nil {
			return nil, fmt.Errorf("failed to scan block source record: %w", err)
		}
		records = append(records, record)
	}

	return records, nil
}

// CreateImportBatch creates a new import batch in the import history
func (p *PostgresDB) CreateImportBatch(ctx context.Context, sourceFile, fileHash, importType, visibility, sourceClass string, orgID *uuid.UUID) (uuid.UUID, error) {
	batchID := uuid.New()
	_, err := p.db.ExecContext(ctx, `
		INSERT INTO import_history (
			id, source_file, file_hash, block_count, import_type,
			status, visibility, source_classification, organization_id
		) VALUES ($1, $2, $3, 0, $4, 'in-progress', $5, $6, $7)
	`, batchID, sourceFile, fileHash, importType, visibility, sourceClass, orgID)

	if err != nil {
		return uuid.Nil, fmt.Errorf("failed to create import batch: %w", err)
	}

	return batchID, nil
}

// Transaction-based helper methods

func (p *PostgresDB) getOrCreateOrganizationTx(ctx context.Context, db interface {
	QueryRowContext(ctx context.Context, query string, args ...interface{}) *sql.Row
	ExecContext(ctx context.Context, query string, args ...interface{}) (sql.Result, error)
}, name, tier string) (*Organization, error) {
	var org Organization
	err := db.QueryRowContext(ctx, `
		SELECT id, name, tier, created_at, updated_at
		FROM organizations
		WHERE name = $1
	`, name).Scan(&org.ID, &org.Name, &org.Tier, &org.CreatedAt, &org.UpdatedAt)

	if err == nil {
		return &org, nil
	}

	if err != sql.ErrNoRows {
		return nil, fmt.Errorf("failed to query organization: %w", err)
	}

	// Create new organization
	org = Organization{
		ID:        uuid.New(),
		Name:      name,
		Tier:      tier,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	_, err = db.ExecContext(ctx, `
		INSERT INTO organizations (id, name, tier, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5)
	`, org.ID, org.Name, org.Tier, org.CreatedAt, org.UpdatedAt)

	if err != nil {
		return nil, fmt.Errorf("failed to create organization: %w", err)
	}

	return &org, nil
}

func (p *PostgresDB) getOrCreateProjectTx(ctx context.Context, db interface {
	QueryRowContext(ctx context.Context, query string, args ...interface{}) *sql.Row
	ExecContext(ctx context.Context, query string, args ...interface{}) (sql.Result, error)
}, directoryPath string, orgID *uuid.UUID) (*types.Project, error) {
	var project types.Project
	err := db.QueryRowContext(ctx, `
		SELECT id, name, directory_path, created_at, updated_at
		FROM projects
		WHERE directory_path = $1
	`, directoryPath).Scan(&project.ID, &project.Name, &project.DirectoryPath, &project.CreatedAt, &project.UpdatedAt)

	if err == nil {
		return &project, nil
	}

	if err != sql.ErrNoRows {
		return nil, fmt.Errorf("failed to query project: %w", err)
	}

	// Create new project from directory path
	project = types.Project{
		ID:            uuid.New(),
		Name:          extractProjectName(directoryPath),
		DirectoryPath: directoryPath,
		CreatedAt:     time.Now(),
		UpdatedAt:     time.Now(),
	}

	_, err = db.ExecContext(ctx, `
		INSERT INTO projects (id, name, directory_path, organization_id, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6)
	`, project.ID, project.Name, project.DirectoryPath, orgID, project.CreatedAt, project.UpdatedAt)

	if err != nil {
		return nil, fmt.Errorf("failed to create project: %w", err)
	}

	return &project, nil
}

func (p *PostgresDB) saveBlockTagsTx(ctx context.Context, db interface {
	QueryRowContext(ctx context.Context, query string, args ...interface{}) *sql.Row
	ExecContext(ctx context.Context, query string, args ...interface{}) (sql.Result, error)
}, blockID uuid.UUID, tagNames []string) error {
	for _, tagName := range tagNames {
		// Get or create tag
		var tagID uuid.UUID
		err := db.QueryRowContext(ctx, `
			INSERT INTO tags (id, name, created_at)
			VALUES ($1, $2, $3)
			ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name
			RETURNING id
		`, uuid.New(), tagName, time.Now()).Scan(&tagID)

		if err != nil {
			// Try to get existing
			err = db.QueryRowContext(ctx, `SELECT id FROM tags WHERE name = $1`, tagName).Scan(&tagID)
			if err != nil {
				return fmt.Errorf("failed to get/create tag %s: %w", tagName, err)
			}
		}

		// Link tag to block
		_, err = db.ExecContext(ctx, `
			INSERT INTO block_tags (block_id, tag_id, confidence, created_at)
			VALUES ($1, $2, $3, $4)
			ON CONFLICT (block_id, tag_id) DO NOTHING
		`, blockID, tagID, 1.0, time.Now())

		if err != nil {
			return fmt.Errorf("failed to link tag %s to block: %w", tagName, err)
		}
	}

	return nil
}

func (p *PostgresDB) updateImportHistoryTx(ctx context.Context, db interface {
	ExecContext(ctx context.Context, query string, args ...interface{}) (sql.Result, error)
}, batchID uuid.UUID, sourceFile, fileHash, status, errorMessage string) error {
	_, err := db.ExecContext(ctx, `
		UPDATE import_history
		SET status = $1,
		    error_message = $2,
		    updated_at = CURRENT_TIMESTAMP
		WHERE id = $3
	`, status, errorMessage, batchID)

	if err != nil {
		return fmt.Errorf("failed to update import history: %w", err)
	}

	return nil
}

// Helper types for import operations

type Organization struct {
	ID        uuid.UUID
	Name      string
	Tier      string
	CreatedAt time.Time
	UpdatedAt time.Time
}

type ImportHistoryRecord struct {
	ID                   uuid.UUID
	SourceFile           string
	FileHash             string
	ImportedAt           string
	UpdatedAt            string
	BlockCount           int
	ImportType           string
	Status               string
	Visibility           string
	SourceClassification string
	OrganizationID       *uuid.UUID
}

type BlockSourceRecord struct {
	BlockID    uuid.UUID
	SourceFile string
	SourceHash string
	SourceType string
	Topic      string
}

// Helper function to extract project name from directory path
func extractProjectName(path string) string {
	// Simple extraction: get the last component of the path
	parts := []rune(path)
	for i := len(parts) - 1; i >= 0; i-- {
		if parts[i] == '/' {
			return string(parts[i+1:])
		}
	}
	return path
}

// Helper function to convert float64 slice to float32 for pgvector
func toFloat32(f64 []float64) []float32 {
	f32 := make([]float32, len(f64))
	for i, v := range f64 {
		f32[i] = float32(v)
	}
	return f32
}
