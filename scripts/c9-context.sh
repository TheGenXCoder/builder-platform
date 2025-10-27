#!/bin/bash
# Catalyst9 Context Switching Helper Functions
# Source this file in your ~/.zshrc or ~/.bashrc:
#   source ~/path/to/catalyst-core/scripts/c9-context.sh

# Show current C9 context
c9-context() {
    echo "Current Catalyst9 Context:"
    echo "  User: ${C9_USER:-not set}"
    echo "  Org: ${C9_ORG:-personal}"
    echo "  Project: ${C9_PROJECT:-none}"
    echo "  Visibility: ${C9_DEFAULT_VISIBILITY:-private}"
    echo "  Search Scope: ${C9_SEARCH_SCOPE:-all}"
    echo "  Tags: ${C9_DEFAULT_TAGS:-none}"

    # Check for .c9rc in current directory
    if [ -f .c9rc ]; then
        echo ""
        echo "  📄 .c9rc found in current directory"
        echo "     (will override above settings when MCP starts)"
    fi
}

# Switch to personal context
c9-personal() {
    export C9_ORG=""
    export C9_PROJECT="personal"
    export C9_DEFAULT_VISIBILITY="private"
    export C9_SEARCH_SCOPE="personal"
    export C9_DEFAULT_TAGS=""
    echo "✓ Switched to personal context"
    c9-context
}

# Switch to Catalyst9 org context
c9-catalyst() {
    export C9_ORG="catalyst9"
    export C9_PROJECT="catalyst-core"
    export C9_DEFAULT_VISIBILITY="org"
    export C9_SEARCH_SCOPE="all"
    export C9_DEFAULT_TAGS="c9,development"
    echo "✓ Switched to Catalyst9 development context"
    c9-context
}

# Switch to UTA org context
c9-uta() {
    export C9_ORG="uta"
    export C9_PROJECT="uta-api"
    export C9_DEFAULT_VISIBILITY="org"
    export C9_SEARCH_SCOPE="org"
    export C9_DEFAULT_TAGS="uta,client-work,api"
    echo "✓ Switched to UTA organization context"
    c9-context
}

# Create a custom context
c9-set() {
    local org="$1"
    local project="$2"
    local visibility="${3:-org}"

    if [ -z "$org" ]; then
        echo "Usage: c9-set <org> <project> [visibility]"
        echo "Example: c9-set acme my-project org"
        return 1
    fi

    export C9_ORG="$org"
    export C9_PROJECT="${project:-$org}"
    export C9_DEFAULT_VISIBILITY="$visibility"
    export C9_SEARCH_SCOPE="all"
    echo "✓ Switched to $org context"
    c9-context
}

# Clear context (back to defaults)
c9-clear() {
    unset C9_ORG
    unset C9_PROJECT
    unset C9_DEFAULT_VISIBILITY
    unset C9_SEARCH_SCOPE
    unset C9_DEFAULT_TAGS
    echo "✓ Cleared C9 context (will use .c9rc or defaults)"
    c9-context
}

# Create a .c9rc file in current directory
c9-init() {
    local org="${1:-personal}"
    local project="${2:-$(basename $(pwd))}"
    local visibility="${3:-private}"

    if [ -f .c9rc ]; then
        echo "⚠️  .c9rc already exists in this directory"
        read -p "Overwrite? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Cancelled"
            return 0
        fi
    fi

    cat > .c9rc << EOF
# Catalyst9 Project Context Configuration
# Automatically loaded by C9 MCP wrapper

# Organization context (leave empty for personal)
C9_ORG=$org

# Default visibility for knowledge added in this project
C9_DEFAULT_VISIBILITY=$visibility

# Default tags to auto-apply
C9_DEFAULT_TAGS=$project,development

# Search scope (personal, org, team, project, all)
C9_SEARCH_SCOPE=all

# Project identifier
C9_PROJECT=$project

# Description
C9_PROJECT_DESC="Project: $project"
EOF

    echo "✓ Created .c9rc for project: $project"
    echo "  Org: $org"
    echo "  Visibility: $visibility"
    echo ""
    echo "  Edit .c9rc to customize settings"
    echo "  Add .c9rc to .gitignore if it contains sensitive info"
}

# Help
c9-help() {
    cat << 'EOF'
Catalyst9 Context Switching Commands:

  c9-context       Show current context
  c9-personal      Switch to personal context
  c9-catalyst      Switch to Catalyst9 org context
  c9-uta           Switch to UTA org context
  c9-set           Create custom context: c9-set <org> <project> [visibility]
  c9-clear         Clear context (use .c9rc or defaults)
  c9-init          Create .c9rc in current directory: c9-init [org] [project] [visibility]
  c9-help          Show this help

Context Hierarchy (highest priority first):
  1. Environment variables (C9_ORG, C9_PROJECT, etc.)
  2. .c9rc file in current directory (or parent directories)
  3. Built-in defaults (personal, private)

Examples:
  c9-uta                           # Switch to UTA context
  c9-set acme my-project org       # Custom org context
  c9-init catalyst9 kg-system org  # Create .c9rc for C9 project
  c9-personal                      # Switch back to personal

The context determines:
  - Which org knowledge is added to by default
  - Default visibility (private, org, team, public)
  - Search scope
  - Auto-applied tags
EOF
}

# Auto-detect context on cd
c9-auto-detect() {
    if [ -f .c9rc ]; then
        echo "📄 Catalyst9 project detected (.c9rc found)"
        grep "^C9_PROJECT=" .c9rc 2>/dev/null | sed 's/C9_PROJECT=/  Project: /'
        grep "^C9_ORG=" .c9rc 2>/dev/null | sed 's/C9_ORG=/  Org: /'
    fi
}

# Optional: Auto-detect on directory change
# Uncomment to enable:
# cd() {
#     builtin cd "$@" && c9-auto-detect
# }

echo "Catalyst9 context functions loaded. Type 'c9-help' for usage."
