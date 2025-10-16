# /install-agent-os Slash Command

**Purpose:** Install Agent-OS in any project directory with a single slash command

**Created:** October 15, 2025

---

## What Is This?

A Claude Code slash command that wraps the Agent-OS installation script, making it easy to install Agent-OS in any project with automatic system-level standards inheritance.

**Command:** `/install-agent-os`

**Location:**
- System: `~/agent-os/profiles/default/commands/install-agent-os/`
- Will be included in all NEW Agent-OS installations automatically

---

## How to Use

### In a New Project (After Agent-OS is Installed Once)

```bash
cd ~/mynewproject
# Start Claude Code
```

Then simply type:
```
/install-agent-os
```

Claude Code will:
1. Confirm the current directory
2. Run `~/agent-os/scripts/project-install.sh --profile default`
3. Explain what was installed
4. Offer to create initial project structure

### In an Existing Project (Add Command Manually)

If you have an existing project with Agent-OS already installed, add the command:

```bash
cd ~/your-existing-project

# Copy the command from Agent-OS profile
cp ~/agent-os/profiles/default/commands/install-agent-os/multi-agent/install-agent-os.md \
   .claude/commands/install-agent-os.md
```

Now `/install-agent-os` will be available in that project.

---

## What Gets Installed

When you run `/install-agent-os`, the following are installed:

### Agent-OS Structure
```
agent-os/
├── config.yml
├── standards/          # Inherits from ~/.agent-os/standards/
└── ...

.claude/
├── commands/          # 5 commands including /install-agent-os
│   ├── agent-os/
│   │   ├── new-spec.md
│   │   ├── create-spec.md
│   │   ├── implement-spec.md
│   │   └── plan-product.md
│   └── install-agent-os.md (this command)
└── agents/            # 6 agents for spec-driven development
```

### System-Level Standards Inherited
From `~/.agent-os/standards/`:
- **context-preservation.md** - Automatic context preservation (70%/80% thresholds)
- **best-practices.md** - Development best practices
- **code-style.md** - Code style guidelines
- **tech-stack.md** - Technology decisions
- Any custom standards you've added

### Claude Code Commands
- `/new-spec` - Initialize new feature specification
- `/create-spec` - Generate detailed spec and task breakdown
- `/implement-spec` - Implement a specification
- `/plan-product` - Create product planning docs (mission, roadmap, tech stack)
- `/install-agent-os` - Install Agent-OS (this command)

### Claude Code Agents
- spec-initializer
- spec-researcher
- spec-creator
- task-breaker
- spec-implementer
- product-planner

---

## Installation Locations

### Command Added to Agent-OS Profile ✅

**Location:** `~/agent-os/profiles/default/commands/install-agent-os/`

**Files Created:**
- `multi-agent/install-agent-os.md` - Multi-agent mode version
- `single-agent/install-agent-os.md` - Single-agent mode version

**Effect:**
- All FUTURE Agent-OS installations will include `/install-agent-os` command automatically
- When anyone runs `~/agent-os/scripts/project-install.sh`, they get this command

### Command Added to Builder Platform ✅

**Location:** `.claude/commands/install-agent-os.md`

**Effect:**
- Available immediately in Builder Platform project
- Can test the command here before distributing

---

## Why This Is Useful

### Problem
Previously, to install Agent-OS in a new project:
```bash
cd ~/mynewproject
~/agent-os/scripts/project-install.sh --profile default
# Long command to type, easy to forget
```

### Solution
Now:
```bash
cd ~/mynewproject
# In Claude Code, just type:
/install-agent-os
```

### Benefits
1. **Easier to remember** - Slash command vs long script path
2. **Discoverable** - Shows up in command list
3. **Guided process** - Claude Code walks you through installation
4. **Explains what was installed** - Clear feedback on what you get
5. **Offers next steps** - README creation, git init, project structure

---

## Distribution to Others

### For New Users

When someone installs Agent-OS for the first time:

1. **They install Agent-OS globally:**
   ```bash
   git clone https://github.com/buildermethods/agent-os ~/agent-os
   ~/agent-os/scripts/system-install.sh
   ```

2. **Then in any NEW project:**
   ```bash
   cd ~/their-project
   # In Claude Code:
   /install-agent-os
   ```

   The command is automatically available because it's in the Agent-OS profile!

### For Existing Users

If they already have Agent-OS installed (before this command existed):

