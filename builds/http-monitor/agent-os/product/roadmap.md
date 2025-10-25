# Product Roadmap

1. [ ] Core Monitoring Engine — Build the foundational monitoring system using Go goroutines for concurrent HTTP/HTTPS health checks on scheduled intervals (time.Ticker), store check results in PostgreSQL with partitioned tables for time-series data, and provide a basic admin interface (HTMX + html/template) for creating and managing monitors. `L`

2. [ ] Real-Time Dashboard — Create a live dashboard using HTMX with server-sent events (SSE) that displays current status of all monitors, shows recent check history (last 24 hours), and provides uptime percentages with color-coded status indicators and automatic real-time updates without page refreshes. `M`

3. [ ] Email Alert System — Implement email notification delivery using Go's net/smtp when monitors transition from passing to failing (or vice versa), with configurable retry logic (e.g., fail 3 consecutive checks before alerting) to prevent false alarms from transient issues. `M`

4. [ ] Response Time Tracking — Add response time measurement to each health check using Go's time package, store historical response time data in PostgreSQL partitioned tables, and display basic response time charts on the dashboard showing performance trends over 24 hours, 7 days, and 30 days. `M`

5. [ ] Advanced Health Check Configuration — Enable customizable success criteria beyond HTTP 200 using Go's http.Client, including status code validation, response time thresholds, response body content matching (substring or regex), and custom header validation. Store configuration in PostgreSQL JSONB columns for flexibility. `L`

6. [ ] Multi-Channel Alerting — Expand notification system to support Slack webhooks, Discord webhooks, and generic webhook integrations using Go's http.Client with retry logic, allowing teams to route alerts to their existing communication platforms with customizable message templates (html/template). `M`

7. [ ] Monitor Management API — Build RESTful API using chi router for programmatic monitor creation, updates, deletion, and status retrieval, enabling infrastructure-as-code workflows and CI/CD integration for monitoring configuration. Include JWT or API key authentication. `M`

8. [ ] Uptime Reports & Analytics — Generate historical uptime reports for any time period (daily, weekly, monthly, custom date ranges) using PostgreSQL time-series queries, calculate SLA percentages, identify patterns in failures, and export reports as PDF (third-party Go library) or CSV. `L`

9. [ ] Public Status Pages — Create optional public-facing status pages using HTMX for real-time updates that display service health for end users, support custom branding via configuration, allow incident updates, and provide subscription options for status change notifications. `L`

10. [ ] Degradation Detection & Alerting — Implement intelligent performance monitoring in Go that establishes baseline response times per monitor using statistical analysis, detects gradual degradation (e.g., response times increasing 50% over 6 hours), and sends early warning alerts before complete service failures. `M`

11. [ ] Configuration as Code — Support YAML/JSON configuration files for defining monitors (parsed by Go's encoding/yaml and encoding/json), allow bulk import/export of monitor configurations via API, enable version control of monitoring setup, and provide CLI tool (Go cobra or flag) for configuration deployment. `S`

12. [ ] Advanced Scheduling & Maintenance Windows — Add support for complex check schedules using cron-style expressions (robfig/cron library), maintenance window configuration (suppress alerts during planned downtime stored in PostgreSQL), and timezone-aware scheduling for global teams using Go's time package. `S`

> Notes
> - Roadmap follows technical dependencies: core engine → dashboard → alerting → advanced features
> - Each feature builds toward the mission of providing enterprise monitoring without enterprise complexity
> - Ordered to deliver value incrementally: basic monitoring (1-3) → insights (4-5) → team collaboration (6-7) → polish (8-12)
> - Backend uses Go with standard library + pgx, frontend uses HTMX + Tailwind CSS, deployment via Docker Compose
> - Go's concurrency model makes features 1-4 significantly faster to implement than traditional frameworks
> - HTMX eliminates frontend build complexity while providing modern real-time UX for features 2, 9
