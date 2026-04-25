#!/bin/bash
# validate.sh — Общий health-check одной директории (агент ИЛИ маленькая система).
# 6 проверок: broken links / INDEX / размер CLAUDE.md / TODO-заглушки / дубли identity / пустые файлы.
# Для ДЕТАЛЬНОЙ проверки одного агента: validate-agent.sh
# Для ВСЕГО офиса: validate-office.sh
# Использование: bash validate.sh <target-dir>
# Возвращает: PASS/FAIL + список ошибок

set -uo pipefail

TARGET="${1:?Укажи директорию для проверки: bash validate.sh ./my-office}"
ERRORS=0
WARNINGS=0

echo "=== Demiurg Validate ==="
echo "Target: $TARGET"
echo ""

# --- 1. Проверка broken links в .md файлах ---
echo "--- Checking broken links ---"
while IFS= read -r mdfile; do
  # Ищем ссылки формата `path/to/file.md` (в обратных кавычках)
  while IFS= read -r link; do
    # Убираем обратные кавычки
    clean_link=$(echo "$link" | sed 's/`//g')
    # Пропускаем пустые, URL, переменные, команды
    [[ -z "$clean_link" ]] && continue
    [[ "$clean_link" == http* ]] && continue
    [[ "$clean_link" == *"{"* ]] && continue
    [[ "$clean_link" == *"$"* ]] && continue
    [[ "$clean_link" == bash* ]] && continue
    [[ "$clean_link" == *"/"*"/"* ]] || continue  # хотя бы один /

    # Только .md и .sh файлы
    [[ "$clean_link" == *.md ]] || [[ "$clean_link" == *.sh ]] || continue

    # Пропускаем только шаблонные/placeholder пути (не реальные файлы)
    [[ "$clean_link" == path/* ]] && continue
    [[ "$clean_link" == *"<"* ]] && continue
    [[ "$clean_link" == *"example"* ]] && continue
    [[ "$clean_link" == *"template"* ]] && continue
    # Проверяем относительно target или относительно файла
    if [ ! -f "$TARGET/$clean_link" ] && [ ! -f "$(dirname "$mdfile")/$clean_link" ]; then
      echo "  BROKEN: $mdfile -> $clean_link"
      ((ERRORS++)) || true
    fi
  done < <(grep -oE '`[^`]+\.(md|sh)`' "$mdfile" 2>/dev/null | sed 's/`//g' || true)
done < <(find "$TARGET" -name "*.md" -not -path "*/archive/*" 2>/dev/null)

# --- 2. Проверка INDEX.md в папках с >3 файлами ---
echo "--- Checking INDEX.md ---"
while IFS= read -r dir; do
  file_count=$(find "$dir" -maxdepth 1 -name "*.md" | wc -l | tr -d ' ')
  if [ "$file_count" -gt 3 ]; then
    if [ ! -f "$dir/INDEX.md" ]; then
      echo "  MISSING INDEX: $dir ($file_count files, no INDEX.md)"
      ((WARNINGS++)) || true
    fi
  fi
done < <(find "$TARGET" -type d -not -path "*/archive/*" 2>/dev/null)

# --- 3. Проверка размера CLAUDE.md ---
echo "--- Checking CLAUDE.md sizes ---"
while IFS= read -r claude; do
  lines=$(wc -l < "$claude" | tr -d ' ')
  if [ "$lines" -gt 200 ]; then
    echo "  OVERSIZED: $claude ($lines lines, max 200)"
    ((ERRORS++)) || true
  elif [ "$lines" -gt 150 ]; then
    echo "  WARNING: $claude ($lines lines, approaching limit)"
    ((WARNINGS++)) || true
  fi
done < <(find "$TARGET" -name "CLAUDE.md" 2>/dev/null)

# --- 4. Проверка TODO-заглушек ---
echo "--- Checking TODO stubs ---"
todo_count=$(grep -rl "TODO" "$TARGET" --include="*.md" 2>/dev/null | wc -l | tr -d ' ')
todo_count=${todo_count:-0}
if [ "$todo_count" -gt 0 ]; then
  echo "  FILES WITH TODO: $todo_count"
  grep -r "TODO" "$TARGET" --include="*.md" -l 2>/dev/null | while read -r f; do
    count=$(grep -c "TODO" "$f" 2>/dev/null || echo 0)
    echo "    $f ($count TODOs)"
  done
  ((WARNINGS += todo_count)) || true
fi

# --- 5. Проверка дублирования контента ---
echo "--- Checking duplicates ---"
# Проверяем Identity-блоки (первые 5 строк CLAUDE.md) через temp file
dup_tmp=$(mktemp)
find "$TARGET" -name "CLAUDE.md" 2>/dev/null | while read -r claude; do
  identity=$(head -5 "$claude" | md5 2>/dev/null || head -5 "$claude" | md5sum 2>/dev/null | cut -d' ' -f1)
  echo "$identity $claude" >> "$dup_tmp"
done
# Найти дубли по хешу
if [ -f "$dup_tmp" ]; then
  while IFS= read -r hash; do
    files=$(grep "^$hash " "$dup_tmp" | awk '{print $2}' | tr '\n' ' ')
    echo "  DUPLICATE IDENTITY: $files"
    ((ERRORS++)) || true
  done < <(awk '{print $1}' "$dup_tmp" | sort | uniq -d)
  rm -f "$dup_tmp"
fi

# --- 6. Проверка пустых файлов ---
echo "--- Checking empty files ---"
while IFS= read -r mdfile; do
  lines=$(wc -l < "$mdfile" | tr -d ' ')
  if [ "$lines" -lt 3 ]; then
    echo "  EMPTY/STUB: $mdfile ($lines lines)"
    ((WARNINGS++)) || true
  fi
done < <(find "$TARGET" -name "*.md" -not -name "DEPRECATED*" -not -path "*/archive/*" 2>/dev/null)

# --- Итог ---
echo ""
echo "=== RESULTS ==="
echo "Errors:   $ERRORS"
echo "Warnings: $WARNINGS"
echo ""

if [ "$ERRORS" -gt 0 ]; then
  echo "STATUS: FAIL"
  exit 1
else
  if [ "$WARNINGS" -gt 0 ]; then
    echo "STATUS: PASS (with warnings)"
  else
    echo "STATUS: PASS"
  fi
  exit 0
fi
