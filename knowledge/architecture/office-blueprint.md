# Office Blueprint — Универсальная структура AI-офиса

Что обязательно в корне любого офиса который строит Демиург — **независимо от типа** (dev / marketing / client / mixed). Это нижний слой. Над ним — `office-types/{marketing,client,mixed}.md` с особенностями специализаций.

**Когда читать:** перед фазой Build / Wire любого офиса. **Источники:** `~/workspace/knowledge/claude-code-architecture/MASTER.md` (мастер-методология Хозяина, 24.04), `~/workspace/examples/client-office/` (рабочий чистый паттерн), внешний research 25.04 (`audits/2026-04-25-external-research.md`).

---

## 10 железных принципов (синтез MASTER + external research)

1. **Folder = Agent.** Меняешь папку — меняется агент, не модель. `office/agents/{name}/`.
2. **CLAUDE.md ≤ 200 строк** (лучше 100). Карта-указатель и конституция, не свалка знаний. **Сигнал к разбиению:** "Claude игнорит половину инструкций" — на модули.
3. **Index + россыпь маленьких файлов > мегадокумент.** Большой контекст разбей на 10-30 узких .md, заведи INDEX.md как карту.
4. **Progressive Disclosure** (Anthropic Skills): L1 metadata всегда → L2 SKILL.md/CLAUDE.md по триггеру → L3 references on-demand. Применяется и к knowledge/ агента: INDEX (всегда) → architecture/ (по триггеру) → references/ (по запросу).
5. **CLAUDE.md ≠ MEMORY.md.** CLAUDE.md = твои инструкции Claude. MEMORY.md = блокнот Claude про твой проект.
6. **Compound Loop.** Если правишь Claude дважды по одной ошибке — учение в CLAUDE.md / rule / skill, не в голове.
7. **Writer / Reviewer.** Кто написал — не ревьюит. Только чистый контекст ловит слабые места.
8. **Skills vs Subagents vs Hooks** — три разных инструмента: skill = on-demand рецепт, subagent = изолированный коллега для тяжёлой/параллельной работы, hook = детерминированный скрипт на событие. Детали: `agent-design.md` секция «Когда что использовать».
9. **Signal-to-Noise > объём контекста.** После ~30-40% заполнения окна качество ответов деградирует.
10. **Hub-and-spoke дефолт 2026.** Director + N специалистов. Mesh (peer-to-peer) разрешён только для 2 связанных ролей с явным bidirectional handoff'ом и обоснованием в brief'е. Error amplification: hub 4.4× vs mesh 17.2× ([study](https://dev.to/agentsindex/multi-agent-systems-how-they-work-when-to-use-them-and-which-architecture-to-choose-flo)).

---

## Эталонная структура папок

```
{office}/
├── CLAUDE.md                    # Корневой бриф ≤200 строк (см. ниже обязательные секции)
├── AGENTS.md                    # Живая карта команды
├── context.md                   # Текущий snapshot ≤50 строк (ТОП-3 приоритета, активные проекты)
├── STRUCTURE.md                 # Карта папок (для Архитектора команды)
├── .claude/
│   ├── settings.json            # permissions, hooks, allowed_tools
│   ├── rules/                   # Модульные правила (tone, communication, deployment)
│   ├── skills/                  # On-demand рецепты
│   ├── agents/                  # Описания субагентов
│   └── memory/                  # Auto-memory (MEMORY.md ≤200 строк + topic-файлы)
├── agents/
│   └── {name}/
│       ├── CLAUDE.md            # Склейка @core.md @overrides.md (или просто core.md)
│       ├── core.md              # Ядро агента — роль, инструкции, pipeline (template-managed)
│       ├── overrides.md         # Персональные правила клиента (приоритет над core)
│       ├── memory.md            # Decisions/Patterns/Context (append-only, агент сам пишет)
│       ├── failures.md          # Ошибки и правила на будущее (append-only, grep перед задачей)
│       ├── soul.md              # (опционально) Душа, миссия, характер
│       └── knowledge/           # Knowledge агента (если своя, иначе ссылка в общую)
├── knowledge/                   # Общая база знаний (PARA-style)
│   ├── INDEX.md
│   ├── brand/
│   ├── methodology/
│   ├── audience/
│   └── case-studies/
├── projects/                    # Активные проекты
│   └── {project}/
│       ├── CLAUDE.md            # Проектный бриф
│       ├── brief.md
│       └── outputs/
├── clients/                     # (для client-офисов) единое хранилище клиентов
│   ├── INDEX.md
│   └── {client}/
│       ├── CLAUDE.md
│       ├── brief.md
│       └── communications/
├── ops/
│   ├── log.md
│   └── decisions/
├── protocols/                   # Governance, data-routing, hand-off протоколы
└── archive/                     # Завершённое read-only
```

**Правила:**
- Максимум **3 уровня вложенности** для рабочих файлов (Claude теряется глубже)
- **Путь = смысл** — по пути файла Claude понимает что внутри без чтения
- **clients/ — symlink** из office/hub/clients/ если есть оба слоя — единый источник правды
- **archive/ — read-only**, не подгружается в текущий контекст

---

## Корневой `office/CLAUDE.md` — обязательные секции

Шаблон ~150 строк. Каждая секция — 5-15 строк, не больше.

1. **Что это** (1 строка). "AI-офис v2: операционная система для управления онлайн-школой через Claude Code."
2. **Роль и режим работы.** Кто ты (имя/роль), партнёр кого. Перехват задач: Tier → агент → предложение.
3. **Tier (приоритеты).** Revenue Tiers 1-4, A+ Task = Tier 1, ratio ≥ 40%.
4. **Навигация** — таблица `Что → Где` (4-6 строк).
5. **Команда** — ссылка на `office/AGENTS.md` (всегда живая карта). НЕ перечислять всех агентов в CLAUDE.md.
6. **Reading order для новой сессии.** Какие 3-5 файлов первыми (CLAUDE.md → AGENTS.md → context.md → projects/active/brief.md).
7. **Кодовые слова и аббревиатуры.** Как клиент/владелец говорит ↔ что делать.
8. **Инструменты и сервисы.** Notion (если используется) как ЕДИНЫЙ источник, VPS, GitHub, Telegram.
9. **Guardrails.** Расходы, секреты, типографика, безопасность.
10. **Когда звать человека.** Триггеры для эскалации (2 фейла → REWIND, размытая → /interview).
11. **Что запоминать в память** (4 категории: user_*, feedback_*, project_*, reference_*).
12. **Что НЕ запоминать.** Чувствительные данные, состояние задачи, дубли.

**Тест на каждую строку (HumanLayer, самая цитируемая статья 2026):** «Если убрать эту строку — Claude ошибётся в следующей сессии? Если нет — режь.»

---

## Каскад CLAUDE.md (грузится сверху вниз)

| Уровень | Путь | Что туда |
|---------|------|----------|
| Глобальный | `~/.claude/CLAUDE.md` | Стиль владельца (em-dash, тон), общие принципы для всех проектов |
| Проектный | `./CLAUDE.md` | Что за проект, ЦА, навигация, кодовые слова |
| Локальный | `./.claude/CLAUDE.md` | (опционально) правила, валидные только в этой папке |
| Подпапочный | `./clients/x/CLAUDE.md` | Контекст клиента — грузится только при работе там |
| Личный | `./CLAUDE.local.md` | Секреты, тестовые ключи (gitignored) |

---

## Layered memory у каждого агента

Двухгенерационный консенсус (mnemo + client-office-template + Letta/Anthropic memory tool). См. детали в `memory-architecture.md`.

| Файл | Что там | Кто редактирует |
|------|---------|-----------------|
| `core.md` | Ядро — роль, инструкции, pipeline | Template-managed (обновляется через `/update-agents`) |
| `overrides.md` | Персональные правила клиента | Клиент пишет руками, **приоритет над core** |
| `memory.md` | Decisions/Patterns/Context (append-only) | **Агент пишет сам** после задач |
| `failures.md` | Ошибки + правила на будущее (append-only) | **Агент пишет сам**, grep перед каждой задачей |
| `CLAUDE.md` | Склейка `@core.md @overrides.md` (если используется include) | Не трогать |

Это даёт агенту **реальное обучение на опыте**, а не статичный промпт. Memory append-only — старые записи не переписываются.

---

## Decision tree: соло-агент или офис?

Multi-agent стоит ~15× токенов и не окупается для мелких задач (Anthropic). **Перед TEAM-режимом — ROI-чек:**

| Условие | Действие |
|---------|----------|
| Задачи < 4 человеко-часов в неделю | Один агент со скиллами, не офис |
| Сильная взаимозависимость задач (большинство кодовых) | Один агент со скиллами |
| Нужен общий контекст всем агентам одновременно | Один агент со скиллами |
| Задачи параллелизуемы (research, marketing campaigns, account management) | Офис (multi-agent) |
| > 1 явный домен экспертизы (marketing + sales + product) | Офис с pod'ами |

**В Intake:** обязательный вопрос клиенту — «какие задачи отдаёшь офису, сколько часов в неделю занимают у человека?»

---

## Office types — особенности по специализациям

Универсальный blueprint выше — нижний слой. Сверху — особенности типа:

- **`office-types/marketing.md`** — состав 6 ролей (Campaign Strategist, Copywriter, Designer, Content Strategist, Performance Analyst, Intelligence). Brand guidelines как validator, tone-of-voice как linter, CTR как test-suite.
- **`office-types/client.md`** — состав 7 ролей (Client Director, BDR/SDR, AE, Proposal, Customer Success, Support Triage, Intelligence). Long-running memory critical, bi-temporal graph для устаревающих фактов, human-in-the-loop на trust boundaries.
- **`office-types/mixed.md`** — гибрид (Нейроштаб). > 8 агентов → pod'ы обязательны (один Director-lite на pod, Top-Director связывает). Главная опасность — пересечение зон.

---

## Чего категорически НЕ класть в корневой CLAUDE.md

- Полное описание ЦА с цитатами и сегментами → `knowledge/audience.md`, ссылка
- Длинные таблицы клиентов → `clients/INDEX.md`
- Конкретные SOP / процедуры → `skills/`
- Технические детали реализации продукта → `projects/x/CLAUDE.md`
- Историю проекта → `knowledge/case-studies/`
- Правила линтера / code style → работа prettier/eslint, не AI
- Литературные тексты, мотивационные речи. Декларативные пункты, не проза.

---

## Эталоны (читай перед сборкой)

**Внутренние:**
- `~/workspace/knowledge/claude-code-architecture/MASTER.md` — мастер-методология (56К). Полная теория.
- `~/workspace/examples/client-office/` — целевой blueprint (layered memory + agent-packs + язык-для-клиента). Чистый паттерн второго поколения.
- `~/workspace/office/` — реальный сложный офис на 17 агентов. **С минусами** (нет единого формата памяти, Director > 200 строк) — учит и тому что НЕ повторять.

**Внешние:**
- [Anthropic — Building effective agents](https://www.anthropic.com/engineering/building-effective-agents)
- [Anthropic — Multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system)
- [Anthropic — Equipping agents with Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
