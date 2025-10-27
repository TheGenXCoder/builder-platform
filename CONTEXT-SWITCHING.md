# Catalyst9 Multi-Project Context Switching

## Overview

Catalyst9 supports **automatic context switching** based on your current project. This allows you to:

- Work on multiple projects/orgs simultaneously
- Automatically apply correct org/visibility/tags based on context
- Quickly switch between personal, client work (like UTA), and C9 development
- Never worry about accidentally adding knowledge to the wrong org

## How It Works

### Context Priority (highest to lowest):

1. **Environment Variables** - Override everything
2. **`.c9rc` file** - Project-level configuration (walks up directory tree)
3. **Built-in Defaults** - Personal, private

### Automatic Context Detection

When you start Claude or run C9 MCP, it automatically:
1. Looks for `.c9rc` in current directory
2. Walks up parent directories to find `.c9rc`
3. Loads configuration from found file
4. Applies environment variable overrides
5. Uses that context for all operations

## Quick Start

### 1. Enable Context Switching

Add to your `~/.zshrc` (or `~/.bashrc`):

```bash
# Load C9 context switching functions
source ~/personal/catalyst9/catalyst-core/scripts/c9-context.sh
```

Reload your shell:
```bash
source ~/.zshrc
```

### 2. Create Project Context

In your project directory:

```bash
# For a personal project
cd ~/my-project
c9-init personal my-project private

# For UTA client work
cd ~/work/uta-api
c9-init uta uta-api org

# For C9 development
cd ~/catalyst9/catalyst-core
c9-init catalyst9 catalyst-core org
```

### 3. Use Context Commands

```bash
# Show current context
c9-context

# Switch contexts
c9-personal      # Personal context
c9-uta          # UTA organization
c9-catalyst     # Catalyst9 org
c9-set acme my-project org  # Custom context

# Clear context (use .c9rc or defaults)
c9-clear
```

## Examples

### Example 1: Working on UTA Project

```bash
cd ~/work/uta-api
c9-uta  # or just rely on .c9rc

# Now when you use Claude:
# - "Add this API endpoint design to catalyst9"
#   → Automatically added to UTA org with tags: uta, api-integration, client-work
# - "Search catalyst9 for authentication"
#   → Searches only UTA org knowledge
```

### Example 2: Working on C9 Development

```bash
cd ~/catalyst9/catalyst-core
c9-catalyst

# When you use Claude:
# - "Add this implementation decision to catalyst9"
#   → Added to Catalyst9 org with tags: c9, development, knowledge-graph
# - "Search catalyst9 for authentication"
#   → Searches all accessible knowledge (personal + C9 org)
```

### Example 3: Personal Notes

```bash
cd ~/notes
c9-personal

# When you use Claude:
# - "Add this idea to catalyst9"
#   → Added to your personal space, private visibility
# - "Search catalyst9 for ideas"
#   → Searches only your personal knowledge
```

## `.c9rc` File Format

Create a `.c9rc` file in your project root:

```bash
# Organization context (leave empty for personal)
C9_ORG=uta

# Default visibility for knowledge added in this project
C9_DEFAULT_VISIBILITY=org

# Default tags to auto-apply
C9_DEFAULT_TAGS=uta,api-integration,client-work

# Search scope (personal, org, team, project, all)
C9_SEARCH_SCOPE=org

# Project identifier
C9_PROJECT=uta-api-integration

# Description (for documentation)
C9_PROJECT_DESC="UTA API Integration - Client Project"
```

### Visibility Options

- **`private`** - Only you can access (default)
- **`org`** - Everyone in the organization can access
- **`team`** - Specific team members can access
- **`public`** - Everyone can access

### Search Scope Options

- **`personal`** - Search only your personal knowledge
- **`org`** - Search only specified org's knowledge
- **`team`** - Search only team knowledge
- **`project`** - Search project-specific knowledge
- **`all`** - Search everything you have access to

## Environment Variable Overrides

You can override `.c9rc` settings with environment variables:

```bash
# Override for current session
export C9_ORG=uta
export C9_DEFAULT_VISIBILITY=org
export C9_SEARCH_SCOPE=org

# Or set permanently in ~/.zshrc
```

### Available Variables:

- `C9_ORG` - Organization slug
- `C9_PROJECT` - Project identifier
- `C9_DEFAULT_VISIBILITY` - Default visibility level
- `C9_DEFAULT_TAGS` - Comma-separated default tags
- `C9_SEARCH_SCOPE` - Default search scope

## Shell Function Reference

### `c9-context`
Show current context configuration

### `c9-personal`
Switch to personal context (private, no org)

