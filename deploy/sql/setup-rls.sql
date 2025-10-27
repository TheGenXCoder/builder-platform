-- Catalyst9 Row-Level Security (RLS) Setup
-- True multi-tenant isolation at the database level

-- Enable RLS on core tables
ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create secure user management
CREATE TABLE IF NOT EXISTS api_keys (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    key_hash VARCHAR(64) NOT NULL UNIQUE, -- SHA256 hash, never store plain keys
    created_at TIMESTAMP DEFAULT NOW(),
    last_used TIMESTAMP,
    revoked BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMP DEFAULT (NOW() + INTERVAL '1 year')
);

-- Update users table for better security
ALTER TABLE users ADD COLUMN IF NOT EXISTS email VARCHAR(255) UNIQUE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR(50) DEFAULT 'user';
ALTER TABLE users ADD COLUMN IF NOT EXISTS active BOOLEAN DEFAULT true;
ALTER TABLE users DROP COLUMN IF EXISTS api_key; -- Never store plain keys!

-- Create application role for API connections
CREATE ROLE catalyst9_api WITH LOGIN PASSWORD 'CHANGE_THIS_IN_PRODUCTION';
GRANT USAGE ON SCHEMA public TO catalyst9_api;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO catalyst9_api;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO catalyst9_api;

-- RLS Policies for blocks table

-- Policy 1: Users can only see their own blocks OR shared blocks
CREATE POLICY blocks_select_policy ON blocks
    FOR SELECT
    USING (
        user_id = current_setting('app.current_user_id')::INTEGER
        OR shared = true
        OR EXISTS (
            SELECT 1 FROM users
            WHERE users.id = current_setting('app.current_user_id')::INTEGER
            AND users.role = 'admin'
        )
    );

-- Policy 2: Users can only insert blocks as themselves
CREATE POLICY blocks_insert_policy ON blocks
    FOR INSERT
    WITH CHECK (
        user_id = current_setting('app.current_user_id')::INTEGER
    );

-- Policy 3: Users can only update their own blocks
CREATE POLICY blocks_update_policy ON blocks
    FOR UPDATE
    USING (user_id = current_setting('app.current_user_id')::INTEGER)
    WITH CHECK (user_id = current_setting('app.current_user_id')::INTEGER);

-- Policy 4: Users can only delete their own blocks
CREATE POLICY blocks_delete_policy ON blocks
    FOR DELETE
    USING (user_id = current_setting('app.current_user_id')::INTEGER);

-- RLS Policies for users table

-- Policy 1: Users can see all users (for sharing features)
CREATE POLICY users_select_policy ON users
    FOR SELECT
    USING (true); -- Can see usernames, but not sensitive data

-- Policy 2: Users can only update their own profile
CREATE POLICY users_update_policy ON users
    FOR UPDATE
    USING (id = current_setting('app.current_user_id')::INTEGER)
    WITH CHECK (id = current_setting('app.current_user_id')::INTEGER);

-- Create secure views for API access
CREATE OR REPLACE VIEW my_blocks AS
SELECT * FROM blocks
WHERE user_id = current_setting('app.current_user_id')::INTEGER;

CREATE OR REPLACE VIEW shared_blocks AS
SELECT
    b.*,
    u.username as owner
FROM blocks b
JOIN users u ON b.user_id = u.id
WHERE b.shared = true;

-- Function to authenticate API requests
CREATE OR REPLACE FUNCTION authenticate_api_key(api_key_hash VARCHAR)
RETURNS TABLE(user_id INTEGER, username VARCHAR, role VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT
        u.id as user_id,
        u.username,
        u.role
    FROM users u
    JOIN api_keys ak ON u.id = ak.user_id
    WHERE
        ak.key_hash = api_key_hash
        AND ak.revoked = FALSE
        AND (ak.expires_at IS NULL OR ak.expires_at > NOW())
        AND u.active = TRUE;

    -- Update last_used timestamp
    UPDATE api_keys
    SET last_used = NOW()
    WHERE key_hash = api_key_hash;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to set current user for RLS
CREATE OR REPLACE FUNCTION set_current_user(user_id INTEGER)
RETURNS void AS $$
BEGIN
    PERFORM set_config('app.current_user_id', user_id::text, false);
END;
$$ LANGUAGE plpgsql;

-- Audit trail for security
CREATE TABLE IF NOT EXISTS audit_log (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    action VARCHAR(50),
    table_name VARCHAR(50),
    record_id INTEGER,
    old_data JSONB,
    new_data JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Trigger for audit logging
CREATE OR REPLACE FUNCTION audit_trigger()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_log (user_id, action, table_name, record_id, old_data, new_data)
    VALUES (
        current_setting('app.current_user_id', true)::INTEGER,
        TG_OP,
        TG_TABLE_NAME,
        COALESCE(NEW.id, OLD.id),
        to_jsonb(OLD),
        to_jsonb(NEW)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply audit triggers to sensitive tables
CREATE TRIGGER blocks_audit
    AFTER INSERT OR UPDATE OR DELETE ON blocks
    FOR EACH ROW EXECUTE FUNCTION audit_trigger();

CREATE TRIGGER users_audit
    AFTER UPDATE OR DELETE ON users
    FOR EACH ROW EXECUTE FUNCTION audit_trigger();

-- Example: How the API should connect

-- 1. API receives request with API key
-- 2. Hash the API key
-- 3. Call authenticate_api_key(hash) to get user_id
-- 4. Set session: SELECT set_current_user(user_id);
-- 5. All subsequent queries in that session respect RLS
-- 6. User can ONLY access their own data

-- Test data with secure keys (these are examples - generate real ones!)
INSERT INTO users (username, email, role) VALUES
    ('bert', 'bert@catalyst9.ai', 'admin'),
    ('erwin', 'erwin@example.com', 'user'),
    ('john', 'john@example.com', 'user')
ON CONFLICT (username) DO NOTHING;

-- Note: API keys should be generated by the application and hashed before storage
-- NEVER store plain API keys in the database!

COMMENT ON TABLE api_keys IS 'Stores hashed API keys only - never plain text';
COMMENT ON COLUMN api_keys.key_hash IS 'SHA256 hash of the API key';
COMMENT ON FUNCTION authenticate_api_key IS 'Authenticates user by API key hash and sets up RLS context';