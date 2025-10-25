# /start-build - Initialize New Build Project

Initialize a new build project in the `builds/` directory with full Agent-OS integration.

## Command Usage

```
/start-build [build-name] [--skip-product-planning]
```

**Parameters:**
- `build-name` (required): Name of the new build (kebab-case recommended)
- `--skip-product-planning` (optional): Skip automatic product planning step

**Examples:**
```
/start-build my-new-feature
/start-build advanced-dashboard --skip-product-planning
/start-build ml-pipeline-v2
```

---

## What This Command Does

**Phase 1: Build Directory Initialization**
1. ✅ Creates `builds/[build-name]/` directory structure
2. ✅ Initializes build status tracking
3. ✅ Creates README with quick start guide
4. ✅ Sets up .gitignore if needed

**Phase 2: Agent-OS Installation**
1. ✅ Changes to build directory
2. ✅ Runs `/install-agent-os` to set up Agent-OS infrastructure
3. ✅ Installs 19+ inherited standards
4. ✅ Enables all Claude Code commands and agents
5. ✅ Configures multi-agent mode

**Phase 3: Product Planning (Optional)**
1. ✅ Runs `/plan-product` to create:
   - `agent-os/product/mission.md` - Product vision and strategy
   - `agent-os/product/roadmap.md` - Feature roadmap
   - `agent-os/product/tech-stack.md` - Technology decisions
2. ⏭️ Skips if `--skip-product-planning` flag provided

**Phase 4: Build Initialization Complete**
1. ✅ Creates BUILD-INITIALIZED.md status document
2. ✅ Logs all created files and directories
3. ✅ Provides next steps and quick commands
4. ✅ Returns to platform root directory

---

## Implementation Workflow

### Step 1: Validate and Prepare

**Actions:**
1. Verify current directory is platform root
2. Validate build name (alphanumeric, hyphens, underscores only)
3. Check if `builds/[build-name]/` already exists
   - If exists: Error and exit
   - If not: Proceed
4. Parse command flags

**Validations:**
- Build name must not be empty
- Build name must be valid directory name
- Platform must have `builds/` directory
- Agent-OS must be available in platform

### Step 2: Create Build Directory Structure

**Actions:**
1. Create `builds/[build-name]/` directory
2. Create initial subdirectories:
   ```
   builds/[build-name]/
   ├── README.md                 # Quick start guide
   ├── .gitignore               # Build-specific ignores
   └── BUILD-STATUS.md          # Initialization tracking
   ```

**README.md Contents:**
```markdown
# [Build Name]

**Build Type:** [Inferred from name or "General"]
**Created:** [ISO-8601 timestamp]
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
```

**BUILD-STATUS.md Contents:**
```markdown
# Build Status: [Build Name]

**Created:** [ISO-8601 timestamp]
**Current Phase:** Initialization Complete
**Agent-OS Version:** [from config.yml]

## Initialization Log

### ✅ Phase 1: Directory Structure
- Created: builds/[build-name]/
- Created: README.md
- Created: .gitignore
- Created: BUILD-STATUS.md

### ✅ Phase 2: Agent-OS Installation
- Installed Agent-OS in: builds/[build-name]/agent-os/
- Inherited Standards: 19+ standards from platform
- Commands Enabled: /plan-product, /new-spec, /create-spec, /implement-spec
- Multi-Agent Mode: Enabled

### [✅/⏭️] Phase 3: Product Planning
[If ran:]
- ✅ Created: agent-os/product/mission.md
- ✅ Created: agent-os/product/roadmap.md
- ✅ Created: agent-os/product/tech-stack.md
[If skipped:]
- ⏭️ Skipped: Product planning (use /plan-product when ready)

### ✅ Phase 4: Build Ready
- Status: Initialized and ready for development
- Next: Create first spec with /new-spec

## File Inventory

**Created Files:**
- README.md
- .gitignore
- BUILD-STATUS.md
- agent-os/config.yml
- agent-os/product/mission.md (if product planning ran)
- agent-os/product/roadmap.md (if product planning ran)
- agent-os/product/tech-stack.md (if product planning ran)
- agent-os/standards/global/* (19+ inherited standards)
- agent-os/standards/backend/* (backend standards)
- agent-os/standards/frontend/* (frontend standards)
- agent-os/standards/testing/* (testing standards)

**Total Files Created:** [count]

## Quick Commands Reference

From `builds/[build-name]/` directory:

```bash
# Define product (if skipped)
/plan-product

