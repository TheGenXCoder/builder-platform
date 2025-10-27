# Catalyst9 Users & Access

## Active Users

### Bert (Owner)
- **Username:** bert
- **API Key:** sk-catalyst9-bert-2025-001
- **Access:** Full admin, all spaces
- **MCP Config:**
  ```json
  {
    "CATALYST9_USER": "bert",
    "CATALYST9_API_KEY": "sk-catalyst9-bert-2025-001"
  }
  ```

### Erwin (Friend)
- **Username:** erwin
- **API Key:** sk-catalyst9-erwin-2025-001
- **Access:** Personal space + shared
- **MCP Config:**
  ```json
  {
    "CATALYST9_USER": "erwin",
    "CATALYST9_API_KEY": "sk-catalyst9-erwin-2025-001"
  }
  ```

### Test Users

#### Alice (Demo)
- **Username:** alice
- **API Key:** sk-catalyst9-alice-demo-001
- **Access:** Limited demo account

#### Anonymous
- **Username:** anonymous
- **API Key:** (none)
- **Access:** Read-only public knowledge

## Setting Up Access from Any Machine

### 1. Download the MCP wrapper
```bash
curl -O https://raw.githubusercontent.com/TheGenXCoder/builder-platform/main/catalyst-core/projects/knowledge-graph-system/catalyst9-mcp.py
```

### 2. Configure Claude Desktop
Add to `~/.config/claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "catalyst9": {
      "command": "python3",
      "args": ["/path/to/catalyst9-mcp.py"],
      "env": {
        "CATALYST9_API_URL": "https://catalyst9.ai",
        "CATALYST9_USER": "your_username",
        "CATALYST9_API_KEY": "your_api_key"
      }
    }
  }
}
```

### 3. Test Connection
Once configured, Claude can:
- Search YOUR knowledge (not others')
- Add to YOUR knowledge space
- Access shared project knowledge
- See YOUR statistics

## Features by User Type

### Owner (bert)
- Full database access
- User management
- System statistics
- All knowledge spaces
- Admin tools in MCP

### Regular Users (erwin, alice)
- Personal knowledge space
- Shared space access
- Own statistics
- Search across allowed spaces
- Add/edit own content

### Anonymous
- Public knowledge search only
- No write access
- Basic statistics
- Rate limited

## Security Model

1. **Isolation by Default**
   - Each user's knowledge is private
   - No cross-user access without sharing
   - Separate embeddings per user

2. **Explicit Sharing**
   - Users choose what to share
   - Project-level sharing
   - Public knowledge opt-in

3. **API Key Security**
   - Unique per user
   - HTTPS-only transmission
   - Rate limiting per key
   - Revocable

## Database Schema (Multi-Tenant)

```sql
-- Users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    api_key VARCHAR(100) UNIQUE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Blocks with user ownership
CREATE TABLE blocks (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    content TEXT NOT NULL,
    embedding vector(1536),
    shared BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Initial users
INSERT INTO users (username, api_key) VALUES
    ('bert', 'sk-catalyst9-bert-2025-001'),
    ('erwin', 'sk-catalyst9-erwin-2025-001'),
    ('alice', 'sk-catalyst9-alice-demo-001'),
    ('anonymous', NULL);
```

## Repository Information

**GitHub Repo:** https://github.com/TheGenXCoder/builder-platform
**Local Directory:** catalyst-core (within builder-platform)
**Production URL:** https://catalyst9.ai
**MCP Wrapper:** projects/knowledge-graph-system/catalyst9-mcp.py

---

**Note:** The authentication system is being implemented. For now, the API keys above will identify users but won't enforce access control. Full multi-tenant isolation coming soon.