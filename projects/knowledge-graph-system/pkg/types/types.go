package types

import (
	"time"

	"github.com/google/uuid"
	"github.com/pgvector/pgvector-go"
)

// Project represents a multi-project workspace
type Project struct {
	ID            uuid.UUID `json:"id"`
	Name          string    `json:"name"`
	DirectoryPath string    `json:"directory_path"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
}

// Block represents a conversation block (topic + 3-5 exchanges)
type Block struct {
	ID            uuid.UUID      `json:"id"`
	ProjectID     uuid.UUID      `json:"project_id"`
	Topic         string         `json:"topic"`
	StartedAt     time.Time      `json:"started_at"`
	CompletedAt   *time.Time     `json:"completed_at,omitempty"`
	ExchangeCount int            `json:"exchange_count"`
	Embedding     pgvector.Vector `json:"-"` // 384-dim vector from nomic-embed-text
	Metadata      map[string]interface{} `json:"metadata,omitempty"`
	CreatedAt     time.Time      `json:"created_at"`
	UpdatedAt     time.Time      `json:"updated_at"`

	// Relations (not stored in DB, populated by queries)
	Exchanges     []Exchange     `json:"exchanges,omitempty"`
	Tags          []Tag          `json:"tags,omitempty"`
	Relationships []Relationship `json:"relationships,omitempty"`
}

// Exchange represents a single Q&A pair within a block
type Exchange struct {
	ID        uuid.UUID       `json:"id"`
	BlockID   uuid.UUID       `json:"block_id"`
	Sequence  int             `json:"sequence"`
	Question  string          `json:"question"`
	Answer    string          `json:"answer"`
	Timestamp time.Time       `json:"timestamp"`
	ModelUsed string          `json:"model_used,omitempty"`
	Embedding pgvector.Vector `json:"-"`
}

// Tag represents a semantic tag
type Tag struct {
	ID        uuid.UUID `json:"id"`
	Name      string    `json:"name"`
	CreatedAt time.Time `json:"created_at"`
}

// BlockTag represents the many-to-many relationship between blocks and tags
type BlockTag struct {
	BlockID    uuid.UUID `json:"block_id"`
	TagID      uuid.UUID `json:"tag_id"`
	Confidence float64   `json:"confidence"`
	CreatedAt  time.Time `json:"created_at"`
}

// Relationship represents a block-to-block relationship
type Relationship struct {
	FromBlockID      uuid.UUID `json:"from_block_id"`
	ToBlockID        uuid.UUID `json:"to_block_id"`
	RelationshipType string    `json:"relationship_type"` // derived-from, related-to, implements, etc
	Confidence       float64   `json:"confidence"`
	CreatedAt        time.Time `json:"created_at"`
}

// SearchOptions configures search behavior
type SearchOptions struct {
	ProjectID    *uuid.UUID `json:"project_id,omitempty"`    // Filter to specific project
	Limit        int        `json:"limit"`                    // Max results (default 10)
	MinRelevance float64    `json:"min_relevance,omitempty"` // Minimum relevance score (0-1)
	IncludeNPlus bool       `json:"include_n_plus"`          // Include N+1 relationships
}

// SearchResult represents a single search result with relevance
type SearchResult struct {
	Block     *Block    `json:"block"`
	Relevance float64   `json:"relevance"` // Similarity score (0-1, higher is better)
	Related   []*Block  `json:"related,omitempty"` // N+1: one hop away
}

// SearchResults represents the complete search response
type SearchResults struct {
	Results    []SearchResult `json:"results"`
	TotalFound int            `json:"total_found"`
	SearchTime time.Duration  `json:"search_time"` // Must be sub-200ms
}

// ContextBundle represents N+1 context for a block
type ContextBundle struct {
	PrimaryBlock *Block   `json:"primary_block"`
	RelatedBlocks []*Block `json:"related_blocks"` // One hop away via tags/relationships
	Tags         []Tag    `json:"tags"`
}
