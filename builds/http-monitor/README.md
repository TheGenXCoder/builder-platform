# HTTP Monitor

**Build Type:** Monitoring Tool
**Created:** 2025-10-21T00:00:00Z
**Status:** Initialized

## Quick Start

This build has been initialized with Agent-OS integration.

### Available Commands

- `/plan-product` - Define product vision and roadmap (if not already done)
- `/new-spec [feature]` - Create new feature specification
- `/create-spec` - Write detailed specification from requirements
- `/implement-spec` - Implement spec with specialized agents

### Directory Structure

- `agent-os/` - Agent-OS configuration and standards
  - `product/` - Product mission, roadmap, tech-stack
  - `standards/` - Inherited and custom development standards
  - `specs/` - Feature specifications (created via /new-spec)
- `src/` - Source code (create as needed)
- `docs/` - Documentation (create as needed)

### Next Steps

1. Review or create product documentation:
   - Edit `agent-os/product/mission.md`
   - Edit `agent-os/product/roadmap.md`
   - Edit `agent-os/product/tech-stack.md`

2. Create your first feature spec:
   ```
   /new-spec [feature-name]
   ```

3. Build your feature:
   ```
   /create-spec
   /implement-spec
   ```

---

**Build initialized via `/start-build` command**
**Platform:** builder-platform
