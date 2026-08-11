#!/bin/bash
# PreToolUse-хук для Bash: не даёт обойти правила работы с main.
#
# Третий слой защиты. Первые два — .githooks/pre-push и ruleset protect-main
# на GitHub. Ценность этого слоя в том, что он ловит ровно то, чего не ловят
# те два: обход через --no-verify и мердж PR.

set -uo pipefail

cmd=$(/usr/bin/jq -r '.tool_input.command // ""')

deny() {
	printf 'Заблокировано хуком .claude/hooks/guard-git.sh: %s\n\n%s\n' "$1" "$2" >&2
	exit 2
}

if printf '%s' "$cmd" | grep -Fq -- '--no-verify'; then
	deny "попытка обойти git-хуки через --no-verify" \
	     "Хук pre-push стоит не для украшения. Мешает по делу — скажи об этом, а не обходи."
fi

if printf '%s' "$cmd" | grep -Eq 'gh pr (merge|ready)'; then
	deny "мердж PR или снятие статуса черновика" \
	     "Решение о мердже принимает человек. Оставь PR черновиком."
fi

if printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]])git([[:space:]]+-[^[:space:]]+)*[[:space:]]+push([[:space:]]|$)'; then
	if printf '%s' "$cmd" | grep -Eq '(^|[[:space:]:])(main|master)([[:space:]]|$)'; then
		deny "в команде указана ветка main/master" \
		     "Работай через feature-ветку и PR."
	fi
	branch=$(git -C "${CLAUDE_PROJECT_DIR:-.}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
	if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
		deny "текущая ветка — $branch" \
		     "Создай ветку: git switch -c feature/<KEY>-<кратко> main"
	fi
fi

exit 0
