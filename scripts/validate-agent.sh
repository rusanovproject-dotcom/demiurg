#!/bin/bash
# validate-agent.sh — Детальная проверка ОДНОГО агента БЕЗ LLM.
# 10 чеков: CLAUDE.md exists / size / frontmatter / Input→Output / Self-check /
#           Output contract / AI-слоп / broken links (backticks + markdown) /
#           skills с MANDATORY TRIGGERS / "НЕ отвечает за".
# Ловит 80% проблем бесплатно. Запускать ПЕРЕД Validator-субагентом.
# Для общего health-check директории: validate.sh
# Для всего офиса: validate-office.sh
# Использование: ./validate-agent.sh /path/to/agent/directory

set -euo pipefail

AGENT_DIR="${1:?Укажи путь к директории агента: ./validate-agent.sh /path/to/agent}"
ERRORS=0
WARNINGS=0
CHECKS=0

red() { echo -e "\033[31m✗ $1\033[0m"; }
green() { echo -e "\033[32m✓ $1\033[0m"; }
yellow() { echo -e "\033[33m⚠ $1\033[0m"; }
blue() { echo -e "\033[34m→ $1\033[0m"; }

echo "═══════════════════════════════════════"
echo "  validate-agent.sh — $(basename "$AGENT_DIR")"
echo "═══════════════════════════════════════"
echo ""

# ─── 1. CLAUDE.md существует ───
CHECKS=$((CHECKS + 1))
CLAUDE_MD="$AGENT_DIR/CLAUDE.md"
if [[ ! -f "$CLAUDE_MD" ]]; then
  red "CLAUDE.md не найден в $AGENT_DIR"
  echo ""
  red "FATAL: Без CLAUDE.md агент не существует."
  exit 1
fi
green "CLAUDE.md найден"

# ─── 2. Размер CLAUDE.md ≤ 150 строк ───
CHECKS=$((CHECKS + 1))
LINES=$(wc -l < "$CLAUDE_MD" | tr -d ' ')
if [[ $LINES -gt 150 ]]; then
  red "CLAUDE.md = $LINES строк (макс 150)"
  ERRORS=$((ERRORS + 1))
elif [[ $LINES -gt 120 ]]; then
  yellow "CLAUDE.md = $LINES строк (рекомендуется ≤120)"
  WARNINGS=$((WARNINGS + 1))
else
  green "CLAUDE.md = $LINES строк"
fi

# ─── 3. Frontmatter ───
CHECKS=$((CHECKS + 1))
if head -1 "$CLAUDE_MD" | grep -q "^---"; then
  FRONTMATTER=$(sed -n '1,/^---$/p' "$CLAUDE_MD" | tail -n +2)

  for field in name description model; do
    CHECKS=$((CHECKS + 1))
    if echo "$FRONTMATTER" | grep -q "^${field}:"; then
      green "frontmatter: $field"
    else
      red "frontmatter: $field отсутствует"
      ERRORS=$((ERRORS + 1))
    fi
  done
else
  red "Нет frontmatter (---)"
  ERRORS=$((ERRORS + 1))
fi

# ─── 4. Примеры Input→Output ───
CHECKS=$((CHECKS + 1))
EXAMPLES=$(grep -ci "input\|output\|пример" "$CLAUDE_MD" 2>/dev/null || echo 0)
if [[ $EXAMPLES -ge 2 ]]; then
  green "Примеры найдены ($EXAMPLES упоминаний)"
else
  red "Мало примеров Input→Output (нашёл $EXAMPLES, нужно ≥2)"
  ERRORS=$((ERRORS + 1))
fi

# ─── 5. Self-check ───
CHECKS=$((CHECKS + 1))
if grep -qi "self-check\|чеклист\|проверь перед" "$CLAUDE_MD" 2>/dev/null; then
  green "Self-check секция найдена"
else
  yellow "Нет Self-check секции"
  WARNINGS=$((WARNINGS + 1))