### `c9-catalyst`
Switch to Catalyst9 organization context

### `c9-uta`
Switch to UTA organization context

### `c9-set <org> <project> [visibility]`
Create custom context
```bash
c9-set acme my-project org
```

### `c9-clear`
Clear environment overrides, use .c9rc or defaults

### `c9-init [org] [project] [visibility]`
Create `.c9rc` in current directory
```bash
c9-init uta uta-api org
```

### `c9-help`
Show help and command reference

## Best Practices

### 1. One `.c9rc` per Project
Create a `.c9rc` in each project root. The MCP wrapper will find it automatically.

### 2. Commit `.c9rc` to Git
Project context should be shared with your team. Everyone working on UTA should use UTA context.

### 3. Use Environment Variables for Personal Overrides
If you need personal settings different from team, use environment variables.

### 4. Keep Tags Organized
Use consistent tag naming:
- `uta`, `acme` - Organization/client name
- `api`, `ui`, `docs` - Component/area
- `decision`, `implementation`, `bug` - Type of knowledge

### 5. Set Appropriate Visibility
- Client work (UTA): `org` visibility so team can see it
- Personal notes: `private` visibility
- Open source: `public` visibility

## Use Cases

### Client Work (UTA Example)

**Setup:**
```bash
cd ~/work/uta-api
c9-init uta uta-api org
```

**`.c9rc`:**
```
C9_ORG=uta
C9_DEFAULT_VISIBILITY=org
C9_DEFAULT_TAGS=uta,api-integration,client-work
C9_SEARCH_SCOPE=org
```

**Result:**
- All knowledge auto-tagged with UTA tags
- Shared with UTA organization members
- Searches only UTA knowledge by default

### Internal Development (C9)

**Setup:**
```bash
cd ~/catalyst9/catalyst-core
c9-init catalyst9 catalyst-core org
```

**`.c9rc`:**
```
C9_ORG=catalyst9
C9_DEFAULT_VISIBILITY=org
C9_DEFAULT_TAGS=c9,development,knowledge-graph
C9_SEARCH_SCOPE=all
```

**Result:**
- Knowledge shared with C9 team
- Searches all accessible knowledge (helps with cross-referencing)
- Auto-tagged for C9 development

### Personal Research

**Setup:**
```bash
cd ~/research
c9-init personal research private
```

**`.c9rc`:**
```
C9_ORG=
C9_DEFAULT_VISIBILITY=private
C9_DEFAULT_TAGS=research,personal
C9_SEARCH_SCOPE=personal
```

**Result:**
- Everything stays private
- Only searches your personal knowledge
- Organized with your tags

## Integration with Claude Desktop & Claude Code

### Claude Desktop
Already configured! Uses the launcher script which reads `.c9rc` automatically.

### Claude Code
To enable in Claude Code, MCP must be configured to use the updated wrapper with context support.

## Troubleshooting

### Context Not Being Applied

1. Check current context:
   ```bash
   c9-context
   ```

2. Verify `.c9rc` exists:
   ```bash
   ls -la .c9rc
   ```

3. Check environment overrides:
   ```bash
   env | grep C9_
   ```

### Wrong Org Being Used

Priority order:
1. Environment variables (highest)
2. `.c9rc` file
3. Built-in defaults (lowest)

Clear environment overrides:
```bash
c9-clear
```

### Tags Not Being Applied

Check `.c9rc` format - must be `key=value` with no quotes:
```bash
# Correct
C9_DEFAULT_TAGS=uta,api,client-work

# Incorrect (don't use quotes)
C9_DEFAULT_TAGS="uta,api,client-work"
```

## Examples in Action

### Scenario: Working on Multiple Clients

You have 3 terminal windows open:

**Terminal 1: UTA Work**
```bash
cd ~/work/uta-api
c9-uta
claude  # Starts with UTA context
```

**Terminal 2: C9 Development**
```bash
cd ~/catalyst9/catalyst-core
c9-catalyst
claude  # Starts with C9 context
```

**Terminal 3: Personal Notes**
```bash
cd ~/notes
c9-personal
claude  # Starts with personal context
```

Each Claude session automatically uses the right context!

## Summary

- **No manual switching needed** - Context auto-detected from `.c9rc`
- **Per-project configuration** - Each project has its own settings
- **Environment override** - Use shell commands for quick switches
- **Team-friendly** - Share `.c9rc` with your team via git
- **Safe defaults** - Everything is private unless you specify otherwise

**DOGFOOD MODE ACTIVATED** 🐕🍴

Now we can use Catalyst9 to build Catalyst9!
