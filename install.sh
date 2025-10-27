#!/bin/bash
# Catalyst9 One-Command Installer
# Usage: curl -sSL https://catalyst9.ai/install.sh | bash

set -e

echo "🚀 Installing Catalyst9 Knowledge Graph..."

# Detect OS
OS="$(uname -s)"
INSTALL_DIR="$HOME/.catalyst9"

# Create install directory
mkdir -p "$INSTALL_DIR"

# Download MCP wrapper
echo "📥 Downloading MCP wrapper..."
curl -sSL -o "$INSTALL_DIR/catalyst9-mcp.py" \
  https://raw.githubusercontent.com/TheGenXCoder/builder-platform/main/catalyst-core/projects/knowledge-graph-system/catalyst9-mcp.py
chmod +x "$INSTALL_DIR/catalyst9-mcp.py"

# Install Python dependencies
echo "📦 Installing dependencies..."
if command -v pip3 &> /dev/null; then
    pip3 install --user --quiet cryptography requests 2>/dev/null || pip install --user --quiet cryptography requests
elif command -v pip &> /dev/null; then
    pip install --user --quiet cryptography requests
else
    echo "⚠️  Warning: pip not found. You may need to install Python dependencies manually:"
    echo "    pip install cryptography requests"
fi

# Prompt for credentials
echo ""
echo "🔑 Enter your Catalyst9 credentials:"
read -p "Username: " C9_USER
read -p "API Key: " C9_USER_KEY

# Create launcher script
cat > "$INSTALL_DIR/launch-mcp.sh" << EOF
#!/bin/bash
export CATALYST9_API_URL="https://catalyst9.ai"
export CATALYST9_USER="$C9_USER"
export CATALYST9_API_KEY="$C9_USER_KEY"
exec python3 "$INSTALL_DIR/catalyst9-mcp.py" 2>/dev/null || exec python "$INSTALL_DIR/catalyst9-mcp.py"
EOF
chmod +x "$INSTALL_DIR/launch-mcp.sh"

# Find Claude config
CLAUDE_CONFIG=""
if [ -f "$HOME/.config/claude/claude_desktop_config.json" ]; then
    CLAUDE_CONFIG="$HOME/.config/claude/claude_desktop_config.json"
elif [ -f "$HOME/Library/Application Support/Claude/claude_desktop_config.json" ]; then
    CLAUDE_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
fi

if [ -n "$CLAUDE_CONFIG" ]; then
    echo ""
    echo "📝 Configuring Claude Desktop..."

    # Backup existing config
    cp "$CLAUDE_CONFIG" "$CLAUDE_CONFIG.backup"

    # Check if config already has mcpServers
    if grep -q '"mcpServers"' "$CLAUDE_CONFIG"; then
        echo "⚠️  Claude config already has MCP servers."
        echo "   Please add this manually to $CLAUDE_CONFIG:"
        echo ""
        echo '  "catalyst9": {'
        echo '    "command": "'$INSTALL_DIR'/launch-mcp.sh"'
        echo '  }'
    else
        # Create new config with catalyst9
        cat > "$CLAUDE_CONFIG" << CONFIGEOF
{
  "mcpServers": {
    "catalyst9": {
      "command": "$INSTALL_DIR/launch-mcp.sh"
    }
  }
}
CONFIGEOF
        echo "✅ Claude Desktop configured!"
    fi
else
    echo "⚠️  Could not find Claude config. Please create:"
    echo "   $HOME/.config/claude/claude_desktop_config.json"
    echo ""
    echo "   With this content:"
    echo '   {'
    echo '     "mcpServers": {'
    echo '       "catalyst9": {'
    echo '         "command": "'$INSTALL_DIR'/launch-mcp.sh"'
    echo '       }'
    echo '     }'
    echo '   }'
fi

# Test connection
echo ""
echo "🔍 Testing connection to catalyst9.ai..."
if curl -sSf https://catalyst9.ai/health > /dev/null 2>&1; then
    echo "✅ Connection successful!"
else
    echo "⚠️  Cannot reach catalyst9.ai. Check your internet connection."
fi

echo ""
echo "✨ Catalyst9 installed successfully!"
echo ""
echo "📋 Next steps:"
echo "   1. Restart Claude Desktop"
echo "   2. Start using: 'Search catalyst9 for knowledge graph'"
echo ""
echo "📁 Installed to: $INSTALL_DIR"
echo "🔧 Config: $CLAUDE_CONFIG"
echo ""
echo "Need help? Visit https://github.com/TheGenXCoder/builder-platform"