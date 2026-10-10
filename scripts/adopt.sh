#!/usr/bin/env bash
# ADOPT: читает согласованное scout-досье. Без --apply только показывает план.
# Поддерживает новый формат с колонкой «Слой/этап» и старые досье с 6 колонками.
set -uo pipefail

DOSSIER="${1:?Укажи scout-досье: scripts/adopt.sh knowledge/scout/<slug>-YYYY-MM-DD.md [--apply]}"
APPLY="${2:-}"
[[ -f "$DOSSIER" ]] || { echo "✗ Досье не найдено: $DOSSIER"; exit 1; }
[[ -z "$APPLY" || "$APPLY" == "--apply" ]] || { echo "✗ Неизвестный аргумент: $APPLY"; exit 1; }

trim() { sed 's/^[[:space:]]*//;s/[[:space:]]*$//'; }
TABLE=$(awk '/^## ADOPT-предложение/{f=1;next} f&&/^## /{exit} f&&/^\|/{print}' "$DOSSIER")
[[ -n "$TABLE" ]] || { echo "✗ В досье нет таблицы ADOPT-предложение"; exit 1; }

MUST=0; OPT=0; REJ=0; OK=0; FAIL=0; RESULTS=""
echo "═══ ADOPT: $DOSSIER ═══"
while IFS= read -r line; do
  tool=$(printf '%s' "$line" | cut -d'|' -f2 | trim)
  [[ -z "$tool" || "$tool" == "Инструмент" || "$tool" == "Скилл/инструмент" || "$tool" == ---* ]] && continue
  fields=$(printf '%s' "$line" | awk -F'|' '{print NF}')
  if [[ "$fields" -ge 9 ]]; then
    decision=$(printf '%s' "$line" | cut -d'|' -f5 | trim)
    command=$(printf '%s' "$line" | cut -d'|' -f8 | trim)
  elif [[ "$fields" -eq 8 ]]; then
    decision=$(printf '%s' "$line" | cut -d'|' -f5 | trim)
    command=$(printf '%s' "$line" | cut -d'|' -f7 | trim)
  else
    echo "✗ Некорректная строка таблицы: $tool"; FAIL=$((FAIL+1)); continue
  fi
  command=${command#\`}; command=${command%\`}
  case "$decision" in
    *"в основу"*|*"обязательно"*)
      MUST=$((MUST+1))
      if [[ "$APPLY" == "--apply" ]]; then
        if [[ -z "$command" || "$command" == "—" || "$command" == *...* ]]; then
          echo "✗ $tool: нет конкретной команды установки"; FAIL=$((FAIL+1)); continue
        fi
        if ! printf '%s' "$command" | grep -Eq '^(npx skills add |claude mcp add )'; then
          echo "✗ $tool: установка вручную, команда вне разрешённого списка"; FAIL=$((FAIL+1)); continue
        fi
        if printf '%s' "$command" | grep -Eq '[;&|$()<>`\\]'; then
          echo "✗ $tool: команда содержит управляющие символы"; FAIL=$((FAIL+1)); continue
        fi
        echo "→ ставлю: $tool ($command)"
        if bash -c "$command"; then
          OK=$((OK+1)); RESULTS+="- ✓ поставлено: $tool (\`$command\`)"$'\n'
        else
          FAIL=$((FAIL+1)); RESULTS+="- ✗ провал установки: $tool (\`$command\`)"$'\n'
        fi
      else
        echo "  [в основу] $tool — $command"
      fi ;;
    *"на выбор"*|*"на обсуждение"*|*"опционально"*|*"спросить"*)
      OPT=$((OPT+1)); echo "  [на выбор] $tool — решение владельца, сам не ставлю" ;;
    *"отклонено"*) REJ=$((REJ+1)) ;;
    *) echo "✗ $tool: неизвестное решение '$decision'"; FAIL=$((FAIL+1)) ;;
  esac
done <<< "$TABLE"

echo "Обязательных: $MUST · на выбор: $OPT · отклонено: $REJ · ошибок: $FAIL"
if [[ "$APPLY" == "--apply" ]]; then
  {
    echo ""
    echo "## ADOPT-итог (adopt.sh, $(date +%Y-%m-%d))"
    printf '%s' "$RESULTS"
    echo "- На выбор не тронуто: $OPT · отклонено: $REJ · ошибок: $FAIL"
    echo '- Демиургу: фактические `mcp__server__tool` поставленных MCP → `knowledge/{agent}/_toolmap.md`'
  } >> "$DOSSIER"
  echo "Итог дописан в досье. Успешно: $OK, ошибок: $FAIL"
else
  echo "Сухой прогон. После согласования: bash scripts/adopt.sh $DOSSIER --apply"
fi
[[ $FAIL -eq 0 ]]
