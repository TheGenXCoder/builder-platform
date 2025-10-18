# Stow Integration Complete

**Date:** October 17, 2025
**Status:** ✅ Complete - Integrated with Existing Dotfiles

---

## Summary

Successfully integrated Agent-OS and Claude Code system configuration into your existing Stow-managed dotfiles repository.

**Dotfiles Repo:** https://github.com/TheGenXCoder/dotfiles

---

## What Changed

### Before
```
~/.agent-os/          # Manual symlink → ~/system-config/agent-os
~/.claude/            # Manual symlink → ~/system-config/claude
~/system-config/      # Separate git repo (pushed to GitHub)
~/dotfiles/           # Your existing Stow dotfiles
```

### After
```
~/.agent-os/          # Stow symlink → ~/dotfiles/agent-os/.agent-os
~/.claude/            # Stow symlinks → ~/dotfiles/claude/.claude/*
~/dotfiles/           # Contains everything (pushed to GitHub)
  ├── agent-os/.agent-os/    # NEW: Agent-OS package
  └── claude/.claude/        # NEW: Claude Code package
```

---

## Current Setup

### Stow Packages Added

**1. agent-os Package**
```
~/dotfiles/agent-os/
└── .agent-os/
    ├── standards/
    │   ├── context-preservation.md  (7.3KB)
    │   ├── best-practices.md
    │   ├── code-style.md
    │   └── tech-stack.md
    ├── commands/
    ├── config.yml
    └── ...
```

**Managed by:** `stow agent-os`
**Creates:** `~/.agent-os -> dotfiles/agent-os/.agent-os`

**2. claude Package**
```
~/dotfiles/claude/
└── .claude/
    ├── CLAUDE.md  (with context preservation)
    ├── commands/
    │   └── install-agent-os.md
    ├── agents/
    ├── plugins/
    ├── settings.json
    └── settings.local.json
```

**Managed by:** `stow claude`
**Creates:** Individual symlinks in `~/.claude/` for each file/directory

### Device-Specific Files (Not Synced)

These exist in `~/.claude/` but are NOT symlinks (local only):
- `debug/` - Debug logs
- `projects/` - Project-specific data
- `shell-snapshots/` - Shell state
- `todos/` - Per-device todos

**Excluded by:** `~/dotfiles/.gitignore`

---

## Workflow

### Making Changes

**Edit configuration:**
```bash
# Edit via symlink (edits dotfiles repo)
vim ~/.agent-os/standards/context-preservation.md
# OR
vim ~/.claude/CLAUDE.md
# OR
vim ~/dotfiles/agent-os/.agent-os/standards/new-standard.md
```

**Commit and push:**
```bash
cd ~/dotfiles
git add .
git commit -m "Update context preservation thresholds"
git push
```

### On Another Device

**First time setup:**
```bash
# 1. Clone your dotfiles
git clone git@github.com:TheGenXCoder/dotfiles.git ~/dotfiles

# 2. Install base Agent-OS (if not already installed)
git clone https://github.com/buildermethods/agent-os ~/agent-os
~/agent-os/scripts/system-install.sh

# 3. Stow the packages
cd ~/dotfiles
stow agent-os
stow claude

# 4. Restart Claude Code
# Done! All configuration active
```

**Sync updates:**
```bash
cd ~/dotfiles
git pull
# Changes automatically reflected via Stow symlinks
# Restart Claude Code if CLAUDE.md changed
```

---

## Features Included

### Context Preservation System ✅
- Automatic monitoring at 70%/80% thresholds
- Working file (.working.md) for crash recovery
- Session logs (conversation-logs/) for complete history
- Pre-risky-operation preservation
- Zero data loss across all Claude Code sessions

### /install-agent-os Command ✅
- Easy Agent-OS installation in any project
- Just type `/install-agent-os` in Claude Code
- Inherits all system-level standards automatically

### System-Level Standards ✅
- context-preservation.md
- best-practices.md
- code-style.md
- tech-stack.md
- All custom Agent-OS standards

### Global CLAUDE.md ✅
- Context preservation behavior injected globally
- Applies to all Claude Code sessions automatically

---

## Git Repositories

### Primary: ~/dotfiles (Active)
- **URL:** https://github.com/TheGenXCoder/dotfiles
- **Contains:** All dotfiles including agent-os and claude packages
- **Commit:** 6ea61df "Add Agent-OS and Claude Code packages"
- **Status:** ✅ Pushed and active

### Secondary: system-config (Deprecated)
- **URL:** https://github.com/TheGenXCoder/system-config
- **Status:** ⚠️ No longer needed (everything in dotfiles now)
- **Action Needed:** Delete manually at https://github.com/TheGenXCoder/system-config/settings

**To delete:**
1. Go to https://github.com/TheGenXCoder/system-config/settings
2. Scroll to "Danger Zone"
3. Click "Delete this repository"
4. Type the repo name to confirm

---

## Verification

### Check Stow Symlinks

```bash
$ ls -la ~/.agent-os
lrwxr-xr-x  ~/.agent-os -> dotfiles/agent-os/.agent-os

$ ls -la ~/.claude
# Shows individual file symlinks to dotfiles/claude/.claude/*
# Plus local directories (debug, projects, etc.) not symlinked
```

### Check Context Preservation Active

```bash
# Start Claude Code in any project
# .working.md should be created automatically
# Context monitoring should be active
```

### Check Git Status

