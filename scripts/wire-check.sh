#!/bin/bash
# wire-check.sh — Гейт после фазы Wire (последняя фаза конвейера Демиурга).
# Проверяет: агент прописан в AGENTS.md, handoff-ссылки валидны, нет broken связей с context.md.
# Запускать ПОСЛЕ validate-agent.sh + Validator (когда score ≥ 80) перед финальной отдачей.
# Использование: bash wire-check.sh /path/to/agent/directory [/path/to/office]
# Exit: 0 если все 4 чека PASS, иначе число ошибок.

set -uo pipefail

AGENT_DIR="${1:?Укажи путь к директории агента: ./wire-check.sh /path/to/agent [/path/to/office]}"
OFFICE_DIR="${2:-}"
ERRORS=0
WARNINGS=0

red()    { echo -e "\033[31m✗ $1\033[0m"; }
green()  { echo -e "\033[32m✓ $1\033[0m"; }
yellow() { echo -e "\033[33m⚠ $1\033[0m"; }
blue()   { echo -e "\033[34m→ $1\033[0m"; }

AGENT_NAME=$(basename "$AGENT_DIR")

echo "═══════════════════════════════════════"
echo "  wire-check.sh — $AGENT_NAME"
echo "═══════════════════════════════════════"
echo ""

# Auto-detect office если не передан
if [[ -z "$OFFICE_DIR" ]]; then
  PARENT=$(dirname "$AGENT_DIR")
  if [[ "$(basename "$PARENT")" == "agents" ]]; then
    OFFICE_DIR=$(dirname "$PARENT")
    blue "Office auto-detected: $OFFICE_DIR"
  else
    red "Не могу определить office. Передай вторым аргументом."
    exit 2
  fi
fi

AGENTS_MD="$OFFICE_DIR/AGENTS.md"
CONTEXT_MD="$OFFICE_DIR/context.md"
AGENT_CLAUDE_MD="$AGENT_DIR/CLAUDE.md"

# ─── 1. Запись в AGENTS.md ───
if [[ ! -f "$AGENTS_MD" ]]; then
  red "AGENTS.md не найден в $OFFICE_DIR"
  ERRORS=$((ERRORS + 1))
else
  if grep -qi "^[[:space:]]*[-*|][[:space:]]*\*\?\*\?$AGENT_NAME\b\|/$AGENT_NAME/\|/$AGENT_NAME\.md\|^# $AGENT_NAME" "$AGENTS_MD" 2>/dev/null \
     || grep -qi "$AGENT_NAME" "$AGENTS_MD" 2>/dev/null; then
    green "Запись в AGENTS.md найдена"
  else
    red "Агент '$AGENT_NAME' не найден в AGENTS.md — забыли вписать"
    ERRORS=$((ERRORS + 1))
  fi
fi

# ─── 2. Handoff-ссылки в CLAUDE.md агента валидны ───
if [[ ! -f "$AGENT_CLAUDE_MD" ]]; then
  red "CLAUDE.md агента не найден: $AGENT_CLAUDE_MD"
  ERRORS=$((ERRORS + 1))
else
  HANDOFF_BROKEN=0
  HANDOFF_TOTAL=0

  # Извлекаем упомянутых других агентов через handoff/redirect/передай паттерны
  while IFS= read -r mentioned; do
    HANDOFF_TOTAL=$((HANDOFF_TOTAL + 1))
    # Очищаем от форматирования
    clean=$(echo "$mentioned" | tr -d '`*_,.;:')
    [[ -z "$clean" ]] && continue
    [[ "$clean" == "$AGENT_NAME" ]] && continue

    # Проверяем что упомянутый агент есть в AGENTS.md
    if [[ -f "$AGENTS_MD" ]] && ! grep -qi "$clean" "$AGENTS_MD" 2>/dev/null; then
      HANDOFF_BROKEN=$((HANDOFF_BROKEN + 1))
      blue "  handoff → $clean (не найден в AGENTS.md)"
    fi
  done < <(grep -oiE '(передай|to:|handoff to|→)[[:space:]]+[A-ZА-Я][A-Za-zА-Яа-я-]+' "$AGENT_CLAUDE_MD" 2>/dev/null \
           | sed -E 's/^(передай|to:|handoff to|→)[[:space:]]+//i' | sort -u || true)

  if [[ $HANDOFF_BROKEN -gt 0 ]]; then
    red "Broken handoff: $HANDOFF_BROKEN из $HANDOFF_TOTAL ссылок ведут на несуществующих агентов"
    ERRORS=$((ERRORS + 1))
  elif [[ $HANDOFF_TOTAL -gt 0 ]]; then
    green "Handoff-ссылки валидны ($HANDOFF_TOTAL)"
  else
    yellow "Handoff-ссылок не найдено (агент изолирован?)"
    WARNINGS=$((WARNINGS + 1))
  fi
