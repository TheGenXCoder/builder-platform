#!/bin/bash
# Setup MCP integration for Claude Code

CONFIG_DIR="$HOME/.config/claude"
CONFIG_FILE="$CONFIG_DIR/claude_desktop_config.json"
MCP_SERVER_PATH="$(pwd)/mcp-server"

echo "Setting up Knowledge Graph MCP Server..."
echo ""

# Check if mcp-server binary exists
if [ ! -f "$MCP_SERVER_PATH" ]; then
    echo "❌ Error: mcp-server binary not found at: $MCP_SERVER_PATH"
    echo "   Run: go build -o mcp-server ./cmd/mcp-server"
    exit 1
fi

echo "✓ Found mcp-server binary"

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Check if config file exists
if [ -f "$CONFIG_FILE" ]; then
    echo "⚠️  Config file already exists: $CONFIG_FILE"
    echo ""
    echo "Add this to your mcpServers section:"
    echo ""
    cat <<EOF
    "knowledge-graph": {
      "command": "$MCP_SERVER_PATH",
      "env": {
        "KG_DB_URL": "host=localhost port=5432 dbname=knowledge_graph sslmode=disable"
      }
    }
EOF
else
    echo "Creating new config file..."
    cat > "$CONFIG_FILE" <<EOF
{
  "mcpServers": {
    "knowledge-graph": {
      "command": "$MCP_SERVER_PATH",
      "env": {
        "KG_DB_URL": "host=localhost port=5432 dbname=knowledge_graph sslmode=disable"
      }
    }
  }
}
EOF
    echo "✓ Created: $CONFIG_FILE"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Restart Claude Code"
echo "2. In any project, ask: 'What knowledge graph tools do you have?'"
echo "3. Start saving and searching conversations!"
echo ""
echo "The system will auto-detect your project from the current directory."
