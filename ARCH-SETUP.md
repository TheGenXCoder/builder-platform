# Setting Up Catalyst9 on Arch Linux - Step by Step

## Step 1: Clone the Repository

On your Arch box, open terminal and run:

```bash
# Go to where you keep your projects
cd ~/projects  # or wherever you prefer

# Clone your repo
git clone https://github.com/TheGenXCoder/builder-platform.git

# Go into the catalyst-core directory
cd builder-platform/catalyst-core
```

## Step 2: Install Python Dependencies

Arch uses `pacman` and Python should already be installed:

```bash
# Check Python version (need 3.8+)
python --version

# Install pip if needed
sudo pacman -S python-pip

# Install the cryptography library for the invite system
pip install --user cryptography requests
```

## Step 3: Download Just the MCP Wrapper

You don't need the whole repo if you just want to connect. You can grab just the MCP wrapper:

```bash
# Make a directory for catalyst9
mkdir -p ~/.catalyst9

# Download the MCP wrapper directly
curl -o ~/.catalyst9/catalyst9-mcp.py \
  https://raw.githubusercontent.com/TheGenXCoder/builder-platform/main/catalyst-core/projects/knowledge-graph-system/catalyst9-mcp.py

# Make it executable
chmod +x ~/.catalyst9/catalyst9-mcp.py
```

## Step 4: Set Up Your API Credentials

### Option A: Use Environment Variables (Recommended)

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
# Edit your shell config
nano ~/.bashrc  # or ~/.zshrc if using zsh

# Add these lines (with YOUR actual API key)
export C9_USER='bert'
export C9_USER_KEY='cat9_Pn0CSVnzJXW6WSCo4PO7dPjB0zk92Amq9SmDNVmPFlA'

# Reload your shell
source ~/.bashrc
```

### Option B: Create Credentials File

```bash
# Create credentials file
nano ~/.catalyst9/credentials

# Add your credentials
C9_USER=bert
C9_USER_KEY=cat9_Pn0CSVnzJXW6WSCo4PO7dPjB0zk92Amq9SmDNVmPFlA
```

## Step 5: Create MCP Launcher Script

Create a launcher that loads your credentials:

```bash
cat > ~/.catalyst9/launch-mcp.sh << 'EOF'
#!/bin/bash
# Load credentials
if [ -f ~/.catalyst9/credentials ]; then
    source ~/.catalyst9/credentials
fi

# Or use from shell environment
export CATALYST9_API_URL="https://catalyst9.ai"
export CATALYST9_USER="${C9_USER}"
export CATALYST9_API_KEY="${C9_USER_KEY}"

# Launch the MCP wrapper
exec python ~/.catalyst9/catalyst9-mcp.py
EOF

# Make it executable
chmod +x ~/.catalyst9/launch-mcp.sh
```

## Step 6: Configure Claude Desktop on Arch

Find your Claude config file (location varies):

```bash
# Common locations on Linux
~/.config/claude/claude_desktop_config.json
~/.config/Claude/claude_desktop_config.json
~/.local/share/claude/claude_desktop_config.json
```

Edit the config:

```bash
nano ~/.config/claude/claude_desktop_config.json
```

Add this configuration:

```json
{
  "mcpServers": {
    "catalyst9": {
      "command": "/home/YOUR_USERNAME/.catalyst9/launch-mcp.sh"
    }
  }
}
```

Replace `YOUR_USERNAME` with your actual Arch username.

## Step 7: Test Your Setup

### Test 1: Check API is reachable
```bash
curl -I https://catalyst9.ai/health
# Should return HTTP/2 200
```

### Test 2: Test your credentials work
```bash
# Source your credentials
source ~/.catalyst9/credentials

# Test API with your key
curl https://catalyst9.ai/api/v1/auth/verify \
  -H "Authorization: Bearer $C9_USER_KEY"
```

### Test 3: Test the MCP wrapper directly
```bash
# Run the launcher
~/.catalyst9/launch-mcp.sh

# Type this test request:
{"jsonrpc": "2.0", "method": "initialize", "id": 1}

# Should return initialization response
# Press Ctrl+C to exit
```

## Step 8: Start Claude Desktop

```bash
# Restart Claude Desktop to load the new MCP config
# The command depends on how you installed Claude

# If installed via AUR
claude-desktop

# Or kill and restart if already running
pkill -f claude
claude-desktop &
```

## Troubleshooting

### Can't find Claude config?
```bash
# Search for it
find ~/ -name "claude_desktop_config.json" 2>/dev/null
```

### Python issues?
```bash
# Make sure you have Python 3
python --version

# On Arch, python is Python 3 by default
# But if you need to specify:
python3 ~/.catalyst9/catalyst9-mcp.py
```

### Permission denied?
```bash
# Make sure scripts are executable
chmod +x ~/.catalyst9/*.sh
chmod +x ~/.catalyst9/*.py
```

### MCP not showing in Claude?
1. Make sure Claude is completely closed
2. Check the config file is valid JSON
3. Check the path in config is absolute (starts with /)
4. Restart Claude Desktop

## Quick Test Commands

Once everything is set up, in Claude you should be able to:

1. Search your knowledge:
   "Search catalyst9 for 'knowledge graph'"

2. Add knowledge:
   "Add to catalyst9: Testing from Arch Linux"

3. Check stats:
   "Show my catalyst9 statistics"

## Summary Checklist

- [ ] Python installed (comes with Arch)
- [ ] Downloaded catalyst9-mcp.py
- [ ] Created launch-mcp.sh script
- [ ] Added credentials (env vars or file)
- [ ] Configured Claude Desktop
- [ ] Tested API connection
- [ ] Restarted Claude Desktop

---

That's it! Your Arch box should now be connected to Catalyst9 at catalyst9.ai using the same knowledge base as your Mac.