fi

# ─── 6. Output contract ───
CHECKS=$((CHECKS + 1))
if grep -qi "output contract\|результат.*=" "$CLAUDE_MD" 2>/dev/null; then
  green "Output contract найден"
else
  yellow "Нет Output contract"
  WARNINGS=$((WARNINGS + 1))
fi

# ─── 7. AI-слоп ───
CHECKS=$((CHECKS + 1))
SLOP_PATTERNS="в мире где|давайте рассмотрим|рад помочь|с удовольствием|отличный вопрос|погрузимся|на самом деле|уникальное предложение"
SLOP_FOUND=$(grep -vE '\[ \]|\[x\]' "$CLAUDE_MD" 2>/dev/null | grep -ciE "$SLOP_PATTERNS" 2>/dev/null || true)
SLOP_FOUND=${SLOP_FOUND:-0}
SLOP_FOUND=$(echo "$SLOP_FOUND" | tr -d '[:space:]')
if [[ "$SLOP_FOUND" -gt 0 ]] 2>/dev/null; then
  red "AI-слоп найден ($SLOP_FOUND совпадений)"
  grep -niE "$SLOP_PATTERNS" "$CLAUDE_MD" 2>/dev/null | head -5 | while read -r line; do
    blue "  $line"
  done
  ERRORS=$((ERRORS + 1))
else
  green "AI-слоп не найден"
fi

