---
name: build
description: >
  Единый скилл сборки AI-систем. Два режима: single (один агент) и team (AI-офис).
  Ядро процесса: Scout → Adopt → Knowledge → Build → Validate (eval) → Wire.
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

Каждый агент проходит все фазы схемы. БЕЗ ИСКЛЮЧЕНИЙ (единственная оговорка —
ТГ-only рантайм, см. WIRE). Порядок задаётся стрелками — без номеров.

```
INTAKE → BRIEF → SCOUT → ADOPT → KNOWLEDGE → BUILD → VALIDATE → ITERATE → WIRE (→ DEPLOY-HANDOFF, если ТГ)
```

- **INTAKE** — 6-7 уточняющих вопросов Хозяину одним сообщением → ответ одним сообщением
   - 7 тем: роль, выход, взаимодействия, методологии, инструменты, триггеры,
     **рантайм** («где агент будет жить: эфемерный субагент Claude Code / ТГ-бот / оба» —
     определяет протокол памяти и обвязку, см. `knowledge/architecture/memory-architecture.md`)
   - Роль — одной фразой БЕЗ союза «и». Две ответственности = два агента.
   - Без Intake Brief = твои фантазии, а не реальная потребность
   - Исключения: минорная правка (1-2 файла) ИЛИ Хозяин сказал «без вопросов»
     (тогда рантайм по умолчанию = субагент Claude Code)
- **BRIEF** — роль, задачи, связи (собирается ИЗ ответов Intake или из team table)
- **SCOUT** — /scout <домен> → досье в `knowledge/scout/` В КОРНЕ офиса
   (директория с корневым CLAUDE.md офиса; формат `<slug>-YYYY-MM-DD.md`).
   НЕ в папке Демиурга — путь записи и путь проверки «есть ли досье» обязаны совпадать
   (урок ревью 2026-07-21: расхождение путей делало ADOPT слепым)
   - Мировой топ: люди, методологии, публичные скиллы/промпты, MCP, prompt-engineering, reference
   - **Видео-разведка обязательна:** свежие YouTube-разборы (≤12 мес) «как собрать
     [роль]-агента» / «лучшие MCP для [домена]» — вытащить из роликов реальные стеки
     инструментов и воркфлоу (детали — skill-scout, категория 4b)
   - Multi-signal scoring → тиры S/A/B
   - ОБЯЗАТЕЛЬНО перед Knowledge Mining. Исключение: есть досье свежее 30 дней → используй его
- **ADOPT** — обязательный гейт согласования стека. Демиург показывает Хозяину
   **ADOPT-таблицу** из досье (секция «ADOPT-предложение») и ждёт явного апрува:

   | Инструмент | Тип | Тир | Вердикт | Зачем агенту | Установка |
   |---|---|---|---|---|---|
   | aceternity-ui MCP | MCP | S | ставим обязательно | анимированные секции без ручного CSS | `claude mcp add ...` |
   | frontend-design | skill | S | ставим обязательно | анти-generic дизайн-процесс | `npx skills add ...` |
   | <нишевый tool> | MCP | B | опционально — спросить | ... | ... |
   | <слабый tool> | skill | B | отклонено: дублирует X | — | — |

   Вердикты: **ставим обязательно** (без этого агент слабый — Демиург обязан их выделить) /
   **опционально** (спросить Хозяина) / **отклонено** (с причиной). Хозяин правит вердикты →
   одобренное РЕАЛЬНО ставится — `bash scripts/adopt.sh <досье>` (сухой прогон),
   `--apply` ставит «обязательные» и дописывает «ADOPT-итог» в досье; руками то же самое:
   - скиллы: `npx skills add <owner/repo>` в папку офиса
   - MCP: `claude mcp add <server> ...` (scope project)
   - установленное грантится агенту: конкретные `mcp__<server>__<tool>` → в файл-карту
     `knowledge/{agent}/_toolmap.md` (артефакт, не «в голове») → в `tools:` обёртки (BUILD)
   - итог фиксируется В ДОСЬЕ: секция «ADOPT-итог» — что поставлено (фактические
     `mcp__server__tool`), что отклонено и почему.
   Scout без ADOPT = фаза-декорация (0 досье за жизнь Демиурга — урок аудита 2026-07).
- **KNOWLEDGE** — Knowledge Miner сканирует workspace → knowledge/{agent}/ (учитывает scout-досье)
   - Score < 5 = БЛОКЕР (нет данных → нет агента)
   - Score ≥ 5 → продолжаем
