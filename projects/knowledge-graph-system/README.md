# Knowledge Graph System

**Universal Context Preservation & Knowledge Management for Builder Platform**

## Vision

The missing piece that makes the Builder Platform truly compound knowledge over time.

### The Problem We're Solving

**Current State:**
- Context windows exhaust during productive work
- Same instructions repeated across sessions
- Research and decisions lost after conversation ends
- No searchable history of "why we did this"
- Knowledge doesn't accumulate - every session starts from zero

**Target State:**
- Never lose context again
- Never repeat an instruction
- Every conversation logged and searchable
- Every decision tracked with relationships
- System gets smarter about YOUR projects over time
- Knowledge compounds exponentially

## Product Overview

A **system-wide knowledge management platform** that:

1. **Captures Everything:**
   - Every Claude conversation
   - Every article/doc you read
   - Every configuration file
   - Every code decision
   - Every research finding

2. **Makes It Searchable:**
   - Semantic search (find by meaning, not keywords)
   - Graph relationships (understand connections)
   - Timeline view (see evolution)
   - Tag taxonomy (organize naturally)

3. **Injects Context Automatically:**
   - Claude Code queries knowledge base before responding
   - Relevant past knowledge injected into context
   - You never re-explain anything
   - System remembers YOUR project patterns

4. **Compounds Over Time:**
   - Week 1: Logging and basic search
   - Month 3: Smart context injection
   - Year 1: Predictive knowledge retrieval
   - Year 2: Your personal AI that truly knows your work

## Architecture Approach

### Hybrid System (MVP → Scale)

**Phase 1 (MVP - Week 1-2):**
- SQLite + Full-Text Search (FTS5)
- Automatic conversation logging
- Simple CLI: `knowledge search "rate limiting"`
- Foundation for everything else

**Phase 2 (Semantic - Week 3-4):**
- Qdrant vector database (local)
- Ollama embeddings (nomic-embed-text)
- Semantic search: Find by meaning
- CLI: `knowledge find "how do we scale services"`

**Phase 3 (Relationships - Month 2):**
- Neo4j graph database
- Entity extraction (LLM-powered)
- Relationship mapping
- Query: "What would changing auth affect?"

**Phase 4 (Intelligence - Month 3):**
- Unified query interface
- Natural language queries
- Auto-inject into Claude context
- MCP server integration

### Tech Stack (User Choices)

**Backend:**
- Go (performance, concurrency, single binary)
- SQLite (embedded, zero config, fast FTS)
- Qdrant (vector DB, local-first, scales to cloud)
- Neo4j (graph DB, industry standard)

**Embedding & NLP:**
- Ollama (local models, private)
- nomic-embed-text (274MB, fast, excellent quality)
- Local LLMs for entity extraction (codellama, mistral)

**Interfaces:**
- CLI (primary, universal)
- Neovim plugin (Lua)
- VS Code extension (TypeScript)
- MCP server (Claude Code integration)

**Query Languages:**
- Natural language (NLP → structured query)
- Cypher (expert mode, graph queries)
- SQL (power users, custom reports)

### Dual Query Interface

**Natural Language (Default):**
```bash
$ knowledge find "how do we handle authentication"
$ knowledge what would be affected by changing rate limiting
$ knowledge show me all decisions about database schema
```

**Expert Mode (Cypher/SQL):**
```bash
$ knowledge query --cypher "MATCH (d:Decision)-[:AFFECTS]->(m:Module) WHERE m.name = 'auth' RETURN d"
$ knowledge query --sql "SELECT * FROM entries WHERE tags LIKE '%authentication%' ORDER BY timestamp DESC"
```

Think: Splunk's search language power, but for YOUR knowledge.

## Integration with Builder Platform

This system IS the Graph RAG architecture described in builder-platform/README.md:

- **Total Context Preservation:** Conversation logging system expanded
- **D.R.Y. Principle:** Query before researching
- **Self-Improvement Loop:** Logs → knowledge → better platform
- **Compounding Knowledge:** Month 1 (30hr) → Year 2 (8hr)
- **Domain Transfer:** Same methodology, different subjects

**Universal for All Builder Platform Projects:**
- Automotive research (VR30 specs) → searchable forever
- Culinary research (cassoulet variants) → searchable forever
- Any domain research → searchable forever
- Cross-domain learning from patterns

## Installation

### Prerequisites

1. **PostgreSQL 17** with pgvector extension
   ```bash
   brew install postgresql@17 pgvector
   brew services start postgresql@17
   ```

2. **Ollama** with nomic-embed-text model
   ```bash
   brew install ollama
   ollama serve  # In one terminal
   ollama pull nomic-embed-text  # In another
   ```

