#!/bin/bash
# Sends macOS notification labelled with the session's chat topic.
# Usage: notify.sh <message>
MESSAGE="$1"

# Graceful fallback: if terminal-notifier is missing, print install hint and exit.
if ! command -v terminal-notifier >/dev/null 2>&1; then
  echo "chat-topic-notifier: terminal-notifier not found. Install with: brew install terminal-notifier" >&2
  exit 0
fi

INPUT=$(cat /dev/stdin)
SESSION_ID=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('session_id',''))" 2>/dev/null)
CWD=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null)

# Get session title from transcript (set by /rename or by set-topic.sh)
TOPIC=""
if [ -n "$SESSION_ID" ] && [ -n "$CWD" ]; then
  PROJECT_DIR=$(echo "$CWD" | tr '/' '-')
  TRANSCRIPT="$HOME/.claude/projects/${PROJECT_DIR}/${SESSION_ID}.jsonl"
  if [ -f "$TRANSCRIPT" ]; then
    TOPIC=$(grep '"custom-title"' "$TRANSCRIPT" | tail -1 | python3 -c "import sys,json; print(json.load(sys.stdin).get('customTitle',''))" 2>/dev/null)
  fi
fi

if [ -n "$TOPIC" ]; then
  TITLE="CC: $TOPIC"
else
  TITLE="CC: No topic"
fi

terminal-notifier -title "$TITLE" -message "$MESSAGE"
