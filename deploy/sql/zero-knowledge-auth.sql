-- Catalyst9 Zero-Knowledge Authentication Schema
-- Private keys are NEVER stored - only public keys and encrypted data

-- Invite codes table
CREATE TABLE IF NOT EXISTS invites (
    id SERIAL PRIMARY KEY,
    invite_hash VARCHAR(64) UNIQUE NOT NULL, -- SHA256 of invite code
    username VARCHAR(50) NOT NULL,
    inviter_id INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP DEFAULT (NOW() + INTERVAL '7 days'),
    used BOOLEAN DEFAULT FALSE,
    used_at TIMESTAMP,
    used_by_email VARCHAR(255)
);

-- Update users table for zero-knowledge auth
ALTER TABLE users ADD COLUMN IF NOT EXISTS public_key TEXT; -- RSA public key PEM
ALTER TABLE users ADD COLUMN IF NOT EXISTS encrypted_api_key TEXT; -- API key encrypted with public key
ALTER TABLE users ADD COLUMN IF NOT EXISTS recovery_hash VARCHAR(64); -- Hash of recovery phrases
ALTER TABLE users ADD COLUMN IF NOT EXISTS registration_method VARCHAR(50) DEFAULT 'legacy'; -- 'legacy' or 'zero-knowledge'
ALTER TABLE users ADD COLUMN IF NOT EXISTS invite_used VARCHAR(64) REFERENCES invites(invite_hash);

