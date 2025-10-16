# Install Agent-OS in Current Project

You are helping the user install Agent-OS in the current working directory.

## Process

### Step 1: Confirm Current Directory
Show the user the current working directory and ask if they want to install Agent-OS here.

### Step 2: Run Installation Script
If confirmed, execute the official Agent-OS installation script:

```bash
~/agent-os/scripts/project-install.sh --profile default
```

### Step 3: Explain What Was Installed
After successful installation, inform the user:

```
✅ Agent-OS installed successfully!

What was installed:
- agent-os/ directory with configuration
- 19 standards (inherited from ~/.agent-os/standards/)
- 4 Claude Code commands (/new-spec, /create-spec, /implement-spec, /plan-product)
- 6 Claude Code agents
- Multi-agent mode enabled with Claude Code

System-level standards inherited:
- context-preservation.md (automatic context preservation at 70%/80% thresholds)
- best-practices.md
- code-style.md
- tech-stack.md
- And any custom standards from ~/.agent-os/

Your project now has:
- Spec-driven development workflow
- Hierarchical standards inheritance from ~/.agent-os/
- Context preservation (already active globally via ~/.claude/CLAUDE.md)
- Agent-OS commands available (including this /install-agent-os command)

Next steps:
- Run /plan-product to define product vision, roadmap, tech stack
- Run /new-spec to create your first feature specification
- Or start working - context preservation is automatic
```

### Step 4: Offer to Create Initial Project Structure
Ask if they want to:
1. Create a README.md
2. Initialize git (if not already initialized)
3. Create initial project structure (src/, docs/, etc.)

Proceed step by step, waiting for user confirmation at each stage.
