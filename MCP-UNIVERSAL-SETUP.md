# Catalyst9 Knowledge Graph - Universal MCP Access

Connect to Catalyst9 from ANY machine using MCP (Model Context Protocol).

## Quick Setup (Any Machine)

### 1. Install Python (if needed)
```bash
# macOS/Linux
python3 --version || brew install python3

# Windows
# Download from python.org
```

### 2. Download MCP Wrapper
```bash
# Download the wrapper script
curl -O https://catalyst9.ai/mcp/catalyst9-mcp.py
chmod +x catalyst9-mcp.py
```

### 3. Configure Claude Desktop

Add to your Claude Desktop config (`~/.config/claude/claude_desktop_config.json`):

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

## Getting Your Credentials

### Option 1: Self-Service (Coming Soon)
```bash
curl -X POST https://catalyst9.ai/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username": "your_name", "email": "your@email.com"}'
```

### Option 2: Request Access
Contact Bert for credentials:
- Username (e.g., "bert", "erwin", "alice")
- API Key (unique per user)

## Multi-User Features

### Personal Knowledge Spaces
Each user has their own:
- Knowledge blocks
- Search history
- Custom tags
- Private notes

### Shared Spaces
- Project knowledge (opt-in sharing)
- Public knowledge base
- Team workspaces

## Example Usage

### For Bert (owner)
```json
{
  "CATALYST9_USER": "bert",
  "CATALYST9_API_KEY": "sk-catalyst9-bert-xxxxx"
}
```

### For Erwin (friend)
```json
{
  "CATALYST9_USER": "erwin",
  "CATALYST9_API_KEY": "sk-catalyst9-erwin-xxxxx"
}
```

### For New Users
```json
{
  "CATALYST9_USER": "alice",
  "CATALYST9_API_KEY": "sk-catalyst9-alice-xxxxx"
}
```

## API Endpoints

All requests include user authentication:

```bash
# Search your knowledge
curl https://catalyst9.ai/api/v1/search \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{"query": "your search"}'

# Add knowledge (saved to your space)
curl https://catalyst9.ai/api/v1/knowledge/add \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{"content": "your knowledge"}'
```

## Repository Information

**GitHub:** https://github.com/TheGenXCoder/builder-platform
**Directory:** catalyst-core (within builder-platform repo)
**Live API:** https://catalyst9.ai
**Status:** https://catalyst9.ai/health

## Platform Support

✅ **macOS** - Native support
✅ **Linux** - Native support
✅ **Windows** - Python required
✅ **WSL** - Full support
✅ **Remote servers** - SSH + MCP

## Troubleshooting

### Connection Issues
```bash
# Test API access
curl https://catalyst9.ai/health

# Test authentication
curl https://catalyst9.ai/api/v1/auth/verify \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### MCP Not Working
1. Restart Claude Desktop
2. Check Python path: `which python3`
3. Verify script location
4. Check credentials in config

## Security

- API keys are user-specific
- HTTPS-only communication
- Knowledge isolation by default
- Explicit sharing required
- Rate limiting per user

## Coming Soon

- [ ] Self-service registration
- [ ] OAuth integration (GitHub, Google)
- [ ] Team management dashboard
- [ ] API key rotation
- [ ] Usage analytics per user
- [ ] Collaborative knowledge spaces

---

**Connect from anywhere. Your knowledge, always accessible.**