---
name: build
description: >
  Единый скилл сборки AI-систем. Два режима: single (один агент) и team (AI-офис).
  Ядро процесса: Knowledge Mining → Build → Validate → Iterate.
  Агент строится ВОКРУГ знаний, а не знания подгоняются под шаблон.
  MANDATORY TRIGGERS: собери, создай агента, пересобери, build, новый агент,
  AI-офис, команду, wizard, heavy, light, пересобрать.
  DO NOT use when: аудит (→ внешний review), полировка (→ внешний polish), код (→ CTO).
---

# Build — Сборка AI-систем

Единая точка входа. Два режима — один процесс.

## Режимы

```
SINGLE — один агент или скилл
  Knowledge Mining → Build → Validate. 10-30 мин.
  Триггеры: "создай агента", "один скилл", "добавь агента"

TEAM — AI-офис с нуля (wizard + интервью)
  Intake → Blueprint → Team → Knowledge Mining → Build → Wiring → Soul → Onboarding.
  Детали: references/wizard-phases.md
  Триггеры: "собери команду", "wizard", "офис с нуля"
```

Если непонятно какой режим — спроси: "Один агент или целая команда?"

## Ядро процесса (для ОБОИХ режимов)

Каждый агент проходит 8 этапов. БЕЗ ИСКЛЮЧЕНИЙ. Порядок задаётся стрелками — без номеров.

```
INTAKE → BRIEF → SCOUT → KNOWLEDGE → BUILD → VALIDATE → ITERATE → WIRE
```

- **INTAKE** — 5-6 уточняющих вопросов Хозяину одним сообщением → ответ одним сообщением
   - 6 тем: роль, выход, взаимодействия, методологии, инструменты, триггеры
   - Без Intake Brief = твои фантазии, а не реальная потребность
   - Исключения: минорная правка (1-2 файла) ИЛИ Хозяин сказал «без вопросов»
- **BRIEF** — роль, задачи, связи (собирается ИЗ ответов Intake или из team table)
- **SCOUT** — /scout <домен> → досье в knowledge/scout/<домен>-YYYY-MM-DD.md
   - Мировой топ: люди, методологии, публичные скиллы/промпты, MCP, prompt-engineering, reference
   - Multi-signal scoring → тиры S/A/B
   - ОБЯЗАТЕЛЬНО перед Knowledge Mining. Исключение: есть досье свежее 30 дней → используй его
- **KNOWLEDGE** — Knowledge Miner сканирует workspace → knowledge/{agent}/ (учитывает scout-досье)
   - Score < 5 = БЛОКЕР (нет данных → нет агента)
   - Score ≥ 5 → продолжаем
- **BUILD** — Builder создаёт CLAUDE.md + skills/ (используя scout-досье + examples/)
- **VALIDATE** — validate-agent.sh (бесплатно) → Validator (LLM)
   - Score < 60 = FAIL → пересобрать (назад к BUILD)
   - Score 60-79 = NEEDS WORK → Refiner фиксит → re-validate
   - Score ≥ 80 = PASS
- **ITERATE** — если NEEDS WORK, макс 2 раунда (BUILD→VALIDATE)
- **WIRE** — Демиург сам: AGENTS.md, context.md, handoff-ссылки

**Зачем SCOUT перед KNOWLEDGE:** scout = внешний research (мировой топ по домену), knowledge = внутренний (что уже есть в workspace). Если собираем агента без знания мирового топа — теряем качество на старте. Scout закрывает эту дыру за ~10-15 минут.

## Субагенты (спавнить через Agent tool)

| Субагент / Скилл | Файл | Модель | Когда |
|----------|------|--------|-------|
| Skill Scout | `~/.claude/skills/skill-scout/SKILL.md` (скилл `/scout`) | sonnet | Scout — ПЕРЕД Knowledge Mining |
| Knowledge Miner | `agents/knowledge-miner.md` | sonnet | Knowledge Mining — ПЕРЕД сборкой |
| Builder | `agents/builder.md` | opus | Build — создание файлов |
| Validator | `agents/validator.md` | sonnet | Validate — проверка |
| Refiner | `agents/refiner.md` | sonnet | Iterate — фиксы по issues |

