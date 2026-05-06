#!/bin/bash
# UserPromptSubmit hook: if the session has no customTitle yet, generate one
# in the background via `claude -p` and append a custom-title entry to the
# transcript. notify.sh reads that entry to label macOS notifications.
INPUT=$(cat /dev/stdin)
SESSION_ID=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('session_id',''))" 2>/dev/null)
CWD=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null)
PROMPT=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('prompt',''))" 2>/dev/null)

if [ -z "$SESSION_ID" ] || [ -z "$CWD" ] || [ -z "$PROMPT" ]; then
  exit 0
fi

PROJECT_DIR=$(echo "$CWD" | tr '/' '-')
TRANSCRIPT="$HOME/.claude/projects/${PROJECT_DIR}/${SESSION_ID}.jsonl"
LOCK_DIR="$HOME/.claude/plugins/chat-topic-notifier"
LOCK="$LOCK_DIR/${SESSION_ID}.lock"

# Skip if a topic already exists in the transcript.
if [ -f "$TRANSCRIPT" ] && grep -q '"custom-title"' "$TRANSCRIPT"; then
  exit 0
fi

# Skip if another hook invocation is already generating a topic for this session.
if [ -e "$LOCK" ]; then
  exit 0
fi

mkdir -p "$LOCK_DIR"
touch "$LOCK"

(
  # --setting-sources "" prevents the nested claude from inheriting our Stop/UserPromptSubmit hooks
  # (otherwise it would fire notify.sh on its own completion, spamming notifications).
  TOPIC=$(printf '%s' "$PROMPT" | claude -p --model haiku --output-format text --setting-sources "" \
    "Reply with 1-3 words summarizing the topic of the user's message. Output the topic only, no quotes, no punctuation, no preamble. Use the same language as the user." \
    2>/dev/null)

  TOPIC=$(printf '%s' "$TOPIC" | tr -d '\n\r' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g' | cut -c1-60)

  if [ -n "$TOPIC" ]; then
    LINE=$(SESSION_ID="$SESSION_ID" TOPIC="$TOPIC" python3 -c "
import json, os
print(json.dumps({
  'type': 'custom-title',
  'customTitle': os.environ['TOPIC'],
  'sessionId': os.environ['SESSION_ID'],
}))")
    mkdir -p "$(dirname "$TRANSCRIPT")"
    echo "$LINE" >> "$TRANSCRIPT"
  fi

  rm -f "$LOCK"
) >/dev/null 2>&1 &

disown 2>/dev/null
exit 0
