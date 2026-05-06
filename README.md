# chat-topic-notifier

Claude Code plugin that:

1. **Auto-generates a 1-3 word topic** for each new chat session via a background `claude -p --model haiku` call, and writes it as a `custom-title` entry into the session transcript.
2. **Shows macOS notifications** labelled with that topic on Stop (`CC: <topic>` / `✅ Task completed`) and on PermissionRequest (`CC: <topic>` / `⏳ Waiting for approval`). Falls back to `CC: No topic` if no topic was set yet.

## Requirements

- macOS
- [`terminal-notifier`](https://github.com/julienXX/terminal-notifier): `brew install terminal-notifier`
- `claude` CLI on PATH (you already have it if you're using Claude Code)
- `python3` (preinstalled on macOS)

## Install

```
/plugin marketplace add kor1b/claude-marketplace
/plugin install chat-topic-notifier@kor1b-claude-marketplace
```

## How it works

- `UserPromptSubmit` hook -> `set-topic.sh`: checks if the transcript already has a `custom-title`. If not, kicks off a background `claude -p` (with `--setting-sources ""` so it doesn't inherit your hooks and spam notifications) and writes the topic into the transcript ~7-9s later. A per-session lock prevents racing parallel prompts.
- `Stop` hook -> `notify.sh '✅ Task completed'`: sends notification when Claude finishes a turn.
- `PermissionRequest` hook -> `notify.sh '⏳ Waiting for approval'`: sends notification when Claude needs your approval for a tool call.

## License

MIT