3. **Go 1.21+**
   ```bash
   brew install go
   ```

### Setup

1. **Initialize database**
   ```bash
   createdb knowledge_graph
   psql knowledge_graph < schema.sql
   ```

2. **Build binaries**
   ```bash
   go build -o knowledge ./cmd/knowledge
   go build -o mcp-server ./cmd/mcp-server
   ```

3. **Test the system**
   ```bash
   ./knowledge test
   ```

   Expected output:
   ```
   ✅ All tests passed!
   ✓ Search completed in 67ms
   ```

4. **Setup Claude Code integration**

   See [MCP-SETUP.md](./MCP-SETUP.md) for detailed MCP configuration.

## Product Strategy

### MVP (Fundable Product)

**Goal:** Prove the concept, secure funding, scale to completion

**Timeline:** 4-6 weeks

**Deliverables:**
1. Working CLI with search (SQLite + FTS)
2. Automatic conversation logging
3. Basic semantic search (Qdrant + Ollama)
4. Demo: "Never lose knowledge again"
5. Pitch deck + demo for funding

**Success Metrics:**
- Can recover any conversation within seconds
- Semantic search finds relevant knowledge 95%+ accuracy
- Zero knowledge loss events
- 10x faster to recall past decisions vs manual search

### Post-Funding (Complete Product)

**Phase 2 (Months 2-3):**
- Graph database (relationships)
- Advanced entity extraction
- Multi-project knowledge sharing
- Neovim + VS Code plugins

**Phase 3 (Months 4-6):**
- Auto-context injection for Claude
- Predictive knowledge retrieval
- Knowledge visualization (graph view)
- Team collaboration features

**Phase 4 (Months 7-12):**
- SaaS platform (multi-tenant)
- Builder Platform integration (official)
- Specialized agents trained on YOUR knowledge
- Enterprise features (SSO, teams, compliance)

## Why This Matters

### For Solo Developers

- Stop repeating yourself to AI assistants
- Build true "memory" across sessions
- Compound learning over time
- Work confidently knowing nothing is lost

### For Builder Platform

- THE missing piece for knowledge compounding
- Makes "platform builds itself" vision real
- Enables true D.R.Y. across all domains
- Foundation for specialized agent training

### For the Market

- Every developer/researcher faces this problem
- No good solution exists (GitHub Copilot doesn't remember YOUR context)
- Huge TAM: Any knowledge worker using AI tools
- Network effects: Knowledge compounds for all users

## Competitive Advantages

1. **Local-First:** Your knowledge, your machine, your privacy
2. **Hybrid Intelligence:** Semantic + Graph + Full-Text search
3. **Builder Platform Integration:** Part of proven methodology
4. **Universal Design:** Works for code, research, any knowledge
5. **Expert Interface:** Power users get Cypher/SQL, not just NLP

## Success Vision

**Year 1:**
- 10,000 users (developers, researchers, writers)
- Average 50GB knowledge base per user
- 95%+ knowledge recall accuracy
- 10x productivity improvement (measured: time to recall info)

**Year 2:**
- 100,000 users across all knowledge domains
- Specialized agents trained on user knowledge
- Platform as infrastructure for Builder Platform
- Enterprise deployments (teams, orgs)

**Year 3:**
- The standard for AI context management
- Integration with all major AI tools
- Network effects: Shared methodology across domains
- "You're not using Knowledge Graph System?" = surprised reaction

## Current Status

**Phase:** Week 1 Implementation Complete ✅

**Shipped (2025-10-24):**
- ✅ PostgreSQL 17 + pgvector database
- ✅ Block-based storage (768-dim vectors)
- ✅ Semantic + keyword hybrid search
- ✅ Ollama embeddings (nomic-embed-text)
- ✅ MCP server for Claude Code integration
- ✅ Sub-200ms search performance (67ms achieved)
- ✅ Go CLI test harness
- ✅ Auto-project detection

**Week 1 Success Metric:** ✅ I STOP LOSING CONTEXT

**Next Steps:**
- Week 2: Tag extraction, relationship inference
- Week 3: Pattern recognition, auto-workflow codification
- Week 4: Neovim plugin, autonomous alpha discovery

**Quick Start:**

See [Installation](#installation) and [MCP Setup](./MCP-SETUP.md) for getting started.

```bash
# Test the system
./knowledge test

# Search knowledge
./knowledge search "PostgreSQL setup"

# Use from Claude Code via MCP
# (See MCP-SETUP.md for configuration)
```

**Location:** `builder-platform/projects/knowledge-graph-system/`

---

**This is the compound interest of knowledge work.**

*"Research once, use forever."*