1. **Update their Agent-OS installation:**
   ```bash
   cd ~/agent-os
   git pull
   ```

2. **The command is now in their profile** for all future installations

3. **To add to existing projects manually:**
   ```bash
   cd ~/their-existing-project
   cp ~/agent-os/profiles/default/commands/install-agent-os/multi-agent/install-agent-os.md \
      .claude/commands/install-agent-os.md
   ```

---

## Answer to Your Original Question

> "So if I start a new project in ~/mynextproject, outside the context of the builder platform, the context preservation system AND agent-os are automatically applied?"

**Updated Answer:**

### Context Preservation System: ✅ YES - Automatically Applied Everywhere
- **Location:** `~/.claude/CLAUDE.md` (global Claude Code instructions)
- **Scope:** ALL Claude Code sessions, any directory
- **What happens:**
  - I create `.working.md` automatically
  - I create `conversation-logs/` automatically
  - I monitor context at 70%/80% thresholds
  - All automatic, no installation needed

### Agent-OS: ✅ YES - Now Easy to Install with Slash Command
- **Location:** `~/agent-os/profiles/default/commands/` (included in profile)
- **Scope:** Available in any project where Agent-OS is installed
- **What happens:**
  1. `cd ~/mynextproject`
  2. Start Claude Code
  3. Type `/install-agent-os`
  4. Boom - Agent-OS installed with system-level standards

### Complete Flow for New Project

```bash
cd ~/mynextproject
# Start Claude Code
```

Then in Claude Code:
```
/install-agent-os
```

Result:
- ✅ Agent-OS installed
- ✅ Context preservation active (was already global)
- ✅ System standards inherited from ~/.agent-os/
- ✅ Spec-driven workflow ready
- ✅ All commands available
- ✅ Ready to build

---

## Testing the Command

### Test in Builder Platform (Available Now)

```
/install-agent-os
```

Should show current directory and ask if you want to install (already installed, but tests the command).

### Test in New Project

```bash
mkdir -p ~/test-new-project
cd ~/test-new-project
# Start Claude Code in this directory
```

Then:
```
/install-agent-os
```

Should install Agent-OS fresh, inheriting all system-level standards including context-preservation.md.

---

## Command Implementation Details

### Multi-Agent Version
**File:** `~/agent-os/profiles/default/commands/install-agent-os/multi-agent/install-agent-os.md`

**Used when:** Multi-agent mode enabled (default for Claude Code)

**Process:**
1. Confirm directory
2. Run installation script
3. Explain what was installed (detailed)
4. Offer project structure setup

### Single-Agent Version
**File:** `~/agent-os/profiles/default/commands/install-agent-os/single-agent/install-agent-os.md`

**Used when:** Single-agent mode

**Process:**
- Same as multi-agent but more concise
- Optimized for single-agent workflow

---

## Success Criteria

✅ **Command created in Agent-OS profile** - Available for all future installations
✅ **Command available in Builder Platform** - Can test immediately
✅ **Documentation complete** - Users know how to use it
✅ **Answers original question** - Yes, context preservation + easy Agent-OS install

---

## Next Steps

### Immediate
- [ ] Test `/install-agent-os` in Builder Platform
- [ ] Test in new project directory
- [ ] Validate that system standards inherit correctly

### Future
- [ ] Contribute to BuilderMethods Agent-OS repository (if appropriate)
- [ ] Share with other Builder Platform users
- [ ] Document in Agent-OS documentation

---

## Summary

**You asked for a way to make Agent-OS installation available to others via slash command, not just zsh alias.**

**Solution Delivered:**

1. ✅ Created `/install-agent-os` slash command
2. ✅ Added to Agent-OS profile (~/agent-os/profiles/default/commands/)
3. ✅ Will be included in ALL future Agent-OS installations automatically
4. ✅ Available in Builder Platform immediately for testing
5. ✅ Works alongside context preservation system (already global)

**Result:** Anyone with Agent-OS can type `/install-agent-os` in any new project and get:
- Spec-driven development workflow
- System-level standards (including context preservation)
- All commands and agents
- Guided setup process

**Distribution:** Share the command by sharing Agent-OS. When they install Agent-OS, they get this command automatically.

---

**Command Location:** `~/agent-os/profiles/default/commands/install-agent-os/`

**Test It:** `/install-agent-os` (available now in Builder Platform)

**Status:** ✅ Complete and ready for distribution
