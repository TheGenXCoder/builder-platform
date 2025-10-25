# Tech Stack

## Overview

HTTP Monitor uses a high-performance, lightweight tech stack specifically chosen for concurrent HTTP monitoring at scale. The combination of Go's goroutines, PostgreSQL's time-series capabilities, HTMX's server-driven approach, and Docker's containerization creates a monitoring platform that is fast, resource-efficient, and simple to self-host.

## Application Framework

### Backend Language & Framework
- **Language:** Go 1.21+
- **HTTP Server:** Standard library net/http with chi router
- **Rationale:** Go is the ideal choice for HTTP monitoring due to its exceptional concurrency model (goroutines), built-in HTTP client with timeouts and cancellation, low memory footprint, and single-binary deployment. A monitoring system that checks hundreds of endpoints every minute needs the efficiency and performance that Go provides out of the box.

### HTTP Router
- **Router:** chi (lightweight, stdlib-compatible)
- **Alternative:** Standard library http.ServeMux (Go 1.22+ enhancements)
- **Rationale:** chi provides a clean routing API while remaining 100% compatible with standard library interfaces. For a monitoring dashboard, routing needs are simple, and chi delivers without the overhead of larger frameworks.

### Template Engine
- **Engine:** Go standard library html/template
- **Escaping:** Automatic HTML escaping for security
- **Rationale:** Server-rendered templates pair perfectly with HTMX. Go's template engine is secure by default, performant, and requires no external dependencies.

## Data Storage

### Primary Database
- **Database:** PostgreSQL 15+
- **Driver:** pgx (high-performance PostgreSQL driver)
- **Connection Pooling:** pgxpool for efficient connection management
- **Rationale:** PostgreSQL provides excellent time-series data support through table partitioning, JSONB for flexible monitor configurations, and robust indexing for fast queries. pgx is the fastest PostgreSQL driver for Go, offering prepared statements and batch operations critical for high-volume monitoring data.

### Database Optimizations
- **Time-Series Data:** Table partitioning by time (daily or weekly partitions)
- **Indexes:** Composite indexes on (monitor_id, checked_at) for fast historical queries
- **JSONB:** Store monitor configuration (headers, validation rules) in JSONB columns
- **Data Retention:** Automatic partition pruning via pg_cron or Go scheduled job
- **Rationale:** Monitoring systems generate massive write volumes. Partitioning keeps queries fast (scan only relevant partitions), while JSONB enables flexible monitor configuration without schema migrations for every new check type.

### Migrations
- **Tool:** golang-migrate/migrate or custom migration system
- **Format:** SQL files with up/down migrations
- **Versioning:** Migration version tracked in database schema_migrations table
- **Rationale:** SQL migrations give full control over database schema, indexes, and partitioning logic. Critical for time-series optimization strategies.

## Frontend

### Hypermedia Framework
- **Framework:** HTMX 1.9+
- **Rationale:** HTMX is the perfect choice for a monitoring dashboard. Real-time updates via server-sent events (SSE), partial page updates without full reloads, and zero build step complexity. The dashboard shows live monitor status without React's complexity or JavaScript bundle weight. Server-driven architecture means all business logic stays in Go where it belongs.

### CSS Framework
- **Framework:** Tailwind CSS 3.4+
- **Build:** Tailwind CLI (standalone binary)
- **Rationale:** Tailwind enables rapid UI development with utility classes. The standalone CLI integrates seamlessly with Go's template workflow—no Node.js build pipeline required for development.

### Client-Side Interactivity (Optional)
- **Library:** Alpine.js 3.x (minimal, only if needed)
- **Use Cases:** Dropdown menus, modals, client-side form validation
- **Rationale:** Alpine.js provides lightweight interactivity (like toggling UI elements) without requiring a full JavaScript framework. Most interactivity comes from HTMX; Alpine.js fills gaps for purely client-side UI state.

### Real-Time Updates
- **Technology:** Server-Sent Events (SSE) via HTMX
- **Protocol:** HTTP/1.1 text/event-stream
- **Rationale:** SSE provides unidirectional real-time updates (server to client) perfect for dashboard status updates. HTMX has built-in SSE support (hx-sse attribute). No WebSocket complexity needed for read-only dashboard updates.