# ─── 8. Валидность ссылок ───
CHECKS=$((CHECKS + 1))
BROKEN_LINKS=0
# Ищем ссылки вида `path/to/file.md` или backtick-пути
while IFS= read -r link; do
  # Убираем backticks и кавычки
  clean_link=$(echo "$link" | sed 's/[`"'"'"']//g' | xargs)

  # Пропускаем пустые, URL, и не-файловые ссылки
  [[ -z "$clean_link" ]] && continue
  [[ "$clean_link" == http* ]] && continue
  [[ "$clean_link" != */* ]] && continue
  [[ "$clean_link" != *.md ]] && [[ "$clean_link" != *.sh ]] && [[ "$clean_link" != *.json ]] && continue

  # Резолвим путь
  if [[ "$clean_link" == ~/* ]]; then
    resolved="${clean_link/#\~/$HOME}"
  elif [[ "$clean_link" == /* ]]; then
    resolved="$clean_link"
  else
    resolved="$AGENT_DIR/$clean_link"
  fi

  if [[ ! -e "$resolved" ]]; then
    if [[ $BROKEN_LINKS -eq 0 ]]; then
      red "Broken links:"
    fi
    blue "  $clean_link → не существует"
    BROKEN_LINKS=$((BROKEN_LINKS + 1))
  fi
done < <( ( grep -oE '`[^`]+\.(md|sh|json)`' "$CLAUDE_MD" 2>/dev/null | sed 's/`//g'; grep -oE '\(([^)]+\.(md|sh|json))\)' "$CLAUDE_MD" 2>/dev/null | sed 's/^(//; s/)$//' ) | sort -u || true)

if [[ $BROKEN_LINKS -gt 0 ]]; then
  red "$BROKEN_LINKS broken link(s)"
  ERRORS=$((ERRORS + 1))
else
  green "Все ссылки валидны (или нет inline-ссылок)"
fi

# ─── 9. Скиллы ───
CHECKS=$((CHECKS + 1))
SKILLS_DIR="$AGENT_DIR/skills"
if [[ -d "$SKILLS_DIR" ]]; then
  SKILL_COUNT=$(find "$SKILLS_DIR" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
  green "Скиллов: $SKILL_COUNT"

  # Проверяем MANDATORY TRIGGERS в каждом скилле
  while IFS= read -r skill_file; do
    CHECKS=$((CHECKS + 1))
    skill_name=$(dirname "$skill_file" | xargs basename)
    if grep -q -i "trigger\|mandatory" "$skill_file" 2>/dev/null || grep -q "триггер\|Триггер\|ТРИГГЕР\|когда вызывать\|Когда вызывать" "$skill_file" 2>/dev/null; then
      green "  $skill_name: triggers найдены"
    else
      yellow "  $skill_name: нет MANDATORY TRIGGERS"
      WARNINGS=$((WARNINGS + 1))
    fi

    # Размер скилла
    CHECKS=$((CHECKS + 1))
    skill_lines=$(wc -l < "$skill_file" | tr -d ' ')
    if [[ $skill_lines -gt 100 ]]; then
      yellow "  $skill_name: $skill_lines строк (рекомендуется ≤100)"
      WARNINGS=$((WARNINGS + 1))
    fi
  done < <(find "$SKILLS_DIR" -name "SKILL.md" 2>/dev/null)
else
  yellow "Нет директории skills/"
  WARNINGS=$((WARNINGS + 1))
fi

# ─── 10. "НЕ отвечает за" ───
CHECKS=$((CHECKS + 1))
if grep -qi "НЕ отвечае\|не отвечает за\|не делает" "$CLAUDE_MD" 2>/dev/null; then
  green "Зона 'НЕ отвечает за' найдена"
else
  yellow "Нет секции 'НЕ отвечает за'"
  WARNINGS=$((WARNINGS + 1))
fi

# ─── 11. Knowledge Miner _score.json (если есть knowledge/) ───
KNOWLEDGE_DIR="$AGENT_DIR/knowledge"
if [[ -d "$KNOWLEDGE_DIR" ]]; then
  CHECKS=$((CHECKS + 1))
  SCORE_FILE="$KNOWLEDGE_DIR/_score.json"
  if [[ -f "$SCORE_FILE" ]]; then
    # Извлекаем avg и verdict через простой grep (не требуем jq)
    AVG=$(grep -oE '"avg"[[:space:]]*:[[:space:]]*[0-9]+\.?[0-9]*' "$SCORE_FILE" 2>/dev/null | grep -oE '[0-9]+\.?[0-9]*$' | head -1)
    VERDICT=$(grep -oE '"verdict"[[:space:]]*:[[:space:]]*"[A-Z_]+"' "$SCORE_FILE" 2>/dev/null | grep -oE '"[A-Z_]+"$' | tr -d '"')

    if [[ -z "$AVG" ]] || [[ -z "$VERDICT" ]]; then
      yellow "_score.json есть, но не парсится (avg/verdict не найдены)"
      WARNINGS=$((WARNINGS + 1))
    elif [[ "$VERDICT" == "BLOCK" ]]; then
      red "Knowledge score: avg=$AVG verdict=BLOCK — Builder НЕ должен стартовать"
      ERRORS=$((ERRORS + 1))
    elif [[ "$VERDICT" == "NEEDS_WORK" ]]; then
      yellow "Knowledge score: avg=$AVG verdict=NEEDS_WORK — Builder может работать с warning"
      WARNINGS=$((WARNINGS + 1))
    else
      green "Knowledge score: avg=$AVG verdict=PASS"
    fi
  else
    yellow "Нет _score.json от Knowledge Miner (knowledge/ есть, score не записан)"
    WARNINGS=$((WARNINGS + 1))
  fi
fi

# ═══ ИТОГ ═══
echo ""
echo "═══════════════════════════════════════"
SCORE=$((CHECKS - ERRORS))
PERCENT=$((SCORE * 100 / CHECKS))

if [[ $ERRORS -eq 0 ]]; then
  green "PASS — $SCORE/$CHECKS проверок ($PERCENT%), $WARNINGS предупреждений"
elif [[ $ERRORS -le 2 ]]; then
  yellow "NEEDS WORK — $ERRORS ошибок, $WARNINGS предупреждений ($PERCENT%)"
else
  red "FAIL — $ERRORS ошибок, $WARNINGS предупреждений ($PERCENT%)"
fi
echo "═══════════════════════════════════════"

exit $ERRORS
