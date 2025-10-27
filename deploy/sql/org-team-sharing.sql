-- Catalyst9 Organization & Team Knowledge Sharing
-- Enables collaborative knowledge while maintaining zero-knowledge auth

-- Organizations (companies, projects, etc.)
CREATE TABLE IF NOT EXISTS organizations (
    id SERIAL PRIMARY KEY,
    slug VARCHAR(50) UNIQUE NOT NULL, -- e.g., 'uta', 'catalyst9', 'acme-corp'
    name VARCHAR(255) NOT NULL, -- 'University of Texas Arlington'
    description TEXT,
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    settings JSONB DEFAULT '{}', -- org-specific settings
    is_active BOOLEAN DEFAULT true
);

-- Teams within organizations
CREATE TABLE IF NOT EXISTS teams (
    id SERIAL PRIMARY KEY,
    org_id INTEGER REFERENCES organizations(id) ON DELETE CASCADE,
    slug VARCHAR(50) NOT NULL, -- e.g., 'engineering', 'marketing'
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    settings JSONB DEFAULT '{}',
    UNIQUE(org_id, slug)
);

-- Organization membership
CREATE TABLE IF NOT EXISTS org_members (
    id SERIAL PRIMARY KEY,
    org_id INTEGER REFERENCES organizations(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL DEFAULT 'member', -- 'owner', 'admin', 'member', 'viewer'
    joined_at TIMESTAMP DEFAULT NOW(),
    invited_by INTEGER REFERENCES users(id),
    is_active BOOLEAN DEFAULT true,
    UNIQUE(org_id, user_id)
);

-- Team membership
CREATE TABLE IF NOT EXISTS team_members (
    id SERIAL PRIMARY KEY,
    team_id INTEGER REFERENCES teams(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(50) DEFAULT 'member', -- 'lead', 'member'
    joined_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(team_id, user_id)
);

-- Knowledge spaces (different sharing contexts)
CREATE TABLE IF NOT EXISTS knowledge_spaces (
    id SERIAL PRIMARY KEY,
    space_type VARCHAR(50) NOT NULL, -- 'personal', 'org', 'team', 'public'
    owner_id INTEGER, -- user_id for personal, null for others
    org_id INTEGER REFERENCES organizations(id),
    team_id INTEGER REFERENCES teams(id),
    name VARCHAR(255),
    description TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    settings JSONB DEFAULT '{}', -- visibility, permissions, etc.
    CONSTRAINT valid_space CHECK (
        (space_type = 'personal' AND owner_id IS NOT NULL) OR
        (space_type = 'org' AND org_id IS NOT NULL) OR
        (space_type = 'team' AND team_id IS NOT NULL) OR
        (space_type = 'public')
    )
);

-- Update blocks table to support spaces
ALTER TABLE blocks ADD COLUMN IF NOT EXISTS space_id INTEGER REFERENCES knowledge_spaces(id);
ALTER TABLE blocks ADD COLUMN IF NOT EXISTS org_id INTEGER REFERENCES organizations(id);
ALTER TABLE blocks ADD COLUMN IF NOT EXISTS team_id INTEGER REFERENCES teams(id);
ALTER TABLE blocks ADD COLUMN IF NOT EXISTS visibility VARCHAR(50) DEFAULT 'private';
-- 'private', 'org', 'team', 'public'

-- Sharing permissions for specific blocks
CREATE TABLE IF NOT EXISTS block_permissions (
    id SERIAL PRIMARY KEY,
    block_id INTEGER REFERENCES blocks(id) ON DELETE CASCADE,
    granted_to_user_id INTEGER REFERENCES users(id),
    granted_to_org_id INTEGER REFERENCES organizations(id),
    granted_to_team_id INTEGER REFERENCES teams(id),
    permission VARCHAR(50) DEFAULT 'read', -- 'read', 'write', 'admin'
    granted_by INTEGER REFERENCES users(id),
    granted_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP,
    CONSTRAINT has_grantee CHECK (
        granted_to_user_id IS NOT NULL OR
        granted_to_org_id IS NOT NULL OR
        granted_to_team_id IS NOT NULL
    )
);

-- Projects (cross-org collaborations like UTA work)
CREATE TABLE IF NOT EXISTS projects (
    id SERIAL PRIMARY KEY,
    slug VARCHAR(100) UNIQUE NOT NULL, -- 'uta-api-integration'
    name VARCHAR(255) NOT NULL,
    description TEXT,
    primary_org_id INTEGER REFERENCES organizations(id),
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    settings JSONB DEFAULT '{}'
);

-- Project collaborators (users from different orgs)
CREATE TABLE IF NOT EXISTS project_collaborators (
    id SERIAL PRIMARY KEY,
    project_id INTEGER REFERENCES projects(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id),
    org_id INTEGER REFERENCES organizations(id), -- which org they represent
    role VARCHAR(50) DEFAULT 'contributor', -- 'owner', 'lead', 'contributor', 'viewer'
    added_at TIMESTAMP DEFAULT NOW(),
    added_by INTEGER REFERENCES users(id),
    UNIQUE(project_id, user_id)
);

-- Project knowledge (shared across orgs)
CREATE TABLE IF NOT EXISTS project_knowledge (
    id SERIAL PRIMARY KEY,
    project_id INTEGER REFERENCES projects(id) ON DELETE CASCADE,
    block_id INTEGER REFERENCES blocks(id) ON DELETE CASCADE,
    added_by INTEGER REFERENCES users(id),
    added_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(project_id, block_id)
);

-- RLS Policies for organizations

-- Users can see orgs they belong to
CREATE POLICY org_member_select ON organizations
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM org_members om
            WHERE om.org_id = organizations.id
            AND om.user_id = current_setting('app.current_user_id')::INTEGER
            AND om.is_active = true
        )
        OR is_active = true -- Public orgs visible to all
    );

