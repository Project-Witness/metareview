#!/usr/bin/env bash
# user-prompt-submit.sh — append timestamp marker for speaker boundary detection

SESSION_DIR="${METAREVIEW_SESSION_DIR:-}"
[[ -z "$SESSION_DIR" ]] && exit 0
[[ -d "$SESSION_DIR" ]] || exit 0

TS=$(date +%s)
PROMPT_LEN=0
if [[ ! -t 0 ]]; then
    INPUT=$(cat)
    PROMPT_LEN=${#INPUT}
fi

echo "{\"event\":\"user_submit\",\"ts\":$TS,\"prompt_length\":$PROMPT_LEN}" \
    >> "$SESSION_DIR/markers.jsonl"

exit 0
