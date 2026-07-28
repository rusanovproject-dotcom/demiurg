#!/bin/bash
# Agent Quality Auto-Check — быстрая автоматическая проверка файлов агента
# Usage: bash auto-check.sh <path-to-agent-directory>
#
# Проверяет наличие ключевых элементов и выдаёт preliminary score.
# Для полной оценки нужен ручной ревью по 8 измерениям.

AGENT_DIR="${1:-.}"
SCORE=0
MAX_SCORE=100
ISSUES=""
GOOD=""

echo "=========================================="
echo "  AGENT QUALITY AUTO-CHECK"
echo "  Path: $AGENT_DIR"
echo "=========================================="
echo ""

# --- Check 1: CLAUDE.md exists ---
if [ -f "$AGENT_DIR/CLAUDE.md" ]; then
    SCORE=$((SCORE + 5))
    GOOD="$GOOD\n  [+5] CLAUDE.md найден"

    LINES=$(wc -l < "$AGENT_DIR/CLAUDE.md")

    # Check size
    if [ "$LINES" -lt 500 ]; then
        SCORE=$((SCORE + 3))
        GOOD="$GOOD\n  [+3] Размер CLAUDE.md оптимальный ($LINES строк)"
    else
        ISSUES="$ISSUES\n  [-] CLAUDE.md слишком большой ($LINES строк, рекомендация <500)"
    fi

    # Check for role definition
    if grep -qi "роль\|role\|ты —\|you are\|специализация\|specializ" "$AGENT_DIR/CLAUDE.md"; then
        SCORE=$((SCORE + 5))
        GOOD="$GOOD\n  [+5] Роль определена"
    else
        ISSUES="$ISSUES\n  [-5] Нет определения роли"
    fi

    # Check for boundaries (what agent does NOT do)
    if grep -qi "не делает\|не дела\|НЕ \|don't\|never\|запрещ\|нельзя\|ограничен" "$AGENT_DIR/CLAUDE.md"; then
        SCORE=$((SCORE + 3))
        GOOD="$GOOD\n  [+3] Есть границы/ограничения"
    else
        ISSUES="$ISSUES\n  [-3] Нет ограничений роли (что агент НЕ делает)"
    fi

    # Check for context loading
    if grep -qi "context\|контекст\|state\.md\|загруз\|при старте\|before start" "$AGENT_DIR/CLAUDE.md"; then
        SCORE=$((SCORE + 5))
        GOOD="$GOOD\n  [+5] Есть context loading"
    else
        ISSUES="$ISSUES\n  [-5] Нет загрузки контекста"
    fi

    # Check for error handling
    if grep -qi "ошибк\|error\|fail\|retry\|escalat\|восстановлен\|recovery\|сбо" "$AGENT_DIR/CLAUDE.md"; then
        SCORE=$((SCORE + 5))
        GOOD="$GOOD\n  [+5] Есть обработка ошибок"
    else
        ISSUES="$ISSUES\n  [-5] Нет обработки ошибок"
    fi

    # Check for human-in-the-loop
    if grep -qi "подтвержд\|одобрен\|approval\|human\|confirm\|ревью\|review\|проверк" "$AGENT_DIR/CLAUDE.md"; then
        SCORE=$((SCORE + 5))
        GOOD="$GOOD\n  [+5] Есть human-in-the-loop"
    else
        ISSUES="$ISSUES\n  [-5] Нет human-in-the-loop"
    fi

    # Check for examples
    if grep -qi "пример\|example\|плохо:\|хорошо:\|bad:\|good:" "$AGENT_DIR/CLAUDE.md"; then
        SCORE=$((SCORE + 4))
        GOOD="$GOOD\n  [+4] Есть примеры"
    else
        ISSUES="$ISSUES\n  [-4] Нет примеров good/bad"
    fi

    # Check for tools/MCP
    if grep -qi "mcp\|инструмент\|tool\|github\|api\|server" "$AGENT_DIR/CLAUDE.md"; then
        SCORE=$((SCORE + 3))
        GOOD="$GOOD\n  [+3] Определены инструменты"
    else
        ISSUES="$ISSUES\n  [-3] Нет определения инструментов"
    fi

    # Check for security
    if grep -qi "безопасн\|security\|секрет\|secret\|ключ\|key\|\.env\|least privilege\|привилег" "$AGENT_DIR/CLAUDE.md"; then
        SCORE=$((SCORE + 4))
        GOOD="$GOOD\n  [+4] Есть security measures"
    else
        ISSUES="$ISSUES\n  [-4] Нет security measures"
    fi

    # Check for monitoring/logging
    if grep -qi "лог\|log\|мониторинг\|monitor\|метрик\|metric\|observ\|трек\|track" "$AGENT_DIR/CLAUDE.md"; then
        SCORE=$((SCORE + 3))
        GOOD="$GOOD\n  [+3] Есть мониторинг/логирование"
    else
        ISSUES="$ISSUES\n  [-3] Нет мониторинга"
    fi

    # Check for team awareness
    if grep -qi "команд\|team\|agent\|агент\|координац\|роутинг\|routing\|делегир" "$AGENT_DIR/CLAUDE.md"; then
        SCORE=$((SCORE + 3))
        GOOD="$GOOD\n  [+3] Есть awareness команды"
    else
        ISSUES="$ISSUES\n  [-3] Нет awareness команды"
    fi

