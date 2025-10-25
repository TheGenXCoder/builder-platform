# Tech Stack

> These technical choices are strategic decisions that support the product mission: building AI-agnostic infrastructure that makes AI models interchangeable, knowledge portable, and context cumulative.

---

## Backend

### Primary Language: Go

**Why Go:**
- **Performance:** Compiled language with low latency for real-time query responses (sub-second requirement)
- **Concurrency:** Native goroutines for parallel processing (entity extraction, embedding generation, multi-model queries)
- **Single Binary Distribution:** Cross-compile to macOS/Linux/Windows with zero dependencies (critical for CLI adoption)
- **Simplicity:** Straightforward language, easy to maintain long-term (solo developer initially, small team later)
- **Ecosystem:** Excellent libraries for database access (pgx), gRPC, HTTP servers, CLI frameworks (cobra)

**What We're Building in Go:**
- CLI application (primary user interface)
- API server (REST/gRPC endpoints)
- Background daemon (continuous ingestion, embedding generation)
- Database access layer (PostgreSQL, Neo4j clients)
- Multi-model AI connector (unified abstraction over OpenAI, Anthropic, Ollama APIs)

**Why NOT Alternatives:**
- **NOT Python:** Too slow for real-time queries, dependency hell for distribution (CLI must be single binary)
- **NOT Rust:** Steeper learning curve, longer development time (part-time initially requires velocity)
- **NOT Node.js/TypeScript:** Less performant for CPU-intensive operations, awkward single-binary distribution

---

### ML Pipeline Language: Python

**Why Python:**
- **ML Ecosystem:** spaCy, transformers, sentence-transformers—best-in-class NLP libraries
- **Entity Extraction:** spaCy's NER is production-ready and fast
- **Embedding Models:** Sentence-transformers, Ollama Python client, OpenAI embeddings—all Python-first
- **Community:** Largest ML/AI developer community, easiest hiring for ML expertise
- **Rapid Prototyping:** Iterate quickly on entity extraction logic, relationship detection, embedding strategies

**What We're Building in Python:**
- Entity extraction service (spaCy NER + custom models)
- Relationship detection (co-occurrence, dependency parsing, LLM-assisted)
- Embedding generation (sentence-transformers, Ollama embeddings)
- Data preprocessing pipelines (text cleaning, chunking, metadata extraction)
- ML model training (custom entity types, domain-specific extractors)

**Why NOT Alternatives:**
- **NOT Go for ML:** Go's ML ecosystem is immature (no spaCy equivalent, limited transformers support)
- **NOT Pure LLM-based extraction:** Too slow, too expensive, not deterministic enough for infrastructure
- **NOT Java/Scala:** Python has won the ML ecosystem war; fighting it is counterproductive

**Go + Python Integration:**
- gRPC for communication (typed, fast, language-agnostic)
- Python services deployed as microservices (Docker containers)
- Go orchestrates, Python specializes (separation of concerns)

---

## Database

### Phase 1: PostgreSQL + pgvector

**Why PostgreSQL:**
- **Relational + Vector + Full-Text in One:** pgvector extension adds vector similarity search without needing separate vector DB
- **Production-Ready:** 30+ years of stability, horizontal scaling proven, ACID transactions
- **Query Flexibility:** SQL is powerful and familiar; no need to learn new query language initially
- **Cost-Effective:** Open source, no licensing fees, runs anywhere (local, cloud, self-hosted)
- **Simplicity:** Single database means simpler architecture, fewer moving parts (critical for solo developer initially)

**What We're Storing:**
- **Entities Table:** id, type, content, metadata, created_at, updated_at
- **Embeddings Table:** entity_id, embedding_vector (pgvector), model_version
- **Relationships Table:** source_id, target_id, relationship_type, confidence, metadata
- **Sessions Table:** session_id, ai_model, timestamp, user_id (for audit/compliance)
- **Full-Text Indexes:** PostgreSQL's built-in full-text search for keyword queries

**pgvector Capabilities:**
- Vector similarity search (cosine, L2, inner product)
- Combined queries: vector similarity + full-text + relational filters
- Index support (IVFFlat, HNSW) for fast approximate nearest neighbor search
- Scales to millions of vectors with proper indexing

**Why NOT Alternatives (Phase 1):**
- **NOT Pinecone/Weaviate/Qdrant:** Adds complexity, cost, and another service to manage (premature for MVP)
- **NOT MongoDB:** Document model doesn't fit relational entity-relationship structure; no pgvector equivalent
- **NOT Elasticsearch:** Full-text search is great, but relational queries are awkward; pgvector is simpler

