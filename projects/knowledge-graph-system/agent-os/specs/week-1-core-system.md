# Specification: Knowledge Graph System - Week 1 Core Infrastructure

## Executive Summary

**Goal:** Build the foundational knowledge graph system that eliminates context repetition through automated conversation capture, semantic search, and intelligent context injection.

**Week 1 Success:** "I STOP LOSING CONTEXT. I don't have to remind you of the same thing over and over."

**Approach:** Core infrastructure layer (stable, valuable) + Claude MCP adapter (cheap, replaceable) + block-based storage with semantic search from day 1.

**Timeline:** 7 days to working system being used in production (dogfooding)

**Architecture Philosophy:** Build the expensive, valuable core once. Make adapters cheap and replaceable. Hedge against AI tool changes.

---

## User Context & Pain Points

### Current Reality (Living It NOW)

**User Profile:**
- 50-year-old second-act founder
- Part-time builder (job required for income)
- Building transformative infrastructure (5-10 year vision)
- Faith/family boundaries (sustainable pace)
- Pattern of quitting - this needs to be THE win
- Neovim power user (Ghostty + tmux workflow)

**Active Pain:**
"I can't make it a couple hours without having to repeat myself and that makes my skin crawl."

**Repeated Context Examples:**
- "Always validate against XSD"
- "Spec is derived from integration guide"
- "This client uses Windows even though I develop on Mac"

**Active Projects (Context Switching):**
- Knowledge Graph System (this build)
- 3-party API middleware (active pain NOW)
- Real estate lead gen (future)
- Multiple simultaneous projects

**Workflow:**
- Ghostty + tmux (Claude left pane, Neovim top-right, terminal bottom-right)
- aerospace (Mac) or hyprland (Arch) for workspaces
- Multiple concurrent projects

### Week 1 Success Criteria (User's Words)

"I STOP LOSING CONTEXT. I don't have to remind you of the same thing over and over."

**Measured By:**
- Zero repeated instructions within same day
- Zero "remember when I told you X" moments
- Claude just "knows" project context automatically
- User confidence in system reliability

---

## System Architecture

### The Core + Adapter Pattern

```
┌─────────────────────────────────────────────────┐
│   KNOWLEDGE GRAPH CORE (Stable, Expensive)      │
│                                                  │
│   - PostgreSQL + pgvector                       │
│   - Block-based storage                         │
│   - Semantic search (sub-200ms)                 │
│   - Tag/relationship extraction                 │
│   - N+1 context bundling                        │
│   - Multi-project isolation                     │
│                                                  │
│   Internal API (Never Changes):                 │
│   - Search(query, opts) → Results               │
│   - SaveBlock(block) → error                    │
│   - GetContextNPlusOne(blockID) → Bundle        │
│   - SearchProject(projectID, query) → Results   │
└────────────────┬────────────────────────────────┘
                 │ Stable Internal API
┌────────────────▼────────────────────────────────┐
│   ADAPTER LAYER (Replaceable, Cheap)            │
│                                                  │
│   Week 1: Claude MCP Adapter (~200 lines)       │
│   Week 2: Gemini Adapter (Rajesh)               │
│   Future: Skills Adapter (when MCP deprecated)  │
│                                                  │
│   Adapter Responsibilities:                     │
│   - Intercept AI tool messages                  │
│   - Query core for context                      │
│   - Inject context invisibly                    │
│   - Track exchanges for block completion        │
│   - Auto-save completed blocks                  │
└────────────────┬────────────────────────────────┘
                 │ AI Tool Integration
┌────────────────▼────────────────────────────────┐
│   AI TOOLS (User's Choice)                      │
│                                                  │
│   Week 1: Claude Code                           │
│   Week 2: Gemini (Rajesh waits)                 │
│   Future: Any tool with adapter                 │
└─────────────────────────────────────────────────┘
```

### Why This Architecture?

**Core is Expensive:**
- Database schema design
- Semantic search optimization
- Relationship inference algorithms
- Multi-project isolation
- Performance tuning (sub-200ms)

**Core is Valuable:**
- Compounds over time (more data = better)
- Works with ANY AI tool (via adapters)
- Survives API changes (stable internal interface)
- User owns their knowledge forever

**Adapters are Cheap:**
- ~200 lines of code
- Tool-specific integration logic
- Easy to replace when tool changes
- Multiple adapters run simultaneously

**Hedge Against Change:**
- MCP might be deprecated (Skills API replaces it)
- Claude Code might change pricing/features
- New AI tools emerge (Gemini, local models)
- Core remains stable, swap adapters

---

## Core Requirements

### Functional Requirements (Week 1)

**Must Have:**

1. **Block-Based Storage**
   - Capture conversation "blocks" (topic + 3-5 exchanges)
   - Auto-detect block completion (topic shift, time threshold, significant event)
   - Store blocks with semantic embeddings (pgvector)
   - Extract tags automatically (local Ollama model)
   - Infer relationships between blocks (pattern-based Week 1)

2. **Semantic Search**
   - Vector similarity search (pgvector)
   - Keyword search fallback (PostgreSQL full-text)
   - Merge and rank results (relevance score)
   - Filter by project (multi-project support)
   - Sub-200ms response time (95th percentile)

3. **N+1 Context Injection**
   - Return direct answer (matched block)
   - Plus one-hop relationships (tags, related blocks)
   - Inject into Claude context invisibly
   - User sees Claude "just knowing" things

4. **Claude MCP Adapter**
   - Intercept user messages before Claude
   - Search knowledge graph automatically
   - Inject relevant context (invisible to user)
   - Track exchanges for block detection
   - Auto-save completed blocks

5. **Multi-Project Support**
   - Detect project from workspace directory
   - Isolate knowledge by project
   - Search within project by default
   - Cross-project search when needed

6. **Auto-Save with Intelligence**
   - Save when topic appears complete (3-5 exchanges)
   - Save on significant events (>500 lines code, summary requested)
   - Save on reasonable time threshold (not longer than X minutes)
   - Don't save every single message (performance)

**Must NOT Have (Week 1):**
- Web dashboard (maybe basic metrics page)
- TUI (terminal UI)
- Gemini adapter (Week 2)
- Complex graph visualization
- Advanced relationship inference (LLM-based)
- Model routing (comes after multi-model)
- Classifier (comes after routing)

### Non-Functional Requirements