- **BUILD** — Builder создаёт CLAUDE.md + skills/ (используя scout-досье + examples/)
   - **Карта инструментов (обязательный шаг):** минимальный allowlist `tools:` под роль
     + КОНКРЕТНЫЕ MCP (`mcp__<server>__<tool>` или `mcp__<server>`) из scout-досье.
     Read-only ролям (валидаторы, разведка) — без Write/Edit. Опущенное `tools:`
     (= унаследовать ВСЁ, включая MCP) — только осознанно, с пометкой почему.
   - **Память под рантайм:** субагент CC → `memory: project` во frontmatter обёртки
     + строка чтения памяти в теле; ТГ-бот → фенс-блок ```memory``` в output contract
     + Stop-хук в мозге (handoff Гефесту, `/deploy-agent`)
- **VALIDATE** — validate-agent.sh (бесплатно) → Validator (LLM) → smoke-миссия
   - Score < 60 = FAIL → пересобрать (назад к BUILD)
   - Score 60-79 = NEEDS WORK → Refiner фиксит → re-validate
   - Score ≥ 80 = PASS по статике
   - **Smoke-миссия:** дай собранному агенту одну реальную задачу его роли через
     Agent tool. Ответ мимо output contract → NEEDS WORK (Refiner); падение, отказ
     без причины или свободное эссе → назад в BUILD (пересборка).
     **Нет пройденного smoke → нет WIRE.** Статический score ≥ 80 при проваленном
     smoke = НЕ PASS (оцениваем результат, не структуру)
   - **Полный поведенческий eval** (3 теста, механика: `references/behavior-eval.md`):
     smoke → discovery-тест триггеринга (5 своих / 3 чужих фразы) → golden-set памяти
     + recall-probe. Провал: smoke → BUILD; discovery → правка description обёртки;
     recall → правка контуров памяти