---

### Phase 2: Neo4j (Advanced Graph Operations)

**Why Neo4j:**
- **Native Graph Storage:** Optimized for graph traversal (6+ hop queries are fast)
- **Cypher Query Language:** Expressive, readable graph queries (e.g., "MATCH (a)-[:RELATED*1..5]->(b)")
- **Relationship-First:** Relationships are first-class citizens, not JOIN tables (conceptually cleaner for knowledge graphs)
- **Visualization:** Built-in graph visualization tools (Neo4j Browser) for exploring knowledge graphs
- **Scaling:** Proven at scale (used by NASA, Walmart, eBay for graph workloads)

**When to Use Neo4j:**
- Complex graph traversals (e.g., "Find all entities connected to this concept within 3 degrees")
- Relationship-heavy queries (e.g., "Show me the path from this decision to that requirement")
- Power users who want Cypher query expressiveness (expert mode)
- Enterprise customers with large, complex knowledge graphs (100K+ entities, 1M+ relationships)

**Why NOT Use Neo4j in Phase 1:**
- Adds operational complexity (another database to deploy, monitor, backup)
- PostgreSQL + pgvector is sufficient for MVP and early adopters
- Cypher learning curve for users who just want SQL
- Cost: Neo4j Enterprise is expensive (though Community Edition is free)

**Migration Strategy:**
- Build abstraction layer: database interface with PostgreSQL and Neo4j implementations
- Users choose backend based on needs: PostgreSQL for simplicity, Neo4j for advanced graphs
- Migration tool: export from PostgreSQL, import to Neo4j (preserve entity IDs and relationships)

**Why NOT Alternatives:**
- **NOT JanusGraph/TigerGraph:** Less mature ecosystem, smaller community, harder hiring
- **NOT AWS Neptune/Azure Cosmos Gremlin:** Vendor lock-in, cost, less flexibility than self-hosted Neo4j

---

## Embedding & NLP

### Local Models via Ollama

**Why Ollama:**
- **Privacy:** All embedding and NLP processing happens locally (no data sent to cloud)
- **Cost:** Zero API costs (critical for high-volume ingestion)
- **Speed:** Local inference is fast (sub-second embeddings for most text)
- **Flexibility:** Easy to swap models (nomic-embed-text, all-MiniLM-L6-v2, custom fine-tuned models)
- **Developer-Friendly:** Simple API, easy Docker deployment, integrates with Python/Go clients

**Embedding Model: nomic-embed-text**

**Why nomic-embed-text:**
- **Quality:** Competitive with OpenAI embeddings on most benchmarks
- **Open Source:** MIT license, can modify and deploy freely
- **Efficiency:** 137M parameters, fast inference on CPU (no GPU required for most use cases)
- **Context Length:** 8192 tokens (longer than many alternatives)
- **Local-First Philosophy:** Aligns with product mission (you own your infrastructure)

**What We're Embedding:**
- Entity content (descriptions, definitions, context)
- Relationship descriptions (semantic meaning of connections)
- User queries (to find relevant entities via vector similarity)
- Session summaries (to retrieve related past conversations)

**Entity Extraction Models:**
- **spaCy (en_core_web_lg):** Fast, deterministic NER for common entity types (PERSON, ORG, GPE, DATE)
- **Ollama + LLaMA/Mistral:** LLM-assisted extraction for domain-specific entities (e.g., "architectural decision", "API endpoint", "bug fix")
- **Custom Fine-Tuned Models:** As product matures, fine-tune on user knowledge graphs for better extraction

**Why NOT Alternatives:**
- **NOT OpenAI Embeddings:** API costs prohibitive for high-volume ingestion; vendor lock-in contradicts product mission
- **NOT BERT-based models only:** Ollama gives us flexibility to experiment with latest models (Gemma, Phi, etc.)
- **NOT Cloud-only NLP:** Privacy and cost concerns; local-first is strategic advantage

---

## AI Model Integration

### Multi-Model Abstraction Layer

**Supported Models (Phase 1):**
- **OpenAI (GPT-4, GPT-4-Turbo, GPT-3.5-Turbo):** Most popular, best code generation
- **Anthropic (Claude 3 Opus, Sonnet, Haiku):** Best for analysis, reasoning, long-form content
- **Ollama (LLaMA, Mistral, CodeLlama, etc.):** Local inference, privacy, cost-free
- **Google (Gemini Pro, Gemini Ultra):** Multimodal, competitive with GPT-4