else
    ISSUES="$ISSUES\n  [-] CLAUDE.md НЕ НАЙДЕН — критическая проблема"
fi

# --- Check 2: State management files ---
if [ -f "$AGENT_DIR/state.md" ] || [ -f "$AGENT_DIR/ops/state.md" ] || [ -f "$AGENT_DIR/ops/context.md" ]; then
    SCORE=$((SCORE + 5))
    GOOD="$GOOD\n  [+5] State management file найден"
else
    ISSUES="$ISSUES\n  [-5] Нет state.md / context.md"
fi

# --- Check 3: Decision log ---
if [ -d "$AGENT_DIR/decisions" ] || [ -f "$AGENT_DIR/decisions.md" ] || [ -f "$AGENT_DIR/DECISIONS.md" ]; then
    SCORE=$((SCORE + 3))
    GOOD="$GOOD\n  [+3] Decision log найден"
fi

# --- Check 4: Skills / agents directory ---
if [ -d "$AGENT_DIR/agents" ] || [ -d "$AGENT_DIR/skills" ] || [ -d "$AGENT_DIR/.claude/agents" ]; then
    SCORE=$((SCORE + 3))
    GOOD="$GOOD\n  [+3] Agents/skills directory найден"
fi

# --- Check 5: Architecture docs ---
if [ -f "$AGENT_DIR/ARCHITECTURE.md" ] || [ -f "$AGENT_DIR/AGENTS.md" ]; then
    SCORE=$((SCORE + 3))
    GOOD="$GOOD\n  [+3] Architecture documentation найден"
fi

# Cap at max
if [ "$SCORE" -gt "$MAX_SCORE" ]; then
    SCORE=$MAX_SCORE
fi

# --- Output ---
echo "РЕЗУЛЬТАТ: $SCORE / ~$MAX_SCORE (preliminary)"
echo ""

# Level
if [ "$SCORE" -ge 85 ]; then
    echo "УРОВЕНЬ: ELITE"
elif [ "$SCORE" -ge 70 ]; then
    echo "УРОВЕНЬ: STRONG"
elif [ "$SCORE" -ge 50 ]; then
    echo "УРОВЕНЬ: DEVELOPING"
elif [ "$SCORE" -ge 30 ]; then
    echo "УРОВЕНЬ: WEAK"
else
    echo "УРОВЕНЬ: CRITICAL"
fi

echo ""
echo "--- ЧТО ХОРОШО ---"
echo -e "$GOOD"
echo ""
echo "--- ЧТО ИСПРАВИТЬ ---"
echo -e "$ISSUES"
echo ""
echo "=========================================="
echo "  Для полной оценки: запроси ручной ревью"
echo "  по 8 измерениям (SKILL.md → agent-quality-reviewer)"
echo "=========================================="
