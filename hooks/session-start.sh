#!/usr/bin/env bash
# session-start.sh — bootstrap ~/.metareview/ on first run

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MR_HOME="$HOME/.metareview"

# Check if already installed
if [[ -d "$MR_HOME/bin" ]] && [[ -x "$MR_HOME/bin/metareview" ]]; then
    # Already installed — check for updates
    # Compare plugin version with installed version
    exit 0
fi

# First-time setup
mkdir -p "$MR_HOME"/{bin,sessions,reviews,knowledge}

# Copy scripts
for script in "$PLUGIN_ROOT/scripts/"*; do
    cp "$script" "$MR_HOME/bin/"
    chmod +x "$MR_HOME/bin/$(basename "$script")"
done

# Copy knowledge base
for kb in "$PLUGIN_ROOT/knowledge/"*.md; do
    [[ -f "$kb" ]] && cp "$kb" "$MR_HOME/knowledge/"
done

# Write default config (don't overwrite existing)
if [[ ! -f "$MR_HOME/config.json" ]]; then
    cp "$PLUGIN_ROOT/config.default.json" "$MR_HOME/config.json"
fi

# Initialize history
if [[ ! -f "$MR_HOME/history.json" ]]; then
    echo '[]' > "$MR_HOME/history.json"
fi

# Check if .zshrc integration is present
NEEDS_SHELL_SETUP=false
if ! grep -q "metareview" "$HOME/.zshrc" 2>/dev/null; then
    NEEDS_SHELL_SETUP=true
fi

# Output as JSON for Claude Code to display
cat << EOF
{
  "hookResult": {
    "additionalContext": "metareview plugin bootstrapped at ~/.metareview/. ${NEEDS_SHELL_SETUP:+\n\n**ACTION REQUIRED:** Add these lines to your ~/.zshrc to enable session capture:\n\`\`\`\n# Metareview — Claude Code session monitor\nexport PATH=\"\$HOME/.metareview/bin:\$PATH\"\nsource \"\$HOME/.metareview/bin/claude-wrapper.sh\"\n\`\`\`\nThen run: source ~/.zshrc}"
  }
}
EOF