```bash
$ cd ~/dotfiles && git status
# Should be clean (or show uncommitted local dotfile changes)

$ cd ~/dotfiles && git log -1 --oneline
6ea61df Add Agent-OS and Claude Code packages with context preservation
```

---

## Maintenance

### Update Configuration

```bash
# Edit files (via symlinks)
vim ~/.agent-os/standards/context-preservation.md

# Commit
cd ~/dotfiles
git add .
git commit -m "Update context preservation"
git push
```

### Add New Standard

```bash
# Create new standard
vim ~/dotfiles/agent-os/.agent-os/standards/new-standard.md

# Commit
cd ~/dotfiles
git add agent-os/
git commit -m "Add new-standard"
git push
```

### Restow After Changes

If you add new files to a package, restow:
```bash
cd ~/dotfiles
stow -R agent-os  # Re-stow (remove old, create new)
stow -R claude
```

---

## Troubleshooting

### Symlinks Not Working

**Check Stow packages:**
```bash
cd ~/dotfiles
stow -v agent-os  # Verbose mode shows what it's doing
stow -v claude
```

**Manually verify symlinks:**
```bash
ls -la ~/.agent-os
# Should point to dotfiles/agent-os/.agent-os

ls -la ~/.claude/CLAUDE.md
# Should point to ../dotfiles/claude/.claude/CLAUDE.md
```

### Changes Not Appearing

**Verify git is synced:**
```bash
cd ~/dotfiles
git status      # Check for uncommitted changes
git pull        # Get latest from GitHub
```

**Restart Claude Code:**
- CLAUDE.md changes require restart
- Context preservation loads on startup

### Stow Conflicts

**If Stow complains about conflicts:**
```bash
# Use --adopt to adopt existing files
cd ~/dotfiles
stow --adopt claude

# Or remove existing files first
rm ~/.claude/CLAUDE.md
stow claude
```

---

## Benefits of Stow Integration

### vs Separate system-config Repo ✅

**Before (system-config):**
- Separate repo to manage
- Manual symlink commands
- Two repos to keep track of

**Now (Stow dotfiles):**
- One repo for all configuration
- Standardized Stow workflow
- Consistent with your existing dotfiles

### vs Manual Symlinks ✅

**Before:**
- Remember `ln -sf ~/system-config/agent-os ~/.agent-os`
- Hard to unstow/restow
- Not standardized

**Now:**
- Simple `stow agent-os` command
- Easy to unstow: `stow -D agent-os`
- Restow: `stow -R agent-os`
- Standard dotfiles pattern

### Consistency ✅

**All dotfiles managed the same way:**
- `stow zsh` for zsh config
- `stow nvim` for neovim config
- `stow agent-os` for Agent-OS config
- `stow claude` for Claude Code config

---

## Files Committed to Dotfiles

**Git commit:** 6ea61df

**Files:**
- agent-os/.agent-os/standards/context-preservation.md
- agent-os/.agent-os/standards/best-practices.md
- agent-os/.agent-os/standards/code-style.md
- agent-os/.agent-os/standards/tech-stack.md
- agent-os/.agent-os/commands/*
- agent-os/.agent-os/config.yml
- claude/.claude/CLAUDE.md
- claude/.claude/CLAUDE.md.backup-20251015-170315
- claude/.claude/commands/install-agent-os.md
- claude/.claude/agents/*
- claude/.claude/plugins/config.json
- claude/.claude/settings.json
- claude/.claude/settings.local.json
- .gitignore (updated to exclude device-specific files)

**Total:** 36 files, 4,693 lines

---

## Next Steps

### On This Device ✅
- [x] Stow integration complete
- [x] Committed to dotfiles repo
- [x] Pushed to GitHub
- [x] Old system-config repo cleaned up locally

### On Other Devices 📋
When you set up another device:

1. **Clone dotfiles:**
   ```bash
   git clone git@github.com:TheGenXCoder/dotfiles.git ~/dotfiles
   ```

2. **Stow packages:**
   ```bash
   cd ~/dotfiles
   stow agent-os
   stow claude
   # Plus your other packages: stow zsh, stow nvim, etc.
   ```

3. **Verify:**
   ```bash
   ls -la ~/.agent-os ~/.claude
   # Start Claude Code - context preservation should be active
   ```

### Cleanup 🧹
- [ ] Delete GitHub repo: https://github.com/TheGenXCoder/system-config
  - No longer needed (everything in dotfiles)
  - Go to Settings → Danger Zone → Delete repository

---

## Summary

**Achievement:** Integrated Agent-OS and Claude Code configuration into your existing Stow dotfiles workflow.

**Before:** 2 separate repos (dotfiles + system-config) with manual symlinks

**Now:** 1 unified dotfiles repo with standardized Stow management

**Current State:**
- ✅ Stow managing ~/.agent-os and ~/.claude
- ✅ All config in ~/dotfiles repo
- ✅ Pushed to GitHub (TheGenXCoder/dotfiles)
- ✅ Context preservation active
- ✅ /install-agent-os command available
- ✅ Ready to sync to other devices

**Workflow:**
```bash
# Make changes
vim ~/.agent-os/standards/context-preservation.md

# Sync
cd ~/dotfiles && git add . && git commit -m "Update" && git push

# On other device
cd ~/dotfiles && git pull
```

**Perfect integration with your existing dotfiles management!**

---

**Status:** ✅ COMPLETE
**Date:** 2025-10-17
**Dotfiles Repo:** https://github.com/TheGenXCoder/dotfiles
**Ready for:** Multi-device sync with Stow
