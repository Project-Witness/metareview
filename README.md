# metareview

A Claude Code session quality auditor. It transparently captures every session, runs pattern-matching analysis when the session ends, and on demand calls an LLM to produce a structured diagnostic report plus an actionable brief to start the next session with.

## How it works

Four layers:

```
┌─────────────────────────────────────────────────────────┐
│  Layer 1: Capture                                       │
│  claude-wrapper.sh wraps every `claude` invocation      │
│  with `script`, capturing all terminal I/O to           │
│  ~/.metareview/sessions/<id>/raw.log                    │
├─────────────────────────────────────────────────────────┤
│  Layer 2: Storage                                       │
│  Per-session directories hold raw.log, transcript.txt,  │
│  meta.json (timestamps, cwd, exit code), markers.jsonl  │
├─────────────────────────────────────────────────────────┤
│  Layer 3: Analysis (two tiers)                          │
│  Free — heuristics: pattern-matching on transcript      │
│    Signals: correction cycles, sorry loops, frustration,│
│    unclaimed deliverables, repeated user messages       │
│  Paid — llm-analyze: full LLM review via Anthropic API  │
│    Produces REVIEW.md + NEXT-SESSION.md per session     │
├─────────────────────────────────────────────────────────┤
│  Layer 4: Output                                        │
│  Terminal summary after every session (color-coded)     │
│  REVIEW.md: structured diagnostic across 5 dimensions   │
│  NEXT-SESSION.md: carry-forward brief + starter prompt  │
└─────────────────────────────────────────────────────────┘
```

## Install

One line:

```bash
brew install jq && bash <(curl -sSL https://raw.githubusercontent.com/Project-Witness/metareview/main/install.sh)
```

This installs `jq` (if needed), clones the plugin, registers it with Claude Code, copies scripts to `~/.metareview/`, and prompts to add shell integration. Press `Y` when asked, then run `source ~/.zshrc`.

If you already have `jq`:

```bash
bash <(curl -sSL https://raw.githubusercontent.com/Project-Witness/metareview/main/install.sh)
```

### Requirements

- macOS or Linux
- `jq` (installed automatically by the command above)
- `ANTHROPIC_API_KEY` environment variable — only needed for the LLM analysis tier (`metareview <id>`). Not required for session capture or heuristic scoring.

## Usage

### Session capture

Once shell integration is active, every `claude` invocation is automatically captured. No flags needed.

```bash
claude                        # captured automatically
METAREVIEW=0 claude           # bypass capture for this session
claude --mr-off               # same, via flag
```

### Reviewing sessions

```bash
# List recent sessions with heuristic scores
metareview list

# Filter to problem sessions
metareview list --red
metareview list --yellow

# Run LLM analysis on a session (standard model)
metareview <session-id>

# Deep analysis with Opus
metareview <session-id> --deep

# Start a new session pre-loaded with previous session's brief
metareview start <session-id>

# Storage and config summary
metareview status

# Run retention pruning manually
metareview clean

# Edit config
metareview config
```

### Mid-session review (Claude Code skill)

From inside any Claude Code session:

```
/metareview
```

This invokes the metareview skill, which reads the live transcript and produces a real-time session health report — delivery check, communication check, process check, and a recommendation to continue or exit.

## Configuration

Config lives at `~/.metareview/config.json`. Edit with `metareview config`.

```json
{
  "capture": {
    "enabled": true
  },
  "heuristics": {
    "auto_run": true,
    "thresholds": {
      "green_max": 4,
      "yellow_max": 9
    }
  },
  "llm": {
    "default_model": "claude-sonnet-4-6",
    "deep_model": "claude-opus-4-6",
    "max_cost_usd": 1.00
  },
  "retention": {
    "raw_log_days": 7,
    "transcript_days": 30,
    "reviews": "forever"
  }
}
```

| Key | Default | Description |
|-----|---------|-------------|
| `capture.enabled` | `true` | Toggle session capture on/off |
| `heuristics.auto_run` | `true` | Run heuristic scan automatically after each session |
| `heuristics.thresholds.green_max` | `4` | Max heuristic score for green rating |
| `heuristics.thresholds.yellow_max` | `9` | Max heuristic score for yellow rating (above = red) |
| `llm.default_model` | `claude-sonnet-4-6` | Model used for `metareview <id>` |
| `llm.deep_model` | `claude-opus-4-6` | Model used for `metareview <id> --deep` |
| `llm.max_cost_usd` | `1.00` | Hard cap on per-analysis API cost |
| `retention.raw_log_days` | `7` | Days to keep raw terminal logs |
| `retention.transcript_days` | `30` | Days to keep cleaned transcripts |

## Data layout

```
~/.metareview/
├── bin/           # Scripts (managed by plugin)
├── sessions/
│   └── <id>/
│       ├── raw.log          # Raw terminal capture
│       ├── transcript.txt   # Cleaned, speaker-marked transcript
│       ├── meta.json        # Session metadata + heuristic scores
│       └── markers.jsonl    # User prompt timestamps (from hook)
├── reviews/
│   └── <id>/
│       ├── REVIEW.md        # Full LLM diagnostic report
│       ├── NEXT-SESSION.md  # Carry-forward brief
│       └── meta.json        # Copy of session meta at review time
├── knowledge/
│   ├── core-rubric.md       # Evaluation framework
│   └── anti-patterns.md     # Known CC failure modes catalog
├── config.json
└── history.json             # Index of all sessions
```

## Uninstall

```bash
metareview uninstall
```

Removes `~/.metareview/`, the skill, and any metareview lines from `~/.zshrc`.