fi

# ─── 3. context.md обновлён за последние 7 дней (если есть) ───
if [[ -f "$CONTEXT_MD" ]]; then
  # macOS / Linux compatibility
  if MTIME=$(stat -f "%m" "$CONTEXT_MD" 2>/dev/null) || MTIME=$(stat -c "%Y" "$CONTEXT_MD" 2>/dev/null); then
    NOW=$(date +%s)
    AGE_DAYS=$(( (NOW - MTIME) / 86400 ))
    if [[ $AGE_DAYS -le 7 ]]; then
      green "context.md обновлён ($AGE_DAYS дн назад)"
    elif [[ $AGE_DAYS -le 30 ]]; then
      yellow "context.md устарел ($AGE_DAYS дн назад) — обнови при wire-фазе"
      WARNINGS=$((WARNINGS + 1))
    else
      red "context.md давно не обновлялся ($AGE_DAYS дн назад) — забытый офис"
      ERRORS=$((ERRORS + 1))
    fi
  fi
else
  yellow "context.md отсутствует в $OFFICE_DIR — рекомендуется создать"
  WARNINGS=$((WARNINGS + 1))
fi

# ─── 4. Overlap zones (грубая проверка) ───
# Сравниваем frontmatter description нашего агента с другими — % shared слов
if [[ -f "$AGENT_CLAUDE_MD" ]]; then
  MY_DESC=$(grep -oE '^description:[[:space:]]*.+' "$AGENT_CLAUDE_MD" 2>/dev/null | head -1 || echo "")
  if [[ -n "$MY_DESC" ]]; then
    # Простой подсчёт: ищем других агентов с похожим описанием
    OVERLAP_FOUND=0
    while IFS= read -r other_dir; do
      [[ "$other_dir" == "$AGENT_DIR" ]] && continue
      OTHER_CLAUDE="$other_dir/CLAUDE.md"
      [[ ! -f "$OTHER_CLAUDE" ]] && continue
      OTHER_DESC=$(grep -oE '^description:[[:space:]]*.+' "$OTHER_CLAUDE" 2>/dev/null | head -1 || echo "")
      [[ -z "$OTHER_DESC" ]] && continue

      # Грубая метрика: 3+ общих слова длиной > 4 = warning
      SHARED=$(echo "$MY_DESC $OTHER_DESC" | tr ' ' '\n' | sort | uniq -d | awk 'length > 4' | wc -l | tr -d ' ')
      if [[ $SHARED -ge 5 ]]; then
        OVERLAP_FOUND=$((OVERLAP_FOUND + 1))
        blue "  overlap c $(basename "$other_dir") — $SHARED общих ключевых слов"
      fi
    done < <(find "$OFFICE_DIR/agents" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)

    if [[ $OVERLAP_FOUND -ge 2 ]]; then
      yellow "Возможный overlap зон с $OVERLAP_FOUND агентами — проверь границы"
      WARNINGS=$((WARNINGS + 1))
    elif [[ $OVERLAP_FOUND -eq 1 ]]; then
      yellow "Возможный overlap с 1 агентом — допустимо если связь явная"
      WARNINGS=$((WARNINGS + 1))
    else
      green "Overlap зон не обнаружен"
    fi
  fi
fi

# ═══ ИТОГ ═══
echo ""
echo "═══════════════════════════════════════"

if [[ $ERRORS -eq 0 ]] && [[ $WARNINGS -eq 0 ]]; then
  green "WIRE PASS — все 4 чека прошли"
elif [[ $ERRORS -eq 0 ]]; then
  yellow "WIRE PASS WITH WARNINGS — $WARNINGS предупреждений"
else
  red "WIRE FAIL — $ERRORS ошибок, $WARNINGS предупреждений"
fi
echo "═══════════════════════════════════════"

exit $ERRORS