# Create new feature spec
/new-spec [feature-name]

# After spec initialized, write detailed spec
/create-spec

# Implement the spec
/implement-spec

# View all standards
ls agent-os/standards/global/
```

## Git Integration

**Recommendation:** Commit initialization:
```bash
git add .
git commit -m "Initialize [build-name] build with Agent-OS"
```

---

**Build initialized successfully. Ready for development.**
```

**.gitignore Contents:**
```
# Build artifacts
*.log
*.tmp
.DS_Store

# IDE
.vscode/
.idea/

# Dependencies
node_modules/
vendor/

# Build outputs
dist/
build/
target/

# Environment
.env
.env.local

# Working files
.working.md
```

### Step 3: Install Agent-OS

**Actions:**
1. Change directory to `builds/[build-name]/`
2. Verify platform Agent-OS is available
3. Run Agent-OS installation:
   - If platform has `/install-agent-os` command: Use that
   - Otherwise: Run installation script directly
4. Verify installation completed successfully:
   - Check for `agent-os/config.yml`
   - Verify standards directories exist
   - Confirm commands are available

**Expected Result:**
```
builds/[build-name]/
├── agent-os/
│   ├── config.yml
│   ├── product/                 # Empty initially
│   ├── standards/
│   │   ├── global/              # 19+ inherited standards
│   │   ├── backend/
│   │   ├── frontend/
│   │   └── testing/
│   └── specs/                   # Empty initially
└── .agent-os/                   # Symlink or copy
```

### Step 4: Product Planning (Conditional)

**If `--skip-product-planning` flag NOT provided:**

**Actions:**
1. Check if `/plan-product` command exists
2. If exists: Run `/plan-product` command
   - Creates `agent-os/product/mission.md`
   - Creates `agent-os/product/roadmap.md`
   - Creates `agent-os/product/tech-stack.md`
3. If not exists: Skip with warning

**If `--skip-product-planning` flag provided:**
- Skip product planning
- Note in BUILD-STATUS.md that user can run `/plan-product` later

### Step 5: Finalize and Report

**Actions:**
1. Update BUILD-STATUS.md with complete initialization log
2. Count all created files
3. Log git status
4. Return to platform root directory
5. Display success message with next steps

**Success Message:**
```
✅ Build Initialized Successfully: [build-name]

📁 Location: builds/[build-name]/

✅ Created:
   - Build directory structure
   - README.md with quick start guide
   - Agent-OS installation with 19+ standards
   - [Product planning documents (if ran)]
   - BUILD-STATUS.md tracking document

📊 Files Created: [count]

🎯 Next Steps:

   1. Navigate to build directory:
      cd builds/[build-name]

   2. [If product planning skipped:]
      Define your product vision:
      /plan-product

   3. Create your first feature spec:
      /new-spec [feature-name]

   4. Review build status:
      cat BUILD-STATUS.md

📖 Quick Reference:
   - README: builds/[build-name]/README.md
   - Status: builds/[build-name]/BUILD-STATUS.md
   - Standards: builds/[build-name]/agent-os/standards/

🔄 Returned to platform root. Navigate to build when ready:
   cd builds/[build-name]
```

---

## Error Handling

**Common Errors:**

1. **Build Already Exists:**
   ```
   ❌ Error: Build 'build-name' already exists at builds/build-name/

   Options:
   - Choose a different name
   - Remove existing build: rm -rf builds/build-name
   - Navigate to existing build: cd builds/build-name
   ```