-- Encrypted user data (only accessible with private key)
CREATE TABLE IF NOT EXISTS encrypted_user_data (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    data_type VARCHAR(50), -- 'preferences', 'settings', 'notes', etc.
    encrypted_data TEXT, -- Encrypted with user's public key
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- API key table update for zero-knowledge
ALTER TABLE api_keys ADD COLUMN IF NOT EXISTS is_encrypted BOOLEAN DEFAULT FALSE;
ALTER TABLE api_keys ADD COLUMN IF NOT EXISTS decryption_method VARCHAR(50); -- 'rsa-oaep-sha256'

-- Audit trail for invites
CREATE TABLE IF NOT EXISTS invite_audit (
    id SERIAL PRIMARY KEY,
    action VARCHAR(50), -- 'created', 'used', 'expired', 'revoked'
    invite_hash VARCHAR(64),
    username VARCHAR(50),
    inviter VARCHAR(50),
    email VARCHAR(255),
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Recovery attempt tracking (for security)
CREATE TABLE IF NOT EXISTS recovery_attempts (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50),
    recovery_hash_attempted VARCHAR(64),
    success BOOLEAN,
    ip_address INET,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Functions for zero-knowledge auth

-- Function to create an invite
CREATE OR REPLACE FUNCTION create_invite(
    p_username VARCHAR,
    p_inviter_id INTEGER,
    p_invite_hash VARCHAR
) RETURNS TABLE(success BOOLEAN, message TEXT) AS $$
BEGIN
    -- Check if username already exists or has pending invite
    IF EXISTS (SELECT 1 FROM users WHERE username = p_username) THEN
        RETURN QUERY SELECT FALSE, 'Username already exists';
    END IF;

    IF EXISTS (SELECT 1 FROM invites WHERE username = p_username AND used = FALSE AND expires_at > NOW()) THEN
        RETURN QUERY SELECT FALSE, 'Active invite already exists for this username';
    END IF;

    -- Create invite
    INSERT INTO invites (invite_hash, username, inviter_id)
    VALUES (p_invite_hash, p_username, p_inviter_id);

    -- Log to audit
    INSERT INTO invite_audit (action, invite_hash, username, inviter)
    SELECT 'created', p_invite_hash, p_username, u.username
    FROM users u WHERE u.id = p_inviter_id;

    RETURN QUERY SELECT TRUE, 'Invite created successfully';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to register with zero-knowledge auth
CREATE OR REPLACE FUNCTION register_zero_knowledge(
    p_invite_hash VARCHAR,
    p_email VARCHAR,
    p_public_key TEXT,
    p_encrypted_api_key TEXT,
    p_api_key_hash VARCHAR,
    p_recovery_hash VARCHAR
) RETURNS TABLE(success BOOLEAN, message TEXT, user_id INTEGER, username VARCHAR) AS $$
DECLARE
    v_username VARCHAR;
    v_user_id INTEGER;
BEGIN
    -- Validate invite
    SELECT i.username INTO v_username
    FROM invites i
    WHERE i.invite_hash = p_invite_hash
      AND i.used = FALSE
      AND i.expires_at > NOW();

    IF v_username IS NULL THEN
        RETURN QUERY SELECT FALSE, 'Invalid or expired invite code', NULL::INTEGER, NULL::VARCHAR;
        RETURN;
    END IF;

    -- Create user
    INSERT INTO users (username, email, public_key, encrypted_api_key, recovery_hash, registration_method, invite_used, role)
    VALUES (v_username, p_email, p_public_key, p_encrypted_api_key, p_recovery_hash, 'zero-knowledge', p_invite_hash, 'user')
    RETURNING id INTO v_user_id;

    -- Store encrypted API key info
    INSERT INTO api_keys (user_id, key_hash, is_encrypted, decryption_method)
    VALUES (v_user_id, p_api_key_hash, TRUE, 'rsa-oaep-sha256');

    -- Mark invite as used
    UPDATE invites
    SET used = TRUE,
        used_at = NOW(),
        used_by_email = p_email
    WHERE invite_hash = p_invite_hash;

    -- Audit log
    INSERT INTO invite_audit (action, invite_hash, username, email)
    VALUES ('used', p_invite_hash, v_username, p_email);

    RETURN QUERY SELECT TRUE, 'Registration successful', v_user_id, v_username;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to verify recovery phrases
CREATE OR REPLACE FUNCTION verify_recovery_phrases(
    p_username VARCHAR,
    p_recovery_hash VARCHAR
) RETURNS BOOLEAN AS $$
DECLARE
    v_stored_hash VARCHAR;
BEGIN
    SELECT recovery_hash INTO v_stored_hash
    FROM users
    WHERE username = p_username;

    -- Log attempt
    INSERT INTO recovery_attempts (username, recovery_hash_attempted, success)
    VALUES (p_username, p_recovery_hash, v_stored_hash = p_recovery_hash);

    RETURN v_stored_hash = p_recovery_hash;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Clean up expired invites
CREATE OR REPLACE FUNCTION cleanup_expired_invites() RETURNS void AS $$
BEGIN
    UPDATE invites
    SET used = TRUE
    WHERE expires_at < NOW()
      AND used = FALSE;

    INSERT INTO invite_audit (action, invite_hash, username)
    SELECT 'expired', invite_hash, username
    FROM invites
    WHERE expires_at < NOW()
      AND used = FALSE;
END;
$$ LANGUAGE plpgsql;

-- Scheduled cleanup (run daily)
-- SELECT cron.schedule('cleanup-invites', '0 0 * * *', 'SELECT cleanup_expired_invites();');

-- Views for admin dashboard

CREATE OR REPLACE VIEW invite_status AS
SELECT
    i.username,
    u.username as inviter,
    i.created_at,
    i.expires_at,
    i.used,
    i.used_at,
    i.used_by_email,
    CASE
        WHEN i.used THEN 'used'
        WHEN i.expires_at < NOW() THEN 'expired'
        ELSE 'pending'
    END as status
FROM invites i
LEFT JOIN users u ON i.inviter_id = u.id
ORDER BY i.created_at DESC;

CREATE OR REPLACE VIEW user_auth_methods AS
SELECT
    username,
    email,
    registration_method,
    CASE WHEN public_key IS NOT NULL THEN TRUE ELSE FALSE END as has_public_key,
    CASE WHEN encrypted_api_key IS NOT NULL THEN TRUE ELSE FALSE END as has_encrypted_api,
    created_at
FROM users
ORDER BY created_at DESC;

-- Indexes for performance
CREATE INDEX idx_invites_hash ON invites(invite_hash);
CREATE INDEX idx_invites_username ON invites(username);
CREATE INDEX idx_invites_expires ON invites(expires_at) WHERE used = FALSE;
CREATE INDEX idx_recovery_attempts_username ON recovery_attempts(username);
CREATE INDEX idx_recovery_attempts_created ON recovery_attempts(created_at);

-- Initial data
INSERT INTO users (username, email, role, registration_method)
VALUES ('admin', 'admin@catalyst9.ai', 'admin', 'legacy')
ON CONFLICT (username) DO NOTHING;

COMMENT ON TABLE invites IS 'Stores invite code hashes - actual codes never stored';
COMMENT ON COLUMN users.public_key IS 'RSA public key for encrypting user data';
COMMENT ON COLUMN users.encrypted_api_key IS 'API key encrypted with public key - can only be decrypted with private key';
COMMENT ON COLUMN users.recovery_hash IS 'SHA256 of recovery phrases - used for account recovery verification';