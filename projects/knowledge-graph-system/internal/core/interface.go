package core

import (
	"context"

	"github.com/TheGenXCoder/knowledge-graph/pkg/types"
	"github.com/google/uuid"
)

// KnowledgeGraph is the core interface - stable, never changes
// Adapters (MCP, Gemini, etc.) interact through this interface
type KnowledgeGraph interface {
	// Search performs semantic + keyword hybrid search
	// Returns results ranked by relevance, must complete sub-200ms (goal)
	Search(ctx context.Context, query string, opts types.SearchOptions) (*types.SearchResults, error)

	// SaveBlock saves a conversation block with auto-tagging
	// Extracts tags and infers relationships automatically
	SaveBlock(ctx context.Context, block *types.Block) error

	// GetBlock retrieves a block by ID
	GetBlock(ctx context.Context, id uuid.UUID) (*types.Block, error)

	// GetContextNPlusOne retrieves a block plus everything one hop away
	// Returns N+1 context bundle: block + related blocks via tags/relationships
	GetContextNPlusOne(ctx context.Context, blockID uuid.UUID) (*types.ContextBundle, error)

	// SearchProject searches within a specific project
	// Useful for multi-project isolation
	SearchProject(ctx context.Context, projectID uuid.UUID, query string, opts types.SearchOptions) (*types.SearchResults, error)

	// GetOrCreateProject gets existing or creates new project
	GetOrCreateProject(ctx context.Context, name string, directory string) (*types.Project, error)

	// SaveExchange adds an exchange to a block (for building blocks incrementally)
	SaveExchange(ctx context.Context, exchange *types.Exchange) error

	// ExtractTags uses local LLM to extract semantic tags from content
	ExtractTags(ctx context.Context, content string) ([]string, error)

	// Close closes the knowledge graph connection
	Close() error
}

// Embedder interface for generating vector embeddings
type Embedder interface {
	// Embed generates a vector embedding for text
	// Uses Ollama nomic-embed-text (384 dimensions)
	Embed(ctx context.Context, text string) ([]float64, error)

	// EmbedBatch generates embeddings for multiple texts efficiently
	EmbedBatch(ctx context.Context, texts []string) ([][]float64, error)
}
