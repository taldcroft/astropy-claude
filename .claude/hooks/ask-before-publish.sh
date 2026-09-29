#!/bin/bash
# PreToolUse hook (Bash): force a permission prompt before committing, pushing,
# creating/editing a PR, or writing a PR description file via the shell.
cmd=$(jq -r '.tool_input.command // ""')

ask() {
  jq -cn --arg r "$1" '{hookSpecificOutput: {hookEventName: "PreToolUse",
    permissionDecision: "ask", permissionDecisionReason: $r}}'
  exit 0
}

# "git ... commit" / "git ... push", allowing options such as -C <dir> in between
if printf '%s' "$cmd" | grep -Eq '(^|[^[:alnum:]_-])git([[:space:]]+[^[:space:];&|]+)*[[:space:]]+(commit|push)([[:space:]]|$|[;&|])'; then
  ask "Always ask before a git commit or push."
fi
if printf '%s' "$cmd" | grep -Eq 'gh[[:space:]]+pr[[:space:]]+(create|edit)'; then
  ask "Always ask before creating or editing a PR."
fi
if printf '%s' "$cmd" | grep -Eq '(>|tee|sed[[:space:]]+-i|cp|mv|rsync).*pr[0-9]*-description\.md'; then
  ask "Always ask before writing a PR description file."
fi
exit 0