-- Only org admins can update org
CREATE POLICY org_admin_update ON organizations
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM org_members om
            WHERE om.org_id = organizations.id
            AND om.user_id = current_setting('app.current_user_id')::INTEGER
            AND om.role IN ('owner', 'admin')
        )
    );

-- RLS for blocks with org/team sharing

DROP POLICY IF EXISTS blocks_select_policy ON blocks;
CREATE POLICY blocks_select_enhanced ON blocks
    FOR SELECT
    USING (
        -- Own blocks
        user_id = current_setting('app.current_user_id')::INTEGER

        -- Public blocks
        OR visibility = 'public'

        -- Org blocks (if member)
        OR (visibility = 'org' AND EXISTS (
            SELECT 1 FROM org_members om
            WHERE om.org_id = blocks.org_id
            AND om.user_id = current_setting('app.current_user_id')::INTEGER
            AND om.is_active = true
        ))

        -- Team blocks (if member)
        OR (visibility = 'team' AND EXISTS (
            SELECT 1 FROM team_members tm
            WHERE tm.team_id = blocks.team_id
            AND tm.user_id = current_setting('app.current_user_id')::INTEGER
        ))

        -- Explicitly shared with user
        OR EXISTS (
            SELECT 1 FROM block_permissions bp
            WHERE bp.block_id = blocks.id
            AND bp.granted_to_user_id = current_setting('app.current_user_id')::INTEGER
            AND (bp.expires_at IS NULL OR bp.expires_at > NOW())
        )

        -- Project knowledge
        OR EXISTS (
            SELECT 1 FROM project_knowledge pk
            JOIN project_collaborators pc ON pk.project_id = pc.project_id
            WHERE pk.block_id = blocks.id
            AND pc.user_id = current_setting('app.current_user_id')::INTEGER
        )
    );

-- Functions for org management

-- Create organization
CREATE OR REPLACE FUNCTION create_organization(
    p_slug VARCHAR,
    p_name VARCHAR,
    p_description TEXT,
    p_user_id INTEGER
) RETURNS INTEGER AS $$
DECLARE
    v_org_id INTEGER;
BEGIN
    INSERT INTO organizations (slug, name, description, created_by)
    VALUES (p_slug, p_name, p_description, p_user_id)
    RETURNING id INTO v_org_id;

    -- Creator becomes owner
    INSERT INTO org_members (org_id, user_id, role, invited_by)
    VALUES (v_org_id, p_user_id, 'owner', p_user_id);

    -- Create default spaces
    INSERT INTO knowledge_spaces (space_type, org_id, name)
    VALUES
        ('org', v_org_id, p_name || ' - General'),
        ('org', v_org_id, p_name || ' - Private');

    RETURN v_org_id;
END;
$$ LANGUAGE plpgsql;

