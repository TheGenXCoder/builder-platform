-- Knowledge Graph System - Week 1 Schema
-- Block-based storage with pgvector semantic search

-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Projects (multi-project support)
CREATE TABLE IF NOT EXISTS projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    directory_path TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Conversation blocks (atomic unit of knowledge)
CREATE TABLE IF NOT EXISTS blocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
    topic VARCHAR(500) NOT NULL,
    started_at TIMESTAMP NOT NULL,
    completed_at TIMESTAMP,
    exchange_count INT DEFAULT 0,
    embedding VECTOR(768),  -- nomic-embed-text produces 768-dim vectors
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Individual exchanges within blocks
CREATE TABLE IF NOT EXISTS exchanges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    block_id UUID REFERENCES blocks(id) ON DELETE CASCADE,
    sequence INT NOT NULL,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    model_used VARCHAR(100),
    embedding VECTOR(768),
    UNIQUE(block_id, sequence)
);

-- Tags (extracted automatically)
CREATE TABLE IF NOT EXISTS tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Block-to-tag relationships (many-to-many)
CREATE TABLE IF NOT EXISTS block_tags (
    block_id UUID REFERENCES blocks(id) ON DELETE CASCADE,
    tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
    confidence FLOAT DEFAULT 1.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (block_id, tag_id)
);

-- Block-to-block relationships (graph)
CREATE TABLE IF NOT EXISTS block_relationships (
    from_block_id UUID REFERENCES blocks(id) ON DELETE CASCADE,
    to_block_id UUID REFERENCES blocks(id) ON DELETE CASCADE,
    relationship_type VARCHAR(50) NOT NULL,  -- derived-from, related-to, implements, etc
    confidence FLOAT DEFAULT 1.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (from_block_id, to_block_id, relationship_type)
);

-- Indexes for performance (sub-200ms search goal)
CREATE INDEX IF NOT EXISTS idx_blocks_project ON blocks(project_id);
CREATE INDEX IF NOT EXISTS idx_blocks_topic ON blocks USING gin(to_tsvector('english', topic));
CREATE INDEX IF NOT EXISTS idx_blocks_created ON blocks(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_blocks_embedding ON blocks USING hnsw (embedding vector_cosine_ops);

CREATE INDEX IF NOT EXISTS idx_exchanges_block ON exchanges(block_id, sequence);
CREATE INDEX IF NOT EXISTS idx_exchanges_timestamp ON exchanges(timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_tags_name ON tags(name);

CREATE INDEX IF NOT EXISTS idx_block_tags_block ON block_tags(block_id);
CREATE INDEX IF NOT EXISTS idx_block_tags_tag ON block_tags(tag_id);

CREATE INDEX IF NOT EXISTS idx_block_relationships_from ON block_relationships(from_block_id);
CREATE INDEX IF NOT EXISTS idx_block_relationships_to ON block_relationships(to_block_id);

-- Full-text search support
CREATE INDEX IF NOT EXISTS idx_exchanges_fts ON exchanges
    USING gin(to_tsvector('english', question || ' ' || answer));

-- Update timestamps trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_blocks_updated_at BEFORE UPDATE ON blocks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert default project for current work
INSERT INTO projects (name, directory_path)
VALUES ('builder-platform', '/Users/BertSmith/personal/builder-platform')
ON CONFLICT (directory_path) DO NOTHING;
