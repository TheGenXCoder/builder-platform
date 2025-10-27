# Organization & Team Knowledge Sharing

## Overview

Catalyst9 supports multiple levels of knowledge sharing while maintaining zero-knowledge authentication:

```
┌─────────────────────────────────────────┐
│            Knowledge Spaces              │
├─────────────────────────────────────────┤
│ 🔒 Personal (Default)                    │
│    └─ Only you can access               │
│                                          │
│ 👥 Team                                  │
│    └─ Your team members                 │
│                                          │
│ 🏢 Organization                          │
│    └─ Anyone in your org (e.g., UTA)   │
│                                          │
│ 🤝 Project                               │
│    └─ Cross-org collaborators           │
│                                          │
│ 🌍 Public                                │
│    └─ Everyone can access               │
└─────────────────────────────────────────┘
```

## How It Works

### 1. Personal Knowledge (Default)
```sql
-- By default, everything is private
INSERT INTO blocks (user_id, content, visibility)
VALUES (your_id, 'Private note', 'private');
```
- Only you can see it
- Encrypted with your keys
- Never shared unless you explicitly choose

### 2. Organization Sharing
```sql
-- Share with your organization (e.g., UTA)
UPDATE blocks SET visibility = 'org', org_id = [uta_id]
WHERE id = [block_id];
```
- All UTA members can access
- Still encrypted at rest
- RLS enforces org boundaries

### 3. Team Sharing
```sql
-- Share with specific team
UPDATE blocks SET visibility = 'team', team_id = [engineering_team_id]
WHERE id = [block_id];
```
- Only team members see it
- Useful for department-specific knowledge

### 4. Project Collaboration
```sql
-- Cross-org project (e.g., UTA API work)
INSERT INTO projects (slug, name)
VALUES ('uta-api', 'UTA API Integration');

-- Add collaborators from different orgs
INSERT INTO project_collaborators (project_id, user_id, org_id)
VALUES
  ([project_id], [bert_id], [catalyst9_org]),
  ([project_id], [uta_user_id], [uta_org]);
```

## Example: UTA Work

### Setting Up UTA Organization
```bash
# As admin, create UTA org
SELECT create_organization('uta', 'University of Texas Arlington', 'API Integration Project', [your_user_id]);

# Add team members
SELECT add_org_member([uta_org_id], 'john', 'member', [your_user_id]);
SELECT add_org_member([uta_org_id], 'alice', 'member', [your_user_id]);
```

### Sharing UTA Knowledge
```python
# In your MCP or API
def add_uta_knowledge(content):
    """Add knowledge visible to all UTA team members"""
    return api.add_knowledge(
        content=content,
        visibility='org',
        org_id='uta',
        tags=['uta', 'api', 'integration']
    )
```

### Searching Across Spaces
```python
# Search your personal + UTA knowledge
results = api.search(
    query="API endpoint",
    spaces=['personal', 'org:uta']
)

# Search everything you have access to
results = api.search(
    query="authentication",
    spaces=['all']  # Personal + all orgs/teams/projects
)
```

## Permission Levels

### Organization Roles
- **Owner**: Can delete org, manage all settings
- **Admin**: Can add/remove members, manage teams
- **Member**: Can read/write org knowledge
- **Viewer**: Read-only access

### Team Roles
- **Lead**: Can manage team members
- **Member**: Can read/write team knowledge

### Project Roles
- **Owner**: Created the project
- **Lead**: Can add collaborators
- **Contributor**: Can add/edit knowledge
- **Viewer**: Read-only access

## Security Model

### Zero-Knowledge Maintained
```
Your Private Key
       ↓
Decrypts Your API Key
       ↓
Authenticates You
       ↓
PostgreSQL RLS Applies
       ↓
You See: Your + Org + Team + Project Knowledge
```

### What Others Can't See
- Your personal knowledge (unless shared)
- Other orgs' knowledge (unless you're a member)
- Private team discussions (unless on team)

### Database Isolation
```sql
-- Even with direct DB access, RLS prevents cross-org access
SET app.current_user_id = 123; -- You
SELECT * FROM blocks; -- Returns ONLY your accessible knowledge

SET app.current_user_id = 456; -- Someone else
SELECT * FROM blocks; -- Returns THEIR accessible knowledge
```

## Use Cases

### 1. Company Knowledge Base
```
Organization: acme-corp
├── Teams:
│   ├── engineering (technical docs)
│   ├── sales (customer notes)
│   └── support (issue resolutions)
└── Shared: company policies, procedures
```

### 2. Client Project (like UTA)
```
Project: uta-api-integration
├── Members:
│   ├── bert@catalyst9 (developer)
│   ├── john@uta (stakeholder)
│   └── alice@uta (project manager)
└── Knowledge: API specs, meeting notes, decisions
```

### 3. Open Source Project
```
Organization: my-oss-project
├── Visibility: public
├── Members: contributors
└── Knowledge: docs, examples, tutorials
```

## API Examples

### Create Organization
```bash
curl -X POST https://catalyst9.ai/api/v1/orgs \
  -H "Authorization: Bearer $API_KEY" \
  -d '{
    "slug": "uta",
    "name": "University of Texas Arlington",
    "description": "UTA API Integration"
  }'
```

### Join Organization (with invite)
```bash
curl -X POST https://catalyst9.ai/api/v1/orgs/uta/join \
  -H "Authorization: Bearer $API_KEY" \
  -d '{"invite_code": "org_invite_xxx"}'
```

### Share Knowledge with Org
```bash
curl -X POST https://catalyst9.ai/api/v1/knowledge/share \
  -H "Authorization: Bearer $API_KEY" \
  -d '{
    "block_id": 123,
    "visibility": "org",
    "org_id": "uta"
  }'
```

### Search Org Knowledge
```bash
curl -X POST https://catalyst9.ai/api/v1/search \
  -H "Authorization: Bearer $API_KEY" \
  -d '{
    "query": "API endpoints",
    "spaces": ["org:uta"]
  }'
```

## MCP Configuration for Organizations

Update your MCP to specify default org:
```json
{
  "catalyst9": {
    "env": {
      "CATALYST9_USER": "bert",
      "CATALYST9_API_KEY": "...",
      "CATALYST9_DEFAULT_ORG": "uta",
      "CATALYST9_DEFAULT_VISIBILITY": "org"
    }
  }
}
```

## Privacy Guarantees

1. **Default Private**: All knowledge is private by default
2. **Explicit Sharing**: Must explicitly choose to share
3. **No Leakage**: RLS prevents accidental exposure
4. **Audit Trail**: All sharing actions logged
5. **Zero-Knowledge**: Your private key still protects personal data

## Migration from Personal-Only

Existing blocks remain private. To share:
```sql
-- Share specific knowledge with UTA org
UPDATE blocks
SET visibility = 'org', org_id = (SELECT id FROM organizations WHERE slug = 'uta')
WHERE id IN (
  SELECT id FROM blocks
  WHERE content LIKE '%UTA%'
  AND user_id = [your_id]
);
```

## Summary

- **Personal**: Your private knowledge (default)
- **Organization**: Share with company/client (e.g., UTA)
- **Team**: Share with specific group
- **Project**: Cross-org collaboration
- **Public**: Open knowledge

All while maintaining:
- Zero-knowledge authentication
- PostgreSQL RLS enforcement
- Complete audit trails
- No access to others' private data