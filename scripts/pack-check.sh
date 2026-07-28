#!/bin/bash
# pack-check.sh — PRE-PUBLISH гейт: проверка комплектности пака агента перед выкладкой наружу.
#
# Ловит ровно те дыры, из-за которых у пользователя пака «README обещает, а в репо нет»:
#   1. Скилл упомянут в доке, но его нет в репо (и наоборот — есть, но не описан)
#   2. Роутинг внутри скиллов ведёт в несуществующий скилл
#   3. Приватные пути и личные имена, которые у чужого человека будут битыми
#   4. Секреты в открытом виде
#   5. Скилл без валидного frontmatter (name/description) — Claude его не увидит
#
# Usage: bash scripts/pack-check.sh [путь-до-пака] [--names "Имя1,Имя2"]
# Exit:  0 — можно публиковать, 1 — есть блокеры
#
# Настройка личных имён для проверки: --names "Иван,Мария" (по умолчанию не ищет).

set -uo pipefail

PACK_DIR="."
PERSONAL_NAMES=""
while [ $# -gt 0 ]; do
    case "$1" in
        --names) PERSONAL_NAMES="${2:-}"; shift 2 ;;
        *) PACK_DIR="$1"; shift ;;
    esac
done

cd "$PACK_DIR" 2>/dev/null || { echo "Нет такой папки: $PACK_DIR"; exit 1; }

BLOCKERS=0
WARNINGS=0
block() { echo "  ✗ БЛОКЕР: $1"; BLOCKERS=$((BLOCKERS + 1)); }
warn()  { echo "  ⚠ $1"; WARNINGS=$((WARNINGS + 1)); }
ok()    { echo "  ✓ $1"; }

echo "=========================================="
echo "  PRE-PUBLISH CHECK — комплектность пака"
echo "  Путь: $(pwd)"
echo "=========================================="

# Доки, в которых ищем упоминания скиллов
DOCS=$(ls README.md CLAUDE.md AGENTS.md 2>/dev/null)
[ -z "$DOCS" ] && { echo "Нет ни README.md, ни CLAUDE.md — это не пак. Стоп."; exit 1; }

# --- 1. Скиллы: факт против документации ---
echo ""
echo "[1] Скиллы: репозиторий против README"

if [ ! -d skills ]; then
    warn "Папки skills/ нет — если пак без скиллов, это нормально"
else
    REAL_SKILLS=$(find skills -maxdepth 2 -name SKILL.md 2>/dev/null | sed 's|^skills/||; s|/SKILL.md$||' | sort)
    [ -z "$REAL_SKILLS" ] && warn "В skills/ нет ни одного SKILL.md"

    # Скилл есть в репо, но нигде не описан
    for s in $REAL_SKILLS; do
        if ! grep -qF "$s" $DOCS 2>/dev/null; then
            block "скилл '$s' есть в репо, но не упомянут в README/CLAUDE.md — пользователь о нём не узнает"
        fi
    done

    # Скилл обещан в доке, но его нет в репо.
    # Явная ссылка `skills/<имя>/` — однозначное обещание.
    PROMISED=$(grep -ohE 'skills/[a-z0-9][a-z0-9-]*/' $DOCS 2>/dev/null | sed 's|^skills/||; s|/$||' | sort -u)
    for p in $PROMISED; do
        if [ ! -f "skills/$p/SKILL.md" ]; then
            block "README/CLAUDE.md обещает 'skills/$p/', но в репо такого скилла нет"
        fi
    done

    [ $BLOCKERS -eq 0 ] && ok "все скиллы на месте и описаны ($(echo "$REAL_SKILLS" | wc -w | tr -d ' ') шт.)"
fi

# --- 1b. Любая папка, обещанная в доке ---
# Ловит дерево «что внутри», где перечислены папки, которых давно нет.
echo ""
echo "[1b] Папки, обещанные в документации"

DIR_BAD=0
SELF_NAME=$(basename "$(pwd)")
MENTIONED=$(grep -ohE '(^|[ │├└─`|(])[a-z0-9][a-z0-9._-]{2,}/' $DOCS 2>/dev/null \
            | grep -oE '[a-z0-9][a-z0-9._-]{2,}/' | sed 's|/$||' | sort -u)
for d in $MENTIONED; do
    # Имя самого пака в дереве «что внутри» — это корень, не подпапка
    [ "$d" = "$SELF_NAME" ] && continue
    # Строка вида «demiurg/» без отступа — тоже корень ASCII-дерева
    grep -qE "^${d}/$" $DOCS 2>/dev/null && continue
    # Есть где-нибудь в дереве пака — считаем обещание выполненным
    find . -type d -name "$d" -not -path "./.git/*" 2>/dev/null | grep -q . && continue
    # Или это файл (например, ссылка на .md с косой чертой в конце строки)
    find . -type f -name "$d*" -not -path "./.git/*" 2>/dev/null | grep -q . && continue
    block "документация упоминает папку '$d/', но её нет в паке"
    DIR_BAD=$((DIR_BAD + 1))
