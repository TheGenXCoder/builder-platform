## Tech Stack

Define your technical stack below. This serves as a reference and helps maintain consistency across projects.

### Primary Languages & Runtimes
- **Backend:** Go (systems, services, APIs)
- **Frontend:** JavaScript/TypeScript (web applications)
- **Scripting:** Python (automation, ML/data processing)
- **Systems:** Go (high-performance, concurrent systems)

### Application Framework & Runtime
- **Web Framework:** Go (gin, echo, fiber) or Node.js (Next.js, Express)
- **Language/Runtime:** Go 1.21+, Node.js 20+, Python 3.11+
- **Package Manager:** Go modules, npm/bun, pip

### Frontend
- **JavaScript Framework:** React, Next.js
- **CSS Framework:** Tailwind CSS
- **UI Components:** shadcn/ui (copy-to-codebase approach)
- **Type Safety:** TypeScript (strict mode)

### Database & Storage
- **Primary Database:** PostgreSQL 15+
- **Time-Series/Metrics:** PostgreSQL with TimescaleDB extension
- **ORM/Query Builder:**
  - Go: sqlc or pgx
  - Node.js: Prisma
  - Python: SQLAlchemy
- **Caching:** Redis 7+
- **Object Storage:** S3-compatible (AWS S3, MinIO)

### Message Queue & Events
- **Message Broker:** NATS / NATS JetStream
- **Event Streaming:** NATS JetStream or Kafka (when required)
- **Pub/Sub:** NATS core messaging

### Testing & Quality
- **Go Testing:** stdlib testing, testify
- **JavaScript Testing:** Jest, Vitest
- **Python Testing:** pytest
- **Linting/Formatting:**
  - Go: gofmt, golangci-lint
  - JavaScript: ESLint, Prettier
  - Python: ruff, black
- **Type Checking:** TypeScript (strict), mypy (Python)

### Deployment & Infrastructure
- **Containers:** Docker
- **Orchestration:** Kubernetes (k3s for local/edge, EKS/GKE for cloud)
- **CI/CD:** GitHub Actions
- **Hosting:**
  - Services: Railway, Render, Vercel (web apps)
  - Cloud: AWS, GCP (when self-hosting required)
- **Infrastructure as Code:** Terraform or Pulumi

### Observability & Monitoring
- **Metrics:** Prometheus + Grafana
- **Logging:** Structured logging (JSON)
  - Go: slog (stdlib)
  - JavaScript: pino
  - Python: structlog
- **Tracing:** OpenTelemetry
- **Error Tracking:** Sentry (consent-based)
- **Alerting:** Prometheus Alertmanager or PagerDuty

### AI/ML Stack
- **Local Models:** Ollama (codellama, llama3, mistral, deepseek-coder)
- **Model Serving:** Ollama API or custom Go/Python services
- **Computer Vision:** OpenCV, PyTorch
- **ML Training:** PyTorch, scikit-learn
- **Model Optimization:** ONNX Runtime, TensorRT

### Development Tools
- **Version Control:** Git, GitHub
- **Code Editor:** VSCode, Neovim
- **API Development:** Postman/Insomnia, httpie
- **Database Tools:** psql, pgAdmin, DBeaver

### Security & Authentication
- **Authentication:** Passkeys (WebAuthn), OAuth 2.0
- **Authorization:** RBAC (role-based access control)
- **Secrets Management:** Environment variables, Vault (production)
- **TLS/SSL:** Let's Encrypt, cert-manager (Kubernetes)

### Model Selection Strategy (from CLAUDE.md)
- **Default:** Local Ollama models (codellama, mistral, llama3)
- **Cloud Fallback:** Claude 3.5 Sonnet (complex tasks)
- **Maximum Reasoning:** Claude 4.1 Opus (rare, only when necessary)
- **RAM Limit:** 36GB - choose models appropriately

### Technology Selection Principles
- **2-Way Doors:** Prefer technologies with abstraction layers and portability
- **Open Standards:** Favor open protocols over proprietary formats
- **Data Ownership:** Always maintain control of data
- **Self-Hosting Option:** Prefer technologies that can be self-hosted
- **Performance:** Go for services, TypeScript for applications
- **Developer Experience:** Strong type systems, excellent tooling
