# System Configuration Sync Guide

**Multi-Device Setup for Builder Platform System Configuration**

**Repository:** https://github.com/TheGenXCoder/system-config (Private)

---

## Overview

Your system-level Agent-OS and Claude Code configurations are now version controlled and can be synced across devices.

**What's Included:**
- `~/.agent-os/` - System-level Agent-OS standards and configuration
- `~/.claude/` - Global Claude Code configuration and commands

**Repository Location:** `~/system-config` → Pushed to GitHub

---

## Current Device Setup (Already Completed)

On your primary device, the following structure is in place:

```
~/system-config/              # Git repo (pushed to GitHub)
├── agent-os/                 # Copy of ~/.agent-os/
├── claude/                   # Copy of ~/.claude/
└── README.md                 # Installation instructions

~/.agent-os/                  # System-level Agent-OS (original location)
~/.claude/                    # Global Claude Code config (original location)
```

**Status:** ✅ Repository created and pushed to GitHub

---

## Installing on New Device

### Prerequisites

1. **Install Claude Code**
   ```bash
   # Download from https://claude.ai/download
   # Or use installer if available
   ```

2. **Install Base Agent-OS**
   ```bash
   git clone https://github.com/buildermethods/agent-os ~/agent-os
   ~/agent-os/scripts/system-install.sh
   ```

3. **Configure GitHub SSH** (if not already)
   ```bash
   # Generate SSH key if needed
   ssh-keygen -t ed25519 -C "your_email@example.com"

   # Add to GitHub: https://github.com/settings/keys
   cat ~/.ssh/id_ed25519.pub
   ```

### Installation Steps

```bash
# 1. Clone your system-config repo
git clone git@github.com:TheGenXCoder/system-config.git ~/system-config

# 2. Backup existing configs (if any)
mv ~/.agent-os ~/.agent-os.backup-$(date +%Y%m%d) 2>/dev/null || true
mv ~/.claude ~/.claude.backup-$(date +%Y%m%d) 2>/dev/null || true

# 3. Create symlinks to the repo
ln -sf ~/system-config/agent-os ~/.agent-os
ln -sf ~/system-config/claude ~/.claude

# 4. Verify installation
ls -la ~/.agent-os
ls -la ~/.claude

# 5. Restart Claude Code
# Your system-level config is now active!
```

### What You Get

After installation on the new device:

✅ **Context Preservation System**
- Automatic monitoring at 70%/80% thresholds
- Working file (.working.md) for crash recovery
- Session logs (conversation-logs/) for complete history
- Zero data loss across all Claude Code sessions

✅ **/install-agent-os Command**
- Type `/install-agent-os` in any project
- Easy Agent-OS installation with system standards

✅ **System-Level Standards**
- context-preservation.md
- best-practices.md
- code-style.md
- tech-stack.md
- All custom standards from primary device

✅ **Global CLAUDE.md**
- Context preservation behavior injected globally
- Applies to all Claude Code sessions automatically

---

## Syncing Changes Between Devices

### Push Changes (From Any Device)

After modifying system configuration:

```bash
cd ~/system-config
git add .
git commit -m "Update context preservation thresholds"
git push
```

### Pull Changes (To Other Devices)

To get updates on another device:

```bash
cd ~/system-config
git pull
# Changes automatically reflected via symlinks
# Restart Claude Code if needed
```

---

## Making Configuration Changes

### Update Context Preservation Behavior

**Edit the global standard:**
```bash
cd ~/system-config
vim agent-os/standards/context-preservation.md
# Or: vim claude/CLAUDE.md

git add .
git commit -m "Update context preservation: adjust thresholds"
git push
```

### Add New System-Level Standard

```bash
cd ~/system-config/agent-os/standards/
# Create new-standard.md

git add new-standard.md
git commit -m "Add new system-level standard"
git push
```

### Update Global Claude Code Config

```bash
cd ~/system-config
vim claude/CLAUDE.md

git add claude/CLAUDE.md
git commit -m "Update global Claude Code instructions"
git push
```

---

## Maintaining the Configuration

### Regular Maintenance

**Periodically sync changes:**
```bash
# On primary device (after making changes)
cd ~/system-config
git add .
git commit -m "Sync latest configuration"
git push

# On secondary devices
cd ~/system-config
git pull
```

### Backup Strategy

**The repo IS your backup:**
- All changes version controlled
- Push regularly to GitHub
- Private repository protects your config

**Additional backup (optional):**
```bash
# Create local backup
tar -czf ~/Backups/system-config-$(date +%Y%m%d).tar.gz ~/system-config
```

---

## Troubleshooting

