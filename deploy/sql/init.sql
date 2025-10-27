-- Catalyst9 Database Initialization Script
-- Creates the necessary tables and extensions for the knowledge graph

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create schema
CREATE SCHEMA IF NOT EXISTS catalyst9;
SET search_path TO catalyst9, public;

-- Knowledge items table
CREATE TABLE IF NOT EXISTS knowledge_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content TEXT NOT NULL,
    content_type VARCHAR(50) NOT NULL,
    source_file VARCHAR(500),
    source_url VARCHAR(500),
    metadata JSONB DEFAULT '{}',
    embedding vector(768),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Create indexes for knowledge items
CREATE INDEX IF NOT EXISTS idx_knowledge_items_embedding ON knowledge_items
    USING ivfflat (embedding vector_cosine_ops)
    WITH (lists = 100);

CREATE INDEX IF NOT EXISTS idx_knowledge_items_content ON knowledge_items
    USING GIN (to_tsvector('english', content));

CREATE INDEX IF NOT EXISTS idx_knowledge_items_metadata ON knowledge_items
    USING GIN (metadata);

CREATE INDEX IF NOT EXISTS idx_knowledge_items_created_at ON knowledge_items (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_knowledge_items_source_file ON knowledge_items (source_file);

-- User sessions table (for tracking plugin usage)
CREATE TABLE IF NOT EXISTS user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id VARCHAR(255),
    session_token VARCHAR(500) UNIQUE NOT NULL,
    api_key VARCHAR(500),
    editor_type VARCHAR(50), -- 'neovim', 'vscode', etc.
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_active_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_user_sessions_token ON user_sessions (session_token);
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON user_sessions (user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_expires ON user_sessions (expires_at);

-- Chat history table
CREATE TABLE IF NOT EXISTS chat_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID REFERENCES user_sessions(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL, -- 'user' or 'assistant'
    message TEXT NOT NULL,
    context JSONB DEFAULT '{}',
    tokens_used INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_chat_history_session ON chat_history (session_id);
CREATE INDEX IF NOT EXISTS idx_chat_history_created ON chat_history (created_at DESC);

-- Search queries table (for analytics and improvement)
CREATE TABLE IF NOT EXISTS search_queries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID REFERENCES user_sessions(id) ON DELETE SET NULL,
    query TEXT NOT NULL,
    query_embedding vector(768),
    results_count INTEGER DEFAULT 0,
    selected_result_id UUID,
    feedback_score INTEGER CHECK (feedback_score >= 1 AND feedback_score <= 5),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_search_queries_session ON search_queries (session_id);
CREATE INDEX IF NOT EXISTS idx_search_queries_embedding ON search_queries
    USING ivfflat (query_embedding vector_cosine_ops)
    WITH (lists = 100);

-- Code edits table (track AI-assisted edits)
CREATE TABLE IF NOT EXISTS code_edits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID REFERENCES user_sessions(id) ON DELETE CASCADE,
    file_path VARCHAR(500) NOT NULL,
    original_content TEXT,
    edited_content TEXT,
    diff TEXT,
    edit_type VARCHAR(50), -- 'refactor', 'fix', 'feature', etc.
    accepted BOOLEAN,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_code_edits_session ON code_edits (session_id);
CREATE INDEX IF NOT EXISTS idx_code_edits_file ON code_edits (file_path);
CREATE INDEX IF NOT EXISTS idx_code_edits_created ON code_edits (created_at DESC);

-- Git commits table (track AI-generated commits)
CREATE TABLE IF NOT EXISTS git_commits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID REFERENCES user_sessions(id) ON DELETE CASCADE,
    repo_path VARCHAR(500) NOT NULL,
    commit_hash VARCHAR(100),
    commit_message TEXT NOT NULL,
    files_changed JSONB DEFAULT '[]',
    accepted BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_git_commits_session ON git_commits (session_id);
CREATE INDEX IF NOT EXISTS idx_git_commits_repo ON git_commits (repo_path);

-- API keys table
CREATE TABLE IF NOT EXISTS api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key_hash VARCHAR(256) UNIQUE NOT NULL,
    user_email VARCHAR(255),
    name VARCHAR(100),
    permissions JSONB DEFAULT '{"read": true, "write": true}',
    rate_limit INTEGER DEFAULT 1000, -- requests per hour
    usage_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    revoked_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_api_keys_hash ON api_keys (key_hash);
CREATE INDEX IF NOT EXISTS idx_api_keys_email ON api_keys (user_email);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for knowledge_items
CREATE TRIGGER update_knowledge_items_updated_at
    BEFORE UPDATE ON knowledge_items
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Grant permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA catalyst9 TO catalyst9;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA catalyst9 TO catalyst9;
GRANT ALL PRIVILEGES ON SCHEMA catalyst9 TO catalyst9;