### Icons
- **Library:** Lucide Icons (inline SVG)
- **Implementation:** SVG sprites or inline <svg> tags in templates
- **Rationale:** Inline SVG icons eliminate external dependencies and HTTP requests. Lucide provides clean, modern icons for status indicators, navigation, and UI elements.

## Background Jobs & Scheduling

### Job Scheduling
- **Implementation:** Go goroutines + time.Ticker
- **Alternative:** Third-party library like robfig/cron for cron-style schedules
- **Rationale:** Go's goroutines make scheduling trivial. Each monitor gets its own goroutine with a ticker for its check interval (1min, 5min, 15min, etc.). No external job queue needed—Go's concurrency primitives handle thousands of concurrent checks efficiently.

### Concurrent Monitoring
- **Pattern:** Worker pool with bounded concurrency
- **Channels:** Buffered channels for work distribution
- **Context:** context.Context for graceful shutdown and timeout propagation
- **Rationale:** Spawn a goroutine per monitor, but use worker pools to prevent resource exhaustion. Contexts enable clean cancellation when stopping the application or during timeouts.

### Job Persistence
- **Storage:** PostgreSQL (job state, next run time)
- **Recovery:** On startup, load monitor configurations and resume scheduling
- **Rationale:** Store monitor configuration and schedule state in PostgreSQL. On restart, load state and resume. No external job queue needed—Go handles execution, PostgreSQL handles persistence.

## HTTP Client

### HTTP Library
- **Client:** Go standard library net/http
- **Timeout Configuration:** Separate timeouts for dial, TLS handshake, and response read
- **Retry Logic:** Custom retry with exponential backoff via go-retryablehttp or custom implementation
- **Rationale:** Go's standard HTTP client is production-grade, supporting HTTP/1.1 and HTTP/2, with fine-grained timeout control. Perfect for monitoring where timeout precision matters.

### Timeout Strategy
- **Connection Timeout:** 5s (dial + TLS handshake)
- **Response Timeout:** Configurable per monitor (default 10s, max 60s)
- **Total Timeout:** Enforced via context.Context
- **Rationale:** Different monitors have different performance characteristics. Allow per-monitor timeout configuration while enforcing sane defaults.

### SSL/TLS
- **Validation:** Full certificate chain validation by default
- **Custom CA Certs:** Support for private CA certificates via tls.Config
- **Certificate Expiry Tracking:** Extract cert expiry from TLS handshake and alert before expiration
- **Rationale:** Monitoring HTTPS endpoints requires robust TLS handling. Go's crypto/tls package provides excellent certificate inspection and validation APIs.

## Deployment & Infrastructure

### Containerization
- **Container:** Docker multi-stage build
- **Base Image:** golang:1.21 (build stage), alpine:latest or scratch (runtime stage)
- **Orchestration:** Docker Compose for local development and simple deployments
- **Rationale:** Multi-stage Docker builds produce tiny binaries (~10-20MB) in minimal containers. Docker Compose defines the full stack (Go app + PostgreSQL + optional Nginx) in a single docker-compose.yml, making self-hosting trivial.

### Multi-Stage Docker Build
```dockerfile
# Stage 1: Build Go binary
FROM golang:1.21 AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o http-monitor

# Stage 2: Runtime container
FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/http-monitor .
EXPOSE 8080
CMD ["./http-monitor"]
```
- **Size:** ~15MB final image (compared to 800MB+ for full Go image)
- **Security:** Minimal attack surface with alpine or scratch base

### Docker Compose Stack
- **Services:**
  - App: Go binary (http-monitor)
  - Database: PostgreSQL 15+ with persistent volume
  - Reverse Proxy: Nginx (optional, for TLS termination and static asset serving)
- **Volumes:** PostgreSQL data volume, app config/logs
- **Networking:** Internal Docker network for app<->database, exposed port for web UI
- **Rationale:** Single docker-compose.yml provides complete self-hosted deployment. Run `docker-compose up` and the entire monitoring platform is live.

