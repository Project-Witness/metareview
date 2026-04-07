#!/usr/bin/env bash
# claude-wrapper.sh — sourced into .zshrc to transparently wrap every
# `claude` invocation with `script` for I/O capture.
#
# Usage (in .zshrc):
#   source ~/.metareview/bin/claude-wrapper.sh
#
# Bypass modes:
#   METAREVIEW=0 claude ...    — env var bypass
#   claude --mr-off ...        — flag bypass (flag is consumed, not passed)

claude() {
    # ------------------------------------------------------------------
    # 1. Flag bypass: scan args for --mr-off, strip it, call real binary
    # ------------------------------------------------------------------
    local filtered_args=()
    local mr_off=0
    for arg in "$@"; do
        if [[ "$arg" == "--mr-off" ]]; then
            mr_off=1
        else
            filtered_args+=("$arg")
        fi
    done

    if [[ "$mr_off" -eq 1 ]]; then
        command claude "${filtered_args[@]}"
        return $?
    fi

    # ------------------------------------------------------------------
    # 2. Env var bypass
    # ------------------------------------------------------------------
    if [[ "${METAREVIEW:-}" == "0" ]]; then
        command claude "$@"
        return $?
    fi

    # ------------------------------------------------------------------
    # 3. Config check: skip if capture.enabled is false
    # ------------------------------------------------------------------
    local config_file="$HOME/.metareview/config.json"
    if [[ -f "$config_file" ]]; then
        local capture_enabled
        capture_enabled=$(jq -r '.capture.enabled // true' "$config_file" 2>/dev/null)
        if [[ "$capture_enabled" == "false" ]]; then
            command claude "$@"
            return $?
        fi
    fi

    # ------------------------------------------------------------------
    # 4. Create session directory
    # ------------------------------------------------------------------
    local timestamp
    timestamp=$(date -u +"%Y%m%dT%H%M%SZ")
    local session_id="${timestamp}-$$"
    local session_dir="$HOME/.metareview/sessions/${session_id}"
    mkdir -p "$session_dir"

    # ------------------------------------------------------------------
    # 5. Write initial meta.json (use jq for safe JSON encoding)
    # ------------------------------------------------------------------
    local start_time
    start_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local cwd
    cwd=$(pwd)

    # Build a JSON array of args using jq
    local args_json
    args_json=$(printf '%s\n' "$@" | jq -R . | jq -s .)

    jq -n \
        --arg session_id "$session_id" \
        --arg start_time "$start_time" \
        --arg cwd        "$cwd" \
        --argjson args   "$args_json" \
        --argjson pid    $$ \
        '{
            session_id: $session_id,
            start_time: $start_time,
            cwd:        $cwd,
            args:       $args,
            pid:        $pid,
            status:     "running"
        }' > "$session_dir/meta.json"

    # ------------------------------------------------------------------
    # 6. Export env vars for mid-session skill / hooks
    # ------------------------------------------------------------------
    export METAREVIEW_SESSION_ID="$session_id"
    export METAREVIEW_SESSION_DIR="$session_dir"
    export METAREVIEW_TRANSCRIPT="$session_dir/raw.log"

    # ------------------------------------------------------------------
    # 7. Capture — branch on TTY vs pipe
    # ------------------------------------------------------------------
    local exit_code=0

    if [[ -t 0 ]]; then
        # Interactive: use `script` to capture all terminal I/O
        if [[ "$(uname)" == "Darwin" ]]; then
            # macOS: script -q <file> <command> [args...]
            script -q "$session_dir/raw.log" command claude "$@"
            exit_code=$?
        else
            # Linux (util-linux): script -qc "<command>" <file>
            # Build a quoted command string so args with spaces survive eval
            local cmd_str
            cmd_str="command claude $(printf '%q ' "$@")"
            script -qc "$cmd_str" "$session_dir/raw.log"
            exit_code=$?
        fi
    else
        # Pipe mode: tee captures stdin clone + run claude
        tee "$session_dir/raw.log" | command claude "$@"
        exit_code=${PIPESTATUS[1]}
    fi

    # ------------------------------------------------------------------
    # 8. Update meta.json with end-time, duration, exit code, size
    # ------------------------------------------------------------------
    local end_time
    end_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Duration in seconds (macOS date lacks %s in -d, use python for portability)
    local duration_secs
    duration_secs=$(python3 -c "
from datetime import datetime, timezone
fmt = '%Y-%m-%dT%H:%M:%SZ'
start = datetime.strptime('${start_time}', fmt).replace(tzinfo=timezone.utc)
end   = datetime.strptime('${end_time}',   fmt).replace(tzinfo=timezone.utc)
print(int((end - start).total_seconds()))
" 2>/dev/null || echo 0)

    local transcript_size=0
    if [[ -f "$session_dir/raw.log" ]]; then
        transcript_size=$(wc -c < "$session_dir/raw.log" | tr -d ' ')
    fi

    # Extract CC session ID from ~/.claude/sessions/<pid>.json if present
    local cc_session_id=""
    local cc_session_file="$HOME/.claude/sessions/$$.json"
    if [[ -f "$cc_session_file" ]]; then
        cc_session_id=$(jq -r '.sessionId // ""' "$cc_session_file" 2>/dev/null || true)
    fi

    # Rewrite meta.json atomically
    local tmp_meta
    tmp_meta=$(mktemp "$session_dir/meta.json.XXXXXX")
    jq \
        --arg end_time        "$end_time" \
        --argjson duration    "${duration_secs}" \
        --argjson exit_code   "${exit_code}" \
        --argjson size        "${transcript_size}" \
        --arg cc_session_id   "$cc_session_id" \
        '. + {
            end_time:      $end_time,
            duration_secs: $duration,
            exit_code:     $exit_code,
            transcript_bytes: $size,
            cc_session_id: $cc_session_id,
            status:        "complete"
        }' "$session_dir/meta.json" > "$tmp_meta" && mv "$tmp_meta" "$session_dir/meta.json"

    # Set restrictive permissions on session files
    chmod 600 "$session_dir/raw.log"  2>/dev/null || true
    chmod 600 "$session_dir/meta.json" 2>/dev/null || true
    chmod 700 "$session_dir"

    # ------------------------------------------------------------------
    # 9. Post-processing hook — run in background, detached
    # ------------------------------------------------------------------
    local post_session="$HOME/.metareview/bin/post-session"
    if [[ -x "$post_session" ]]; then
        "$post_session" "$session_dir" &
        disown
    fi

    # ------------------------------------------------------------------
    # 10. Cleanup exported env vars
    # ------------------------------------------------------------------
    unset METAREVIEW_SESSION_ID
    unset METAREVIEW_SESSION_DIR
    unset METAREVIEW_TRANSCRIPT

    return $exit_code
}
