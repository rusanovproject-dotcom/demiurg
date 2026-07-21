#!/bin/bash
# adopt.sh — фаза ADOPT конвейера /build: установка одобренного стека из scout-досье.
# Читает таблицу «ADOPT-предложение» досье, показывает план; с --apply ставит строки
# с вердиктом «ставим обязательно» и дописывает «ADOPT-итог (adopt.sh)» в досье.
# «опционально» — только печатает (решение Хозяина), «отклонено» — пропускает.
# Использование: ./adopt.sh <путь-к-досье.md> [--apply]

set -uo pipefail

DOSSIER="${1:?Укажи путь к scout-досье: ./adopt.sh knowledge/scout/<slug>-YYYY-MM-DD.md [--apply]}"
APPLY="${2:-}"

[[ -f "$DOSSIER" ]] || { echo "✗ Досье не найдено: $DOSSIER"; exit 1; }

# Вырезаем таблицу секции «ADOPT-предложение» (строки |...| до следующего заголовка)
TABLE=$(awk '/^## ADOPT-предложение/{f=1;next} f&&/^## /{exit} f&&/^\|/ && !/^\|[ \t:|-]*$/ && !/Инструмент/' "$DOSSIER" || true)

[[ -n "$TABLE" ]] || { echo "✗ В досье нет таблицы «ADOPT-предложение» — досье собрано старым скаутом? Перегони /scout."; exit 1; }

MUST=0; OPT=0; REJ=0; OK=0; FAIL=0
RESULTS=""

echo "═══ ADOPT: $DOSSIER ═══"
while IFS='|' read -r _ tool type tier verdict why cmd _; do
  tool=$(echo "$tool" | xargs); verdict=$(echo "$verdict" | xargs); cmd=$(echo "$cmd" | xargs | sed 's/^`//;s/`$//')
  [[ -z "$tool" ]] && continue
  case "$verdict" in
    *обязательно*)
      MUST=$((MUST+1))
      if [[ "$APPLY" == "--apply" ]]; then
        echo "→ ставлю: $tool  ($cmd)"
        if [[ -z "$cmd" || "$cmd" == "—" ]]; then
          echo "  ⚠ нет команды установки — пропуск"; RESULTS+="- ⚠ $tool: команда установки не указана"$'\n'
        elif bash -c "$cmd"; then
          OK=$((OK+1)); RESULTS+="- ✓ поставлено: $tool (\`$cmd\`)"$'\n'
        else
          FAIL=$((FAIL+1)); RESULTS+="- ✗ провал установки: $tool (\`$cmd\`) — разобраться руками"$'\n'
        fi
      else
        echo "  [обязательно] $tool — $cmd"
      fi ;;
    *опционально*|*спросить*)
      OPT=$((OPT+1)); echo "  [опционально] $tool — решение Хозяина, сам не ставлю" ;;
    *отклонено*)
      REJ=$((REJ+1)) ;;
  esac
done <<< "$TABLE"

echo "───"
echo "Обязательных: $MUST · опциональных (ждут Хозяина): $OPT · отклонено: $REJ"

if [[ "$APPLY" == "--apply" ]]; then
  {
    echo ""
    echo "## ADOPT-итог (adopt.sh, $(date +%Y-%m-%d))"
    echo "$RESULTS"
    echo "- Опциональных не тронуто: $OPT · отклонено по досье: $REJ"
    echo "- TODO Демиургу: конкретные \`mcp__server__tool\` поставленных MCP → в \`knowledge/{agent}/_toolmap.md\`"
  } >> "$DOSSIER"
  echo "Итог дописан в досье. Успешно: $OK, провалов: $FAIL"
  [[ $FAIL -eq 0 ]] || exit 1
else
  echo "Сухой прогон. Ставить: ./adopt.sh $DOSSIER --apply"
fi
