#!/usr/bin/env python3
"""
context-budget.py — сколько контекста агент грузит на каждый тип вызова.

Зачем. Статический score меряет файлы, поведенческий eval меряет ответы, а
цена вызова не меряется ничем. При этом именно она определяет, останется ли
агенту место на работу. Замер на живом офисе: такт копирайтера ~6.7к токенов,
такт свежесобранного агента — 48к. Разница не была видна никому, пока её не
посчитали.

Что считает:
  ПОСТОЯННАЯ ЧАСТЬ — обёртка в .claude/agents/ + файлы, объявленные
    «читается всегда» (LAWS.md и подобные). Платится за КАЖДЫЙ вызов.
  ТАКТ — постоянная часть + тело скилла + всё, что скилл реально тянет
    через contract.reads (транзитивно, с защитой от циклов).

Оценка токенов приблизительная: ~3 байта UTF-8 на токен для смеси
русского и английского. Для решения «резать или нет» точности хватает,
для биллинга — нет.

Запуск:
    python3 context-budget.py <путь-к-агенту> [--office <корень>] [--json]

Коды возврата: 0 — всё в пределах · 1 — есть красные такты · 2 — ошибка.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path

# Оценка токенов. Кириллица токенизируется заметно плотнее латиницы:
# примерно 2.5 символа на токен против 4. Считать байты и делить на константу
# нельзя — в UTF-8 кириллический символ занимает два байта, и оценка уезжает
# почти вдвое. Считаем по символам, раздельно.
CHARS_PER_TOKEN_CYR = 2.5
CHARS_PER_TOKEN_LAT = 4.0

# Пороги. Основание — замер работающих агентов офиса, а не круглые числа.
CONST_GREEN, CONST_YELLOW = 3_000, 5_000
TACT_GREEN, TACT_YELLOW = 8_000, 15_000

# Файлы, которые агент объявляет «читается всегда»
ALWAYS_CANDIDATES = ("LAWS.md", "PRINCIPLES.md", "CANON.md")


def tokens(path: Path) -> int:
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return 0
    cyr = sum(1 for ch in text if "Ѐ" <= ch <= "ӿ")
    return int(cyr / CHARS_PER_TOKEN_CYR + (len(text) - cyr) / CHARS_PER_TOKEN_LAT)


def resolve(ref: str, skill_dir: Path, agent_dir: Path) -> Path | None:
    """Путь из contract может быть от папки скилла или от корня агента."""
    ref = ref.strip().strip("`'\"")
    if not ref or "*" in ref or ref.startswith(("~", "http")):
        return None  # плейсхолдер, глоб или внешний адрес — не считаем
    for base in (skill_dir, agent_dir):
        cand = (base / ref).resolve()
        if cand.is_file():
            return cand
    return None


def contract_reads(skill_md: Path) -> list[str]:
    text = skill_md.read_text(encoding="utf-8", errors="replace")
    block = re.search(r"^contract:.*?(?=^\S|\A---\s*$)", text, re.S | re.M)
    if not block:
        return []
    reads = re.search(r"reads:\s*(\[[^\]]*\]|(?:\n\s+-\s*[^\n]+)+)", block.group(0))
    if not reads:
        return []
    return re.findall(r"[\w./<>-]+\.(?:md|json|txt|py|sh)", reads.group(1))


# Директивы, по которым файл действительно загружается, а не просто назван.
# Упоминание пути в прозе загрузкой НЕ является — иначе счёт раздувается в разы
# и инструмент начинает врать ровно тем способом, против которого написан.
LOAD_DIRECTIVE = re.compile(
    r"(?:прочита|проче|загрузи|подгрузи|читается|открой|read\s)[^\n]{0,80}?"
    r"`([\w./<>-]+\.(?:md|json))`",
    re.I,
)


def follows(start: Path, agent_dir: Path, seen: set[Path]) -> tuple[int, list]:
    """
    Цепочка загрузок: файл читает файл, тот читает следующий.
    Считаем ТОЛЬКО явные директивы чтения. Циклы отсекаем через seen.
    Возвращает (токены цепочки без самого start, список звеньев).
    """
    if start.suffix not in (".md",):
        return 0, []
    text = start.read_text(encoding="utf-8", errors="replace")
    total, chain = 0, []
    for ref in LOAD_DIRECTIVE.findall(text):
        nxt = resolve(ref, start.parent, agent_dir)
        if nxt and nxt not in seen:
            seen.add(nxt)
            t = tokens(nxt)
            deep_t, deep_chain = follows(nxt, agent_dir, seen)
            total += t + deep_t
            chain.append((nxt.name, t))
            chain.extend(deep_chain)
    return total, chain


def mentioned_only(skill_md: Path, agent_dir: Path, counted: set[Path]) -> int:
    """Файлы, названные в теле без директивы чтения. Считаются отдельно —
    это риск «а вдруг подгрузит», а не факт загрузки."""
    text = skill_md.read_text(encoding="utf-8", errors="replace")
    total = 0
    for ref in set(re.findall(r"`([\w./<>-]+\.md)`", text)):
        p = resolve(ref, skill_md.parent, agent_dir)
        if p and p not in counted:
            counted.add(p)
            total += tokens(p)
    return total


def measure(agent_dir: Path, office_root: Path) -> dict:
    name = agent_dir.name
    wrapper = office_root.parent / ".claude" / "agents" / f"{name}.md"
    if not wrapper.is_file():
        wrapper = office_root / ".claude" / "agents" / f"{name}.md"

    const = tokens(wrapper)
    const_parts = [("обёртка", tokens(wrapper))]
    for fname in ALWAYS_CANDIDATES:
        f = agent_dir / fname
        if f.is_file():
            t = tokens(f)
            const += t
            const_parts.append((fname, t))

    tacts = []
    for skill_md in sorted(agent_dir.glob("skills/*/SKILL.md")):
        skill_dir = skill_md.parent
        body = tokens(skill_md)
        seen: set[Path] = {skill_md}
        pulled, missing = 0, []
        detail = []
        for ref in contract_reads(skill_md):
            target = resolve(ref, skill_dir, agent_dir)
            if target is None:
                missing.append(ref)
                continue
            if target in seen:
                continue
            seen.add(target)
            t = tokens(target)
            chain_t, chain = follows(target, agent_dir, seen)
            pulled += t + chain_t
            detail.append((target.name, t + chain_t))
            detail.extend(chain)
        risk = mentioned_only(skill_md, agent_dir, set(seen))
        tacts.append({
            "skill": skill_dir.name,
            "body": body,
            "pulled": pulled,
            "risk": risk,
            "total": const + body + pulled,
            "heaviest": sorted(detail, key=lambda x: -x[1])[:3],
            "unresolved": missing,
        })

    return {"agent": name, "const": const, "const_parts": const_parts,
            "tacts": tacts}


def flag(value: int, green: int, yellow: int) -> str:
    return "🟢" if value <= green else ("🟡" if value <= yellow else "🔴")


def report(data: dict) -> int:
    print(f"\n  БЮДЖЕТ КОНТЕКСТА — {data['agent']}\n")
    c = data["const"]
    print(f"  {flag(c, CONST_GREEN, CONST_YELLOW)} постоянная часть: {c:,} ток."
          f"  (платится за каждый вызов)".replace(",", " "))
    for label, t in data["const_parts"]:
        print(f"        {label:<24} {t:>7,}".replace(",", " "))

    print(f"\n  Такты (постоянная часть + тело скилла + что он тянет):\n")
    worst = 0
    for t in data["tacts"]:
        worst = max(worst, t["total"])
        heavy = " · ".join(f"{n} {v:,}".replace(",", " ") for n, v in t["heaviest"])
        print(f"  {flag(t['total'], TACT_GREEN, TACT_YELLOW)} {t['skill']:<20}"
              f" {t['total']:>7,}".replace(",", " ")
              + f"   тело {t['body']:,} + тянет {t['pulled']:,}".replace(",", " "))
        if heavy:
            print(f"        тяжёлое: {heavy}")
        if t.get("risk"):
            print(f"        + названо в теле без директивы чтения: {t['risk']:,}"
                  .replace(",", " ")
                  + " ток. — в счёт не идёт, но если агент их откроет, такт вырастет")
        if t["unresolved"]:
            print(f"        ⚠ в контракте есть, на диске нет: {', '.join(t['unresolved'][:4])}")

    print(f"\n  Пороги: постоянная часть 🟢≤{CONST_GREEN:,} 🟡≤{CONST_YELLOW:,}"
          f" · такт 🟢≤{TACT_GREEN:,} 🟡≤{TACT_YELLOW:,}".replace(",", " "))
    print("  Основание — замер работающих агентов офиса, не круглые числа.\n")

    if worst > TACT_YELLOW:
        print("  🔴 Есть такты за красной чертой. Что делать по убыванию отдачи:")
        print("     1. Файл, который тянут ВСЕ скиллы, — вынести в постоянную часть")
        print("        не выйдет, он и так там. Значит резать его самого.")
        print("     2. Справочник >3к токенов — разбить и грузить нужный кусок,")
        print("        а не целиком (рубрика целиком нужна на критике, не на сборе).")
        print("     3. «Читается всегда» — проверить, правда ли всегда.")
        print("     4. Дубли между core.md, законами и телом скилла — оставить один.\n")
        return 1
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("agent", help="папка агента, например office/agents/copywriter")
    ap.add_argument("--office", default=None, help="корень офиса (по умолчанию — вверх от агента)")
    ap.add_argument("--json", action="store_true", help="машинный вывод")
    a = ap.parse_args()

    agent_dir = Path(a.agent).resolve()
    if not agent_dir.is_dir():
        print(f"нет такой папки: {agent_dir}", file=sys.stderr)
        return 2
    office = Path(a.office).resolve() if a.office else agent_dir.parent.parent

    data = measure(agent_dir, office)
    if a.json:
        print(json.dumps(data, ensure_ascii=False, indent=2))
        return 1 if any(t["total"] > TACT_YELLOW for t in data["tacts"]) else 0
    return report(data)


if __name__ == "__main__":
    sys.exit(main())