Для TEAM-режима дополнительно:
| Researcher | `agents/researcher.md` | sonnet | Разведка — best practices |
| Auditor | `agents/auditor.md` | sonnet | Разведка — аудит workspace |
| Judge | `agents/judge.md` | opus | Финальная оценка системы |

## Knowledge routing

**ПЕРЕД КАЖДОЙ сборкой загрузи:**
1. `knowledge/architecture/ideal-agent-anatomy.md` — эталон
2. `knowledge/evolving/audit-lessons.md` — ошибки НЕ повторять

**Builder ОБЯЗАН прочитать:**
- `knowledge/examples/` — реальные работающие агенты как few-shot
- `knowledge/architecture/agent-design.md` — шаблон CLAUDE.md
- `knowledge/skill-mastery/anatomy.md` — шаблон скилла

Полная таблица routing: `references/knowledge-routing.md`

## validate-agent.sh (бесплатная проверка)

```bash
bash scripts/validate-agent.sh /path/to/agent/
```
Ловит 80% проблем без LLM: ссылки, размер, frontmatter, примеры, AI-слоп.
Запускай ПЕРЕД Validator-субагентом.

## Output contract

Результат build = директория агента:
```
{agent}/
  CLAUDE.md        ≤150 строк, identity ≤300 tok
  skills/          SKILL.md с MANDATORY TRIGGERS
  knowledge/       реальный контент (не пустые ссылки)
```

## Quality gates

| Этап | Условие перехода |
|------|-----------------|
| Intake → Brief | Получены ответы Хозяина на 5-6 вопросов (или явное «без вопросов» / минорная правка) |
| Brief → Scout | Brief содержит: роль (домен), задачи, связи |
| Scout → Knowledge | Досье `knowledge/scout/<домен>-YYYY-MM-DD.md` создано (или существует свежее 30 дней). Хозяин одобрил топ-5 |
| Knowledge → Build | Knowledge Miner score ≥ 5 |
| Build → Validate | Все файлы созданы, validate-agent.sh PASS |
| Validate → Done | Validator score ≥ 80 |
| Iterate | Макс 2 раунда, delta < 5 → стоп |

Детальные критерии: `references/quality-gates.md`

## Пример (SINGLE)

```
Input: "Создай агента-копирайтера для Telegram-канала"

→ BRIEF: копирайтер, посты/рассылки/крео, стиль Хозяина
→ SCOUT: /scout копирайтер → knowledge/scout/копирайтер-YYYY-MM-DD.md
  (Hormozi, Sugarman, Schwartz, Halbert + leaked prompts + awesome-lists).
  Хозяин одобрил топ-5.
→ KNOWLEDGE: Miner нашёл brand/voice.md (563 строки стиля),
  audience/audience-research.md, 5 постов-примеров → score 8
→ BUILD: Builder создал CLAUDE.md 84 строки + 3 скилла,
  использовал examples/copywriter-v1.md как few-shot
→ VALIDATE: validate-agent.sh → 2 warnings. Validator → score 85 PASS
→ WIRE: добавлен в AGENTS.md, handoff от Director
```

## Пример (TEAM)

```
Input: "Собери AI-офис для коуча с 3 проектами"

→ INTAKE: 4 вопроса → проекты, стек, команда (references/wizard-phases.md)
→ BLUEPRINT: small-team, scaffold → 18 файлов
→ TEAM: Director + CTO + CMO, таблица зон
→ Для КАЖДОГО агента: Knowledge → Build → Validate → Iterate
→ WIRING: AGENTS.md + context.md + DRY-RUN 3/3
→ SOUL: Creator добавляет характер каждому
→ ONBOARDING: quick-start + user-guide
→ Результат: 26 файлов, avg score 84
```

## Стоп-краны

- Макс 10 агентов (>7 = warning, >10 = Hierarchical)
- Макс 2 раунда iterate на агента
- Макс 3 раунда review на систему (TEAM)
- >50% контекста → compact, >70% → checkpoint + /clear
- Knowledge score < 5 → БЛОКЕР, не строить

## Ссылки

- Wizard фазы (TEAM режим): `references/wizard-phases.md`
- Субагенты (спеки): `references/subagent-specs.md`
- Quality gates (детали): `references/quality-gates.md`
- Knowledge routing: `references/knowledge-routing.md`
