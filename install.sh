#!/usr/bin/env bash
set -euo pipefail

# metareview installer — one-line install for Claude Code session quality auditor
# Usage: bash <(curl -sSL https://raw.githubusercontent.com/Project-Witness/metareview/main/install.sh)

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${BOLD}metareview${NC} — Claude Code session quality auditor"
echo ""

# Check dependencies
echo -e "${CYAN}Checking dependencies...${NC}"
missing=false

if ! command -v jq &>/dev/null; then
    echo -e "  ${RED}jq${NC} — not found. Install with: brew install jq"
    missing=true
else
    echo -e "  ${GREEN}jq${NC} — found"
fi

if ! command -v git &>/dev/null; then
    echo -e "  ${RED}git${NC} — not found"
    missing=true
else
    echo -e "  ${GREEN}git${NC} — found"
fi

if $missing; then
    echo ""
    echo -e "${RED}Install missing dependencies and re-run.${NC}"
    exit 1
fi

echo ""

# Step 1: Clone repo to plugin cache location
PLUGIN_DIR="$HOME/.cache/plugins/github.com-Project-Witness-metareview"
echo -e "${CYAN}Installing plugin...${NC}"

if [[ -d "$PLUGIN_DIR" ]]; then
    echo "  Updating existing installation..."
    git -C "$PLUGIN_DIR" pull --quiet 2>/dev/null || {
        rm -rf "$PLUGIN_DIR"
        git clone --quiet https://github.com/Project-Witness/metareview.git "$PLUGIN_DIR"
    }
else
    git clone --quiet https://github.com/Project-Witness/metareview.git "$PLUGIN_DIR"
fi
echo -e "  ${GREEN}Plugin cloned${NC}"

# Step 2: Register in settings.json
SETTINGS="$HOME/.claude/settings.json"
echo -e "${CYAN}Registering plugin...${NC}"

if [[ -f "$SETTINGS" ]]; then
    # Add marketplace source if not present
    has_marketplace=$(jq -r '.extraKnownMarketplaces["metareview-marketplace"] // empty' "$SETTINGS" 2>/dev/null)
    if [[ -z "$has_marketplace" ]]; then
        jq --arg path "$PLUGIN_DIR" \
            '.extraKnownMarketplaces["metareview-marketplace"] = {"source": {"source": "directory", "path": $path}}' \
            "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
    fi

    # Enable plugin if not present
    has_plugin=$(jq -r '.enabledPlugins["metareview@metareview-marketplace"] // empty' "$SETTINGS" 2>/dev/null)
    if [[ -z "$has_plugin" ]]; then
        jq '.enabledPlugins["metareview@metareview-marketplace"] = true' \
            "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
    fi
    echo -e "  ${GREEN}Plugin registered in settings.json${NC}"
else
    echo -e "  ${YELLOW}~/.claude/settings.json not found — register manually${NC}"
fi

# Step 3: Bootstrap ~/.metareview/
MR_HOME="$HOME/.metareview"
echo -e "${CYAN}Setting up metareview...${NC}"

mkdir -p "$MR_HOME"/{bin,sessions,reviews,knowledge}

# Copy scripts
for script in "$PLUGIN_DIR/scripts/"*; do
    cp "$script" "$MR_HOME/bin/"
    chmod +x "$MR_HOME/bin/$(basename "$script")"
done
echo "  Scripts installed to ~/.metareview/bin/"

# Copy knowledge base
for kb in "$PLUGIN_DIR/knowledge/"*.md; do
    [[ -f "$kb" ]] && cp "$kb" "$MR_HOME/knowledge/"
done
echo "  Knowledge base installed"

# Write default config (preserve existing)
if [[ ! -f "$MR_HOME/config.json" ]]; then
    cp "$PLUGIN_DIR/config.default.json" "$MR_HOME/config.json"
    echo "  Default config written"
else
    echo "  Existing config preserved"
fi

# Initialize history
if [[ ! -f "$MR_HOME/history.json" ]]; then
    echo '[]' > "$MR_HOME/history.json"
fi

echo -e "  ${GREEN}Setup complete${NC}"

# Step 4: Check shell integration
echo ""
if grep -q "metareview" "$HOME/.zshrc" 2>/dev/null; then
    echo -e "${GREEN}Shell integration already configured.${NC}"
else
    echo -e "${YELLOW}${BOLD}One more step — add these lines to your ~/.zshrc:${NC}"
    echo ""
    echo '  # Metareview — Claude Code session monitor'
    echo '  export PATH="$HOME/.metareview/bin:$PATH"'
    echo '  source "$HOME/.metareview/bin/claude-wrapper.sh"'
    echo ""
    echo -e "  Then run: ${BOLD}source ~/.zshrc${NC}"
fi

echo ""
echo -e "${GREEN}${BOLD}metareview v0.1.0 installed.${NC}"
echo ""
echo "  Every 'claude' session will be monitored automatically."
echo "  Use 'claude --mr-off' for unmonitored sessions."
echo ""
echo "  Commands:"
echo "    metareview list          — see captured sessions"
echo "    metareview <id>          — run LLM analysis"
echo "    metareview status        — overview"
echo "    /metareview              — mid-session audit (inside CC)"
echo ""
