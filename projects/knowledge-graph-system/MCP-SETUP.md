# Knowledge Graph MCP Server Setup

## Overview

The Knowledge Graph MCP Server exposes the knowledge graph system to Claude Code via the Model Context Protocol (MCP). This allows Claude Code to save conversation blocks and search across all your past interactions.

## Installation

### 1. Build the MCP Server

```bash
cd /Users/BertSmith/personal/builder-platform/projects/knowledge-graph-system
go build -o mcp-server ./cmd/mcp-server
```

### 2. Configure Claude Code

Add the MCP server to your Claude Code configuration:

**File:** `~/.config/claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "knowledge-graph": {
      "command": "/Users/BertSmith/personal/builder-platform/projects/knowledge-graph-system/mcp-server",
      "env": {
        "KG_DB_URL": "host=localhost port=5432 dbname=knowledge_graph sslmode=disable",
        "KG_OLLAMA_URL": "http://localhost:11434",
        "KG_OLLAMA_MODEL": "nomic-embed-text"
      }
    }
  }
}
```

**For Claude CLI (if using CLI mode):**

**File:** `~/.config/claude-cli/config.json`

```json
{
  "mcpServers": {
    "knowledge-graph": {
      "command": "/Users/BertSmith/personal/builder-platform/projects/knowledge-graph-system/mcp-server",
      "env": {
        "KG_DB_URL": "host=localhost port=5432 dbname=knowledge_graph sslmode=disable",
        "KG_OLLAMA_URL": "http://localhost:11434",
        "KG_OLLAMA_MODEL": "nomic-embed-text"
      }
    }
  }
}
```

### 3. Restart Claude Code

Restart Claude Code to load the MCP server configuration.

## Available MCP Tools

Once configured, Claude Code will have access to these tools:

### 1. `kg_save_block`

Save a conversation block to the knowledge graph.

**Parameters:**
- `topic` (string, required): Topic or title of the conversation block
- `exchanges` (array, required): List of question-answer exchanges
  - `question` (string, required)
  - `answer` (string, required)
  - `model` (string, optional): Model used for the answer

**Example:**
```json
{
  "topic": "Setting up PostgreSQL with pgvector",
  "exchanges": [
    {
      "question": "How do I install pgvector for PostgreSQL 17?",
      "answer": "Install via Homebrew: brew install pgvector",
      "model": "claude-sonnet-4-5"
    },
    {
      "question": "How do I enable the extension?",
      "answer": "Run: CREATE EXTENSION IF NOT EXISTS vector;",
      "model": "claude-sonnet-4-5"
    }
  ]
}
```

**Returns:**
```json
{
  "success": true,
  "block_id": "uuid-here",
  "project": "knowledge-graph-system",
  "exchanges": 2
}
```

### 2. `kg_search`

Search the knowledge graph using semantic + keyword hybrid search.

**Parameters:**
- `query` (string, required): Search query (natural language)
- `limit` (integer, optional): Maximum results (default: 10)
- `include_n_plus` (boolean, optional): Include N+1 related blocks (default: false)

**Example:**
```json
{
  "query": "PostgreSQL vector search setup",
  "limit": 5,
  "include_n_plus": false
}
```

**Returns:**
```json
{
  "results": [
    {
      "block_id": "uuid-here",
      "topic": "Setting up PostgreSQL with pgvector",
      "relevance": 0.95,
      "created": "2025-10-24T22:30:00Z",
      "exchanges": [...]
    }
  ],
  "total_found": 1,
  "search_time": "67ms"
}
```

### 3. `kg_get_context`

Get a block with N+1 context (one hop of relationships).

**Parameters:**
- `block_id` (string, required): UUID of the block to retrieve

**Example:**
```json
{
  "block_id": "49eb4e2a-3aac-4b60-8f51-a50cabb908fb"
}
```

**Returns:**
```json
{
  "primary_block": {
    "id": "uuid-here",
    "topic": "Main topic",
    "exchanges": [...]
  },
  "related_blocks": [...],
  "tags": [...]
}
```

## Usage Patterns

### Pattern 1: Save Session at Natural Breakpoints

When you complete a focused conversation block (3-5 exchanges on a topic), save it:

```
User: "Save this conversation to the knowledge graph"
Claude: [Uses kg_save_block tool to save current conversation]
```

### Pattern 2: Search Before Starting New Work

Before starting new work, search for relevant past context:

```
User: "Have we worked on PostgreSQL vector search before?"
Claude: [Uses kg_search to find relevant blocks]
```

### Pattern 3: Retrieve Full Context

When you find a relevant block, get the full context with related blocks:

```
User: "Show me the full context for that PostgreSQL setup block"
Claude: [Uses kg_get_context to retrieve N+1 context]
```

## Verification

### Test the MCP Server Manually

You can test the MCP server manually with stdin/stdout:

```bash
./mcp-server
```

Then send JSON-RPC requests:

```json
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}
{"jsonrpc":"2.0","id":2,"method":"tools/list"}
```

### Check Claude Code Integration

1. Start Claude Code
2. In a conversation, ask: "What knowledge graph tools do you have access to?"
3. Claude should list the three MCP tools

## Prerequisites

Make sure these are running:
- ✅ PostgreSQL 17 with pgvector extension
- ✅ Ollama with nomic-embed-text model (`ollama pull nomic-embed-text`)
- ✅ Database initialized with schema.sql

## Troubleshooting

### MCP Server Not Starting

Check logs in stderr for error messages. Common issues:
- Database connection failed (check KG_DB_URL)
- Ollama not running (check `curl http://localhost:11434/api/tags`)
- nomic-embed-text model not installed (`ollama pull nomic-embed-text`)

### Tools Not Appearing in Claude Code

1. Check config file location: `~/.config/claude/claude_desktop_config.json`
2. Verify command path is absolute (not relative)
3. Restart Claude Code completely
4. Check Claude Code logs for MCP errors

### Search Performance Slow

- Verify HNSW index exists: `\d blocks` in psql
- Check Ollama response time: `curl -X POST http://localhost:11434/api/embeddings ...`
- Monitor search_time in kg_search results

## Environment Variables

- `KG_DB_URL`: PostgreSQL connection string (default: localhost)
- `KG_OLLAMA_URL`: Ollama API URL (default: http://localhost:11434)
- `KG_OLLAMA_MODEL`: Ollama embedding model (default: nomic-embed-text)

## Week 1 Success Criteria

✅ MCP server exposes knowledge graph to Claude Code
✅ Can save conversation blocks from Claude Code
✅ Can search past conversations from Claude Code
✅ Sub-200ms search performance
✅ Auto-detects project from current directory
✅ **Result: I STOP LOSING CONTEXT**

## Next Steps (Week 2+)

- [ ] Auto-save at conversation boundaries
- [ ] Pattern recognition (auto-generate reports)
- [ ] Tag extraction from content
- [ ] Relationship inference
- [ ] Multi-project switching