**Performance:**
- Search: sub-200ms (95th percentile)
- Block save: <50ms
- Context injection: transparent (user doesn't notice)
- Memory: reasonable for daemon (not bloated)

**Reliability:**
- Zero data loss (every exchange saved)
- Graceful degradation (core search works if embeddings fail)
- Error recovery (retry transient failures)
- Data integrity (PostgreSQL constraints)

**Usability:**
- Invisible to user (MCP integration transparent)
- No manual intervention needed
- Works across all Claude Code sessions
- Multi-project support automatic

**Security:**
- Local-first (data on user's machine)
- PostgreSQL authentication
- No cloud dependencies (except Claude API)
- User owns all data

---

## Database Schema

### Block-Based Storage Design

```sql
-- ============================================================================
-- CORE SCHEMA: Block-based conversation storage
-- ============================================================================

-- Extension for vector embeddings (semantic search)
CREATE EXTENSION IF NOT EXISTS vector;

-- Conversation blocks (atomic unit of knowledge)
CREATE TABLE blocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL,                    -- Which project (API middleware, real estate, etc)
    topic VARCHAR(500) NOT NULL,                 -- Auto-extracted topic
    started_at TIMESTAMP NOT NULL,               -- When block started
    completed_at TIMESTAMP NOT NULL,             -- When block completed
    exchange_count INT NOT NULL DEFAULT 0,       -- How many Q&A pairs
    embedding VECTOR(1536),                      -- pgvector semantic embedding (OpenAI dimensions)
    metadata JSONB,                              -- Flexible storage for future
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Individual exchanges within block (Q&A pairs)
CREATE TABLE exchanges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    block_id UUID NOT NULL REFERENCES blocks(id) ON DELETE CASCADE,
    sequence INT NOT NULL,                       -- Order within block (1, 2, 3...)
    question TEXT NOT NULL,                      -- User message
    answer TEXT NOT NULL,                        -- Claude response
    timestamp TIMESTAMP NOT NULL,                -- When exchange occurred
    model_used VARCHAR(100),                     -- claude-opus-4, claude-sonnet-3.5, etc
    embedding VECTOR(1536),                      -- Exchange-level embedding
    metadata JSONB,                              -- Token counts, etc
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tags (extracted automatically)
CREATE TABLE tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL,
    category VARCHAR(50),                        -- technology, concept, domain, etc
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Block-to-tag relationships (many-to-many)
CREATE TABLE block_tags (
    block_id UUID NOT NULL REFERENCES blocks(id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    confidence FLOAT NOT NULL DEFAULT 1.0,       -- How confident we are (0.0-1.0)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (block_id, tag_id)
);

-- Block-to-block relationships (graph structure)
CREATE TABLE block_relationships (
    from_block_id UUID NOT NULL REFERENCES blocks(id) ON DELETE CASCADE,
    to_block_id UUID NOT NULL REFERENCES blocks(id) ON DELETE CASCADE,
    relationship_type VARCHAR(50) NOT NULL,      -- derived-from, related-to, implements, etc
    confidence FLOAT NOT NULL DEFAULT 1.0,       -- How confident we are (0.0-1.0)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (from_block_id, to_block_id, relationship_type)
);

-- Projects (workspace isolation)
CREATE TABLE projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    directory_path TEXT NOT NULL UNIQUE,         -- Absolute path to project directory
    description TEXT,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- INDEXES: Performance optimization
-- ============================================================================

-- Block indexes
CREATE INDEX idx_blocks_project ON blocks(project_id);
CREATE INDEX idx_blocks_completed_at ON blocks(completed_at DESC);
CREATE INDEX idx_blocks_topic ON blocks USING GIN (to_tsvector('english', topic));

-- Vector similarity index (HNSW for fast approximate nearest neighbor)
CREATE INDEX idx_blocks_embedding ON blocks
USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);

-- Exchange indexes
CREATE INDEX idx_exchanges_block ON exchanges(block_id);
CREATE INDEX idx_exchanges_timestamp ON exchanges(timestamp DESC);
CREATE INDEX idx_exchanges_embedding ON exchanges
USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);

-- Tag indexes
CREATE INDEX idx_tags_name ON tags(name);
CREATE INDEX idx_tags_category ON tags(category);

-- Block-tag indexes
CREATE INDEX idx_block_tags_block ON block_tags(block_id);
CREATE INDEX idx_block_tags_tag ON block_tags(tag_id);
CREATE INDEX idx_block_tags_confidence ON block_tags(confidence DESC);

-- Block relationship indexes
CREATE INDEX idx_block_rels_from ON block_relationships(from_block_id);
CREATE INDEX idx_block_rels_to ON block_relationships(to_block_id);
CREATE INDEX idx_block_rels_type ON block_relationships(relationship_type);

-- Project indexes
CREATE INDEX idx_projects_directory ON projects(directory_path);

-- ============================================================================
-- CONSTRAINTS: Data integrity
-- ============================================================================

-- Exchange sequence must be positive
ALTER TABLE exchanges ADD CONSTRAINT check_sequence_positive
CHECK (sequence > 0);

-- Exchange count must match actual exchanges
-- (Enforced at application layer for performance)

-- Confidence must be between 0 and 1
ALTER TABLE block_tags ADD CONSTRAINT check_confidence_range
CHECK (confidence >= 0.0 AND confidence <= 1.0);

ALTER TABLE block_relationships ADD CONSTRAINT check_relationship_confidence_range
CHECK (confidence >= 0.0 AND confidence <= 1.0);

-- Prevent self-referential relationships
ALTER TABLE block_relationships ADD CONSTRAINT check_no_self_reference
CHECK (from_block_id != to_block_id);

-- ============================================================================
-- FULL-TEXT SEARCH: Keyword fallback
-- ============================================================================

-- Combined content search across blocks and exchanges
CREATE INDEX idx_exchanges_content ON exchanges
USING GIN (to_tsvector('english', question || ' ' || answer));

-- ============================================================================
-- FUNCTIONS: Helper functions for common queries
-- ============================================================================

-- Update block exchange count
CREATE OR REPLACE FUNCTION update_block_exchange_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE blocks
    SET exchange_count = (
        SELECT COUNT(*)
        FROM exchanges
        WHERE block_id = NEW.block_id
    )
    WHERE id = NEW.block_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_exchange_count
AFTER INSERT OR DELETE ON exchanges
FOR EACH ROW
EXECUTE FUNCTION update_block_exchange_count();

-- Update timestamps
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_blocks_updated_at
BEFORE UPDATE ON blocks
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trigger_projects_updated_at
BEFORE UPDATE ON projects
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();
```

### Schema Design Rationale

**Block-Based Storage (Not Message-Based):**
- Performance: Avoid massive volumes of single-message entries
- Semantic unit: Topics naturally span 3-5 exchanges
- Search granularity: Return relevant conversations, not isolated messages
- Graph structure: Blocks relate to blocks (cleaner than message-to-message)

**pgvector from Day 1:**
- Semantic search is core requirement (Option D: comprehensive results)
- Embeddings generated once, queried forever
- HNSW index provides sub-200ms search at scale
- No migration pain later (designed for it from start)

**Multi-Project Isolation:**
- User has multiple active projects
- Context switching is frequent
- Project detection via workspace directory
- Search scoped to project by default

**Tag Extraction:**
- Cheap local model (Ollama llama3/mistral)
- Improves search filtering (N+1: tags lead to related blocks)
- Confidence scoring for low-quality tag detection

**Relationship Inference:**
- Week 1: Pattern-based (simple, fast)
- Week 2+: LLM-based (sophisticated, expensive)
- Confidence scoring enables threshold filtering

---

## Core API (Stable Interface)

### Go Interface Definitions

```go
package core

import (
    "context"
    "time"
)

// ============================================================================
// CORE INTERFACE: Stable API that never changes
// ============================================================================

// KnowledgeGraph is the stable internal API for the knowledge graph system.
// Adapters use this interface. Core implementation may evolve, but interface
// remains stable.
type KnowledgeGraph interface {
    // Search performs hybrid search (semantic + keyword) across knowledge graph
    Search(ctx context.Context, query string, opts SearchOptions) (*SearchResults, error)

    // SaveBlock persists a conversation block with auto-tagging and relationship inference
    SaveBlock(ctx context.Context, block *Block) error

    // GetContextNPlusOne retrieves a block plus all one-hop relationships (N+1 pattern)
    GetContextNPlusOne(ctx context.Context, blockID string) (*ContextBundle, error)

    // SearchProject searches within a specific project's knowledge
    SearchProject(ctx context.Context, projectID string, query string, opts SearchOptions) (*SearchResults, error)

    // GetOrCreateProject finds project by directory path or creates new one
    GetOrCreateProject(ctx context.Context, directoryPath string) (*Project, error)
}

// ============================================================================
// TYPES: Data structures
// ============================================================================

// Block represents a conversation block (topic + exchanges)
type Block struct {
    ID             string
    ProjectID      string
    Topic          string
    StartedAt      time.Time
    CompletedAt    time.Time
    ExchangeCount  int
    Exchanges      []Exchange
    Tags           []Tag
    Relationships  []Relationship
    Embedding      []float32  // 1536 dimensions (OpenAI-compatible)
    Metadata       map[string]interface{}
}

// Exchange represents a single Q&A pair within a block
type Exchange struct {
    ID         string
    BlockID    string
    Sequence   int
    Question   string
    Answer     string
    Timestamp  time.Time
    ModelUsed  string     // claude-opus-4, claude-sonnet-3.5, etc
    Embedding  []float32
    Metadata   map[string]interface{}
}

// Tag represents an extracted topic/concept/technology tag
type Tag struct {
    ID         string
    Name       string
    Category   string     // technology, concept, domain, etc
    Confidence float64    // 0.0-1.0
}

// Relationship represents a connection between two blocks
type Relationship struct {
    Type           string     // derived-from, related-to, implements, etc
    TargetBlockID  string
    Confidence     float64    // 0.0-1.0
}

// Project represents a workspace/project with isolated knowledge
type Project struct {
    ID            string
    Name          string
    DirectoryPath string
    Description   string
    Metadata      map[string]interface{}
}

// SearchOptions configures search behavior
type SearchOptions struct {
    ProjectID      string     // Filter to specific project (empty = all projects)
    Limit          int        // Max results (default: 10)
    MinRelevance   float64    // Minimum relevance score (0.0-1.0, default: 0.0)
    IncludeRelated bool       // Include N+1 relationships (default: true)
}

// SearchResults contains search results with metadata
type SearchResults struct {
    Blocks         []Block
    RelatedBlocks  []Block            // N+1: Blocks one hop away from results
    Tags           []Tag              // Relevant tags from results
    TotalFound     int
    SearchTime     time.Duration
    Query          string
    ProjectID      string
}

// ContextBundle contains a block plus all N+1 relationships
type ContextBundle struct {
    PrimaryBlock   Block
    RelatedBlocks  []Block
    Tags           []Tag
    Relationships  []Relationship
}
```

### API Design Principles

**Stability Over Flexibility:**
- Interface never changes (adapters depend on it)
- Add new methods, never modify existing signatures
- Backwards compatibility is sacred

**Context-Aware:**
- All methods accept `context.Context` for cancellation/deadlines
- Timeout enforcement at API boundary
- Graceful degradation on context cancellation

**Performance Guarantees:**
- Sub-200ms search (enforced at implementation layer)
- Fast block save (<50ms)
- Efficient N+1 queries (single round-trip to DB)

**Error Handling:**
- Clear error types (NotFound, InvalidInput, DatabaseError)
- Errors include context (what operation, what data)
- Retry logic for transient failures (database connection, etc)

---

## Claude MCP Adapter Implementation

### MCP Server Architecture

```go
package mcp

import (
    "context"
    "time"
    "github.com/yourusername/knowledge-graph/pkg/core"
)

// ============================================================================
// MCP ADAPTER: Claude Code integration (~200 lines total)
// ============================================================================

// ClaudeMCPAdapter bridges Claude Code and Knowledge Graph Core
type ClaudeMCPAdapter struct {
    core           core.KnowledgeGraph
    embedder       Embedder                // Generates embeddings (OpenAI API or local)
    currentBlock   *IncompleteBlock        // Block being built from current conversation
    projectID      string                  // Current project (from workspace dir)
    config         MCPConfig
}

// IncompleteBlock tracks ongoing conversation not yet saved
type IncompleteBlock struct {
    Topic          string
    StartedAt      time.Time
    Exchanges      []core.Exchange
    ProjectID      string
}

// MCPConfig configures adapter behavior
type MCPConfig struct {
    MaxExchangesPerBlock    int           // Trigger save after N exchanges (default: 5)
    MaxBlockDuration        time.Duration // Trigger save after duration (default: 30min)
    ContextInjectionMaxSize int           // Max tokens to inject (default: 2000)
    SearchTimeout           time.Duration // Search timeout (default: 200ms)
}

// ============================================================================
// LIFECYCLE: Daemon startup and shutdown
// ============================================================================

// Start initializes MCP server as system daemon
func (a *ClaudeMCPAdapter) Start(ctx context.Context) error {
    // 1. Initialize core connection
    // 2. Start MCP server (listen on Unix socket or port)
    // 3. Register message handlers
    // 4. Log startup success
}

// Stop gracefully shuts down adapter
func (a *ClaudeMCPAdapter) Stop(ctx context.Context) error {
    // 1. Save current incomplete block (if any)
    // 2. Close core connection
    // 3. Stop MCP server
    // 4. Log shutdown
}

// ============================================================================
// MESSAGE HANDLERS: Intercept Claude Code conversation
// ============================================================================

// OnUserMessage intercepts user message before Claude sees it
func (a *ClaudeMCPAdapter) OnUserMessage(ctx context.Context, msg UserMessage) error {
    // 1. Detect project from workspace directory
    project, err := a.core.GetOrCreateProject(ctx, msg.WorkingDirectory)
    if err != nil {
        return err
    }
    a.projectID = project.ID

    // 2. Search knowledge graph for relevant context
    searchCtx, cancel := context.WithTimeout(ctx, a.config.SearchTimeout)
    defer cancel()

    results, err := a.core.SearchProject(searchCtx, a.projectID, msg.Content, core.SearchOptions{
        Limit:          5,
        MinRelevance:   0.6,  // Only inject high-relevance results
        IncludeRelated: true, // N+1 pattern
    })
    if err != nil {
        // Log error but don't fail (graceful degradation)
        log.Warn("Search failed, continuing without context injection", "error", err)
        return nil
    }

    // 3. Build N+1 context bundle from top result
    if len(results.Blocks) > 0 {
        contextBundle, err := a.core.GetContextNPlusOne(ctx, results.Blocks[0].ID)
        if err == nil {
            // 4. Inject context into Claude (invisible to user)
            a.injectContext(ctx, contextBundle)
        }
    }

    // 5. Track exchange for block detection
    a.trackUserMessage(msg)

    return nil
}

// OnClaudeResponse intercepts Claude response after generation
func (a *ClaudeMCPAdapter) OnClaudeResponse(ctx context.Context, resp ClaudeResponse) error {
    // 1. Track exchange completion
    a.trackClaudeResponse(resp)

    // 2. Check if block is complete
    if a.isBlockComplete() {
        // 3. Extract tags using local Ollama model
        tags, err := a.extractTags(ctx, a.currentBlock)
        if err != nil {
            log.Warn("Tag extraction failed", "error", err)
            tags = []core.Tag{} // Continue without tags
        }

        // 4. Infer relationships from block content
        relationships := a.inferRelationships(ctx, a.currentBlock)

        // 5. Generate embedding for entire block
        embedding, err := a.embedder.EmbedBlock(ctx, a.currentBlock)
        if err != nil {
            return err
        }

        // 6. Save block to core
        block := &core.Block{
            ProjectID:     a.currentBlock.ProjectID,
            Topic:         a.currentBlock.Topic,
            StartedAt:     a.currentBlock.StartedAt,
            CompletedAt:   time.Now(),
            ExchangeCount: len(a.currentBlock.Exchanges),
            Exchanges:     a.currentBlock.Exchanges,
            Tags:          tags,
            Relationships: relationships,
            Embedding:     embedding,
        }

        if err := a.core.SaveBlock(ctx, block); err != nil {
            return err
        }

        // 7. Reset for next block
        a.currentBlock = a.newBlock()

        log.Info("Block saved successfully", "block_id", block.ID, "topic", block.Topic)
    }

    return nil
}

// ============================================================================
// CONTEXT INJECTION: Invisible knowledge enhancement
// ============================================================================

// injectContext adds knowledge graph context to Claude's context window
func (a *ClaudeMCPAdapter) injectContext(ctx context.Context, bundle *core.ContextBundle) {
    // Build context string from bundle
    contextStr := a.buildContextString(bundle)

    // Inject as system message (invisible to user, appears to Claude only)
    // Format: "Relevant context from your knowledge graph: ..."

    // Token limit enforcement (don't exceed MaxSize)
    if a.estimateTokens(contextStr) > a.config.ContextInjectionMaxSize {
        contextStr = a.truncateContext(contextStr, a.config.ContextInjectionMaxSize)
    }

    // MCP-specific injection mechanism (depends on MCP protocol)
    a.mcpInject(contextStr)
}

// buildContextString formats context bundle for injection
func (a *ClaudeMCPAdapter) buildContextString(bundle *core.ContextBundle) string {
    // Week 1: Simple format
    // Week 2+: Sophisticated formatting with relevance indicators

    var sb strings.Builder

    sb.WriteString("## Relevant Context from Knowledge Graph\n\n")

    // Primary block
    sb.WriteString(fmt.Sprintf("### %s\n", bundle.PrimaryBlock.Topic))
    sb.WriteString(fmt.Sprintf("(From %s)\n\n", bundle.PrimaryBlock.StartedAt.Format("2006-01-02")))

    // Include last 2 exchanges (most relevant)
    for i := max(0, len(bundle.PrimaryBlock.Exchanges)-2); i < len(bundle.PrimaryBlock.Exchanges); i++ {
        ex := bundle.PrimaryBlock.Exchanges[i]
        sb.WriteString(fmt.Sprintf("Q: %s\n", ex.Question))
        sb.WriteString(fmt.Sprintf("A: %s\n\n", ex.Answer))
    }

    // Related blocks (N+1)
    if len(bundle.RelatedBlocks) > 0 {
        sb.WriteString("### Related Topics:\n")
        for _, rb := range bundle.RelatedBlocks {
            sb.WriteString(fmt.Sprintf("- %s (%s)\n", rb.Topic, rb.StartedAt.Format("2006-01-02")))
        }
    }

    // Tags
    if len(bundle.Tags) > 0 {
        sb.WriteString("\n### Tags: ")
        tagNames := make([]string, len(bundle.Tags))
        for i, tag := range bundle.Tags {
            tagNames[i] = tag.Name
        }
        sb.WriteString(strings.Join(tagNames, ", "))
    }

    return sb.String()
}

// ============================================================================
// BLOCK DETECTION: Determine when conversation topic changes
// ============================================================================

// isBlockComplete determines if current block should be saved
func (a *ClaudeMCPAdapter) isBlockComplete() bool {
    if a.currentBlock == nil {
        return false
    }

    // Condition 1: Exchange count threshold (3-5 exchanges = complete topic)
    if len(a.currentBlock.Exchanges) >= a.config.MaxExchangesPerBlock {
        return true
    }

    // Condition 2: Time threshold (30 minutes = topic likely complete)
    if time.Since(a.currentBlock.StartedAt) > a.config.MaxBlockDuration {
        return true
    }

    // Condition 3: Significant event detection
    // - Code generation >500 lines
    // - User requests summary
    // - File operations completed
    if a.detectSignificantEvent(a.currentBlock) {
        return true
    }

    return false
}

// detectSignificantEvent identifies events that signal block completion
func (a *ClaudeMCPAdapter) detectSignificantEvent(block *IncompleteBlock) bool {
    if len(block.Exchanges) == 0 {
        return false
    }

    lastExchange := block.Exchanges[len(block.Exchanges)-1]

    // Pattern 1: User requests summary ("summarize", "recap", "in summary")
    if containsAny(lastExchange.Question, []string{"summarize", "recap", "summary", "in summary"}) {
        return true
    }

    // Pattern 2: Large code generation (>500 lines in response)
    if countLines(lastExchange.Answer) > 500 {
        return true
    }

    // Pattern 3: Completion phrases ("that's it", "we're done", "perfect, thanks")
    if containsAny(lastExchange.Question, []string{"that's it", "we're done", "perfect", "thanks"}) {
        return true
    }

    return false
}

// ============================================================================
// TAG EXTRACTION: Automated topic tagging (Week 1: Simple)
// ============================================================================

// extractTags uses local Ollama model to extract relevant tags
func (a *ClaudeMCPAdapter) extractTags(ctx context.Context, block *IncompleteBlock) ([]core.Tag, error) {
    // Combine all exchanges into single text
    content := a.combineBlockContent(block)

    // Prompt local Ollama model (llama3 or mistral)
    prompt := fmt.Sprintf(`Extract 5-10 relevant tags from this conversation block.
Focus on: technologies, concepts, decisions, domain terms.
Return tags as comma-separated list.
Do not include generic terms like "discussion" or "question".

Conversation:
%s

Tags:`, content)

    // Query Ollama API (local, fast, free)
    response, err := a.ollamaClient.Generate(ctx, OllamaRequest{
        Model:  "llama3:latest",
        Prompt: prompt,
    })
    if err != nil {
        return nil, err
    }

    // Parse comma-separated tags
    tagNames := parseCommaSeparated(response.Text)

    // Convert to Tag objects
    tags := make([]core.Tag, len(tagNames))
    for i, name := range tagNames {
        tags[i] = core.Tag{
            Name:       strings.ToLower(strings.TrimSpace(name)),
            Category:   "auto-extracted",  // Week 1: Simple category
            Confidence: 0.8,                // Week 1: Fixed confidence
        }
    }

    return tags, nil
}

// ============================================================================
// RELATIONSHIP INFERENCE: Pattern-based (Week 1)
// ============================================================================

// inferRelationships finds connections between current block and existing blocks
func (a *ClaudeMCPAdapter) inferRelationships(ctx context.Context, block *IncompleteBlock) []core.Relationship {
    var relationships []core.Relationship

    // Pattern 1: "based on our discussion about X" (explicit reference)
    mentions := a.findPreviousDiscussionMentions(block)
    for _, mention := range mentions {
        // Search for blocks matching mentioned topic
        results, err := a.core.SearchProject(ctx, block.ProjectID, mention, core.SearchOptions{
            Limit: 1,
        })
        if err == nil && len(results.Blocks) > 0 {
            relationships = append(relationships, core.Relationship{
                Type:          "derived-from",
                TargetBlockID: results.Blocks[0].ID,
                Confidence:    0.8,
            })
        }
    }

    // Pattern 2: Same tags = related topics
    // (Requires tags already extracted - do after tag extraction)
    // Week 2+: Implement tag-based relationship inference

    // Pattern 3: Temporal proximity (blocks from same session)
    // Week 2+: Track session IDs, relate blocks from same session

    return relationships
}

// findPreviousDiscussionMentions extracts references to prior discussions
func (a *ClaudeMCPAdapter) findPreviousDiscussionMentions(block *IncompleteBlock) []string {
    var mentions []string

    // Regex patterns for references:
    // - "based on our discussion about X"
    // - "as we talked about earlier regarding X"
    // - "following up on X"
    // - "continuing from X"

    patterns := []string{
        `(?i)based on our discussion about (.+?)[\.\,\n]`,
        `(?i)as we talked about (?:earlier |)regarding (.+?)[\.\,\n]`,
        `(?i)following up on (.+?)[\.\,\n]`,
        `(?i)continuing from (.+?)[\.\,\n]`,
    }

    content := a.combineBlockContent(block)

    for _, pattern := range patterns {
        re := regexp.MustCompile(pattern)
        matches := re.FindAllStringSubmatch(content, -1)
        for _, match := range matches {
            if len(match) > 1 {
                mentions = append(mentions, match[1])
            }
        }
    }

    return mentions
}
```

### MCP Adapter Design Rationale

**Cheap and Replaceable:**
- Total code: ~200 lines
- No complex logic (core does heavy lifting)
- Easy to swap for Gemini adapter, Skills adapter, etc

**Invisible to User:**
- Context injection transparent
- No UI/prompts (daemon in background)
- User sees Claude "just knowing" things

**Performance-Conscious:**
- 200ms search timeout (don't slow down user)
- Graceful degradation (continue without context if search fails)
- Async block saving (don't block response)

**Stateful but Simple:**
- Tracks current incomplete block
- Detects block completion
- Resets cleanly for next block

---

## Search Implementation

### Hybrid Search Strategy (Semantic + Keyword)

```go
package core

import (
    "context"
    "time"
)

// ============================================================================
// SEARCH: Hybrid semantic + keyword search (sub-200ms goal)
// ============================================================================

// Search performs hybrid search across knowledge graph
func (kg *KnowledgeGraphImpl) Search(ctx context.Context, query string, opts SearchOptions) (*SearchResults, error) {
    start := time.Now()

    // Validate options
    if opts.Limit <= 0 {
        opts.Limit = 10  // Default limit
    }

    // 1. Generate embedding for query (semantic search)
    queryEmbedding, err := kg.embedder.Embed(ctx, query)
    if err != nil {
        // Graceful degradation: Continue with keyword search only
        log.Warn("Embedding generation failed, using keyword search only", "error", err)
        return kg.keywordSearchOnly(ctx, query, opts)
    }

    // 2. Execute semantic search (pgvector)
    semanticResults, err := kg.vectorSearch(ctx, queryEmbedding, opts)
    if err != nil {
        return nil, err
    }

    // 3. Execute keyword search (PostgreSQL full-text)
    keywordResults, err := kg.fullTextSearch(ctx, query, opts)
    if err != nil {
        return nil, err
    }

    // 4. Merge and rank results (hybrid scoring)
    mergedBlocks := kg.mergeAndRank(semanticResults, keywordResults, opts)

    // 5. Load N+1 relationships for top results
    if opts.IncludeRelated {
        for i := range mergedBlocks {
            related, tags := kg.loadRelationships(ctx, mergedBlocks[i].ID)
            // Store in separate arrays (not modifying block itself)
            // Returned in SearchResults.RelatedBlocks and SearchResults.Tags
        }
    }

    // 6. Calculate search time
    searchTime := time.Since(start)

    // 7. Warn if exceeding 200ms threshold
    if searchTime > 200*time.Millisecond {
        log.Warn("Search exceeded 200ms threshold",
            "time_ms", searchTime.Milliseconds(),
            "query", query,
            "results", len(mergedBlocks))
    }

    return &SearchResults{
        Blocks:      mergedBlocks,
        TotalFound:  len(mergedBlocks),
        SearchTime:  searchTime,
        Query:       query,
        ProjectID:   opts.ProjectID,
    }, nil
}

// ============================================================================
// VECTOR SEARCH: pgvector semantic similarity
// ============================================================================

// vectorSearch performs vector similarity search using pgvector
func (kg *KnowledgeGraphImpl) vectorSearch(ctx context.Context, embedding []float32, opts SearchOptions) ([]Block, error) {
    // SQL query using pgvector cosine similarity
    query := `
        SELECT
            b.id,
            b.project_id,
            b.topic,
            b.started_at,
            b.completed_at,
            b.exchange_count,
            b.embedding,
            1 - (b.embedding <=> $1) AS similarity
        FROM blocks b
        WHERE ($2 = '' OR b.project_id = $2::uuid)
        ORDER BY b.embedding <=> $1
        LIMIT $3
    `

    // Execute query
    rows, err := kg.db.QueryContext(ctx, query,
        pgvector.NewVector(embedding),
        opts.ProjectID,
        opts.Limit)
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    // Parse results
    var blocks []Block
    for rows.Next() {
        var b Block
        var similarity float64

        err := rows.Scan(
            &b.ID,
            &b.ProjectID,
            &b.Topic,
            &b.StartedAt,
            &b.CompletedAt,
            &b.ExchangeCount,
            &b.Embedding,
            &similarity,
        )
        if err != nil {
            return nil, err
        }

        // Store similarity score in metadata
        b.Metadata = map[string]interface{}{
            "similarity_score": similarity,
            "search_type":      "semantic",
        }

        // Filter by minimum relevance
        if similarity >= opts.MinRelevance {
            blocks = append(blocks, b)
        }
    }

    return blocks, nil
}

// ============================================================================
// KEYWORD SEARCH: PostgreSQL full-text search (fallback)
// ============================================================================

// fullTextSearch performs keyword-based full-text search
func (kg *KnowledgeGraphImpl) fullTextSearch(ctx context.Context, query string, opts SearchOptions) ([]Block, error) {
    // SQL query using PostgreSQL full-text search
    sqlQuery := `
        SELECT
            b.id,
            b.project_id,
            b.topic,
            b.started_at,
            b.completed_at,
            b.exchange_count,
            ts_rank(
                to_tsvector('english', b.topic || ' ' ||
                    COALESCE((
                        SELECT string_agg(e.question || ' ' || e.answer, ' ')
                        FROM exchanges e
                        WHERE e.block_id = b.id
                    ), '')
                ),
                plainto_tsquery('english', $1)
            ) AS rank
        FROM blocks b
        WHERE
            ($2 = '' OR b.project_id = $2::uuid)
            AND to_tsvector('english', b.topic) @@ plainto_tsquery('english', $1)
        ORDER BY rank DESC
        LIMIT $3
    `

    // Execute query
    rows, err := kg.db.QueryContext(ctx, sqlQuery,
        query,
        opts.ProjectID,
        opts.Limit)
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    // Parse results
    var blocks []Block
    for rows.Next() {
        var b Block
        var rank float64

        err := rows.Scan(
            &b.ID,
            &b.ProjectID,
            &b.Topic,
            &b.StartedAt,
            &b.CompletedAt,
            &b.ExchangeCount,
            &rank,
        )
        if err != nil {
            return nil, err
        }

        // Store rank score in metadata
        b.Metadata = map[string]interface{}{
            "rank_score":  rank,
            "search_type": "keyword",
        }

        blocks = append(blocks, b)
    }

    return blocks, nil
}

// ============================================================================
// MERGE AND RANK: Combine semantic + keyword results
// ============================================================================

// mergeAndRank combines results from both search methods
func (kg *KnowledgeGraphImpl) mergeAndRank(semantic, keyword []Block, opts SearchOptions) []Block {
    // Create map to deduplicate results
    blockMap := make(map[string]*Block)

    // Add semantic results (priority)
    for _, b := range semantic {
        b := b  // Create copy
        blockMap[b.ID] = &b
    }

    // Add keyword results, boost score if also in semantic
    for _, b := range keyword {
        if existing, found := blockMap[b.ID]; found {
            // Block found in both searches - boost score
            semanticScore := existing.Metadata["similarity_score"].(float64)
            keywordScore := b.Metadata["rank_score"].(float64)

            // Hybrid score: weighted combination
            // 70% semantic, 30% keyword (semantic prioritized)
            existing.Metadata["hybrid_score"] = (0.7 * semanticScore) + (0.3 * keywordScore)
            existing.Metadata["search_type"] = "hybrid"
        } else {
            // Keyword-only result
            b := b  // Create copy
            blockMap[b.ID] = &b
        }
    }

    // Convert map to slice
    var results []Block
    for _, b := range blockMap {
        results = append(results, *b)
    }

    // Sort by relevance (hybrid > semantic > keyword)
    sort.Slice(results, func(i, j int) bool {
        scoreI := kg.getRelevanceScore(results[i])
        scoreJ := kg.getRelevanceScore(results[j])
        return scoreI > scoreJ
    })

    // Limit results
    if len(results) > opts.Limit {
        results = results[:opts.Limit]
    }

    return results
}

// getRelevanceScore extracts relevance score from block metadata
func (kg *KnowledgeGraphImpl) getRelevanceScore(b Block) float64 {
    if score, ok := b.Metadata["hybrid_score"].(float64); ok {
        return score
    }
    if score, ok := b.Metadata["similarity_score"].(float64); ok {
        return score
    }
    if score, ok := b.Metadata["rank_score"].(float64); ok {
        return score
    }
    return 0.0
}
```

### Search Performance Optimization

**Sub-200ms Goal:**

1. **HNSW Index (pgvector):**
   - Approximate nearest neighbor (not exact)
   - Trade slight accuracy for massive speed
   - Configurable: `m=16, ef_construction=64`
   - 95%+ accuracy, <200ms at 100K blocks

2. **Database Query Optimization:**
   - Index all foreign keys
   - Index project_id for filtering
   - Full-text GIN index for keyword search
   - Connection pooling (reuse connections)

3. **Graceful Degradation:**
   - If embedding fails → keyword only
   - If vector search slow → keyword only
   - If database slow → cached results
   - Never block user on slow search

4. **Monitoring:**
   - Log all searches >200ms
   - Track p50, p95, p99 latencies
   - Alert on degradation
   - Optimize slow queries

---

## Project Detection (Multi-Project Support)

### Directory-Based Project Mapping

```go
package core

import (
    "context"
    "path/filepath"
    "strings"
)

// ============================================================================
// PROJECT DETECTION: Map workspace directory to project
// ============================================================================

// GetOrCreateProject finds project by directory path or creates new one
func (kg *KnowledgeGraphImpl) GetOrCreateProject(ctx context.Context, directoryPath string) (*Project, error) {
    // Normalize path (absolute, clean)
    absPath, err := filepath.Abs(directoryPath)
    if err != nil {
        return nil, err
    }
    absPath = filepath.Clean(absPath)

    // Try to find existing project
    project, err := kg.findProjectByPath(ctx, absPath)
    if err == nil {
        return project, nil
    }

    // Project doesn't exist - create it
    projectName := kg.deriveProjectName(absPath)

    project = &Project{
        Name:          projectName,
        DirectoryPath: absPath,
        Description:   fmt.Sprintf("Auto-created from directory: %s", absPath),
        Metadata: map[string]interface{}{
            "auto_created": true,
            "created_from": "workspace_detection",
        },
    }

    // Insert into database
    err = kg.createProject(ctx, project)
    if err != nil {
        return nil, err
    }

    log.Info("Created new project", "name", projectName, "path", absPath)

    return project, nil
}

// findProjectByPath searches for project by directory path
func (kg *KnowledgeGraphImpl) findProjectByPath(ctx context.Context, path string) (*Project, error) {
    query := `
        SELECT id, name, directory_path, description, metadata, created_at, updated_at
        FROM projects
        WHERE directory_path = $1
    `

    var p Project
    err := kg.db.QueryRowContext(ctx, query, path).Scan(
        &p.ID,
        &p.Name,
        &p.DirectoryPath,
        &p.Description,
        &p.Metadata,
        &p.CreatedAt,
        &p.UpdatedAt,
    )

    if err == sql.ErrNoRows {
        return nil, ErrProjectNotFound
    }
    if err != nil {
        return nil, err
    }

    return &p, nil
}

// deriveProjectName extracts meaningful name from directory path
func (kg *KnowledgeGraphImpl) deriveProjectName(path string) string {
    // Examples:
    // /Users/BertSmith/personal/builder-platform/projects/knowledge-graph-system
    //   → "knowledge-graph-system"
    // /Users/BertSmith/work/api-middleware
    //   → "api-middleware"
    // /Users/BertSmith/personal/real-estate
    //   → "real-estate"

    // Get base name (last component)
    base := filepath.Base(path)

    // Clean up name
    base = strings.ReplaceAll(base, "_", "-")
    base = strings.ToLower(base)

    return base
}
```

### Project Configuration (Optional Manual Mapping)

```yaml
# ~/.knowledge/projects.yaml (optional manual configuration)
projects:
  - name: knowledge-graph-system
    directory: /Users/BertSmith/personal/builder-platform/projects/knowledge-graph-system
    description: Universal context preservation for Builder Platform

  - name: api-middleware
    directory: /Users/BertSmith/work/api-middleware
    description: 3-party API integration middleware

  - name: real-estate
    directory: /Users/BertSmith/personal/real-estate
    description: Lead generation and CRM system

# Auto-created projects also stored in database
# This config file is optional (database is source of truth)
```

---

## Auto-Save Logic (Block Completion Detection)

### Block Completion Triggers

**Trigger 1: Exchange Count (3-5 exchanges)**

```go
// Topic naturally spans 3-5 Q&A pairs
if len(currentBlock.Exchanges) >= config.MaxExchangesPerBlock {
    return true  // Save block
}
```

**Trigger 2: Time Threshold (30 minutes)**

```go
// Long conversation likely switching topics
if time.Since(currentBlock.StartedAt) > config.MaxBlockDuration {
    return true  // Save block
}
```

**Trigger 3: Significant Events**

```go
// Patterns that signal completion:
// - User requests summary
// - Large code generation (>500 lines)
// - File operations complete
// - User says "thanks" / "perfect" / "done"

if detectSignificantEvent(currentBlock) {
    return true  // Save block
}
```

### Significant Event Detection

```go
func detectSignificantEvent(block *IncompleteBlock) bool {
    if len(block.Exchanges) == 0 {
        return false
    }

    lastExchange := block.Exchanges[len(block.Exchanges)-1]

    // Pattern 1: Summary request
    summaryKeywords := []string{"summarize", "recap", "summary", "in summary", "to recap"}
    if containsAny(lastExchange.Question, summaryKeywords) {
        return true
    }

    // Pattern 2: Large code generation
    if countLines(lastExchange.Answer) > 500 {
        return true
    }

    // Pattern 3: Completion phrases
    completionKeywords := []string{
        "that's it", "we're done", "perfect", "thanks", "great, thanks",
        "looks good", "all set", "that works",
    }
    if containsAny(lastExchange.Question, completionKeywords) {
        return true
    }

    // Pattern 4: File write operations (code implementation complete)
    if strings.Contains(lastExchange.Answer, "✓ Wrote") ||
       strings.Contains(lastExchange.Answer, "File written") {
        return true
    }

    return false
}
```

---

## Dogfooding Plan (Use It to Build Itself)

### Week 1 Milestones with Dogfooding

**Day 1-2: Core + Schema**

**Build:**
- PostgreSQL setup
- Schema creation (blocks, exchanges, tags, relationships, projects)
- Basic save/retrieve operations
- Go core package skeleton

**Dogfood:**
- Manually save design notes from this session
- Test: `INSERT INTO blocks (...) VALUES (...)`
- Verify: Can retrieve saved design decisions

**Success:** Database working, can store and retrieve blocks manually

---

**Day 3-4: Search + MCP Skeleton**

**Build:**
- Semantic search (pgvector)
- Keyword search (full-text)
- Hybrid merge and rank
- MCP adapter skeleton (startup, handlers)
- Project detection

**Dogfood:**
- Search for design decisions made Day 1-2
- Test: Vector similarity finds related topics
- Test: Keyword search finds exact phrases
- Verify: Sub-200ms search time

**Success:** Search working, can find past decisions quickly

---

**Day 5-6: Auto-Save + Tags + Relationships**

**Build:**
- Block completion detection
- Tag extraction (Ollama integration)
- Relationship inference (pattern-based)
- Full MCP integration (context injection)

**Dogfood:**
- STOP manually saving conversations
- Let MCP adapter auto-save this session
- Test: Blocks auto-created from conversation
- Test: Tags extracted automatically
- Test: Relationships inferred correctly

**Success:** Auto-save working, hands-off operation

---

**Day 7: Polish + Production Deploy**

**Build:**
- Error handling polish
- Logging improvements
- Performance tuning (sub-200ms consistently)
- Documentation (README, config examples)

**Dogfood:**
- Use EXCLUSIVELY for all Claude Code sessions
- Test: Multiple projects (knowledge-graph, api-middleware)
- Test: Context switching between projects
- Verify: Zero repeated context today

**Success:** Used in production, eliminating context repetition

---

### Dogfooding Validation Checklist

**Day 1-2:**
- [ ] Can save conversation manually
- [ ] Can retrieve saved conversation
- [ ] Database schema supports all required fields

**Day 3-4:**
- [ ] Can search for "PostgreSQL schema" and find Day 1-2 design
- [ ] Search completes in <200ms
- [ ] Results are relevant (not random)
- [ ] Project detection works (correct project ID assigned)

**Day 5-6:**
- [ ] Block auto-saved from conversation (didn't manually trigger)
- [ ] Tags extracted make sense (not gibberish)
- [ ] Relationships detected when referencing prior topics
- [ ] Context injection working (Claude "remembers" things)

**Day 7:**
- [ ] Used exclusively all day
- [ ] Zero context repetition incidents
- [ ] Multi-project switching works (api-middleware + knowledge-graph)
- [ ] Performance stable (no slowdowns)
- [ ] No crashes or errors

**Week 1 Complete:**
- [ ] User stops repeating context
- [ ] System runs automatically (daemon)
- [ ] Search fast and accurate
- [ ] Confidence to continue building

---

## Week 1 Success Criteria

### User-Focused Success Metrics

**Primary Goal: "I STOP LOSING CONTEXT"**

Measured by:
- ✅ Zero repeated instructions within same day
- ✅ Zero "remember when I told you X" moments
- ✅ Claude provides context-aware responses without prompting
- ✅ User doesn't think about context management (it just works)

**Secondary Goals:**

**Technical Reliability:**
- ✅ Search: <200ms (95th percentile)
- ✅ Block save: <50ms
- ✅ Zero data loss (every exchange saved)
- ✅ Graceful degradation (works even if embeddings fail)

**Usability:**
- ✅ Invisible operation (daemon, no manual intervention)
- ✅ Multi-project support working (api-middleware, knowledge-graph, etc)
- ✅ Project switching automatic (workspace directory detection)

**Dogfooding Validation:**
- ✅ This conversation saved as first block
- ✅ API middleware project context preserved
- ✅ Used daily for all Claude Code sessions
- ✅ User prefers this over manual context management

### What This DOESN'T Need to Be

**Not Required Week 1:**
- Perfect UX (CLI is fine, no web UI needed)
- Beautiful output (functional formatting sufficient)
- Feature-complete (just core: save, search, inject)
- Production-scale (local use only, optimize later)

**Must Be:**
- Reliable for basic use case
- Faster than current pain (manual search in files)
- Gives user confidence to continue building
- Solves the immediate problem (context repetition)

---

## Out of Scope (Week 1)

### Deferred to Week 2+

**Not Building Now:**

1. **Web Dashboard**
   - Maybe basic metrics page
   - Not TUI (terminal UI)
   - Not full web app

2. **Gemini Adapter**
   - Rajesh waits one more week
   - Focus on Claude MCP first
   - Prove pattern works before expanding

3. **Advanced Features**
   - Complex graph visualization
   - LLM-based relationship inference (Week 1 = pattern-based)
   - Model routing (comes after multi-model support)
   - Classifier (comes after routing)
   - Tag-based filtering UI (search works, UI later)

4. **Polish**
   - Advanced error recovery
   - Comprehensive test suite (basic tests only)
   - Performance optimization beyond sub-200ms
   - Advanced configuration options

**Why Deferred:**
- Week 1 = stop the bleeding (context repetition)
- Week 2+ = make it better (additional models, polish)
- User needs relief NOW, not perfect system
- Prove core value before expanding

---

## Week 2 Preview (Not in Scope Now)

### After Week 1 Painkiller is Working

**Week 2 Improvements:**

1. **Gemini Adapter**
   - Rajesh gets his Gemini integration
   - Prove adapter pattern works (multiple AI tools)
   - Shared knowledge across Claude + Gemini

2. **Advanced Relationship Inference**
   - LLM-based (sophisticated)
   - Analyze semantic connections
   - Build richer graph structure

3. **Performance Optimization**
   - Tune beyond sub-200ms
   - Optimize for 100K+ blocks
   - Caching strategies

4. **Polish**
   - Better error messages
   - Comprehensive tests
   - Basic metrics dashboard
   - Configuration UI

**But NOT NOW.**

Week 1 = minimal viable painkiller
Week 2+ = make it better

---

## Implementation Notes

### Development Approach

**Daily Checkpoint Pattern:**

```
Day N:
1. Morning: Review previous day's work
2. Build: Focus on day's milestone
3. Test: Manual testing after each feature
4. Dogfood: Use it immediately
5. Evening: Commit working code
6. Deploy: Push to user's machine
```

**Continuous Dogfooding:**
- Use system to build itself from Day 1
- Manual save → auto-save progression
- Immediate feedback loop
- Real usage drives priorities

### Database Migration Strategy

**Week 1: Simple Approach**
- Schema created via SQL file
- Run once during `knowledge init`
- No migration system yet (Week 2+)

**Week 2+: Proper Migrations**
- golang-migrate or similar
- Version schema changes
- Support upgrades without data loss
- Rollback capability

### Error Handling Philosophy

**Graceful Degradation:**
- Search fails → continue without context injection
- Embeddings fail → keyword search only
- Tag extraction fails → continue without tags
- Database slow → cached results

**Fail Fast for Critical:**
- Block save fails → retry, then error
- Database unavailable → clear error message
- Invalid data → reject immediately

**User-Friendly Messages:**
- No stack traces to user
- Clear problem description
- Actionable next steps
- Log details for debugging

---

## Dependencies & Prerequisites

### System Requirements

**Operating System:**
- macOS (primary target, Week 1)
- Linux (Week 2+)
- Windows (Week 3+)

**Tools:**
- PostgreSQL 15+ (vector extension support)
- Go 1.21+
- Ollama (for tag extraction)

### External Dependencies

**Required:**
```
PostgreSQL 15+         - Database with pgvector
Ollama                 - Local LLM for tag extraction
Claude Code            - AI tool being integrated
```

**Optional:**
```
Homebrew               - Package manager (macOS)
Docker                 - Alternative PostgreSQL deployment
```

### Go Dependencies

```go
// go.mod
module github.com/yourusername/knowledge-graph

go 1.21

require (
    github.com/jackc/pgx/v5         v5.4.3   // PostgreSQL driver
    github.com/pgvector/pgvector-go v0.1.1   // pgvector support
    github.com/ollama/ollama-go     v0.1.0   // Ollama client (tag extraction)
    github.com/sashabaranov/go-openai v1.17.9 // OpenAI client (embeddings)
    github.com/google/uuid          v1.4.0   // UUID generation
    go.uber.org/zap                 v1.26.0  // Structured logging
)
```

---

## Alignment with Standards

### Tech Stack Compliance

**From `tech-stack.md`:**
- ✅ Backend: Go (systems, services)
- ✅ Database: PostgreSQL 15+
- ✅ Local Models: Ollama (tag extraction)
- ✅ Logging: Structured (zap)

### Backend Standards Compliance

**From `backend/models.md`:**
- ✅ Timestamps on all tables (created_at, updated_at)
- ✅ Database constraints (NOT NULL, UNIQUE, foreign keys)
- ✅ Appropriate data types (UUID, VECTOR, TEXT, JSONB)
- ✅ Indexes on foreign keys and frequently queried fields

**From `backend/api.md`:**
- ✅ Clear interface definitions (KnowledgeGraph interface)
- ✅ Context-aware methods (context.Context)
- ✅ Appropriate error handling

### Global Standards Compliance

**From `architectural-decisions.md` (2-Way Door Principle):**
- ✅ Core is stable (expensive to build, valuable over time)
- ✅ Adapters are cheap (~200 lines, easy to replace)
- ✅ Hedges against vendor changes (MCP → Skills → future)
- ✅ User owns data (local PostgreSQL)
- ✅ No vendor lock-in (works with any AI tool via adapters)

**From `error-handling.md`:**
- ✅ User-friendly messages (no stack traces)
- ✅ Fail fast for invalid input
- ✅ Graceful degradation (continue without context if search fails)
- ✅ Retry strategies (transient failures)

**From `coding-style.md`:**
- ✅ Meaningful names (no abbreviations)
- ✅ Small, focused functions
- ✅ Clear comments (explain WHY, not WHAT)
- ✅ DRY principle (shared search logic)

---

## Final Notes

### Philosophy: Infrastructure, Not Tool

**This is not a quick hack.**

This is the foundation of knowledge compounding for the next 5-10 years.

**Build it right:**
- Stable core (never rewrite)
- Cheap adapters (swap as needed)
- User ownership (no lock-in)
- Performance from day 1 (sub-200ms)

### User Context: Second-Act Founder

**Remember:**
- Part-time builder (job required, limited time)
- Pattern of quitting (this must succeed)
- Living the pain NOW (context repetition)
- Faith/family boundaries (sustainable pace)

**This Week Matters:**
- Proves the concept works
- Stops immediate pain
- Builds confidence to continue
- Foundation for transformative infrastructure

### Path Forward

**Week 1:** This spec → minimal working system → user relief
**Week 2:** Gemini adapter + polish + advanced features
**Week 3-4:** Model routing, classifier, optimization
**Month 2+:** Full infrastructure vision (graph viz, federation, etc)

But first: **Stop the bleeding. Give the user relief THIS WEEK.**

---

## Specification Complete

**Target Delivery:** 7 days from start to production use

**Success Measure:** User stops repeating context, uses system daily, builds confidence to continue

**Next Step:** Implementation begins Day 1

---

**This is the red pill. Build it right. No shortcuts.**

**"I STOP LOSING CONTEXT."**

Let's make it happen.