- **ITERATE** — если NEEDS WORK, макс 2 раунда (BUILD→VALIDATE)
- **WIRE** — Демиург сам, три обязательных действия:
   1. **Регистрация:** проверить/дочинить обёртку `.claude/agents/<name>.md` (создана
      Builder'ом в BUILD; отсутствует — создать) в КОРНЕ офиса
      (директория с корневым CLAUDE.md офиса — родитель `team/` или `office/`;
      каталога нет → `mkdir -p .claude/agents/`). Шаблон обёртки — в
      `knowledge/architecture/agent-design.md` («Обёртка-регистрация»): frontmatter
      `name`, директивный `description` (TRIGGERS + ANTI-TRIGGERS, третье лицо),
      `tools:` из карты инструментов, `model:`, `memory: project`; тело — «загрузи
      CLAUDE.md/core.md агента, прочитай memory.md, grep failures.md».
   2. Роутинг-карта офиса (AGENTS.md / team-registry) + handoff-ссылки — как раньше;
      сверить, что реестр `.claude/agents/` и карта не расходятся.
   3. **Приёмка регистрации:** из ЧИСТОЙ сессии позвать агента по имени — должен
      подняться субагент (маркер «подключился — [Имя]»), а не отыгрыш роли.
      Не поднялся → агент НЕ готов, вернись к п.1.
   *Оговорка ТГ-only рантайма:* обёртка опциональна, Wire-приёмка заменяется
   принятым DEPLOY-HANDOFF-брифом (см. фазу ниже и гейт Wire → Done).
- **DEPLOY-HANDOFF** (только если INTAKE-ответ «где живёт» = ТГ-бот или оба) —
  Демиург НЕ деплоит. Собирает бриф Гефесту и передаёт в `/deploy-agent`:
  имя агента · путь мозга (самодостаточная папка БЕЗ относительных путей наружу) ·
  output contract с фенс-блоком ```memory``` · предложение allowlist инструментов ·
  уникальный TMUX_SESSION_PREFIX. Для ТГ-рантайма обязателен мозг-репо, обёртка
  `.claude/agents/` — по желанию (для параллельной жизни субагентом).

**Зачем SCOUT перед KNOWLEDGE:** scout = внешний research (мировой топ по домену), knowledge = внутренний (что уже есть в workspace). Если собираем агента без знания мирового топа — теряем качество на старте. Scout закрывает эту дыру за ~10-15 минут.

## Субагенты (спавнить через Agent tool)

| Субагент / Скилл | Файл | Модель | Когда |
|----------|------|--------|-------|
| Skill Scout | `skills/scout/SKILL.md` (скилл `/scout`, входит в пак) | sonnet | Scout — ПЕРЕД Knowledge Mining |
| Knowledge Miner | `agents/knowledge-miner.md` | sonnet | Knowledge Mining — ПЕРЕД сборкой |
| Builder | `agents/builder.md` | opus | Build — создание файлов |
| Validator | `agents/validator.md` | sonnet | Validate — проверка |
| Refiner | `agents/refiner.md` | sonnet | Iterate — фиксы по issues |

Для TEAM-режима дополнительно:

| Субагент | Файл | Модель | Когда |
|----------|------|--------|-------|
| Researcher | `agents/researcher.md` | sonnet | Разведка — best practices |
| Auditor | `agents/auditor.md` | sonnet | Разведка — аудит workspace |
| Judge | `agents/judge.md` | opus | Финальная оценка системы |

CustDev-пара (углублённый Intake / душа агента):

| Субагент | Файл | Модель | Когда |
|----------|------|--------|-------|
| Interviewer | `agents/interviewer.md` | opus | Глубинное интервью Хозяина (по запросу) |
| Persona Builder | `agents/persona-builder.md` | sonnet | Характер/душа агента после интервью |

## Knowledge routing

**ПЕРЕД КАЖДОЙ сборкой загрузи:**
1. `knowledge/architecture/ideal-agent-anatomy.md` — эталон
2. `knowledge/evolving/audit-lessons.md` — ошибки НЕ повторять

**Builder ОБЯЗАН прочитать:**
- scout-досье текущего агента (`<корень офиса>/knowledge/scout/<slug>-*.md`) + ADOPT-итог
- `knowledge/{agent}/_toolmap.md` — карта инструментов из ADOPT → источник `tools:` обёртки
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
| Intake → Brief | Получены ответы Хозяина на 6-7 вопросов (или явное «без вопросов» / минорная правка) |
| Brief → Scout | Brief содержит: роль (домен), задачи, связи, рантайм |
| Scout → Adopt | Досье `<корень офиса>/knowledge/scout/<slug>-YYYY-MM-DD.md` создано (или существует свежее 30 дней), в нём есть секция «ADOPT-предложение» с вердиктами |
| Adopt → Knowledge | ADOPT-таблица показана Хозяину, вердикты получены. Одобренное установлено и внесено в `knowledge/{agent}/_toolmap.md` (или явно отклонено с причиной в досье, секция «ADOPT-итог») |
| Knowledge → Build | Knowledge Miner score ≥ 5 |
| Build → Validate | Все файлы созданы (вкл. обёртку `.claude/agents/`), validate-agent.sh PASS |
| Validate → Wire | Validator score ≥ 80 И behavior-eval 3/3 (smoke + discovery 5/3 + golden-set/recall — `references/behavior-eval.md`) |
| Wire → Done | Обёртка в `.claude/agents/` существует, агент позвался по имени из чистой сессии. ТГ-only: вместо этого — принятый DEPLOY-HANDOFF-бриф |
| Iterate | Макс 2 раунда, delta < 5 → стоп |

Детальные критерии: `references/quality-gates.md`

## Пример (SINGLE)

```
Input: "Создай агента-копирайтера для Telegram-канала"

→ BRIEF: копирайтер, посты/рассылки/крео, стиль Хозяина
→ SCOUT: /scout копирайтер → <корень офиса>/knowledge/scout/копирайтер-YYYY-MM-DD.md
  (Hormozi, Sugarman, Schwartz, Halbert + leaked prompts + awesome-lists + 2 YouTube-разбора
  «AI copywriting agent stack»).
→ ADOPT: показал таблицу — 2 обязательных (skill hot-trail-аналог, MCP notion), 1 опционально,
  2 отклонено. Хозяин одобрил → поставил, записал в _toolmap.md и «ADOPT-итог» досье.
→ KNOWLEDGE: Miner нашёл brand/voice.md (563 строки стиля),
  audience/audience-research.md, 5 постов-примеров → score 8
→ BUILD: Builder создал CLAUDE.md 84 строки + 3 скилла,
  использовал examples/copywriter-v1.md как few-shot
→ VALIDATE: validate-agent.sh → 2 warnings. Validator → score 85.
  Smoke: «напиши пост про запуск» → ответ в формате output contract. PASS
→ WIRE: обёртка .claude/agents/copywriter.md (tools, memory: project),
  добавлен в AGENTS.md, handoff от Director.
  Приёмка: новая сессия → «копирайтер, черновик поста» → поднялся субагент ✓
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
