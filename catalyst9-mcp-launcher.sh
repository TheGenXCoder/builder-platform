#!/bin/bash
# Catalyst9 MCP Launcher - Uses environment variables from .zshrc

# Source the user's shell environment to get C9_USER and C9_USER_KEY
# Your zsh config is in ~/.config/zsh/.zshrc
if [ -f ~/.config/zsh/.zshrc ]; then
    # Need to set ZDOTDIR for proper zsh config loading
    export ZDOTDIR=~/.config/zsh
    source ~/.config/zsh/.zshrc
elif [ -f ~/.zshrc ]; then
    source ~/.zshrc
elif [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

# Debug output (remove after testing)
echo "Catalyst9 MCP starting for user: ${C9_USER:-NOT_SET}" >&2

# Export for Python script
export CATALYST9_API_URL="https://catalyst9.ai"
export CATALYST9_USER="${C9_USER}"
export CATALYST9_API_KEY="${C9_USER_KEY}"

# Launch the Python MCP wrapper
exec python3 "$(dirname "$0")/projects/knowledge-graph-system/catalyst9-mcp.py"