### Symlinks Not Working

**Check symlinks:**
```bash
ls -la ~/.agent-os
ls -la ~/.claude
```

Should show:
```
~/.agent-os -> /Users/YourName/system-config/agent-os
~/.claude -> /Users/YourName/system-config/claude
```

**Recreate if needed:**
```bash
rm ~/.agent-os ~/.claude
ln -sf ~/system-config/agent-os ~/.agent-os
ln -sf ~/system-config/claude ~/.claude
```

### Changes Not Appearing

**Verify repo is up to date:**
```bash
cd ~/system-config
git status
git pull
```

**Restart Claude Code:**
- Context preservation changes require restart
- CLAUDE.md is loaded on startup

### Merge Conflicts

If you edited config on multiple devices without syncing:

```bash
cd ~/system-config
git pull
# If conflicts:
# 1. Edit conflicted files
# 2. Resolve conflicts manually
# 3. git add <resolved-files>
# 4. git commit
# 5. git push
```

---

## Repository Structure

```
~/system-config/
├── .gitignore              # Excludes device-specific files
├── README.md               # Installation instructions
├── agent-os/               # Maps to ~/.agent-os/
│   ├── standards/
│   │   ├── context-preservation.md  (7.3KB)
│   │   ├── best-practices.md
│   │   ├── code-style.md
│   │   └── tech-stack.md
│   ├── commands/
│   ├── config.yml
│   └── ...
└── claude/                 # Maps to ~/.claude/
    ├── CLAUDE.md           # Enhanced with context preservation
    ├── commands/
    │   └── install-agent-os.md
    ├── agents/
    └── settings.json
```

---

## What's NOT Synced (Intentionally)

These are excluded via `.gitignore`:

```
claude/history.jsonl        # Session history (device-specific)
claude/debug/               # Debug logs
claude/file-history/        # File history
claude/shell-snapshots/     # Shell state
claude/statsig/             # Analytics
claude/todos/               # Per-device todos
claude/projects/            # Project-specific data
```

These are device-specific and shouldn't sync across machines.

---

## Migration from Current Setup

**You've already done this on your primary device!**

If you need to migrate another existing setup:

```bash
# On the device with existing config:

# 1. Clone the repo
git clone git@github.com:TheGenXCoder/system-config.git ~/system-config-new

# 2. Compare your local config with the repo
diff -r ~/.agent-os ~/system-config-new/agent-os
diff -r ~/.claude ~/system-config-new/claude

# 3. Merge any local changes you want to keep
cp ~/.agent-os/standards/your-custom-standard.md ~/system-config-new/agent-os/standards/

# 4. Commit and push
cd ~/system-config-new
git add .
git commit -m "Merge local configuration"
git push

# 5. Switch to symlink setup
mv ~/.agent-os ~/.agent-os.backup-$(date +%Y%m%d)
mv ~/.claude ~/.claude.backup-$(date +%Y%m%d)
mv ~/system-config-new ~/system-config
ln -sf ~/system-config/agent-os ~/.agent-os
ln -sf ~/system-config/claude ~/.claude
```

---

## Security Considerations

**Private Repository:**
- ✅ Repository is private
- ✅ No credentials or API keys stored
- ✅ Configuration only, safe to version control

**SSH Key Access:**
- Use SSH keys for git operations
- Never commit SSH keys to repo
- Keep GitHub SSH keys secure

**Device Trust:**
- Only clone to trusted devices
- Keep devices secure
- Revoke SSH keys from lost/stolen devices

---

## Quick Reference

**Clone on new device:**
```bash
git clone git@github.com:TheGenXCoder/system-config.git ~/system-config
ln -sf ~/system-config/agent-os ~/.agent-os
ln -sf ~/system-config/claude ~/.claude
```

**Push changes:**
```bash
cd ~/system-config
git add . && git commit -m "Update" && git push
```

**Pull changes:**
```bash
cd ~/system-config && git pull
```

**Verify setup:**
```bash
ls -la ~/.agent-os ~/.claude
```

---

## Benefits

✅ **Multi-Device Consistency**
- Same config on all devices
- One source of truth

✅ **Version Control**
- Track changes over time
- Rollback if needed
- See what changed when

✅ **Easy Recovery**
- New device setup: 5 minutes
- Lost config: git clone, done
- Disaster recovery: GitHub has backup

✅ **Collaborative Potential**
- Share standards with team (if desired)
- Fork for different environments
- Contribute improvements back

---

**Repository:** https://github.com/TheGenXCoder/system-config

**Status:** ✅ Active and synced

**Next Step:** Install on your other device using the instructions above!