### Hosting Options
- **Self-Hosted:** Any VPS (DigitalOcean Droplet, Linode, AWS EC2, Hetzner)
- **Requirements:** 1GB+ RAM, 10GB+ disk (scales with data retention)
- **Scaling:** Vertical scaling (more CPU/RAM) for single-node simplicity
- **Rationale:** Self-hosting is the core value proposition. Go's efficiency means a $5-10/month VPS can monitor hundreds of endpoints.

## CI/CD Pipeline

### CI/CD Platform
- **Platform:** GitHub Actions
- **Triggers:** Push to main (production), push to develop (staging)
- **Pipeline Stages:** Test → Build → Docker Push → Deploy
- **Rationale:** GitHub Actions integrates seamlessly with GitHub repositories. Simple YAML configuration for building Go binaries and Docker images.

### Testing Strategy
- **Test Framework:** Go standard library testing package
- **Test Types:** Unit tests (handlers, business logic), integration tests (database, HTTP client)
- **Coverage Target:** 80%+ code coverage
- **CI Requirement:** All tests must pass before merge
- **Rationale:** Go's built-in testing framework is excellent. Table-driven tests make covering edge cases straightforward.

### Build Artifacts
- **Artifacts:** Docker image pushed to Docker Hub or GitHub Container Registry
- **Tagging:** Git commit SHA + semantic version tags (v1.0.0, v1.1.0)
- **Rationale:** Docker images are the deployment unit. Tag with both commit SHA (traceability) and semantic versions (release management).

### Deployment Strategy
- **Production:** Automatic deploy via docker-compose pull + restart on main branch merge
- **Staging:** Automatic deploy to staging environment on develop branch merge
- **Rollback:** Deploy previous Docker image tag via docker-compose
- **Rationale:** Immutable Docker images make rollback instant—just run the previous image tag.

## Notifications & Integrations

### Email Delivery
- **Library:** Standard library net/smtp or third-party library like gomail
- **SMTP Provider:** Postmark, SendGrid, or self-hosted SMTP
- **Templates:** html/template for email bodies
- **Rationale:** Email alerts are critical for monitoring. Go's SMTP support is straightforward, and templates can be reused from web UI.

### Webhook Delivery
- **Implementation:** Standard library net/http POST with retry logic
- **Supported Integrations:** Slack, Discord, generic webhooks, PagerDuty
- **Payload Format:** JSON with consistent schema
- **Retry Strategy:** Exponential backoff (3 retries: 1s, 5s, 25s)
- **Rationale:** Webhooks enable integration with any team communication platform. Retry logic ensures delivery reliability even during transient network issues.

### Alert Channels
- **Email:** SMTP-based email alerts
- **Slack:** Webhook POST to Slack incoming webhook URL
- **Discord:** Webhook POST to Discord webhook URL
- **Generic Webhooks:** HTTP POST with customizable JSON payload
- **PagerDuty:** Integration via Events API v2
- **Rationale:** Support most common team communication platforms out of the box. Generic webhooks enable custom integrations.

## Monitoring & Observability

### Application Logging
- **Format:** Structured JSON logs via log/slog (Go 1.21+)
- **Levels:** DEBUG, INFO, WARN, ERROR
- **Output:** stdout (captured by Docker or systemd)
- **Rationale:** Structured logs enable parsing and filtering. slog is the new standard library logger with excellent performance and zero-allocation structured logging.

### Metrics
- **Library:** prometheus/client_golang
- **Metrics Endpoint:** /metrics (Prometheus format)
- **Key Metrics:** Check success/failure rates, response time histograms, goroutine count, memory usage
- **Rationale:** Prometheus metrics provide insight into the monitoring system itself. Critical for observability and debugging performance issues.

### Health Checks
- **Endpoint:** /health (returns 200 OK if healthy)
- **Checks:** Database connectivity (SELECT 1), goroutine health (panic recovery)
- **Rationale:** Load balancers and orchestrators need health endpoints to route traffic. Simple checks ensure the app and database are operational.

