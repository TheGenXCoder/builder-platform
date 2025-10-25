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

-- Organizations (multi-tenant foundation - Week 1.5+)
CREATE TABLE IF NOT EXISTS organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    tier TEXT DEFAULT 'individual', -- "individual", "team", "enterprise"
    compliance_level TEXT[], -- ["hipaa", "soc2", "gdpr"]
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default organizations
INSERT INTO organizations (name, tier)
VALUES ('personal', 'individual')
ON CONFLICT (name) DO NOTHING;

-- Projects belong to organizations
ALTER TABLE projects ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES organizations(id) DEFAULT (SELECT id FROM organizations WHERE name = 'personal');

-- Blocks have visibility levels
ALTER TABLE blocks ADD COLUMN IF NOT EXISTS visibility TEXT DEFAULT 'org-private';
-- Values: "public", "org-private", "anonymized", "individual"

ALTER TABLE blocks ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES organizations(id) DEFAULT (SELECT id FROM organizations WHERE name = 'personal');

-- Source attribution for blocks (public knowledge)
ALTER TABLE blocks ADD COLUMN IF NOT EXISTS source_url TEXT; -- Original source URL
ALTER TABLE blocks ADD COLUMN IF NOT EXISTS source_attribution TEXT; -- Citation text

-- Import history tracking (Week 1.5)
CREATE TABLE IF NOT EXISTS import_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_file TEXT NOT NULL,
    file_hash TEXT NOT NULL,
    imported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    block_count INT NOT NULL,
    import_type TEXT NOT NULL, -- "conversation-log", "spec", "doc", "working-file"
    status TEXT DEFAULT 'completed', -- "in-progress", "completed", "failed"
    error_message TEXT,

    -- Visibility and organization tracking
    visibility TEXT DEFAULT 'org-private', -- "public", "org-private", "individual"
    source_classification TEXT, -- "public-web", "private-repo", "client-data", "personal"
    organization_id UUID REFERENCES organizations(id),

    UNIQUE(source_file, file_hash)
);

-- Source tracking for blocks (enables reimport and updates)
ALTER TABLE blocks ADD COLUMN IF NOT EXISTS source_file TEXT;
ALTER TABLE blocks ADD COLUMN IF NOT EXISTS source_type TEXT; -- "conversation-log", "spec", etc.
ALTER TABLE blocks ADD COLUMN IF NOT EXISTS source_hash TEXT;
ALTER TABLE blocks ADD COLUMN IF NOT EXISTS import_batch_id UUID REFERENCES import_history(id) ON DELETE SET NULL;

-- Public knowledge pool (future - Week 2+)
CREATE TABLE IF NOT EXISTS public_knowledge (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    block_id UUID REFERENCES blocks(id) ON DELETE CASCADE,
    source_url TEXT NOT NULL,
    source_type TEXT, -- "stackoverflow", "github", "documentation"
    verified BOOLEAN DEFAULT FALSE,
    contribution_count INT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for import queries
CREATE INDEX IF NOT EXISTS idx_import_history_source_file ON import_history(source_file);
CREATE INDEX IF NOT EXISTS idx_import_history_status ON import_history(status);
CREATE INDEX IF NOT EXISTS idx_import_history_org ON import_history(organization_id);
CREATE INDEX IF NOT EXISTS idx_blocks_source ON blocks(source_file, source_hash);
CREATE INDEX IF NOT EXISTS idx_blocks_visibility ON blocks(visibility, organization_id);
CREATE INDEX IF NOT EXISTS idx_blocks_org ON blocks(organization_id);
CREATE INDEX IF NOT EXISTS idx_public_knowledge_url ON public_knowledge(source_url);

-- Insert default project for current work
INSERT INTO projects (name, directory_path)
VALUES ('builder-platform', '/Users/BertSmith/personal/builder-platform')
ON CONFLICT (directory_path) DO NOTHING;