done
[ $DIR_BAD -eq 0 ] && ok "все папки из документации существуют"

# --- 2. Роутинг внутри скиллов ---
echo ""
echo "[2] Роутинг: ссылки вида /<скилл> внутри скиллов"

if [ -d skills ]; then
    ROUTE_BAD=0
    # Собираем /<имя> из текста скиллов; отсеиваем пути (/usr, /Users) и известные внешние команды
    ROUTES=$(grep -rhoE '(^|[ `«(])/[a-z][a-z0-9-]{2,}' skills --include="*.md" 2>/dev/null \
             | grep -oE '/[a-z][a-z0-9-]{2,}' | sed 's|^/||' | sort -u)
    for r in $ROUTES; do
        # Скилл этого пака — ок
        [ -f "skills/$r/SKILL.md" ] && continue
        # Явно внешние/системные — не наша зона
        case "$r" in
            usr|bin|etc|tmp|var|opt|home|dev|path|to|absolute|clear|compact|help|init|login|review|morning|evening) continue ;;
        esac
        # Упомянут в доке как внешний — считаем осознанным
        grep -qF "/$r" $DOCS 2>/dev/null && continue
        warn "ссылка '/$r' в скиллах ведёт в скилл, которого нет в паке — проверь, внешний он или забытый"
        ROUTE_BAD=$((ROUTE_BAD + 1))
    done
    [ $ROUTE_BAD -eq 0 ] && ok "битых ссылок на скиллы не найдено"
fi

# --- 3. Приватные пути и личные имена ---
echo ""
echo "[3] Приватность: чужие пути и имена"

PRIV=$(grep -rlE '/Users/[a-z]|/home/[a-z]+/|~/workspace' . \
       --include="*.md" --include="*.sh" --include="*.json" \
       --exclude-dir=.git --exclude="pack-check*.sh" 2>/dev/null | head -20)
if [ -n "$PRIV" ]; then
    block "абсолютные пути чужой машины (у пользователя будут битыми):"
    echo "$PRIV" | sed 's/^/      /'
else
    ok "абсолютных путей чужой машины нет"
fi

if [ -n "$PERSONAL_NAMES" ]; then
    NAME_BAD=0
    for n in $(echo "$PERSONAL_NAMES" | tr ',' '\n'); do
        n=$(echo "$n" | sed 's/^ *//; s/ *$//')
        [ -z "$n" ] && continue
        HITS=$(grep -rl "$n" . --include="*.md" --exclude-dir=.git 2>/dev/null | head -10)
        if [ -n "$HITS" ]; then
            block "личное имя '$n' осталось в паке (в скиллах пиши обезличенно):"
            echo "$HITS" | sed 's/^/      /'
            NAME_BAD=$((NAME_BAD + 1))
        fi
    done
    [ $NAME_BAD -eq 0 ] && ok "личных имён из списка не найдено"
fi

# --- 4. Секреты ---
echo ""
echo "[4] Секреты"

SECRETS=$(grep -rlE '(sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{20,}|AKIA[A-Z0-9]{16}|xoxb-[0-9]{8,}|eyJ[A-Za-z0-9_-]{30,}\.)' . \
          --exclude-dir=.git --exclude="pack-check.sh" 2>/dev/null | head -10)
if [ -n "$SECRETS" ]; then
    block "похоже на живые токены/ключи:"
    echo "$SECRETS" | sed 's/^/      /'
else
    ok "живых токенов не найдено"
fi

if find . -name ".env" -not -path "./.git/*" 2>/dev/null | grep -q .; then
    block ".env лежит в паке — убери и добавь в .gitignore"
fi

# --- 5. Frontmatter скиллов ---
echo ""
echo "[5] Frontmatter скиллов"

if [ -d skills ]; then
    FM_BAD=0
    while IFS= read -r f; do
        [ -z "$f" ] && continue
        head -1 "$f" | grep -q '^---$' || { block "$f — нет frontmatter, Claude такой скилл не подхватит"; FM_BAD=1; continue; }
        head -20 "$f" | grep -q '^name:' || { block "$f — нет поля name:"; FM_BAD=1; }
        head -20 "$f" | grep -q '^description:' || { block "$f — нет поля description: (без него скилл не триггерится)"; FM_BAD=1; }
    done < <(find skills -maxdepth 2 -name SKILL.md 2>/dev/null)
    [ $FM_BAD -eq 0 ] && ok "frontmatter в порядке у всех скиллов"
fi

# --- Итог ---
echo ""
echo "=========================================="
if [ $BLOCKERS -gt 0 ]; then
    echo "  РЕЗУЛЬТАТ: НЕ ПУБЛИКОВАТЬ"
    echo "  Блокеров: $BLOCKERS, предупреждений: $WARNINGS"
    echo "=========================================="
    exit 1
fi
echo "  РЕЗУЛЬТАТ: можно публиковать"
echo "  Блокеров: 0, предупреждений: $WARNINGS"
echo "=========================================="
exit 0