-- Add user to organization
CREATE OR REPLACE FUNCTION add_org_member(
    p_org_id INTEGER,
    p_username VARCHAR,
    p_role VARCHAR,
    p_invited_by INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    v_user_id INTEGER;
BEGIN
    SELECT id INTO v_user_id FROM users WHERE username = p_username;

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User % not found', p_username;
    END IF;

    INSERT INTO org_members (org_id, user_id, role, invited_by)
    VALUES (p_org_id, v_user_id, p_role, p_invited_by)
    ON CONFLICT (org_id, user_id)
    DO UPDATE SET role = p_role, is_active = true;

    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Share knowledge with organization
CREATE OR REPLACE FUNCTION share_with_org(
    p_block_id INTEGER,
    p_org_id INTEGER,
    p_user_id INTEGER
) RETURNS BOOLEAN AS $$
BEGIN
    -- Verify user owns the block or has admin rights
    IF NOT EXISTS (
        SELECT 1 FROM blocks
        WHERE id = p_block_id
        AND user_id = p_user_id
    ) THEN
        RAISE EXCEPTION 'You do not own this block';
    END IF;

    -- Update block visibility
    UPDATE blocks
    SET visibility = 'org', org_id = p_org_id
    WHERE id = p_block_id;

    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Get user's organizations
CREATE OR REPLACE FUNCTION get_user_orgs(p_user_id INTEGER)
RETURNS TABLE (
    org_id INTEGER,
    slug VARCHAR,
    name VARCHAR,
    role VARCHAR,
    member_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        o.id,
        o.slug,
        o.name,
        om.role,
        COUNT(om2.user_id) as member_count
    FROM organizations o
    JOIN org_members om ON o.id = om.org_id
    LEFT JOIN org_members om2 ON o.id = om2.org_id AND om2.is_active = true
    WHERE om.user_id = p_user_id
    AND om.is_active = true
    GROUP BY o.id, o.slug, o.name, om.role
    ORDER BY o.name;
END;
$$ LANGUAGE plpgsql;

-- Views for easy access

CREATE OR REPLACE VIEW user_accessible_knowledge AS
SELECT
    b.*,
    CASE
        WHEN b.user_id = current_setting('app.current_user_id')::INTEGER THEN 'owned'
        WHEN b.visibility = 'public' THEN 'public'
        WHEN b.visibility = 'org' THEN 'org-shared'
        WHEN b.visibility = 'team' THEN 'team-shared'
        ELSE 'granted'
    END as access_type,
    o.name as org_name,
    t.name as team_name,
    u.username as owner
FROM blocks b
LEFT JOIN organizations o ON b.org_id = o.id
LEFT JOIN teams t ON b.team_id = t.id
LEFT JOIN users u ON b.user_id = u.id
WHERE
    -- Apply same rules as RLS policy
    b.user_id = current_setting('app.current_user_id')::INTEGER
    OR b.visibility = 'public'
    OR (b.visibility = 'org' AND EXISTS (
        SELECT 1 FROM org_members om
        WHERE om.org_id = b.org_id
        AND om.user_id = current_setting('app.current_user_id')::INTEGER
        AND om.is_active = true
    ));

-- Example organizations
INSERT INTO organizations (slug, name, description) VALUES
    ('catalyst9', 'Catalyst9', 'Knowledge Graph Platform'),
    ('uta', 'University of Texas Arlington', 'UTA API Integration Project'),
    ('personal', 'Personal Projects', 'Individual work and notes')
ON CONFLICT (slug) DO NOTHING;

-- Indexes for performance
CREATE INDEX idx_blocks_visibility ON blocks(visibility);
CREATE INDEX idx_blocks_org ON blocks(org_id) WHERE org_id IS NOT NULL;
CREATE INDEX idx_blocks_team ON blocks(team_id) WHERE team_id IS NOT NULL;
CREATE INDEX idx_org_members_user ON org_members(user_id) WHERE is_active = true;
CREATE INDEX idx_team_members_user ON team_members(user_id);
CREATE INDEX idx_project_collaborators_user ON project_collaborators(user_id);

COMMENT ON TABLE organizations IS 'Organizations enable knowledge sharing between members';
COMMENT ON TABLE teams IS 'Teams are sub-groups within organizations';
COMMENT ON TABLE projects IS 'Projects enable cross-organization collaboration (e.g., UTA work)';
COMMENT ON COLUMN blocks.visibility IS 'Controls who can see this block: private, org, team, or public';