**Architecture:**
- **Unified Interface:** Abstract AI models behind common interface (send_message, get_response, stream_response)
- **Context Injection:** Before each AI call, query knowledge graph for relevant entities and inject as context
- **Model Routing:** Users specify model preferences (default to GPT-4, fall back to Claude, use Ollama for bulk tasks)
- **API Key Management:** Secure storage of API keys (OS keychain, env vars, config file encrypted)

**Why NOT Alternatives:**
- **NOT LangChain:** Too opinionated, too much abstraction, breaks frequently with API changes
- **NOT LlamaIndex:** Model-dependent, not truly AI-agnostic (designed for RAG, not infrastructure)
- **NOT Building on Single Model:** Contradicts product mission (AI independence requires multi-model support)

---

## Interfaces

### CLI (Primary Interface)

**Framework: Cobra (Go)**

**Why CLI First:**
- **Universal:** Works on any OS, any terminal, any SSH session
- **Scriptable:** Easy to automate, integrate with CI/CD, use in workflows
- **Fast:** No browser, no GUI overhead, instant responses
- **Power Users:** Developers love CLI tools (our primary audience)
- **Dogfooding:** We'll use CLI to build CLI (validates UX quickly)

**Core Commands:**
- `kg init` — Initialize knowledge graph (local or remote)
- `kg ingest <file/url/text>` — Add content to knowledge graph
- `kg query "<question>"` — Natural language search
- `kg ask "<question>" --model=gpt-4` — Query + AI response with context injection
- `kg graph` — Visualize graph (ASCII/text-based, optional Graphviz export)
- `kg export <format>` — Export to GraphML, JSON-LD, CSV
- `kg import <file>` — Import from common formats
- `kg status` — Show graph statistics (entities, relationships, disk usage)