2. **Invalid Build Name:**
   ```
   ❌ Error: Invalid build name: '[name]'

   Build names must:
   - Contain only alphanumeric characters, hyphens, underscores
   - Not be empty
   - Be valid directory names

   Examples: my-feature, ml_pipeline, dashboard-v2
   ```

3. **Agent-OS Not Available:**
   ```
   ❌ Error: Agent-OS not found in platform

   Required for build initialization.

   Options:
   - Ensure platform has agent-os/ directory
   - Install Agent-OS in platform first
   - Check platform structure
   ```

4. **Installation Failed:**
   ```
   ❌ Error: Agent-OS installation failed

   Partial initialization may have occurred.

   Recovery:
   1. Check builds/[build-name]/ for partial files
   2. Remove if needed: rm -rf builds/[build-name]
   3. Retry: /start-build [build-name]
   4. Check agent-os/scripts/project-install.sh for issues
   ```

---

## Implementation Requirements

**Key Requirements:**
1. ✅ Validate all inputs before creating directories
2. ✅ Create atomic operations where possible
3. ✅ Provide clear error messages with recovery options
4. ✅ Log all actions to BUILD-STATUS.md
5. ✅ Return to platform root after completion
6. ✅ Handle both success and failure cases gracefully
7. ✅ Verify Agent-OS installation completed successfully
8. ✅ Support both with and without product planning

**Dependencies:**
- Platform must have `builds/` directory
- Platform must have Agent-OS available (agent-os/ or ~/.agent-os/)
- `/install-agent-os` command must be available OR installation script accessible
- `/plan-product` command must be available (for product planning phase)

---

## Example Usage Scenarios

### Scenario 1: Full Initialization with Product Planning
```bash
# User in platform root
/start-build advanced-analytics

# Result:
# - builds/advanced-analytics/ created
# - Agent-OS installed
# - Product planning completed
# - Ready for first spec
```

### Scenario 2: Quick Initialization, Plan Later
```bash
/start-build quick-prototype --skip-product-planning

# Result:
# - builds/quick-prototype/ created
# - Agent-OS installed
# - Product planning skipped
# - User can run /plan-product when ready
```

### Scenario 3: ML Project with Custom Standards
```bash
/start-build ml-training-pipeline

# After initialization:
cd builds/ml-training-pipeline
# Add custom ML standards to agent-os/standards/ml/
# Create first spec: /new-spec data-ingestion
```

---

## Integration with Existing Commands

**Workflow After /start-build:**

```
/start-build [name]
   ↓
[Build initialized with Agent-OS]
   ↓
/plan-product (if not already done)
   ↓
[Product vision defined]
   ↓
/new-spec [feature]
   ↓
[Spec folder created]
   ↓
/create-spec
   ↓
[Detailed spec written]
   ↓
/implement-spec
   ↓
[Feature implemented]
```

**Command Relationship:**
- `/start-build` → Creates build infrastructure
- `/install-agent-os` → Installed automatically by /start-build
- `/plan-product` → Run automatically or manually after /start-build
- `/new-spec` → Used after build initialization
- `/create-spec` → Used after spec initialization
- `/implement-spec` → Used after spec creation

---

## Notes for Implementation

**For Claude Code:**
When this command is invoked:

1. Parse the command line to extract build name and flags
2. Execute each phase sequentially
3. Verify each phase completed successfully before proceeding
4. Log all actions and file creations
5. Handle errors gracefully with clear recovery instructions
6. Return to platform root directory after completion
7. Display comprehensive success message with next steps

**Specialist Agents:**
This command orchestrates but does not require specialized subagents. It's a directory and file creation workflow that uses existing commands (`/install-agent-os` and `/plan-product`) to set up the build environment.

**File Operations:**
All file operations should be done with appropriate tools:
- Use `Bash` for directory creation and navigation
- Use `Write` for creating markdown files
- Use existing commands for Agent-OS and product setup
- Use `Read` to verify created files

---

**This command completes the build lifecycle:** Platform → Build → Product → Spec → Implementation