### Error Tracking
- **Service:** Sentry (optional, via sentry-go SDK)
- **Capture:** Panics, unexpected errors, failed checks
- **Rationale:** Error tracking helps debug production issues. Sentry Go SDK integrates cleanly with Go error handling patterns.

## Security

### Authentication & Authorization
- **Admin Auth:** Session-based authentication with HTTP-only cookies
- **Password Hashing:** bcrypt (Go crypto/bcrypt)
- **API Auth:** Bearer tokens (JWT or opaque tokens)
- **Authorization:** Role-based access control (RBAC) in application code
- **Rationale:** Simple session-based auth for web UI, token-based auth for API/automation. bcrypt is industry-standard for password hashing.

### Data Protection
- **Secrets Management:** Environment variables via .env file or Docker secrets
- **Database Encryption:** At-rest encryption via PostgreSQL config or managed provider
- **TLS:** Enforce HTTPS for all web traffic (via Nginx reverse proxy)
- **Rationale:** Environment variables keep secrets out of code. TLS protects data in transit. PostgreSQL encryption protects data at rest.

### Input Validation
- **Validation:** Manual validation in handlers (URL format, interval ranges)
- **SQL Injection Prevention:** Parameterized queries via pgx (automatic)
- **XSS Prevention:** html/template automatic escaping
- **Rationale:** Go's standard library provides excellent security primitives. Manual validation gives full control over business rules.

## Development Tools

### Code Quality
- **Linter:** golangci-lint (aggregates 50+ Go linters)
- **Formatter:** gofmt or goimports (standard Go formatting)
- **Pre-Commit Hooks:** golangci-lint + gofmt via pre-commit framework
- **Rationale:** golangci-lint catches common bugs and style issues. gofmt ensures consistent formatting. Pre-commit hooks enforce quality before commits.

### Local Development
- **Database:** PostgreSQL via Docker or local installation
- **Environment Management:** .env file loaded via godotenv or direnv
- **Live Reload:** air (live reload for Go applications)
- **Rationale:** Docker simplifies PostgreSQL setup. air provides fast feedback during development (watches files, rebuilds, restarts).

### Testing Tools
- **Mocking:** testify/mock or manual mocks
- **HTTP Testing:** httptest package (standard library)
- **Database Testing:** Test containers (testcontainers-go) or shared test database
- **Rationale:** Go's testing package handles most needs. testify adds helpful assertions. testcontainers provides real PostgreSQL for integration tests.

## Third-Party Services

### Optional Services
- **Email Delivery:** Postmark or SendGrid (for reliable transactional email)
- **Error Tracking:** Sentry (for exception monitoring)
- **DNS:** Cloudflare or provider of choice (for app domain)
- **Rationale:** These services provide capabilities that are better outsourced than self-built. All are optional—monitoring works without them.

### Self-Hosted Alternatives
- **Email:** Self-hosted SMTP server (Postfix)
- **Error Tracking:** Self-hosted Sentry instance
- **Rationale:** For users who want zero external dependencies, all services can be self-hosted or omitted.

## Summary

This tech stack prioritizes:

- **Performance:** Go's goroutines enable monitoring thousands of endpoints concurrently with minimal resource usage
- **Simplicity:** HTMX eliminates frontend build complexity while delivering modern real-time UX
- **Scalability:** PostgreSQL time-series optimizations and Go's efficiency scale from 10 to 10,000 monitors
- **Self-Hosting:** Single Docker Compose file deploys the entire stack—no external services required
- **Developer Productivity:** Standard library-first approach, minimal dependencies, fast build times
- **Reliability:** Battle-tested technologies (Go, PostgreSQL, Docker) with proven production track records

The combination of Go + PostgreSQL + HTMX + Docker creates a monitoring platform that is:
- Fast to develop (Go's simplicity + HTMX's no-build approach)
- Fast to run (Go's performance + goroutines)
- Fast to deploy (Docker Compose)
- Cheap to operate (minimal resource footprint)

This stack is ideally suited for HTTP Monitor's mission: enterprise monitoring without enterprise complexity or cost.
