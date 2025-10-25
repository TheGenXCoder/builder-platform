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
			&relevance,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan block: %w", err)
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

	err := p.db.QueryRowContext(ctx, `
		SELECT id, project_id, topic, started_at, completed_at, exchange_count, metadata, created_at, updated_at
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
	)

	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("block not found: %s", id)
	}
	if err != nil {
		return nil, fmt.Errorf("failed to query block: %w", err)
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

// Helper function to convert float64 slice to float32 for pgvector
func toFloat32(f64 []float64) []float32 {
	f32 := make([]float32, len(f64))
	for i, v := range f64 {
		f32[i] = float32(v)
	}
	return f32
}