**Why NOT Alternatives:**
- **NOT Web UI First:** Slower to build, harder to dogfood, less universal (but we'll add web UI later)
- **NOT Desktop App (Electron):** Bloated, slow, contradicts single-binary distribution philosophy

---

### Editor Integrations

**Neovim Plugin (Lua)**

**Why Neovim:**
- **Power Users:** Neovim users are technical early adopters (influential in dev community)
- **Performance:** Fast, lightweight, scriptable
- **Integration:** LSP, tree-sitter, Telescope—modern Neovim is extremely extensible
- **Community:** Active plugin ecosystem, high engagement on GitHub

**Features:**
- `:KGQuery <question>` — Search knowledge graph, display results in split
- `:KGIngest` — Add current buffer/selection to knowledge graph
- `:KGContext` — Inject relevant context above cursor (for AI coding assistants)
- Telescope integration for fuzzy search over entities
- Autocommands to continuously sync notes/docs to knowledge graph

**VS Code Extension (TypeScript)**

**Why VS Code:**
- **Market Share:** Largest editor user base (reach beyond Neovim power users)
- **Ease of Development:** Good extension API, easy to publish
- **AI Assistant Integration:** Many users have GitHub Copilot, Cody—KGS complements them

**Features (MVP):**
- Command palette: "KG: Query", "KG: Ingest", "KG: Show Context"
- Sidebar for graph exploration (tree view of related entities)
- Inline context injection (triggered manually or on AI assistant invocation)

**Why NOT Other Editors (Initially):**
- **NOT JetBrains IDEs:** Smaller audience for infrastructure tools, harder plugin development
- **NOT Emacs:** Smaller user base, Neovim covers terminal-based power users

---

### MCP Server (Claude Code Integration)

**Why MCP (Model Context Protocol):**
- **Native Integration:** Claude Code uses MCP for tool/resource access
- **Dogfooding:** We'll use KGS while building KGS (best way to validate UX)
- **Thought Leadership:** Demonstrate KGS working with Claude (one of many supported models)

**MCP Resources Exposed:**
- `knowledge://entities/<id>` — Retrieve entity by ID
- `knowledge://query?q=<query>` — Natural language search
- `knowledge://graph/<entity_id>` — Get entity + relationships (graph traversal)

**MCP Tools Exposed:**
- `ingest_text(text, metadata)` — Add text to knowledge graph
- `query_graph(question)` — Natural language query
- `get_context(keywords)` — Retrieve relevant context for current task

**Why This Matters:**
- Proves AI-agnostic infrastructure (KGS works with Claude via MCP, GPT-4 via API, Ollama locally)
- Developer advocates can demo KGS + Claude Code live
- Founder builds with own tool (authenticity, real-world validation)

---

### Web UI (Later Phase: HTMX + Go Templates)

**Why HTMX (Not React/TypeScript):**
- **Simplicity:** Server-rendered HTML with dynamic behavior (no SPA complexity)
- **Performance:** Fast page loads, minimal JavaScript, low bandwidth
- **Developer Velocity:** Go templates + HTMX is faster to build than React + API (solo developer initially)
- **Alignment:** Local-first, simple infrastructure philosophy (avoid overengineering)

**What Web UI Provides:**
- Graph visualization (D3.js or Cytoscape.js for interactive graphs)
- Query interface (web form for natural language queries)
- Entity browsing (tree view, search, filters)
- Admin dashboard (user management, stats, system health)

**Why NOT Alternatives:**
- **NOT React:** Overengineered for this use case, requires TypeScript + build tooling + state management
- **NOT Vue/Svelte:** Better than React, but HTMX is even simpler for server-rendered apps
- **NOT Pure Server-Side Rendering:** Some interactivity needed (graph exploration, live search)

---

## Infrastructure & Deployment

### Local-First Architecture

**Why Local-First:**
- **Privacy:** User data never leaves user's machine unless they opt in
- **Ownership:** Users control their knowledge graph (files on disk, database local)
- **Compliance:** No cloud storage = easier compliance (GDPR, HIPAA, SOC 2 for self-hosted)
- **Cost:** No cloud storage costs for users (cheaper than SaaS)
- **Product Mission:** "You own it" is core differentiator

**Local Deployment:**
- Single binary CLI (Go) runs on user's laptop
- PostgreSQL runs locally (Docker or native install)
- Python ML services run locally (Docker or virtualenv)
- All data stored in `~/.knowledge-graph/` (configurable)

**Why NOT Cloud-First:**
- Contradicts product mission (ownership, portability)
- Higher costs for users (SaaS pricing model)
- Privacy concerns (enterprise customers won't adopt)

---

### Federation Capability (Future)

**Why Federation:**
- **Team Collaboration:** Share knowledge subgraphs with teammates (selective disclosure)
- **Public Knowledge Graphs:** Community-curated knowledge (Wikipedia-style for AI context)
- **Decentralization:** No single point of failure, no platform risk

**Architecture:**
- **P2P Protocol:** Nodes discover peers, exchange knowledge subgraphs
- **Selective Disclosure:** Users choose what to share (cryptographic access control)
- **Conflict Resolution:** CRDTs or operational transforms for concurrent updates
- **Trust Model:** Web-of-trust or blockchain-based verification (TBD based on user needs)

**Why NOT Centralized Platform:**
- Single point of failure (platform risk)
- Censorship concerns (public knowledge graphs should be uncensorable)
- Cost: centralized hosting expensive at scale

---

### Cloud Deployment (Managed Hosting Option)

**Why Managed Hosting:**
- **Convenience:** Users who don't want to self-host (lower barrier to adoption)
- **Revenue:** SaaS pricing model (freemium → paid conversion)
- **Enterprise:** Hosted option with SLA, support, compliance certifications

**Infrastructure:**
- **Kubernetes:** Container orchestration for multi-tenant deployment
- **PostgreSQL (Managed):** AWS RDS, Google Cloud SQL, or Crunchy Data
- **Docker Containers:** Go API server, Python ML services, background workers
- **Load Balancing:** Nginx or cloud-native load balancers
- **Monitoring:** Prometheus + Grafana (observability for SRE team)

**Cloud Provider Choice (TBD):**
- **AWS:** Largest ecosystem, best for enterprise customers
- **Google Cloud:** Good for ML workloads (TPUs, Vertex AI)
- **Hetzner/DigitalOcean:** Cost-effective for bootstrapped phase

**Why NOT Serverless:**
- Knowledge graph requires stateful persistence (PostgreSQL, Neo4j)
- Vector search is CPU-intensive (cold starts kill performance)
- Cost unpredictable with high-volume queries

---

## Development Tools

### Version Control: Git + GitHub

**Why GitHub:**
- **Open Source Community:** Largest developer community, best for open source projects
- **CI/CD:** GitHub Actions for automated testing, building, deployment
- **Project Management:** Issues, PRs, Projects for roadmap tracking
- **Visibility:** Social coding, build-in-public, community engagement

**Branching Strategy:**
- `main` — Production-ready code (tagged releases)
- `develop` — Integration branch for features
- Feature branches: `feature/<name>`, `fix/<name>`
- Release branches: `release/v0.1.0`

---

### Testing

**Go Testing (Built-in `testing` package):**
- Unit tests for all packages
- Integration tests for database access, API endpoints
- Benchmark tests for performance-critical code (query latency)

**Python Testing (pytest):**
- Unit tests for entity extraction, embedding generation
- Integration tests for ML pipeline end-to-end
- Fixtures for test data (sample texts, entities, embeddings)

**End-to-End Testing:**
- CLI test scripts (bash scripts exercising `kg` commands)
- Docker Compose for reproducible test environments
- CI/CD runs full test suite on every PR

**Target:** 90%+ code coverage across Go and Python codebases

---

### Linting & Formatting

**Go:**
- `gofmt` — Standard Go formatting
- `golangci-lint` — Comprehensive linting (staticcheck, errcheck, govet, etc.)
- `goimports` — Auto-organize imports

**Python:**
- `black` — Opinionated code formatting (no bikeshedding)
- `ruff` — Fast linter (replaces flake8, isort, pylint)
- `mypy` — Static type checking (enforce type hints)

**Pre-Commit Hooks:**
- Run linters and formatters before commit (prevent bad code from entering repo)
- CI fails if linting errors exist (enforce standards)

---

### Documentation

**Approach:**
- **Architecture Decision Records (ADRs):** Document every major decision (why Go, why PostgreSQL, why Ollama)
- **Code Documentation:** Godoc for Go, docstrings for Python (auto-generated API docs)
- **User Documentation:** Markdown docs in `/docs`, published to GitHub Pages or dedicated site
- **Video Tutorials:** Screen recordings for visual learners (YouTube channel)

**Tools:**
- `mdbook` or `hugo` for static site generation (docs site)
- Mermaid diagrams for architecture visuals
- Asciinema for terminal recordings (CLI demos)

---

## Rationale Summary

### Strategic Coherence

Every technical choice supports the product mission:

1. **Go for CLI and API:** Performance, single-binary distribution, simplicity → enables local-first, universal deployment
2. **Python for ML:** Best-in-class NLP ecosystem → enables high-quality entity extraction and embeddings
3. **PostgreSQL + pgvector → Neo4j:** Start simple, scale to complexity as needed → sustainable for part-time build, grows with product
4. **Ollama + nomic-embed-text:** Local, private, cost-free → aligns with "you own it" mission
5. **Multi-model abstraction:** AI-agnostic by design → core differentiator (models are fungible)
6. **CLI-first, editor integrations, MCP:** Meet developers where they are → adoption and dogfooding
7. **HTMX over React:** Simplicity, velocity, avoid overengineering → sustainable for solo developer initially
8. **Local-first, federation-capable, cloud-optional:** Privacy, ownership, flexibility → product positioning as infrastructure

### Why These Choices Matter Long-Term

- **Open Source Credibility:** Go and Python are open, PostgreSQL and Neo4j are open → aligns with open source core strategy
- **Hiring:** Go and Python are popular → easy to hire as team grows
- **Ecosystem:** SQL and Cypher are standards → power users can extend without learning proprietary query language
- **Portability:** Standard formats (GraphML, JSON-LD) and open protocols → users can leave anytime (builds trust)
- **Sustainability:** Simple architecture, proven technologies → maintainable over 5-10 years (infrastructure requires longevity)

### What We're NOT Doing (And Why)

- **NOT React/TypeScript:** Overengineered for this use case, slows velocity (HTMX is sufficient)
- **NOT Microservices Hell:** Two services (Go + Python) is enough; more adds complexity without value initially
- **NOT Proprietary Formats:** GraphML, JSON-LD, SQL, Cypher are standards → enables ecosystem, prevents lock-in
- **NOT Cloud-Only:** Local-first is strategic advantage → privacy, cost, ownership (cloud is optional add-on)
- **NOT Bleeding-Edge Tech:** Proven technologies (PostgreSQL 30+ years, Go 15 years, spaCy 9 years) → reduce risk, focus on product not tech

### The Bottom Line

**This tech stack is chosen for:**
- **Velocity:** Part-time build initially requires fast iteration (Go + Python + PostgreSQL = proven, fast)
- **Sustainability:** 5-10 year vision requires maintainable tech (no exotic frameworks that disappear)
- **Mission Alignment:** Every choice reinforces AI-agnostic, local-first, open infrastructure positioning
- **Developer Adoption:** CLI-first, editor integrations, standard formats → meets developers where they are
- **Business Model:** Local open source + cloud managed hosting + enterprise features → three revenue streams from one codebase

**This is infrastructure built to last. Simple, proven, extensible. Just like the mission demands.**
